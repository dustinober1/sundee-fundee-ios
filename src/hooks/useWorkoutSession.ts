/**
 * useWorkoutSession — manages active workout session state.
 *
 * Wraps pure session-action domain functions with React state and
 * AsyncStorage persistence. Provides:
 *   - startWorkout / finishWorkout lifecycle
 *   - Dispatch functions for all session mutations
 *   - Auto-save to AsyncStorage on every set completion (crash recovery)
 *   - Restore active workout from AsyncStorage on mount
 *   - getPreviousValues for ghost-text placeholders in SetRow
 */

import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  createSession,
  addExercise,
  removeExercise,
  addSet,
  completeSet,
  reorderExercises,
} from '../domain/workout-session/session-actions';
import type { WorkoutSession } from '../domain/workout-session/session-types';
import { getWorkoutRepo } from '../repositories/WorkoutRepo';
import type { WorkoutRecord, CompletedExercise, CompletedSet } from '../repositories/WorkoutRepo';

const ACTIVE_WORKOUT_KEY = '@sundee/active-workout';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AddExerciseParams {
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
}

export interface CompleteSetParams {
  weight: number;
  reps: number;
  isPersonalRecord?: boolean;
}

export interface UseWorkoutSessionReturn {
  session: WorkoutSession | null;
  isActive: boolean;
  startWorkout: () => void;
  finishWorkout: (uid: string) => Promise<void>;
  dispatchAddExercise: (params: AddExerciseParams) => void;
  dispatchRemoveExercise: (activeExerciseId: string) => void;
  dispatchAddSet: (activeExerciseId: string) => void;
  dispatchCompleteSet: (activeExerciseId: string, setId: string, data: CompleteSetParams) => void;
  dispatchReorderExercises: (orderedIds: string[]) => void;
  getPreviousValues: (exerciseId: string) => Promise<{ weight: number; reps: number }[]>;
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

/**
 * @param isGuest - Whether the user is in guest mode; selects Local vs Firestore repos
 */
export function useWorkoutSession(isGuest: boolean): UseWorkoutSessionReturn {
  const [session, setSession] = useState<WorkoutSession | null>(null);

  // ── Crash recovery: restore any in-progress workout on mount ──────────────
  useEffect(() => {
    async function restoreSession(): Promise<void> {
      try {
        const stored = await AsyncStorage.getItem(ACTIVE_WORKOUT_KEY);
        if (stored) {
          const parsed = JSON.parse(stored) as WorkoutSession;
          setSession(parsed);
        }
      } catch {
        // Corrupted storage — start fresh
      }
    }
    void restoreSession();
  }, []);

  // ── Persist session to AsyncStorage ─────────────────────────────────────
  const persist = useCallback(async (s: WorkoutSession): Promise<void> => {
    try {
      await AsyncStorage.setItem(ACTIVE_WORKOUT_KEY, JSON.stringify(s));
    } catch {
      // Non-fatal — session still lives in state
    }
  }, []);

  // ── startWorkout ──────────────────────────────────────────────────────────
  const startWorkout = useCallback((): void => {
    const newSession = createSession('none');
    setSession(newSession);
    void persist(newSession);
  }, [persist]);

  // ── finishWorkout ─────────────────────────────────────────────────────────
  const finishWorkout = useCallback(
    async (uid: string): Promise<void> => {
      if (!session) return;

      const now = new Date();
      const startedAt = new Date(session.startedAt);
      const durationSeconds = Math.round((now.getTime() - startedAt.getTime()) / 1000);

      // Convert WorkoutSession to WorkoutRecord
      const exercises: CompletedExercise[] = session.exercises.map((ae) => ({
        exerciseId: ae.exerciseId,
        exerciseName: ae.exerciseName,
        muscleGroup: ae.muscleGroup,
        sets: ae.sets
          .filter((s) => s.completed)
          .map(
            (s): CompletedSet => ({
              weight: s.weight,
              reps: s.reps,
              isPersonalRecord: s.isPersonalRecord ?? false,
            }),
          ),
      }));

      const totalVolume = exercises.reduce(
        (total, ex) =>
          total + ex.sets.reduce((exTotal, s) => exTotal + s.weight * s.reps, 0),
        0,
      );

      const record: WorkoutRecord = {
        id: session.id,
        uid,
        completedAt: now.toISOString(),
        durationSeconds,
        source: 'custom',
        exercises,
        totalVolume,
        exerciseCount: exercises.length,
        timerMode: session.timerMode ?? 'none',
      };

      const repo = getWorkoutRepo(isGuest);
      await repo.saveWorkout(uid, record);

      // Clear active workout from AsyncStorage
      try {
        await AsyncStorage.removeItem(ACTIVE_WORKOUT_KEY);
      } catch {
        // Non-fatal
      }

      setSession(null);
    },
    [session, isGuest],
  );

  // ── Dispatch wrappers ────────────────────────────────────────────────────
  const dispatchAddExercise = useCallback(
    (params: AddExerciseParams): void => {
      setSession((prev) => {
        if (!prev) return prev;
        const updated = addExercise(prev, params);
        void persist(updated);
        return updated;
      });
    },
    [persist],
  );

  const dispatchRemoveExercise = useCallback(
    (activeExerciseId: string): void => {
      setSession((prev) => {
        if (!prev) return prev;
        const updated = removeExercise(prev, activeExerciseId);
        void persist(updated);
        return updated;
      });
    },
    [persist],
  );

  const dispatchAddSet = useCallback(
    (activeExerciseId: string): void => {
      setSession((prev) => {
        if (!prev) return prev;
        const updated = addSet(prev, activeExerciseId);
        void persist(updated);
        return updated;
      });
    },
    [persist],
  );

  const dispatchCompleteSet = useCallback(
    (activeExerciseId: string, setId: string, data: CompleteSetParams): void => {
      setSession((prev) => {
        if (!prev) return prev;
        // First apply completeSet domain action, then inject isPersonalRecord flag
        const updated = completeSet(prev, activeExerciseId, setId, {
          weight: data.weight,
          reps: data.reps,
        });
        // Inject isPersonalRecord onto the completed set if provided
        const withPR: WorkoutSession = {
          ...updated,
          exercises: updated.exercises.map((ae) =>
            ae.id !== activeExerciseId
              ? ae
              : {
                  ...ae,
                  sets: ae.sets.map((s) =>
                    s.id !== setId ? s : { ...s, isPersonalRecord: data.isPersonalRecord ?? false },
                  ),
                },
          ),
        };
        void persist(withPR);
        return withPR;
      });
    },
    [persist],
  );

  const dispatchReorderExercises = useCallback(
    (orderedIds: string[]): void => {
      setSession((prev) => {
        if (!prev) return prev;
        const updated = reorderExercises(prev, orderedIds);
        void persist(updated);
        return updated;
      });
    },
    [persist],
  );

  // ── getPreviousValues ─────────────────────────────────────────────────────
  /**
   * Returns the weight/reps pairs from the last completed workout that included
   * this exercise, in set order. Used for ghost-text placeholders in SetRow.
   */
  const getPreviousValues = useCallback(
    async (exerciseId: string): Promise<{ weight: number; reps: number }[]> => {
      try {
        // We need a uid to query — for guest mode uid is irrelevant (single user storage)
        const repo = getWorkoutRepo(isGuest);
        const history = await repo.getHistory('', 20);
        // Find the most recent workout containing this exercise
        for (const record of history) {
          const match = record.exercises?.find((e) => e.exerciseId === exerciseId);
          if (match && match.sets.length > 0) {
            return match.sets.map((s) => ({ weight: s.weight, reps: s.reps }));
          }
        }
      } catch {
        // Non-fatal — just show no ghost text
      }
      return [];
    },
    [isGuest],
  );

  return {
    session,
    isActive: session !== null,
    startWorkout,
    finishWorkout,
    dispatchAddExercise,
    dispatchRemoveExercise,
    dispatchAddSet,
    dispatchCompleteSet,
    dispatchReorderExercises,
    getPreviousValues,
  };
}

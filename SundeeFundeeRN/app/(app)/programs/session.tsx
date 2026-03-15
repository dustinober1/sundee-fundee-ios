/**
 * app/(app)/programs/session.tsx — Active Program Session.
 *
 * Displays the current program session for the enrolled user.
 * Shows each exercise with target weight calculated from the user's logged 1RM.
 *
 * Features:
 * - Load current enrollment to determine week/session indices
 * - Load the matching ProgramSession from the enrolled program
 * - Load user's exercise maxes for target weight calculation
 * - Display: exercise name, sets x reps, target weight (or "X% 1RM" fallback)
 * - Rest period indicator (in seconds)
 * - "Complete Session" — updates enrollment progress, saves workout record, navigate to dashboard
 * - "Start Workout" — navigate to workout-session with exercises preloaded (future: Phase 9)
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getProgramRepo } from '@/src/repositories/ProgramRepo';
import type { Program, ProgramEnrollment, ProgramSession } from '@/src/repositories/ProgramRepo';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import {
  calculateTargetWeight,
  formatTargetWeight,
} from '@/src/components/programs/target-weight';
import type { ExerciseMax } from '@/src/domain/pr-detection/pr-types';
import type { ProgramExercise } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';

// ─── Helper: get current session ────────────────────────────────────────────

/**
 * Returns the ProgramSession for the current enrollment position.
 * Programs store sessions in a flat array. Enrollment tracks currentSession index.
 * Exported for unit testing.
 */
export function getCurrentSession(
  program: Program,
  enrollment: ProgramEnrollment
): ProgramSession | null {
  const session = program.sessions[enrollment.currentSession];
  return session ?? null;
}

/**
 * Computes the next enrollment position after completing the current session.
 * Wraps back to week 0 / session 0 when the last session is reached.
 * Exported for unit testing.
 */
export function getNextEnrollmentPosition(
  program: Program,
  enrollment: ProgramEnrollment
): { weekIndex: number; sessionIndex: number } {
  const nextSessionIndex = enrollment.currentSession + 1;
  if (nextSessionIndex >= program.sessions.length) {
    // Program complete — reset to beginning (repeat cycle)
    return { weekIndex: 0, sessionIndex: 0 };
  }
  return { weekIndex: enrollment.currentWeek, sessionIndex: nextSessionIndex };
}

// ─── ExerciseRow component ───────────────────────────────────────────────────

interface ExerciseRowProps {
  exercise: ProgramExercise;
  maxes: ExerciseMax[];
}

function formatRepsDisplay(exercise: ProgramExercise): string {
  const r = exercise.reps;
  switch (r.kind) {
    case 'fixed': return String(r.value);
    case 'range': return `${r.lo}–${r.hi}`;
    case 'amrap': return 'AMRAP';
    case 'text': return r.value;
  }
}

function ExerciseRow({ exercise, maxes }: ExerciseRowProps): React.JSX.Element {
  const weight = exercise.weight;

  // Determine target weight display
  let targetWeightDisplay: string | null = null;
  if (weight && weight.kind === 'fixed' && weight.value <= 1.0) {
    // Percentage weight — calculate from 1RM
    const absolute = calculateTargetWeight(exercise.name, weight.value, maxes);
    targetWeightDisplay = formatTargetWeight(absolute, weight.value);
  } else if (weight && weight.kind === 'text') {
    targetWeightDisplay = weight.value;
  } else if (weight && weight.kind === 'range') {
    if (weight.lo <= 1.0) {
      // Percentage range
      const lo = calculateTargetWeight(exercise.name, weight.lo, maxes);
      const hi = calculateTargetWeight(exercise.name, weight.hi, maxes);
      if (lo !== null && hi !== null) {
        targetWeightDisplay = `${lo}–${hi} lbs`;
      } else {
        targetWeightDisplay = `${Math.round(weight.lo * 100)}–${Math.round(weight.hi * 100)}% 1RM`;
      }
    }
  }

  return (
    <View style={styles.exerciseRow}>
      <View style={styles.exerciseInfo}>
        <Text style={styles.exerciseName}>{exercise.name}</Text>
        <Text style={styles.exerciseSetsReps}>
          {exercise.sets} sets × {formatRepsDisplay(exercise)}
        </Text>
        {exercise.restSeconds !== undefined && exercise.restSeconds > 0 && (
          <Text style={styles.exerciseRest}>
            Rest: {exercise.restSeconds}s
          </Text>
        )}
      </View>
      {targetWeightDisplay ? (
        <View style={styles.weightBadge}>
          <Text style={styles.weightBadgeText}>{targetWeightDisplay}</Text>
        </View>
      ) : null}
    </View>
  );
}

// ─── ProgramSessionScreen ────────────────────────────────────────────────────

export default function ProgramSessionScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [program, setProgram] = useState<Program | null>(null);
  const [enrollment, setEnrollment] = useState<ProgramEnrollment | null>(null);
  const [maxes, setMaxes] = useState<ExerciseMax[]>([]);
  const [loading, setLoading] = useState(true);
  const [completing, setCompleting] = useState(false);

  const uid = user?.uid ?? '';

  useFocusEffect(
    useCallback(() => {
      let cancelled = false;
      setLoading(true);

      const loadData = async (): Promise<void> => {
        try {
          const enroll = await getProgramRepo(isGuest).getEnrollment(uid);
          if (!enroll || cancelled) {
            if (!cancelled) setLoading(false);
            return;
          }

          const [prog, userMaxes] = await Promise.all([
            getProgramRepo(isGuest).getProgram(enroll.programId),
            getExerciseMaxRepo(isGuest).getAllMaxes(uid),
          ]);

          if (cancelled) return;
          setEnrollment(enroll);
          setProgram(prog);
          setMaxes(userMaxes);
        } catch {
          // Graceful degradation
        } finally {
          if (!cancelled) setLoading(false);
        }
      };

      void loadData();

      return () => {
        cancelled = true;
      };
    }, [uid, isGuest])
  );

  const handleCompleteSession = useCallback(async (): Promise<void> => {
    if (!program || !enrollment) return;
    setCompleting(true);

    try {
      const currentSession = getCurrentSession(program, enrollment);
      const { weekIndex, sessionIndex } = getNextEnrollmentPosition(program, enrollment);

      await getProgramRepo(isGuest).updateEnrollmentProgress(uid, weekIndex, sessionIndex);

      // Save completed workout record
      const workoutRecord = {
        id: `program-${Date.now()}`,
        uid,
        completedAt: new Date().toISOString(),
        durationSeconds: 0,
        source: 'program' as const,
        workoutName: currentSession?.name ?? program.name,
        exercises: [],
        exerciseCount: currentSession?.exercises.length ?? 0,
      };
      await getWorkoutRepo(isGuest).saveWorkout(uid, workoutRecord);

      // Navigate back to dashboard (tab index 0)
      router.replace('/(app)/(tabs)');
    } catch {
      Alert.alert('Error', 'Could not save session. Please try again.');
    } finally {
      setCompleting(false);
    }
  }, [program, enrollment, uid, isGuest, router]);

  // ─── Loading state ─────────────────────────────────────────────────────

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  if (!enrollment || !program) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorText}>No active program enrollment.</Text>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.push('/programs')}
        >
          <Text style={styles.backButtonText}>Browse Programs</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const currentSession = getCurrentSession(program, enrollment);

  if (!currentSession) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.errorText}>Session not found.</Text>
      </View>
    );
  }

  const weekDisplay = enrollment.currentWeek + 1;
  const sessionDisplay = enrollment.currentSession + 1;

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.scrollContent}>
      {/* Session header */}
      <View style={styles.sessionHeader}>
        <Text style={styles.programLabel}>{program.name}</Text>
        <Text style={styles.sessionName}>{currentSession.name}</Text>
        <Text style={styles.sessionMeta}>
          Week {weekDisplay} · Session {sessionDisplay} of {program.sessions.length}
        </Text>
      </View>

      {/* Exercise list */}
      <View style={styles.exerciseSection}>
        <Text style={styles.sectionTitle}>
          {currentSession.exercises.length} Exercise{currentSession.exercises.length !== 1 ? 's' : ''}
        </Text>
        {currentSession.exercises.map((exercise) => (
          <ExerciseRow
            key={exercise.id}
            exercise={exercise}
            maxes={maxes}
          />
        ))}
      </View>

      {/* Target weight note */}
      {maxes.length === 0 && (
        <View style={styles.noMaxesNote}>
          <Text style={styles.noMaxesNoteText}>
            Log your 1RM maxes to see personalized target weights. Visit the Maxes tab to get started.
          </Text>
        </View>
      )}

      {/* Action buttons */}
      <View style={styles.actionsSection}>
        <TouchableOpacity
          style={[styles.completeButton, completing && styles.buttonDisabled]}
          onPress={() => { void handleCompleteSession(); }}
          disabled={completing}
        >
          {completing ? (
            <ActivityIndicator color={colors.CREAM} size="small" />
          ) : (
            <Text style={styles.completeButtonText}>Complete Session</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

// ─── Styles ──────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  scrollContent: {
    paddingBottom: 48,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
    padding: 24,
    gap: 16,
  },
  errorText: {
    fontSize: 16,
    color: colors.GREY,
    textAlign: 'center',
  },
  backButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: colors.NAVY,
  },
  backButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.CREAM,
  },

  // Session header
  sessionHeader: {
    backgroundColor: colors.NAVY,
    paddingHorizontal: 20,
    paddingVertical: 24,
  },
  programLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.ORANGE,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 6,
  },
  sessionName: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 0.3,
    marginBottom: 6,
  },
  sessionMeta: {
    fontSize: 13,
    color: colors.CREAM,
    opacity: 0.7,
  },

  // Exercise section
  exerciseSection: {
    paddingHorizontal: 16,
    paddingTop: 20,
    gap: 2,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  exerciseRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 8,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  exerciseInfo: {
    flex: 1,
    gap: 3,
  },
  exerciseName: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  exerciseSetsReps: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
  exerciseRest: {
    fontSize: 12,
    color: colors.GREY,
  },
  weightBadge: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    marginLeft: 12,
  },
  weightBadgeText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.ORANGE_DARK,
  },

  // No maxes note
  noMaxesNote: {
    marginHorizontal: 16,
    marginTop: 12,
    padding: 14,
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 8,
    borderLeftWidth: 3,
    borderLeftColor: colors.GREY_LIGHT,
  },
  noMaxesNoteText: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },

  // Actions
  actionsSection: {
    paddingHorizontal: 16,
    paddingTop: 24,
    gap: 12,
  },
  completeButton: {
    backgroundColor: colors.ORANGE,
    paddingVertical: 16,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  completeButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
});

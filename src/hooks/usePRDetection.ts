/**
 * usePRDetection — loads ExerciseMax cache and checks PRs on set completion.
 *
 * Provides:
 *   - checkAndRecordPR(exerciseId, weight, reps) — checks PR, saves new max, returns result
 *   - recentPRs — queue of recent PR results for toast display
 *   - clearRecentPRs — dismiss all pending toasts
 *   - loadMaxes(uid) — explicit load trigger (call on workout start)
 */

import { useState, useCallback, useRef } from 'react';
import { getExerciseMaxRepo } from '../repositories/ExerciseMaxRepo';
import { checkForPR } from '../domain/pr-detection/check-pr';
import { estimated1RM } from '../domain/calculations/epley-formula';
import type { ExerciseMax, PRCheckResult } from '../domain/pr-detection/pr-types';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface UsePRDetectionReturn {
  recentPRs: PRCheckResult[];
  loadMaxes: (uid: string) => Promise<void>;
  checkAndRecordPR: (
    uid: string,
    exerciseId: string,
    exerciseName: string,
    weight: number,
    reps: number,
  ) => Promise<PRCheckResult>;
  clearRecentPRs: () => void;
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

/**
 * @param isGuest - Whether the user is in guest mode; selects Local vs Firestore repos
 */
export function usePRDetection(isGuest: boolean): UsePRDetectionReturn {
  const [recentPRs, setRecentPRs] = useState<PRCheckResult[]>([]);

  // In-memory cache of all maxes for this session
  const maxesCacheRef = useRef<ExerciseMax[]>([]);

  // ── loadMaxes ─────────────────────────────────────────────────────────────
  const loadMaxes = useCallback(
    async (uid: string): Promise<void> => {
      try {
        const repo = getExerciseMaxRepo(isGuest);
        const maxes = await repo.getAllMaxes(uid);
        maxesCacheRef.current = maxes;
      } catch {
        // Non-fatal — cache stays empty, every set will look like a PR
        maxesCacheRef.current = [];
      }
    },
    [isGuest],
  );

  // ── checkAndRecordPR ──────────────────────────────────────────────────────
  const checkAndRecordPR = useCallback(
    async (
      uid: string,
      exerciseId: string,
      exerciseName: string,
      weight: number,
      reps: number,
    ): Promise<PRCheckResult> => {
      const result = checkForPR(exerciseId, weight, reps, maxesCacheRef.current);

      if (result.isWeightPR || result.is1RMPR) {
        // Build new ExerciseMax record
        const newMax: ExerciseMax = {
          exerciseId,
          exerciseName,
          repRange: result.repRange ?? 1,
          weight,
          estimated1RM: estimated1RM(weight, reps),
          achievedAt: new Date().toISOString(),
        };

        // Save to repository (upsert-if-better logic is in the repo)
        try {
          const repo = getExerciseMaxRepo(isGuest);
          await repo.saveMax(uid, newMax);
        } catch {
          // Non-fatal — PR still detected, just not persisted this call
        }

        // Update in-memory cache: replace or append
        const cacheIdx = maxesCacheRef.current.findIndex(
          (m) => m.exerciseId === exerciseId && m.repRange === newMax.repRange,
        );
        if (cacheIdx >= 0) {
          maxesCacheRef.current = [
            ...maxesCacheRef.current.slice(0, cacheIdx),
            newMax,
            ...maxesCacheRef.current.slice(cacheIdx + 1),
          ];
        } else {
          maxesCacheRef.current = [...maxesCacheRef.current, newMax];
        }

        // Enqueue for toast display
        setRecentPRs((prev) => [...prev, result]);
      }

      return result;
    },
    [isGuest],
  );

  // ── clearRecentPRs ────────────────────────────────────────────────────────
  const clearRecentPRs = useCallback((): void => {
    setRecentPRs([]);
  }, []);

  return {
    recentPRs,
    loadMaxes,
    checkAndRecordPR,
    clearRecentPRs,
  };
}

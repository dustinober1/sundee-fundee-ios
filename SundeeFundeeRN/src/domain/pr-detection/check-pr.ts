/**
 * PR Detection
 * Pure functions for detecting personal records against multi-rep-range maxes.
 *
 * Checks both:
 *   - Weight PRs at the closest tracked rep range (1, 3, 5, 8, 10)
 *   - Estimated 1RM PRs using the Epley formula
 */

import { estimated1RM } from '../calculations/epley-formula';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export const TRACKED_REP_RANGES = [1, 3, 5, 8, 10] as const;
export type TrackedRepRange = typeof TRACKED_REP_RANGES[number];

export interface ExerciseMax {
  exerciseId: string;
  exerciseName: string;
  repRange: TrackedRepRange;
  weight: number;
  estimated1RM: number;
  achievedAt: string;
}

export interface PRCheckResult {
  isWeightPR: boolean;
  is1RMPR: boolean;
  repRange: TrackedRepRange | null;
  previousBest: number | null;
  newValue: number;
}

// ---------------------------------------------------------------------------
// findClosestRepRange
// ---------------------------------------------------------------------------

/**
 * Finds the closest tracked rep range to the given reps.
 * On ties (equidistant), prefers the lower (first-match) range —
 * matching Swift `min(by:)` strict-less-than semantics.
 *
 * @param reps - Number of reps performed
 * @returns The closest TrackedRepRange value
 */
export function findClosestRepRange(reps: number): TrackedRepRange {
  let closest = TRACKED_REP_RANGES[0];
  let minDistance = Math.abs(reps - closest);

  for (let i = 1; i < TRACKED_REP_RANGES.length; i++) {
    const range = TRACKED_REP_RANGES[i];
    const distance = Math.abs(reps - range);
    // Strict less-than: only update on strictly smaller distance (first match wins on tie)
    if (distance < minDistance) {
      closest = range;
      minDistance = distance;
    }
  }

  return closest;
}

// ---------------------------------------------------------------------------
// checkForPR
// ---------------------------------------------------------------------------

/**
 * Checks whether a completed set represents a personal record.
 *
 * @param exerciseId   - ID of the exercise performed
 * @param weight       - Weight lifted
 * @param reps         - Reps performed
 * @param currentMaxes - All existing ExerciseMax records (may include other exercises)
 * @returns PRCheckResult with both weight PR and estimated 1RM PR flags
 */
export function checkForPR(
  exerciseId: string,
  weight: number,
  reps: number,
  currentMaxes: ExerciseMax[],
): PRCheckResult {
  const repRange = findClosestRepRange(reps);

  // Filter to maxes for this exercise only
  const exerciseMaxes = currentMaxes.filter((m) => m.exerciseId === exerciseId);

  // ---------------------------------------------------------------------------
  // Weight PR check: compare against prior weight at the closest rep range
  // ---------------------------------------------------------------------------
  const priorAtRange = exerciseMaxes.find((m) => m.repRange === repRange);
  const previousBest = priorAtRange?.weight ?? null;
  const isWeightPR = previousBest === null ? true : weight > previousBest;

  // ---------------------------------------------------------------------------
  // 1RM PR check: compare new estimated 1RM against best across all rep ranges
  // ---------------------------------------------------------------------------
  const newEstimated1RM = estimated1RM(weight, reps);
  const bestExisting1RM = exerciseMaxes.length > 0
    ? Math.max(...exerciseMaxes.map((m) => m.estimated1RM))
    : undefined;
  const is1RMPR = bestExisting1RM === undefined ? true : newEstimated1RM > bestExisting1RM;

  return {
    isWeightPR,
    is1RMPR,
    repRange,
    previousBest,
    newValue: weight,
  };
}

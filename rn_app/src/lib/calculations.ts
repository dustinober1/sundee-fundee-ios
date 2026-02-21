import { roundToNearestFive } from './utils';

/**
 * Calculate target weight based on 1RM and percentage
 * @param oneRepMax - User's current 1RM in lbs
 * @param percentage - Decimal percentage (e.g., 0.65 for 65%)
 * @returns Target weight rounded to nearest 5 lbs
 */
export function calculateTargetWeight(oneRepMax: number, percentage: number): number {
  const rawWeight = oneRepMax * percentage;
  return roundToNearestFive(rawWeight);
}

/**
 * Session result classification for recommendation engine
 */
export type SessionResult = 'success' | 'failure' | 'first';

/**
 * Get next recommended working weight based on session result
 * - 'first': 70% of 1RM (starting weight for a new exercise)
 * - 'success': +5 lbs from current weight
 * - 'failure': -5 lbs from current weight, with a floor at 50% of 1RM
 * All results are rounded to nearest 5 lbs.
 *
 * @param currentWeight - Current working weight in lbs
 * @param result - Outcome of the most recent session
 * @param oneRepMax - User's 1RM for this exercise
 * @returns Recommended weight for next session, rounded to nearest 5 lbs
 */
export function getNextRecommendedWeight(
  currentWeight: number,
  result: SessionResult,
  oneRepMax: number
): number {
  switch (result) {
    case 'first':
      return roundToNearestFive(oneRepMax * 0.7);
    case 'success':
      return roundToNearestFive(currentWeight + 5);
    case 'failure': {
      const floor = roundToNearestFive(oneRepMax * 0.5);
      return Math.max(roundToNearestFive(currentWeight - 5), floor);
    }
  }
}

/**
 * Determine if a single set was successfully completed
 * A set is successful if actualReps >= prescribedReps AND
 * (if prescribedWeight is defined) actualWeight >= prescribedWeight.
 */
export function wasSetSuccessful(set: {
  actualReps: number;
  prescribedReps: number;
  actualWeight: number;
  prescribedWeight?: number;
}): boolean {
  const repsOk = set.actualReps >= set.prescribedReps;
  const weightOk =
    set.prescribedWeight === undefined || set.actualWeight >= set.prescribedWeight;
  return repsOk && weightOk;
}

/**
 * Determine if an entire session (array of sets) was successfully completed
 * A session is successful if ALL sets pass wasSetSuccessful.
 * An empty array returns true (vacuously successful).
 */
export function wasSessionSuccessful(
  sets: Array<{
    actualReps: number;
    prescribedReps: number;
    actualWeight: number;
    prescribedWeight?: number;
  }>
): boolean {
  return sets.every(wasSetSuccessful);
}

/**
 * Check if a weight represents a new personal record
 * @param weight - Current weight
 * @param previousMax - Previous maximum weight
 * @returns True if weight exceeds previous max
 */
export function isPersonalRecord(weight: number, previousMax: number): boolean {
  return weight > previousMax;
}

/**
 * Calculate volume load (weight × reps × sets)
 * @param weight - Weight lifted
 * @param reps - Reps completed
 * @param sets - Number of sets
 * @returns Total volume load
 */
export function calculateVolumeLoad(weight: number, reps: number, sets: number): number {
  return weight * reps * sets;
}

/**
 * Determine if user has plateaued (no progress in 3+ workouts)
 * @param weights - Array of weights from recent workouts, ordered by date
 * @returns True if plateau detected
 */
export function detectPlateau(weights: number[]): boolean {
  if (weights.length < 3) return false;

  const lastThree = weights.slice(-3);
  const maxWeight = Math.max(...lastThree);
  const minWeight = Math.min(...lastThree);

  // Plateau if variance is less than 5 lbs
  return maxWeight - minWeight < 5;
}

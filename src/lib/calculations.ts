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

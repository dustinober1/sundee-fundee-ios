import { SessionResult } from "./types";

/**
 * Rounds a value to the nearest multiple of 5.
 */
export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

/**
 * Calculates the target weight for a given 1RM and percentage.
 * Result is rounded to the nearest 5.
 */
export function calculateTargetWeight(oneRepMax: number, percentage: number): number {
  return roundToNearestFive(oneRepMax * percentage);
}

/**
 * Returns the next recommended weight based on previous result.
 * - first: 70% of 1RM, rounded to nearest 5
 * - success: current + 5, rounded up to nearest 5
 * - failure: current - 5, floored at 50% of 1RM (rounded to nearest 5)
 */
export function getNextRecommendedWeight(
  current: number,
  result: (typeof SessionResult)[keyof typeof SessionResult],
  oneRepMax: number
): number {
  switch (result) {
    case SessionResult.first:
      return roundToNearestFive(oneRepMax * 0.7);
    case SessionResult.success:
      return roundToNearestFive(current + 5);
    case SessionResult.failure: {
      const decreased = roundToNearestFive(current - 5);
      const floor = roundToNearestFive(oneRepMax * 0.5);
      return Math.max(decreased, floor);
    }
  }
}

/**
 * Determines whether a set was successful.
 * A set is successful if actual reps >= prescribed reps AND actual weight >= prescribed weight.
 */
export function wasSetSuccessful(
  actualReps: number,
  prescribedReps: number,
  actualWeight: number,
  prescribedWeight?: number
): boolean {
  const repsOk = actualReps >= prescribedReps;
  const weightOk = prescribedWeight === undefined ? true : actualWeight >= prescribedWeight;
  return repsOk && weightOk;
}

/**
 * Returns true if the given weight is a personal record over the previous max.
 */
export function isPersonalRecord(weight: number, previousMax: number): boolean {
  return weight > previousMax;
}

/**
 * Calculates total volume load: weight × reps × sets.
 */
export function calculateVolumeLoad(weight: number, reps: number, sets: number): number {
  return weight * reps * sets;
}

/**
 * Detects a plateau: true if the last 3 weights are all within 5 kg of each other.
 * Returns false if fewer than 3 data points.
 */
export function detectPlateau(weights: number[]): boolean {
  if (weights.length < 3) return false;
  const last3 = weights.slice(-3);
  const min = Math.min(...last3);
  const max = Math.max(...last3);
  return max - min <= 5;
}

/**
 * Estimates 1RM using the Epley formula: weight × (1 + reps / 30).
 * Returns weight directly if reps <= 1.
 */
export function estimate1RM(weight: number, reps: number): number {
  if (reps <= 1) return weight;
  return weight * (1 + reps / 30);
}

/**
 * Returns true if the new 1RM estimate exceeds the current recorded max.
 */
export function isPR(newEstimate: number, currentMax: number): boolean {
  return newEstimate > currentMax;
}

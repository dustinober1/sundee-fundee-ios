/**
 * Target weight calculation helpers for program sessions.
 *
 * Programs can specify exercise weights as a percentage of the user's 1RM
 * (stored as a fixed ExerciseValue with value <= 1.0, e.g., 0.75 for 75%).
 * These helpers compute absolute target weights from the user's logged maxes,
 * round to the nearest 5 lbs, and format for display.
 */
import type { ExerciseMax } from '../../domain/pr-detection/pr-types';
import type { ProgramExercise } from '../../domain/types/index';

/**
 * Threshold below which a fixed ExerciseValue is interpreted as a 1RM percentage.
 * Any fixed weight value <= this threshold is treated as a fraction (e.g., 0.75 = 75%).
 */
const PERCENTAGE_THRESHOLD = 1.0;

/**
 * Calculates the absolute target weight for an exercise by applying a 1RM percentage.
 *
 * Looks up the user's best 1RM for the exercise by name (case-insensitive),
 * multiplies by the percentage, then rounds to the nearest 5 lbs.
 *
 * @param exerciseName - The display name of the exercise (matched case-insensitively)
 * @param percentage - Fraction of 1RM (e.g., 0.75 for 75%)
 * @param maxes - Array of the user's logged exercise maxes
 * @returns Absolute weight in lbs rounded to nearest 5, or null if no 1RM logged
 */
export function calculateTargetWeight(
  exerciseName: string,
  percentage: number,
  maxes: ExerciseMax[]
): number | null {
  const normalizedName = exerciseName.trim().toLowerCase();

  // Find the best 1RM for this exercise (highest estimated1RM among all rep ranges)
  const matchingMaxes = maxes.filter(
    (m) => m.exerciseName.trim().toLowerCase() === normalizedName
  );

  if (matchingMaxes.length === 0) {
    return null;
  }

  const best1RM = Math.max(...matchingMaxes.map((m) => m.estimated1RM));
  const rawWeight = best1RM * percentage;

  // Round to nearest 5 lbs
  return Math.round(rawWeight / 5) * 5;
}

/**
 * Returns the list of exercise names that use a 1RM percentage weight
 * but for which the user has no logged 1RM.
 *
 * A "percentage weight" is identified by an ExerciseValue with kind === 'fixed'
 * and value <= 1.0 (representing a fraction of 1RM, e.g., 0.75).
 *
 * @param exercises - Program exercises to check
 * @param maxes - Array of the user's logged exercise maxes
 * @returns Deduplicated list of exercise names missing a 1RM
 */
export function getMissing1RMs(
  exercises: ProgramExercise[],
  maxes: ExerciseMax[]
): string[] {
  const missing: string[] = [];
  const seen = new Set<string>();

  for (const exercise of exercises) {
    // Only consider exercises with a percentage-style weight (fixed value <= 1.0)
    if (!exercise.weight || exercise.weight.kind !== 'fixed') {
      continue;
    }
    if (exercise.weight.value > PERCENTAGE_THRESHOLD) {
      // This is an absolute weight, not a percentage
      continue;
    }

    const normalizedName = exercise.name.trim().toLowerCase();
    if (seen.has(normalizedName)) {
      continue;
    }

    const has1RM = maxes.some(
      (m) => m.exerciseName.trim().toLowerCase() === normalizedName
    );

    if (!has1RM) {
      missing.push(exercise.name);
      seen.add(normalizedName);
    }
  }

  return missing;
}

/**
 * Formats a target weight for display.
 *
 * If an absolute weight is available, returns "{weight} lbs".
 * If no 1RM is logged, falls back to the percentage string (e.g., "75%").
 *
 * @param weight - Absolute weight in lbs, or null if 1RM not available
 * @param percentage - Fraction of 1RM (e.g., 0.75 for 75%)
 * @returns Human-readable weight string
 */
export function formatTargetWeight(weight: number | null, percentage: number): string {
  if (weight !== null) {
    return `${weight} lbs`;
  }
  const pct = Math.round(percentage * 100);
  return `${pct}%`;
}

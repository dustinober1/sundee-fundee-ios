/**
 * Progress chart data preparation.
 *
 * Pure data transformation functions — no storage access.
 * Converts raw ExerciseMax records and completed workout records into
 * chart-ready arrays suitable for 1RM, volume, and rep-range PR displays.
 */

import type { ExerciseMax, TrackedRepRange } from '../pr-detection/pr-types';
import { TRACKED_REP_RANGES } from '../pr-detection/pr-types';

// ---------------------------------------------------------------------------
// CompletedWorkoutRecord — local type for volume chart calculations
// ---------------------------------------------------------------------------

/**
 * A completed set with recorded weight and reps.
 */
export interface CompletedSet {
  id: string;
  weight: number;
  reps: number;
  completed: boolean;
}

/**
 * A completed exercise within a workout, with its logged sets.
 */
export interface CompletedExercise {
  id: string;
  exerciseId: string;
  exerciseName: string;
  sets: CompletedSet[];
}

/**
 * A persisted workout record containing completed exercises.
 * Used for volume chart data extraction.
 */
export interface CompletedWorkoutRecord {
  id: string;
  /** ISO 8601 timestamp — e.g. "2026-03-15T10:00:00Z" */
  completedAt: string;
  exercises: CompletedExercise[];
}

// ---------------------------------------------------------------------------
// Chart point type
// ---------------------------------------------------------------------------

export interface ChartDataPoint {
  /** ISO date string (YYYY-MM-DD). */
  date: string;
  value: number;
}

// ---------------------------------------------------------------------------
// prepare1RMChartData
// ---------------------------------------------------------------------------

/**
 * Converts raw ExerciseMax records into a 1RM chart-ready time series.
 *
 * - Filters by exerciseId
 * - For each unique date (achievedAt truncated to YYYY-MM-DD), takes the
 *   highest estimated1RM
 * - Returns sorted by date ascending
 */
export function prepare1RMChartData(
  maxes: ExerciseMax[],
  exerciseId: string
): ChartDataPoint[] {
  const filtered = maxes.filter((m) => m.exerciseId === exerciseId);
  if (filtered.length === 0) return [];

  // Group by date, keep best estimated1RM per date
  const bestByDate = new Map<string, number>();
  for (const max of filtered) {
    const dateKey = toDateKey(max.achievedAt);
    const current = bestByDate.get(dateKey);
    if (current === undefined || max.estimated1RM > current) {
      bestByDate.set(dateKey, max.estimated1RM);
    }
  }

  // Sort by date ascending and convert to array
  const sortedKeys = Array.from(bestByDate.keys()).sort();
  return sortedKeys.map((date) => ({ date, value: bestByDate.get(date)! }));
}

// ---------------------------------------------------------------------------
// prepareVolumeChartData
// ---------------------------------------------------------------------------

/**
 * Aggregates total training volume (sum of weight * reps) per workout session
 * for a given exercise.
 *
 * - Only includes records where the exercise is present
 * - Returns sorted by date ascending (using completedAt date portion)
 */
export function prepareVolumeChartData(
  records: CompletedWorkoutRecord[],
  exerciseId: string
): ChartDataPoint[] {
  const result: ChartDataPoint[] = [];

  for (const record of records) {
    const matching = record.exercises.filter((e) => e.exerciseId === exerciseId);
    if (matching.length === 0) continue;

    let totalVolume = 0;
    for (const exercise of matching) {
      for (const set of exercise.sets) {
        if (set.completed) {
          totalVolume += set.weight * set.reps;
        }
      }
    }

    if (totalVolume > 0) {
      result.push({
        date: toDateKey(record.completedAt),
        value: totalVolume,
      });
    }
  }

  // Sort by date ascending
  result.sort((a, b) => a.date.localeCompare(b.date));
  return result;
}

// ---------------------------------------------------------------------------
// prepareRepRangePRs
// ---------------------------------------------------------------------------

export interface RepRangePR {
  repRange: TrackedRepRange;
  weight: number | null;
  date: string | null;
}

/**
 * Returns the best weight achieved for each of the 5 tracked rep ranges
 * for a given exercise.
 *
 * Always returns 5 entries — one per tracked rep range.
 * weight and date are null when no data exists for that rep range.
 */
export function prepareRepRangePRs(
  maxes: ExerciseMax[],
  exerciseId: string
): RepRangePR[] {
  const filtered = maxes.filter((m) => m.exerciseId === exerciseId);

  return TRACKED_REP_RANGES.map((repRange): RepRangePR => {
    const candidates = filtered.filter((m) => m.repRange === repRange);
    if (candidates.length === 0) {
      return { repRange, weight: null, date: null };
    }

    // Find the entry with the best weight
    const best = candidates.reduce((prev, curr) =>
      curr.weight > prev.weight ? curr : prev
    );

    return { repRange, weight: best.weight, date: best.achievedAt };
  });
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/**
 * Extracts the YYYY-MM-DD date portion from an ISO 8601 string.
 * e.g. "2026-03-15T10:00:00Z" → "2026-03-15"
 *      "2026-03-15" → "2026-03-15"
 */
function toDateKey(isoString: string): string {
  return isoString.substring(0, 10);
}

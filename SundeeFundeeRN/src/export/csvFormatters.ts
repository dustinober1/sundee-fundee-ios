/**
 * CSV Formatter Functions
 *
 * Pure functions that convert each user data type to a CSV string.
 * All formatters accept a weightUnit parameter for unit-aware weight columns.
 * Each formatter: (records: T[], weightUnit?: 'lb' | 'kg') => string
 *
 * CSV escaping: values containing commas or double-quotes are wrapped in
 * double-quotes, with internal double-quotes doubled.
 */

import { lbToKg } from '../domain/calculations/weight-unit-conversion';
import type { WorkoutRecord } from '../repositories/WorkoutRepo';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { BenchmarkResultRecord } from '../repositories/BenchmarkRepo';
import type { PeriodLogRecord } from '../repositories/CycleRepo';
import type { PainLogRecord, InjuryProfileRecord } from '../repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '../repositories/ReadinessRepo';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Escape a single CSV cell value. */
function escapeCell(value: string | number | undefined | null): string {
  const str = value === undefined || value === null ? '' : String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

/** Join an array of cell values into a CSV row. */
function csvRow(cells: (string | number | undefined | null)[]): string {
  return cells.map(escapeCell).join(',');
}

/** Format an ISO timestamp or date string as YYYY-MM-DD. */
function toDateString(isoString: string): string {
  // Handles both "2024-06-15T10:00:00Z" and "2024-06-15" formats
  return isoString.slice(0, 10);
}

/** Format seconds as mm:ss. */
function formatSeconds(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

/** Format a benchmark score based on scoring type. */
function formatScore(
  scoringType: BenchmarkResultRecord['scoringType'],
  score: number
): string {
  switch (scoringType) {
    case 'time':
      return formatSeconds(Math.round(score));
    case 'roundsAndReps': {
      const rounds = Math.floor(score / 10000);
      const reps = Math.round(score % 10000);
      return `${rounds} rounds + ${reps} reps`;
    }
    case 'weight':
      return String(score);
    case 'reps':
      return String(Math.round(score));
    case 'distance':
      return formatSeconds(Math.round(score));
    default:
      return String(score);
  }
}

/**
 * Convert a weight value in lbs to the target unit.
 * ExerciseMax.weight is always stored in lbs (per domain convention).
 */
function convertWeightFromLb(lb: number, unit: 'lb' | 'kg'): string {
  if (unit === 'lb') return lb.toFixed(2);
  return lbToKg(lb).toFixed(2);
}

/**
 * WorkoutRecord sets store weight in lbs.
 * Convert to target unit for CSV output.
 */
function convertSetWeight(weightLb: number, unit: 'lb' | 'kg'): string {
  if (unit === 'lb') return weightLb.toFixed(2);
  return lbToKg(weightLb).toFixed(2);
}

// ---------------------------------------------------------------------------
// Formatters
// ---------------------------------------------------------------------------

/**
 * Convert workout records to CSV.
 * One row per set. Column header includes selected weight unit.
 */
export function workoutsToCsv(
  workouts: WorkoutRecord[],
  weightUnit: 'lb' | 'kg'
): string {
  const unitLabel = weightUnit === 'kg' ? 'Weight (kg)' : 'Weight (lbs)';
  const header = `Date,Name,Source,Exercise,Set,Reps,${unitLabel}`;

  const rows: string[] = [header];

  for (const workout of workouts) {
    const date = toDateString(workout.completedAt);
    const name = workout.workoutName ?? '';
    const source = workout.source;

    if (workout.exercises && workout.exercises.length > 0) {
      for (const exercise of workout.exercises) {
        workout.exercises.forEach(() => {});
        exercise.sets.forEach((set, idx) => {
          rows.push(
            csvRow([
              date,
              name,
              source,
              exercise.exerciseName,
              idx + 1,
              set.reps,
              convertSetWeight(set.weight, weightUnit),
            ])
          );
        });
      }
    } else {
      // AI workouts or workouts with no tracked sets — emit one summary row
      rows.push(csvRow([date, name, source, '', '', '', '']));
    }
  }

  return rows.join('\n');
}

/**
 * Convert exercise max records to CSV.
 * ExerciseMax.weight and estimated1RM are stored in lbs; convert as needed.
 */
export function maxesToCsv(
  maxes: ExerciseMax[],
  weightUnit: 'lb' | 'kg'
): string {
  const unitLabel = weightUnit === 'kg' ? '(kg)' : '(lbs)';
  const header = `Exercise,Rep Range,Weight ${unitLabel},Estimated 1RM ${unitLabel},Date`;

  const rows: string[] = [header];

  for (const max of maxes) {
    rows.push(
      csvRow([
        max.exerciseName,
        max.repRange,
        convertWeightFromLb(max.weight, weightUnit),
        convertWeightFromLb(max.estimated1RM, weightUnit),
        max.achievedAt,
      ])
    );
  }

  return rows.join('\n');
}

/**
 * Convert benchmark result records to CSV.
 * Score is formatted based on scoring type (time → mm:ss, roundsAndReps → readable).
 */
export function benchmarksToCsv(benchmarks: BenchmarkResultRecord[]): string {
  const header = 'Name,Type,Score,Date';
  const rows: string[] = [header];

  for (const result of benchmarks) {
    rows.push(
      csvRow([
        result.benchmarkName,
        result.scoringType,
        formatScore(result.scoringType, result.score),
        result.date,
      ])
    );
  }

  return rows.join('\n');
}

/**
 * Convert period log records to CSV.
 * Dates formatted as YYYY-MM-DD.
 */
export function cycleToCsv(periodLogs: PeriodLogRecord[]): string {
  const header = 'Period Start,Period End';
  const rows: string[] = [header];

  for (const log of periodLogs) {
    rows.push(
      csvRow([
        toDateString(log.startDate),
        log.endDate ? toDateString(log.endDate) : '',
      ])
    );
  }

  return rows.join('\n');
}

/**
 * Convert pain log records to CSV.
 */
export function painLogsToCsv(painLogs: PainLogRecord[]): string {
  const header = 'Date,Location (Injury ID),Level (1-10)';
  const rows: string[] = [header];

  for (const log of painLogs) {
    rows.push(csvRow([toDateString(log.date), log.injuryId, log.painLevel]));
  }

  return rows.join('\n');
}

/**
 * Convert injury profile records to CSV.
 */
export function injuriesToCsv(injuries: InjuryProfileRecord[]): string {
  const header = 'Body Location,Recovery Phase,Created Date,Notes';
  const rows: string[] = [header];

  for (const injury of injuries) {
    rows.push(
      csvRow([
        injury.bodyLocation,
        injury.recoveryPhase,
        toDateString(injury.injuryDate),
        injury.notes ?? '',
      ])
    );
  }

  return rows.join('\n');
}

/**
 * Convert readiness survey records to CSV.
 * Includes all 4 slider values and the composite score.
 */
export function readinessToCsv(surveys: ReadinessSurveyRecord[]): string {
  const header = 'Date,Sleep,Energy,Stress,Soreness,Score';
  const rows: string[] = [header];

  for (const survey of surveys) {
    rows.push(
      csvRow([
        survey.date,
        survey.sleepQuality,
        survey.energyLevel,
        survey.stressLevel,
        survey.sorenessLevel,
        survey.result.score,
      ])
    );
  }

  return rows.join('\n');
}

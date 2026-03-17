/**
 * Tests for target weight calculation helpers.
 *
 * These functions compute absolute target weights for program exercises
 * based on the user's logged 1RM data.
 */
import {
  calculateTargetWeight,
  getMissing1RMs,
  formatTargetWeight,
} from '../target-weight';
import type { ExerciseMax } from '../../../domain/pr-detection/pr-types';
import type { ProgramExercise } from '../../../domain/types/index';

// ─── Test fixtures ─────────────────────────────────────────────────────────

const squat1RM: ExerciseMax = {
  exerciseId: 'back-squat',
  exerciseName: 'Back Squat',
  repRange: 1,
  weight: 300,
  estimated1RM: 300,
  achievedAt: '2026-01-01',
};

const bench1RM: ExerciseMax = {
  exerciseId: 'bench-press',
  exerciseName: 'Bench Press',
  repRange: 1,
  weight: 225,
  estimated1RM: 225,
  achievedAt: '2026-01-01',
};

const maxes: ExerciseMax[] = [squat1RM, bench1RM];

// ─── calculateTargetWeight ──────────────────────────────────────────────────

describe('calculateTargetWeight', () => {
  it('returns absolute weight when 1RM exists (75% of 300 = 225)', () => {
    const result = calculateTargetWeight('Back Squat', 0.75, maxes);
    expect(result).toBe(225);
  });

  it('returns null when no 1RM for exercise', () => {
    const result = calculateTargetWeight('Deadlift', 0.80, maxes);
    expect(result).toBeNull();
  });

  it('rounds to nearest 5 lbs for barbell exercises', () => {
    // 300 * 0.77 = 231 -> rounds to 230
    const result = calculateTargetWeight('Back Squat', 0.77, maxes);
    expect(result).toBe(230);
  });

  it('rounds to nearest 5 when result is halfway (exactly 2.5 above a multiple of 5)', () => {
    // 225 * 0.45 = 101.25 -> rounds to 100
    const result = calculateTargetWeight('Bench Press', 0.45, maxes);
    expect(result).toBe(100);
  });
});

// ─── getMissing1RMs ─────────────────────────────────────────────────────────

describe('getMissing1RMs', () => {
  const percentageWeightExercise: ProgramExercise = {
    id: 'e1',
    name: 'Back Squat',
    sets: 3,
    reps: { kind: 'fixed', value: 5 },
    weight: { kind: 'fixed', value: 0.75 }, // percentage (fixed value between 0 and 1 treated as percentage)
  };

  const textWeightExercise: ProgramExercise = {
    id: 'e2',
    name: 'Romanian Deadlift',
    sets: 3,
    reps: { kind: 'fixed', value: 8 },
    weight: { kind: 'text', value: 'Light-Moderate' }, // no 1RM needed
  };

  const noWeightExercise: ProgramExercise = {
    id: 'e3',
    name: 'Pull-up',
    sets: 3,
    reps: { kind: 'fixed', value: 8 },
    // no weight field
  };

  const deadliftPercentageExercise: ProgramExercise = {
    id: 'e4',
    name: 'Deadlift',
    sets: 1,
    reps: { kind: 'fixed', value: 5 },
    weight: { kind: 'fixed', value: 0.85 }, // percentage but no 1RM logged
  };

  it('returns exercise names that have a percentage weight but no logged 1RM', () => {
    const exercises = [percentageWeightExercise, textWeightExercise, noWeightExercise, deadliftPercentageExercise];
    const missing = getMissing1RMs(exercises, maxes);
    // Back Squat has a 1RM, Deadlift does not
    expect(missing).toEqual(['Deadlift']);
  });

  it('returns empty array when all percentage exercises have logged 1RMs', () => {
    const exercises = [percentageWeightExercise];
    const missing = getMissing1RMs(exercises, maxes);
    expect(missing).toEqual([]);
  });

  it('returns empty array when no exercises use percentage weights', () => {
    const exercises = [textWeightExercise, noWeightExercise];
    const missing = getMissing1RMs(exercises, maxes);
    expect(missing).toEqual([]);
  });
});

// ─── formatTargetWeight ─────────────────────────────────────────────────────

describe('formatTargetWeight', () => {
  it('returns "225.0 lbs" when weight is available (lb default)', () => {
    const result = formatTargetWeight(225, 0.75);
    expect(result).toBe('225.0 lbs');
  });

  it('returns "225.0 lbs" when unit is explicitly lb', () => {
    const result = formatTargetWeight(225, 0.75, 'lb');
    expect(result).toBe('225.0 lbs');
  });

  it('returns "102.0 kg" when unit is kg (225 lbs -> ~102 kg)', () => {
    const result = formatTargetWeight(225, 0.75, 'kg');
    expect(result).toBe('102.0 kg');
  });

  it('returns percentage string when no 1RM (weight is null)', () => {
    const result = formatTargetWeight(null, 0.75);
    expect(result).toBe('75%');
  });

  it('returns formatted percentage without trailing zeros', () => {
    const result = formatTargetWeight(null, 0.8);
    expect(result).toBe('80%');
  });

  it('returns percentage string when weight is null and unit is kg (unit ignored)', () => {
    const result = formatTargetWeight(null, 0.75, 'kg');
    expect(result).toBe('75%');
  });
});

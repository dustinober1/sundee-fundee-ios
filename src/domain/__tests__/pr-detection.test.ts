/**
 * PR Detection Tests
 * Tests for checkForPR and findClosestRepRange domain functions.
 */

import { checkForPR, findClosestRepRange } from '../pr-detection';
import type { ExerciseMax } from '../pr-detection';

// ---------------------------------------------------------------------------
// findClosestRepRange
// ---------------------------------------------------------------------------

describe('findClosestRepRange', () => {
  it('returns 1 for reps=1 (exact match)', () => {
    expect(findClosestRepRange(1)).toBe(1);
  });

  it('returns 3 for reps=3 (exact match)', () => {
    expect(findClosestRepRange(3)).toBe(3);
  });

  it('returns 5 for reps=5 (exact match)', () => {
    expect(findClosestRepRange(5)).toBe(5);
  });

  it('returns 8 for reps=8 (exact match)', () => {
    expect(findClosestRepRange(8)).toBe(8);
  });

  it('returns 10 for reps=10 (exact match)', () => {
    expect(findClosestRepRange(10)).toBe(10);
  });

  it('returns 5 for reps=6 (nearest tracked range, |6-5|=1 < |6-8|=2)', () => {
    expect(findClosestRepRange(6)).toBe(5);
  });

  it('returns 8 for reps=7 (|7-8|=1 < |7-5|=2)', () => {
    expect(findClosestRepRange(7)).toBe(8);
  });

  it('returns 3 for reps=4 (equidistant: |4-3|=1, |4-5|=1, tie breaks to first=3)', () => {
    expect(findClosestRepRange(4)).toBe(3);
  });

  it('returns 1 for reps=2 (|2-1|=1, |2-3|=1, tie breaks to first=1)', () => {
    expect(findClosestRepRange(2)).toBe(1);
  });

  it('returns 10 for reps=12 (|12-10|=2 < |12-8|=4)', () => {
    expect(findClosestRepRange(12)).toBe(10);
  });

  it('returns 1 for reps=0 (below minimum, clamped to 1)', () => {
    expect(findClosestRepRange(0)).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// checkForPR — no prior maxes
// ---------------------------------------------------------------------------

describe('checkForPR — no prior maxes', () => {
  it('returns isWeightPR: true and is1RMPR: true when no prior maxes exist', () => {
    const result = checkForPR('ex1', 185, 5, []);
    expect(result.isWeightPR).toBe(true);
    expect(result.is1RMPR).toBe(true);
    expect(result.repRange).toBe(5);
    expect(result.previousBest).toBeNull();
    expect(result.newValue).toBe(185);
  });

  it('returns repRange=1 for single reps', () => {
    const result = checkForPR('ex1', 225, 1, []);
    expect(result.repRange).toBe(1);
    expect(result.isWeightPR).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// checkForPR — weight PR detection
// ---------------------------------------------------------------------------

describe('checkForPR — weight PR', () => {
  const prior5RM: ExerciseMax = {
    exerciseId: 'ex1',
    exerciseName: 'Back Squat',
    repRange: 5,
    weight: 175,
    estimated1RM: 185.83,
    achievedAt: '2024-01-01T00:00:00.000Z',
  };

  it('returns isWeightPR: true when new weight beats prior at same rep range (185 > 175)', () => {
    const result = checkForPR('ex1', 185, 5, [prior5RM]);
    expect(result.isWeightPR).toBe(true);
    expect(result.previousBest).toBe(175);
    expect(result.newValue).toBe(185);
  });

  it('returns isWeightPR: false when new weight is less than prior (175 < 185)', () => {
    const prior: ExerciseMax = { ...prior5RM, weight: 185, estimated1RM: 196.17 };
    const result = checkForPR('ex1', 175, 5, [prior]);
    expect(result.isWeightPR).toBe(false);
  });

  it('returns isWeightPR: false when new weight equals prior (no tie-breaking PR)', () => {
    const result = checkForPR('ex1', 175, 5, [prior5RM]);
    expect(result.isWeightPR).toBe(false);
  });

  it('does not match exercise for different exerciseId', () => {
    const result = checkForPR('ex2', 185, 5, [prior5RM]);
    expect(result.isWeightPR).toBe(true);
    expect(result.previousBest).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// checkForPR — 1RM PR detection
// ---------------------------------------------------------------------------

describe('checkForPR — 1RM PR', () => {
  it('returns is1RMPR: true when estimated1RM(225, 3) > existing estimated1RM of 233', () => {
    // estimated1RM(225, 3) = 225 * (1 + 3/30) = 225 * 1.1 = 247.5 > 233
    const prior: ExerciseMax = {
      exerciseId: 'ex1',
      exerciseName: 'Back Squat',
      repRange: 5,
      weight: 200,
      estimated1RM: 233,
      achievedAt: '2024-01-01T00:00:00.000Z',
    };
    const result = checkForPR('ex1', 225, 3, [prior]);
    expect(result.is1RMPR).toBe(true);
  });

  it('returns is1RMPR: false when estimated1RM does not beat existing best across all rep ranges', () => {
    // estimated1RM(185, 5) = 185 * (1 + 5/30) = 185 * 1.1667 ≈ 215.83
    const prior: ExerciseMax = {
      exerciseId: 'ex1',
      exerciseName: 'Bench Press',
      repRange: 1,
      weight: 225,
      estimated1RM: 225,
      achievedAt: '2024-01-01T00:00:00.000Z',
    };
    const result = checkForPR('ex1', 185, 5, [prior]);
    expect(result.is1RMPR).toBe(false);
  });

  it('compares against best estimated1RM across all rep ranges for that exercise', () => {
    const maxes: ExerciseMax[] = [
      {
        exerciseId: 'ex1',
        exerciseName: 'Deadlift',
        repRange: 5,
        weight: 300,
        estimated1RM: 350,
        achievedAt: '2024-01-01T00:00:00.000Z',
      },
      {
        exerciseId: 'ex1',
        exerciseName: 'Deadlift',
        repRange: 8,
        weight: 265,
        estimated1RM: 335,
        achievedAt: '2024-01-01T00:00:00.000Z',
      },
    ];
    // estimated1RM(315, 5) = 315 * 1.1667 ≈ 367.5 > 350 (best across both)
    const result = checkForPR('ex1', 315, 5, maxes);
    expect(result.is1RMPR).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// checkForPR — closest rep range matching
// ---------------------------------------------------------------------------

describe('checkForPR — rep range matching', () => {
  it('matches a 6-rep set to the 5-rep tracked range', () => {
    const prior: ExerciseMax = {
      exerciseId: 'ex1',
      exerciseName: 'Bench Press',
      repRange: 5,
      weight: 175,
      estimated1RM: 185.83,
      achievedAt: '2024-01-01T00:00:00.000Z',
    };
    const result = checkForPR('ex1', 185, 6, [prior]);
    expect(result.repRange).toBe(5);
    expect(result.isWeightPR).toBe(true);
  });
});

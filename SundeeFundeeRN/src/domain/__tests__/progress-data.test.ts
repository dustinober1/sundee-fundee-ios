/**
 * Tests for progress chart data preparation functions.
 * Covers Plan 04-04 Task 2 behavior.
 */

import {
  prepare1RMChartData,
  prepareVolumeChartData,
  prepareRepRangePRs,
} from '../progress/progress-data';
import type { CompletedWorkoutRecord } from '../progress/progress-data';
import type { ExerciseMax } from '../pr-detection/pr-types';
import { TRACKED_REP_RANGES } from '../pr-detection/pr-types';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const exerciseId = 'ex-squat';

const maxes: ExerciseMax[] = [
  {
    exerciseId,
    exerciseName: 'Back Squat',
    repRange: 5,
    weight: 185,
    estimated1RM: 215,
    achievedAt: '2026-03-01',
  },
  {
    exerciseId,
    exerciseName: 'Back Squat',
    repRange: 5,
    weight: 195,
    estimated1RM: 227,
    achievedAt: '2026-03-10',
  },
  {
    // Same date as above — lower, should NOT appear for that date
    exerciseId,
    exerciseName: 'Back Squat',
    repRange: 1,
    weight: 200,
    estimated1RM: 200,
    achievedAt: '2026-03-10',
  },
  {
    // Different exercise — should not be included when filtering by exerciseId
    exerciseId: 'ex-deadlift',
    exerciseName: 'Deadlift',
    repRange: 5,
    weight: 225,
    estimated1RM: 261,
    achievedAt: '2026-03-05',
  },
  {
    exerciseId,
    exerciseName: 'Back Squat',
    repRange: 3,
    weight: 210,
    estimated1RM: 230,
    achievedAt: '2026-03-15',
  },
];

function makeWorkoutRecord(
  completedAt: string,
  exerciseSetData: { exerciseId: string; setsData: { weight: number; reps: number }[] }[]
): CompletedWorkoutRecord {
  return {
    id: `wr-${completedAt}`,
    completedAt,
    exercises: exerciseSetData.map((e, i) => ({
      id: `ae-${i}`,
      exerciseId: e.exerciseId,
      exerciseName: 'Exercise',
      sets: e.setsData.map((s, si) => ({
        id: `set-${si}`,
        weight: s.weight,
        reps: s.reps,
        completed: true,
      })),
    })),
  };
}

const workoutRecords: CompletedWorkoutRecord[] = [
  makeWorkoutRecord('2026-03-01T10:00:00Z', [
    { exerciseId, setsData: [{ weight: 185, reps: 5 }, { weight: 185, reps: 5 }, { weight: 185, reps: 4 }] },
    { exerciseId: 'ex-deadlift', setsData: [{ weight: 225, reps: 5 }] },
  ]),
  makeWorkoutRecord('2026-03-08T10:00:00Z', [
    { exerciseId, setsData: [{ weight: 195, reps: 5 }, { weight: 195, reps: 5 }] },
  ]),
  makeWorkoutRecord('2026-03-15T10:00:00Z', [
    // Different exercise only — no squat data
    { exerciseId: 'ex-deadlift', setsData: [{ weight: 235, reps: 3 }] },
  ]),
];

// ---------------------------------------------------------------------------
// prepare1RMChartData
// ---------------------------------------------------------------------------

describe('prepare1RMChartData', () => {
  it('returns empty array for empty maxes', () => {
    expect(prepare1RMChartData([], exerciseId)).toHaveLength(0);
  });

  it('filters to only matching exerciseId', () => {
    const result = prepare1RMChartData(maxes, exerciseId);
    result.forEach((point) => {
      // All points should come from squat maxes (no deadlift data)
      expect(point.value).toBeLessThan(260);
    });
  });

  it('returns sorted array of { date, value } ascending by date', () => {
    const result = prepare1RMChartData(maxes, exerciseId);
    for (let i = 1; i < result.length; i++) {
      expect(result[i].date >= result[i - 1].date).toBe(true);
    }
  });

  it('deduplicates by date — uses best (highest) estimated1RM per date', () => {
    // 2026-03-10 has two entries: 227 and 200 — should keep 227
    const result = prepare1RMChartData(maxes, exerciseId);
    const march10 = result.find((p) => p.date === '2026-03-10');
    expect(march10).toBeDefined();
    expect(march10!.value).toBe(227);
  });

  it('returns one point per unique date', () => {
    const result = prepare1RMChartData(maxes, exerciseId);
    const dates = result.map((p) => p.date);
    const uniqueDates = new Set(dates);
    expect(dates.length).toBe(uniqueDates.size);
  });

  it('returns correct number of dates for squat maxes', () => {
    // Squat maxes on: 2026-03-01, 2026-03-10, 2026-03-15 => 3 unique dates
    const result = prepare1RMChartData(maxes, exerciseId);
    expect(result).toHaveLength(3);
  });

  it('returns empty for non-existent exerciseId', () => {
    expect(prepare1RMChartData(maxes, 'ex-bench')).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
// prepareVolumeChartData
// ---------------------------------------------------------------------------

describe('prepareVolumeChartData', () => {
  it('returns empty array for empty records', () => {
    expect(prepareVolumeChartData([], exerciseId)).toHaveLength(0);
  });

  it('returns empty array when no records contain the exercise', () => {
    expect(prepareVolumeChartData(workoutRecords, 'ex-unknown')).toHaveLength(0);
  });

  it('sums weight * reps across all sets for matching exercise', () => {
    // 2026-03-01: (185*5) + (185*5) + (185*4) = 925+925+740 = 2590
    const result = prepareVolumeChartData(workoutRecords, exerciseId);
    const march1 = result.find((p) => p.date.startsWith('2026-03-01'));
    expect(march1).toBeDefined();
    expect(march1!.value).toBe(2590);
  });

  it('returns sorted by date ascending', () => {
    const result = prepareVolumeChartData(workoutRecords, exerciseId);
    for (let i = 1; i < result.length; i++) {
      expect(result[i].date >= result[i - 1].date).toBe(true);
    }
  });

  it('does not include records that have no matching exercise', () => {
    // 2026-03-15 has no squat exercise
    const result = prepareVolumeChartData(workoutRecords, exerciseId);
    const hasMarch15 = result.some((p) => p.date.startsWith('2026-03-15'));
    expect(hasMarch15).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// prepareRepRangePRs
// ---------------------------------------------------------------------------

describe('prepareRepRangePRs', () => {
  it('returns 5 entries — one per tracked rep range', () => {
    const result = prepareRepRangePRs(maxes, exerciseId);
    expect(result).toHaveLength(TRACKED_REP_RANGES.length);
    const ranges = result.map((r) => r.repRange);
    TRACKED_REP_RANGES.forEach((rr) => expect(ranges).toContain(rr));
  });

  it('returns null weight and date for rep ranges with no data', () => {
    // Squat has no 8-rep or 10-rep data in maxes fixture
    const result = prepareRepRangePRs(maxes, exerciseId);
    const eightRep = result.find((r) => r.repRange === 8);
    expect(eightRep).toBeDefined();
    expect(eightRep!.weight).toBeNull();
    expect(eightRep!.date).toBeNull();
    const tenRep = result.find((r) => r.repRange === 10);
    expect(tenRep).toBeDefined();
    expect(tenRep!.weight).toBeNull();
    expect(tenRep!.date).toBeNull();
  });

  it('returns correct best weight for rep ranges with data', () => {
    // 5-rep: two entries with 185 and 195 — best is 195
    const result = prepareRepRangePRs(maxes, exerciseId);
    const fiveRep = result.find((r) => r.repRange === 5);
    expect(fiveRep).toBeDefined();
    expect(fiveRep!.weight).toBe(195);
    // 1-rep: 200
    const oneRep = result.find((r) => r.repRange === 1);
    expect(oneRep!.weight).toBe(200);
    // 3-rep: 210
    const threeRep = result.find((r) => r.repRange === 3);
    expect(threeRep!.weight).toBe(210);
  });

  it('returns empty array for empty maxes', () => {
    const result = prepareRepRangePRs([], exerciseId);
    expect(result).toHaveLength(TRACKED_REP_RANGES.length);
    result.forEach((r) => {
      expect(r.weight).toBeNull();
      expect(r.date).toBeNull();
    });
  });

  it('filters to the specified exerciseId', () => {
    const result = prepareRepRangePRs(maxes, 'ex-deadlift');
    // deadlift has only one 5-rep entry at 225
    const fiveRep = result.find((r) => r.repRange === 5);
    expect(fiveRep!.weight).toBe(225);
    // other rep ranges should be null
    const oneRep = result.find((r) => r.repRange === 1);
    expect(oneRep!.weight).toBeNull();
  });
});

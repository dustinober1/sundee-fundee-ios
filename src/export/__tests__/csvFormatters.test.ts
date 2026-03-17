/**
 * Tests for CSV formatter pure functions.
 * All formatters produce unit-aware CSV strings from typed record arrays.
 */

import {
  workoutsToCsv,
  maxesToCsv,
  benchmarksToCsv,
  cycleToCsv,
  injuriesToCsv,
  painLogsToCsv,
  readinessToCsv,
} from '../csvFormatters';

// ---------------------------------------------------------------------------
// Fixture data
// ---------------------------------------------------------------------------

const makeWorkout = () => ({
  id: 'w1',
  uid: 'u1',
  completedAt: '2024-06-15T10:00:00Z',
  durationSeconds: 3600,
  source: 'custom' as const,
  workoutName: 'Morning Grind',
  exercises: [
    {
      exerciseId: 'e1',
      exerciseName: 'Back Squat',
      muscleGroup: 'legs',
      sets: [
        { weight: 100, reps: 5, isPersonalRecord: false },
        { weight: 100, reps: 5, isPersonalRecord: true },
      ],
    },
    {
      exerciseId: 'e2',
      exerciseName: 'Bench Press, Flat',
      muscleGroup: 'chest',
      sets: [{ weight: 80, reps: 8, isPersonalRecord: false }],
    },
  ],
});

const makeAIWorkout = () => ({
  id: 'w2',
  uid: 'u1',
  completedAt: '2024-06-16T08:00:00Z',
  durationSeconds: 1800,
  source: 'ai' as const,
  workout: {
    id: 'ai1',
    name: 'AI Strength Session',
    exercises: [
      { name: 'Deadlift', sets: 3, reps: 5, weight: '140 lbs', notes: '' },
    ],
  } as any,
});

const makeMax = () => ({
  exerciseId: 'e1',
  exerciseName: 'Back Squat',
  repRange: 5 as const,
  weight: 220.46, // ~100 kg in lbs
  estimated1RM: 247.53,
  achievedAt: '2024-06-01',
});

const makeBenchmark = () => ({
  id: 'b1',
  uid: 'u1',
  benchmarkId: 'fran',
  benchmarkName: 'Fran',
  scoringType: 'time' as const,
  score: 182, // 3:02
  date: '2024-05-20',
});

const makeBenchmarkRoundsReps = () => ({
  id: 'b2',
  uid: 'u1',
  benchmarkId: 'cindy',
  benchmarkName: 'Cindy',
  scoringType: 'roundsAndReps' as const,
  score: 200008, // 20 rounds + 8 reps
  date: '2024-05-21',
});

const makePeriodLog = () => ({
  id: 'p1',
  uid: 'u1',
  startDate: '2024-06-01T00:00:00Z',
  endDate: '2024-06-05T00:00:00Z',
});

const makePainLog = () => ({
  id: 'pl1',
  uid: 'u1',
  injuryId: 'inj1',
  date: '2024-06-10T12:00:00Z',
  painLevel: 4,
});

const makeInjury = () => ({
  id: 'inj1',
  uid: 'u1',
  bodyLocation: 'leftKnee' as const,
  recoveryPhase: 'rehab' as const,
  injuryDate: '2024-05-15T00:00:00Z',
  notes: 'Running injury',
  location: 'Left knee',
});

const makeReadiness = () => ({
  id: '2024-06-10',
  uid: 'u1',
  date: '2024-06-10',
  sleepQuality: 7,
  energyLevel: 6,
  stressLevel: 4,
  sorenessLevel: 5,
  result: {
    score: 0.6,
    recommendation: 'Train normally',
  } as any,
});

// ---------------------------------------------------------------------------
// workoutsToCsv
// ---------------------------------------------------------------------------

describe('workoutsToCsv', () => {
  it('returns header-only for empty array (lb)', () => {
    const csv = workoutsToCsv([], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Date,Name,Source,Exercise,Set,Reps,Weight (lbs)');
  });

  it('returns header-only for empty array (kg)', () => {
    const csv = workoutsToCsv([], 'kg');
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Date,Name,Source,Exercise,Set,Reps,Weight (kg)');
  });

  it('produces one row per set for lb workouts', () => {
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    const lines = csv.trim().split('\n');
    // header + 2 sets for Back Squat + 1 set for Bench Press = 4 lines
    expect(lines).toHaveLength(4);
  });

  it('produces one row per set for kg workouts with converted weight', () => {
    const csv = workoutsToCsv([makeWorkout()], 'kg');
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(4);
    // Weight 100 lbs → ~45.36 kg
    const row1 = lines[1];
    expect(row1).toContain('45.36');
  });

  it('uses YYYY-MM-DD date format', () => {
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('2024-06-15');
  });

  it('includes workout name and source', () => {
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('Morning Grind');
    expect(lines[1]).toContain('custom');
  });

  it('escapes values containing commas', () => {
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    // "Bench Press, Flat" contains a comma — must be quoted
    expect(csv).toContain('"Bench Press, Flat"');
  });

  it('handles AI workouts with no exercises array', () => {
    const csv = workoutsToCsv([makeAIWorkout()], 'lb');
    const lines = csv.trim().split('\n');
    // AI workout with no exercises array should produce 1 row (header + 0 data or 1 summary)
    // At minimum it should not throw
    expect(lines.length).toBeGreaterThanOrEqual(1);
  });

  it('includes correct set number in Set column', () => {
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    const lines = csv.trim().split('\n');
    // lines[1] = set 1 of Back Squat, lines[2] = set 2 of Back Squat
    expect(lines[1]).toContain(',1,');
    expect(lines[2]).toContain(',2,');
  });
});

// ---------------------------------------------------------------------------
// maxesToCsv
// ---------------------------------------------------------------------------

describe('maxesToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = maxesToCsv([], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatch(/Exercise.*Rep Range.*Weight/);
  });

  it('produces correct lb header', () => {
    const csv = maxesToCsv([], 'lb');
    expect(csv).toContain('Weight (lbs)');
    expect(csv).toContain('Estimated 1RM (lbs)');
  });

  it('produces correct kg header', () => {
    const csv = maxesToCsv([], 'kg');
    expect(csv).toContain('Weight (kg)');
    expect(csv).toContain('Estimated 1RM (kg)');
  });

  it('outputs lb weight as-is when unit is lb', () => {
    // ExerciseMax.weight is stored in lbs per domain
    const csv = maxesToCsv([makeMax()], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('220.46');
  });

  it('converts lb weight to kg when unit is kg', () => {
    const csv = maxesToCsv([makeMax()], 'kg');
    const lines = csv.trim().split('\n');
    // 220.46 lbs / 2.2046 ≈ 100.00 kg
    expect(lines[1]).toContain('100.0');
  });

  it('includes rep range and date', () => {
    const csv = maxesToCsv([makeMax()], 'lb');
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('5');
    expect(lines[1]).toContain('2024-06-01');
  });
});

// ---------------------------------------------------------------------------
// benchmarksToCsv
// ---------------------------------------------------------------------------

describe('benchmarksToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = benchmarksToCsv([]);
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Name,Type,Score,Date');
  });

  it('formats time score as mm:ss', () => {
    const csv = benchmarksToCsv([makeBenchmark()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('3:02');
  });

  it('formats roundsAndReps score as rounds + reps', () => {
    const csv = benchmarksToCsv([makeBenchmarkRoundsReps()]);
    const lines = csv.trim().split('\n');
    // 200008 → 20 rounds + 8 reps
    expect(lines[1]).toContain('20 rounds + 8 reps');
  });

  it('includes benchmark name, type and date', () => {
    const csv = benchmarksToCsv([makeBenchmark()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('Fran');
    expect(lines[1]).toContain('time');
    expect(lines[1]).toContain('2024-05-20');
  });
});

// ---------------------------------------------------------------------------
// cycleToCsv
// ---------------------------------------------------------------------------

describe('cycleToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = cycleToCsv([]);
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Period Start,Period End');
  });

  it('formats dates as YYYY-MM-DD', () => {
    const csv = cycleToCsv([makePeriodLog()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('2024-06-01');
    expect(lines[1]).toContain('2024-06-05');
  });

  it('handles missing endDate gracefully', () => {
    const log = { ...makePeriodLog(), endDate: undefined };
    const csv = cycleToCsv([log]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('2024-06-01');
    expect(lines[1]).not.toContain('undefined');
  });
});

// ---------------------------------------------------------------------------
// painLogsToCsv
// ---------------------------------------------------------------------------

describe('painLogsToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = painLogsToCsv([]);
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Date,Location (Injury ID),Level (1-10)');
  });

  it('formats date and pain level', () => {
    const csv = painLogsToCsv([makePainLog()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('2024-06-10');
    expect(lines[1]).toContain('4');
  });

  it('includes injuryId', () => {
    const csv = painLogsToCsv([makePainLog()]);
    expect(csv).toContain('inj1');
  });
});

// ---------------------------------------------------------------------------
// injuriesToCsv
// ---------------------------------------------------------------------------

describe('injuriesToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = injuriesToCsv([]);
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Body Location,Recovery Phase,Created Date,Notes');
  });

  it('formats injury fields', () => {
    const csv = injuriesToCsv([makeInjury()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('leftKnee');
    expect(lines[1]).toContain('rehab');
    expect(lines[1]).toContain('2024-05-15');
  });

  it('includes notes with CSV escaping', () => {
    const injury = { ...makeInjury(), notes: 'Running, jumping injury' };
    const csv = injuriesToCsv([injury]);
    expect(csv).toContain('"Running, jumping injury"');
  });
});

// ---------------------------------------------------------------------------
// readinessToCsv
// ---------------------------------------------------------------------------

describe('readinessToCsv', () => {
  it('returns header-only for empty array', () => {
    const csv = readinessToCsv([]);
    const lines = csv.trim().split('\n');
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('Date,Sleep,Energy,Stress,Soreness,Score');
  });

  it('includes all 4 slider values and composite score', () => {
    const csv = readinessToCsv([makeReadiness()]);
    const lines = csv.trim().split('\n');
    expect(lines[1]).toContain('2024-06-10');
    expect(lines[1]).toContain('7'); // sleep
    expect(lines[1]).toContain('6'); // energy
    expect(lines[1]).toContain('4'); // stress
    expect(lines[1]).toContain('5'); // soreness
    expect(lines[1]).toContain('0.6'); // score
  });
});

// ---------------------------------------------------------------------------
// CSV escaping edge cases
// ---------------------------------------------------------------------------

describe('CSV escaping', () => {
  it('wraps value with comma in double quotes', () => {
    // "Bench Press, Flat" should be wrapped
    const csv = workoutsToCsv([makeWorkout()], 'lb');
    expect(csv).toContain('"Bench Press, Flat"');
  });

  it('escapes double quotes by doubling them', () => {
    const injury = { ...makeInjury(), notes: 'She said "ouch"' };
    const csv = injuriesToCsv([injury]);
    expect(csv).toContain('"She said ""ouch"""');
  });
});

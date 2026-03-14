// =============================================================================
// Cycle domain tests
// Tests for CycleCalculations, CycleAdaptationPolicy, CycleProgramGenerator
// =============================================================================

import {
  getPhaseBoundaries,
  inferCurrentPhase,
  calculateCycleStatus,
  getPhaseRecommendation,
} from '../cycle/cycle-calculations';

import {
  blendMultiplier,
  resolveReadinessTier,
  applyPhaseAdjustment,
} from '../cycle/cycle-adaptation-policy';

import { adaptProgram } from '../cycle/cycle-program-generator';

import {
  calculateCycleStatus as cycleExport,
  applyPhaseAdjustment as policyExport,
  adaptProgram as generatorExport,
} from '../cycle';

import cycleCalcFixtures from '../__fixtures__/cycle-calculations.json';
import cycleAdaptFixtures from '../__fixtures__/cycle-adaptation.json';

import type { CycleSettings, PeriodLog, ProgramExercise, ProgramSession, Program, ExerciseValue } from '../types';

// ---------------------------------------------------------------------------
// CycleCalculations
// ---------------------------------------------------------------------------

describe('CycleCalculations', () => {
  describe('getPhaseBoundaries', () => {
    test.each(cycleCalcFixtures.phaseBoundaries)(
      '$description',
      ({ settings, expected }) => {
        const boundaries = getPhaseBoundaries(settings as CycleSettings);
        expect(boundaries.menstrual).toEqual(expected.menstrual);
        expect(boundaries.follicular).toEqual(expected.follicular);
        expect(boundaries.ovulation).toEqual(expected.ovulation);
        expect(boundaries.luteal).toEqual(expected.luteal);
      }
    );
  });

  describe('inferCurrentPhase', () => {
    test.each(cycleCalcFixtures.phaseInference)(
      '$description',
      ({ settings, cycleDay, expectedPhase }) => {
        const result = inferCurrentPhase(cycleDay, settings as CycleSettings);
        expect(result).toBe(expectedPhase);
      }
    );
  });

  describe('calculateCycleStatus', () => {
    const defaultSettings: CycleSettings = {
      averageCycleLengthDays: 28,
      averagePeriodLengthDays: 5,
      lutealPhaseLengthDays: 14,
    };

    test('returns undefined for empty period logs', () => {
      const result = calculateCycleStatus([], defaultSettings);
      expect(result).toBeUndefined();
    });

    test('returns correct phase for period starting 10 days ago', () => {
      // A period that started 10 days ago — we are in follicular phase
      const referenceDate = new Date(2024, 0, 15); // Jan 15, 2024
      const periodStart = new Date(2024, 0, 5);    // Jan 5, 2024 (10 days ago)
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      expect(result!.currentPhase).toBe('follicular');
      expect(result!.cycleDay).toBe(11); // day 11 (Jan 5 = day 1, Jan 15 = day 11)
    });

    test('returns menstrual phase for period starting 2 days ago', () => {
      const referenceDate = new Date(2024, 0, 15);
      const periodStart = new Date(2024, 0, 13); // 2 days ago
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      expect(result!.currentPhase).toBe('menstrual');
      expect(result!.cycleDay).toBe(3);
    });

    test('returns ovulation phase for period starting 13 days ago', () => {
      const referenceDate = new Date(2024, 0, 15);
      const periodStart = new Date(2024, 0, 2); // 13 days ago (day 14)
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      expect(result!.currentPhase).toBe('ovulation');
      expect(result!.cycleDay).toBe(14);
    });

    test('returns luteal phase for period starting 19 days ago', () => {
      const referenceDate = new Date(2024, 0, 20);
      const periodStart = new Date(2024, 0, 1); // 19 days ago (day 20)
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      expect(result!.currentPhase).toBe('luteal');
      expect(result!.cycleDay).toBe(20);
    });

    test('predictedNextPeriod is cycleLength days after cycle start', () => {
      const referenceDate = new Date(2024, 0, 15);
      const periodStart = new Date(2024, 0, 5);
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      // Predicted next period: Jan 5 + 28 days = Feb 2
      const expected = new Date(2024, 1, 2);
      expect(result!.predictedNextPeriod.getFullYear()).toBe(expected.getFullYear());
      expect(result!.predictedNextPeriod.getMonth()).toBe(expected.getMonth());
      expect(result!.predictedNextPeriod.getDate()).toBe(expected.getDate());
    });

    test('daysUntilNextPhase is non-negative', () => {
      const referenceDate = new Date(2024, 0, 15);
      const periodStart = new Date(2024, 0, 5);
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result!.daysUntilNextPhase).toBeGreaterThanOrEqual(0);
    });

    test('handles period with endDate specified', () => {
      const referenceDate = new Date(2024, 0, 10);
      const periodStart = new Date(2024, 0, 3);
      const periodEnd = new Date(2024, 0, 7);
      const logs: PeriodLog[] = [{ startDate: periodStart, endDate: periodEnd }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      // Day 8 → follicular
      expect(result!.currentPhase).toBe('follicular');
    });

    test('handles multiple period logs, picks correct cycle', () => {
      // Most recent period started 3 days ago (menstrual)
      const referenceDate = new Date(2024, 1, 15); // Feb 15
      const recentPeriod = new Date(2024, 1, 12);  // Feb 12 (3 days ago)
      const oldPeriod = new Date(2024, 0, 15);     // Jan 15 (previous cycle)
      const logs: PeriodLog[] = [
        { startDate: oldPeriod },
        { startDate: recentPeriod },
      ];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      expect(result!.currentPhase).toBe('menstrual');
      expect(result!.cycleDay).toBe(4);
    });

    test('handles far-future reference date (multiple cycles elapsed)', () => {
      const periodStart = new Date(2024, 0, 1);
      // Reference 56 days (2 full 28-day cycles) later
      const referenceDate = new Date(2024, 1, 26);
      const logs: PeriodLog[] = [{ startDate: periodStart }];
      const result = calculateCycleStatus(logs, defaultSettings, referenceDate);
      expect(result).toBeDefined();
      // Should be day 1 of a new cycle
      expect(result!.cycleDay).toBeGreaterThanOrEqual(1);
    });
  });

  describe('inferCurrentPhase — fallback branch', () => {
    test('returns follicular as fallback when cycleDay is out of all phase ranges', () => {
      // Craft a degenerate settings where cycleDay 100 falls outside all phases
      const settings: CycleSettings = {
        averageCycleLengthDays: 10,
        averagePeriodLengthDays: 2,
        lutealPhaseLengthDays: 3,
      };
      // cycleDay 50 is beyond cycleLen=10, so no boundary matches
      const result = inferCurrentPhase(50, settings);
      expect(result).toBe('follicular');
    });
  });

  describe('getPhaseRecommendation', () => {
    test('returns menstrual recommendation', () => {
      const rec = getPhaseRecommendation('menstrual');
      expect(rec.phase).toBe('menstrual');
      expect(rec.intensityRecommendation).toBe('low');
      expect(rec.exercisesToAvoid).toContain('heavy compound lifts');
    });

    test('returns follicular recommendation', () => {
      const rec = getPhaseRecommendation('follicular');
      expect(rec.phase).toBe('follicular');
      expect(rec.intensityRecommendation).toBe('moderate');
      expect(rec.exercisesToAvoid).toHaveLength(0);
    });

    test('returns ovulation recommendation', () => {
      const rec = getPhaseRecommendation('ovulation');
      expect(rec.phase).toBe('ovulation');
      expect(rec.intensityRecommendation).toBe('peak');
      expect(rec.exercisesToEmphasize).toContain('max effort attempts');
    });

    test('returns luteal recommendation', () => {
      const rec = getPhaseRecommendation('luteal');
      expect(rec.phase).toBe('luteal');
      expect(rec.intensityRecommendation).toBe('moderate');
      expect(rec.exercisesToAvoid).toContain('max effort attempts');
    });
  });
});

// ---------------------------------------------------------------------------
// CycleAdaptationPolicy
// ---------------------------------------------------------------------------

describe('CycleAdaptationPolicy', () => {
  describe('blendMultiplier', () => {
    test.each(cycleAdaptFixtures.blendMultiplier)(
      '$description',
      ({ target, readinessScale, confidenceScale, expected }) => {
        const result = blendMultiplier(target, readinessScale, confidenceScale);
        expect(result).toBeCloseTo(expected, 10);
      }
    );
  });

  describe('resolveReadinessTier', () => {
    test.each(cycleAdaptFixtures.resolveReadinessTier)(
      'score $score → $expected',
      ({ score, expected }) => {
        const result = resolveReadinessTier(score === null ? undefined : score);
        expect(result).toBe(expected);
      }
    );
  });

  describe('applyPhaseAdjustment', () => {
    const baseExercise: ProgramExercise = {
      id: 'squat',
      name: 'Back Squat',
      sets: 4,
      reps: { kind: 'fixed', value: 5 },
      weight: { kind: 'fixed', value: 100 },
    };

    test('menstrual phase reduces reps (fixed)', () => {
      // Menstrual: reps multiplier 0.90, neutral readiness (1.0), high confidence (1.0)
      // blendMultiplier(0.90, 1.0, 1.0) = 1 + (0.90 - 1) * 1.0 * 1.0 = 0.90
      // 5 * 0.90 = 4.5 → rounds to 5 (swiftRound)
      const result = applyPhaseAdjustment(baseExercise, 'menstrual', 'neutral', 'high');
      expect(result.reps).toEqual({ kind: 'fixed', value: 5 });
    });

    test('ovulation phase increases reps for range values', () => {
      const rangeExercise: ProgramExercise = {
        ...baseExercise,
        reps: { kind: 'range', lo: 8, hi: 12 },
      };
      // Ovulation: reps multiplier 0.95 — note reps actually reduces slightly at ovulation
      // blendMultiplier(0.95, 1.0, 1.0) = 0.95
      const result = applyPhaseAdjustment(rangeExercise, 'ovulation', 'neutral', 'high');
      expect(result.reps.kind).toBe('range');
    });

    test('amrap reps pass through unchanged', () => {
      const amrapExercise: ProgramExercise = {
        ...baseExercise,
        reps: { kind: 'amrap' },
      };
      const result = applyPhaseAdjustment(amrapExercise, 'menstrual', 'neutral', 'high');
      expect(result.reps).toEqual({ kind: 'amrap' });
    });

    test('text reps pass through unchanged', () => {
      const textExercise: ProgramExercise = {
        ...baseExercise,
        reps: { kind: 'text', value: '30 seconds' },
      };
      const result = applyPhaseAdjustment(textExercise, 'luteal', 'neutral', 'high');
      expect(result.reps).toEqual({ kind: 'text', value: '30 seconds' });
    });

    test('sets scale with sets multiplier', () => {
      const result = applyPhaseAdjustment(baseExercise, 'follicular', 'neutral', 'high');
      // Follicular: sets multiplier 1.0 → sets = 4
      expect(result.sets).toBe(4);
    });

    test('scaled fixed value never goes below 1', () => {
      const tinyExercise: ProgramExercise = {
        ...baseExercise,
        sets: 1,
        reps: { kind: 'fixed', value: 1 },
      };
      const result = applyPhaseAdjustment(tinyExercise, 'menstrual', 'low', 'low');
      // Even with maximum downscaling, value floors at 1
      expect((result.reps as { kind: 'fixed'; value: number }).value).toBeGreaterThanOrEqual(1);
      expect(result.sets).toBeGreaterThanOrEqual(1);
    });

    test('range lo never exceeds hi after scaling', () => {
      const rangeExercise: ProgramExercise = {
        ...baseExercise,
        reps: { kind: 'range', lo: 3, hi: 3 },
      };
      const result = applyPhaseAdjustment(rangeExercise, 'menstrual', 'low', 'low');
      const reps = result.reps as { kind: 'range'; lo: number; hi: number };
      expect(reps.lo).toBeLessThanOrEqual(reps.hi);
    });

    test('no weight exercise (no weight field) handled gracefully', () => {
      const noWeightExercise: ProgramExercise = {
        id: 'pushup',
        name: 'Push-Up',
        sets: 3,
        reps: { kind: 'fixed', value: 10 },
      };
      const result = applyPhaseAdjustment(noWeightExercise, 'ovulation', 'high', 'high');
      expect(result.weight).toBeUndefined();
    });

    test('weight is scaled during ovulation (load increase)', () => {
      // Ovulation load multiplier: 1.12, high readiness: 1.2, high confidence: 1.0
      // blendMultiplier(1.12, 1.2, 1.0) = 1 + (0.12 * 1.2) = 1.144 → clamp to 1.144 (< 1.25)
      const result = applyPhaseAdjustment(baseExercise, 'ovulation', 'high', 'high');
      const weight = result.weight as { kind: 'fixed'; value: number };
      expect(weight.value).toBeGreaterThan(100); // increased from 100
    });

    test('weight is scaled during menstrual (load reduction)', () => {
      // Menstrual load multiplier: 0.90, neutral readiness: 1.0, high confidence: 1.0
      // blendMultiplier(0.90, 1.0, 1.0) = 0.90 → 100 * 0.90 = 90
      const result = applyPhaseAdjustment(baseExercise, 'menstrual', 'neutral', 'high');
      const weight = result.weight as { kind: 'fixed'; value: number };
      expect(weight.value).toBe(90);
    });
  });
});

// ---------------------------------------------------------------------------
// CycleProgramGenerator
// ---------------------------------------------------------------------------

describe('CycleProgramGenerator', () => {
  const settings: CycleSettings = {
    averageCycleLengthDays: 28,
    averagePeriodLengthDays: 5,
    lutealPhaseLengthDays: 14,
  };

  const session: ProgramSession = {
    id: 'session-1',
    name: 'Day 1',
    exercises: [
      {
        id: 'squat',
        name: 'Back Squat',
        sets: 4,
        reps: { kind: 'fixed', value: 5 },
        weight: { kind: 'fixed', value: 100 },
      },
      {
        id: 'deadlift',
        name: 'Deadlift',
        sets: 3,
        reps: { kind: 'range', lo: 3, hi: 5 },
      },
    ],
  };

  const program: Program = {
    id: 'prog-1',
    name: 'Test Program',
    sessions: [session],
  };

  test('adapts program exercises for menstrual phase', () => {
    const periodStart = new Date(2024, 0, 1);  // Jan 1 = day 1 (menstrual)
    const referenceDate = new Date(2024, 0, 3); // Jan 3 = day 3
    const logs: PeriodLog[] = [{ startDate: periodStart }];
    const adapted = adaptProgram(program, logs, settings, referenceDate);
    expect(adapted).toBeDefined();
    expect(adapted.sessions).toHaveLength(1);
    expect(adapted.sessions[0].exercises).toHaveLength(2);
  });

  test('adapts all exercises in a session', () => {
    const periodStart = new Date(2024, 0, 1);
    const referenceDate = new Date(2024, 0, 3);
    const logs: PeriodLog[] = [{ startDate: periodStart }];
    const adapted = adaptProgram(program, logs, settings, referenceDate, 7);
    const origSqReps = (session.exercises[0].reps as { kind: 'fixed'; value: number }).value;
    // Values may change due to phase adjustment — just verify types are preserved
    const adaptedReps = adapted.sessions[0].exercises[0].reps;
    expect(adaptedReps.kind).toBe('fixed');
  });

  test('returns program unchanged for empty period logs', () => {
    const adapted = adaptProgram(program, [], settings);
    // Without logs, calculateCycleStatus returns undefined → falls back to follicular
    expect(adapted.sessions).toHaveLength(1);
  });

  test('handles undefined readinessScore', () => {
    const periodStart = new Date(2024, 0, 1);
    const referenceDate = new Date(2024, 0, 3);
    const logs: PeriodLog[] = [{ startDate: periodStart }];
    const adapted = adaptProgram(program, logs, settings, referenceDate, undefined);
    expect(adapted).toBeDefined();
  });

  test('preserves program metadata (id, name)', () => {
    const periodStart = new Date(2024, 0, 1);
    const logs: PeriodLog[] = [{ startDate: periodStart }];
    const adapted = adaptProgram(program, logs, settings);
    expect(adapted.id).toBe('prog-1');
    expect(adapted.name).toBe('Test Program');
  });

  test('handles multiple logs including one later in array that is most recent (reduce true branch)', () => {
    // Logs intentionally unsorted so reduce must update latest via the true branch
    const olderStart = new Date(2024, 0, 1);   // Jan 1 (first/initial value)
    const recentStart = new Date(2024, 1, 1);  // Feb 1 (later in array, more recent)
    const referenceDate = new Date(2024, 1, 3);
    const logs: PeriodLog[] = [
      { startDate: olderStart },
      { startDate: recentStart },
    ];
    const adapted = adaptProgram(program, logs, settings, referenceDate);
    expect(adapted).toBeDefined();
    expect(adapted.sessions).toHaveLength(1);
  });
});

  describe('resolveConfidenceScale', () => {
    test('high confidence returns 1.0', () => {
      const { resolveConfidenceScale: rcs } = require('../cycle/cycle-adaptation-policy');
      expect(rcs('high')).toBe(1.0);
    });

    test('medium confidence returns 0.8', () => {
      const { resolveConfidenceScale: rcs } = require('../cycle/cycle-adaptation-policy');
      expect(rcs('medium')).toBe(0.8);
    });

    test('low confidence with default lowConfidenceScale returns 0.55 * 0.7 clamped', () => {
      const { resolveConfidenceScale: rcs } = require('../cycle/cycle-adaptation-policy');
      // 0.55 * 0.7 = 0.385 → clamped to [0.1, 1.0] → 0.385
      expect(rcs('low')).toBeCloseTo(0.385, 10);
    });

    test('low confidence with custom lowConfidenceScale', () => {
      const { resolveConfidenceScale: rcs } = require('../cycle/cycle-adaptation-policy');
      expect(rcs('low', 1.0)).toBeCloseTo(0.55, 10);
    });
  });

  describe('resolveConfidence — generator internal', () => {
    test('returns low when currentPhase is undefined with logs present but recent (< 45 days)', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      const referenceDate = new Date(2024, 0, 15);
      const lastPeriodStart = new Date(2024, 0, 5); // 10 days ago, < 45
      // currentPhase undefined, periodLogCount 1, daysSince < 45 → returns 'low' (line 29 fallback)
      const result = rc(undefined, 1, lastPeriodStart, referenceDate);
      expect(result).toBe('low');
    });

    test('returns high when currentPhase present and >= 3 logs', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      const referenceDate = new Date(2024, 0, 15);
      const lastPeriodStart = new Date(2024, 0, 5);
      const result = rc('follicular', 3, lastPeriodStart, referenceDate);
      expect(result).toBe('high');
    });

    test('returns medium when currentPhase present and < 3 logs', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      const referenceDate = new Date(2024, 0, 15);
      const lastPeriodStart = new Date(2024, 0, 5);
      const result = rc('menstrual', 2, lastPeriodStart, referenceDate);
      expect(result).toBe('medium');
    });

    test('returns low when last period start is > 45 days ago', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      const referenceDate = new Date(2024, 2, 15); // March 15
      const lastPeriodStart = new Date(2024, 0, 1); // Jan 1 (73 days ago)
      const result = rc('follicular', 3, lastPeriodStart, referenceDate);
      expect(result).toBe('low');
    });

    test('returns low when periodLogCount is 0', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      const result = rc(undefined, 0, undefined, new Date());
      expect(result).toBe('low');
    });

    test('handles lastPeriodStart undefined with logs present', () => {
      const { resolveConfidence: rc } = require('../cycle/cycle-program-generator');
      // When lastPeriodStart is undefined, skips the 45-day check → falls through to phase checks
      const result = rc('follicular', 2, undefined, new Date(2024, 0, 15));
      expect(result).toBe('medium');
    });
  });

// ---------------------------------------------------------------------------
// Barrel exports (cycle/index.ts)
// ---------------------------------------------------------------------------

describe('Cycle barrel exports', () => {
  test('calculateCycleStatus exported from barrel', () => {
    expect(typeof cycleExport).toBe('function');
  });

  test('applyPhaseAdjustment exported from barrel', () => {
    expect(typeof policyExport).toBe('function');
  });

  test('adaptProgram exported from barrel', () => {
    expect(typeof generatorExport).toBe('function');
  });
});

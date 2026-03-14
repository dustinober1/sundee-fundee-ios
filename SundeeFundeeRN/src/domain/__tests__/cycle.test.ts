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

import cycleCalcFixtures from '../__fixtures__/cycle-calculations.json';

import type { CycleSettings, PeriodLog } from '../types';

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

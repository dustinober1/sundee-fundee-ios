import { describe, it, expect } from 'vitest';
import {
  calculateCycleStatus,
  getPhaseBoundaries,
  getPhaseRecommendation,
  analyzeStrengthPatterns,
  predictStrengthWindow
} from '@/lib/cycle-calculations';
import type { PeriodLog, CycleSettings } from '@/types';
import { addDays } from 'date-fns';

function createDefaultSettings(): CycleSettings {
  return {
    id: 'settings1',
    userId: 'user1',
    averageCycleLength: 28,
    averagePeriodLength: 5,
    lutealPhaseLength: 14,
    enabledSymptomIds: [],
    notificationsEnabled: true
  };
}

describe('Cycle Calculations', () => {
  describe('calculateCycleStatus', () => {
    it('returns null when no period logs exist', () => {
      const result = calculateCycleStatus([], createDefaultSettings());
      expect(result).toBeNull();
    });

    it('calculates status for a simple cycle', () => {
      const periodLogs: PeriodLog[] = [{
        id: '1',
        userId: 'user1',
        startDate: new Date('2023-01-01'),
        endDate: new Date('2023-01-05'),
        createdAt: new Date()
      }];

      const settings = createDefaultSettings();
      const result = calculateCycleStatus(periodLogs, settings, new Date('2023-01-03'));

      expect(result).not.toBeNull();
      expect(result?.currentPhase).toBe('menstrual');
      expect(result?.cycleDay).toBe(3);
    });

    it('determines follicular phase correctly', () => {
      const periodLogs: PeriodLog[] = [{
        id: '1',
        userId: 'user1',
        startDate: new Date('2023-01-01'),
        endDate: new Date('2023-01-05'),
        createdAt: new Date()
      }];

      const settings = createDefaultSettings();
      // Day 8 should be in follicular phase (days 6-11 for default settings)
      const result = calculateCycleStatus(periodLogs, settings, new Date('2023-01-08'));

      expect(result).not.toBeNull();
      expect(result?.currentPhase).toBe('follicular');
    });
  });

  describe('getPhaseBoundaries', () => {
    it('returns correct phase boundaries for default settings', () => {
      const settings = createDefaultSettings();
      const boundaries = getPhaseBoundaries(settings, new Date('2023-01-01'));

      expect(boundaries.menstrual).toEqual({ start: 1, end: 5 });
      expect(boundaries.follicular.start).toBe(6);
      expect(boundaries.ovulation.start).toBeGreaterThanOrEqual(10);
      expect(boundaries.luteal.end).toBe(28);
    });

    it('adjusts boundaries based on custom settings', () => {
      const settings: CycleSettings = {
        id: 'settings1',
        userId: 'user1',
        averageCycleLength: 30,
        averagePeriodLength: 4,
        lutealPhaseLength: 14,
        enabledSymptomIds: [],
        notificationsEnabled: true
      };

      const boundaries = getPhaseBoundaries(settings, new Date('2023-01-01'));

      expect(boundaries.menstrual).toEqual({ start: 1, end: 4 });
      expect(boundaries.luteal.end).toBe(30);
    });
  });

  describe('getPhaseRecommendation', () => {
    it('returns correct recommendation for menstrual phase', () => {
      const recommendation = getPhaseRecommendation('menstrual');

      expect(recommendation.phase).toBe('menstrual');
      expect(recommendation.intensityRecommendation).toBe('low');
      expect(recommendation.exercisesToAvoid).toContain('heavy compound lifts');
    });

    it('returns correct recommendation for ovulation phase', () => {
      const recommendation = getPhaseRecommendation('ovulation');

      expect(recommendation.phase).toBe('ovulation');
      expect(recommendation.intensityRecommendation).toBe('peak');
      expect(recommendation.exercisesToEmphasize).toContain('max effort attempts');
    });

    it('returns recommendation for follicular phase', () => {
      const recommendation = getPhaseRecommendation('follicular');
      expect(recommendation.intensityRecommendation).toBe('moderate');
    });

    it('returns recommendation for luteal phase', () => {
      const recommendation = getPhaseRecommendation('luteal');
      expect(recommendation.intensityRecommendation).toBe('moderate');
      expect(recommendation.exercisesToAvoid).toContain('max effort attempts');
    });
  });

  describe('analyzeStrengthPatterns', () => {
    it('returns null when fewer than 2 periods exist', () => {
      const result = analyzeStrengthPatterns([], [], []);
      expect(result).toBeNull();
    });

    it('returns null with only one period', () => {
      const periodLogs: PeriodLog[] = [
        { id: '1', userId: 'user1', startDate: new Date('2023-01-01'), createdAt: new Date() }
      ];
      const result = analyzeStrengthPatterns([], [], periodLogs);
      expect(result).toBeNull();
    });

    it('returns profile with default values when sufficient data exists', () => {
      const periodLogs: PeriodLog[] = [
        { id: '1', userId: 'user1', startDate: new Date('2023-01-01'), createdAt: new Date() },
        { id: '2', userId: 'user1', startDate: new Date('2023-01-28'), createdAt: new Date() }
      ];

      const result = analyzeStrengthPatterns([], [], periodLogs);

      expect(result).not.toBeNull();
      expect(result?.strongestPhase).toBeDefined();
      expect(result?.weakestPhase).toBeDefined();
      expect(result?.confidence).toBeGreaterThanOrEqual(0);
    });
  });

  describe('predictStrengthWindow', () => {
    it('uses personal profile if available', () => {
      const cycleStatus = {
        currentPhase: 'follicular' as const,
        cycleDay: 10,
        daysUntilNextPhase: 5,
        predictedNextPeriod: addDays(new Date(), 18),
        phaseStartDate: new Date(),
        phaseEndDate: addDays(new Date(), 5)
      };

      const strengthProfile = {
        userId: 'user1',
        phases: [
          { phase: 'menstrual' as const, avgPerformanceDelta: -0.05, sampleSize: 5 },
          { phase: 'follicular' as const, avgPerformanceDelta: 0.02, sampleSize: 8 },
          { phase: 'ovulation' as const, avgPerformanceDelta: 0.08, sampleSize: 3 },
          { phase: 'luteal' as const, avgPerformanceDelta: -0.02, sampleSize: 7 }
        ],
        strongestPhase: 'ovulation' as const,
        weakestPhase: 'menstrual' as const,
        confidence: 0.7
      };

      const result = predictStrengthWindow(cycleStatus, strengthProfile);
      expect(result.confidence).toBe(strengthProfile.confidence);
    });

    it('uses default prediction when no profile available', () => {
      const cycleStatus = {
        currentPhase: 'follicular' as const,
        cycleDay: 10,
        daysUntilNextPhase: 5,
        predictedNextPeriod: addDays(new Date(), 18),
        phaseStartDate: new Date(),
        phaseEndDate: addDays(new Date(), 5)
      };

      const result = predictStrengthWindow(cycleStatus);
      expect(result.confidence).toBe(0.5);
      expect(result.startDate).toBeInstanceOf(Date);
      expect(result.endDate).toBeInstanceOf(Date);
    });
  });
});

/**
 * Tests for shared domain modules and top-level barrel.
 * Written FIRST (RED phase) — implementations do not exist yet.
 */

import type { CelebrationEvent } from '../shared/celebration-event';
import {
  getCelebrationTitle,
  getCelebrationSubtitle,
} from '../shared/celebration-event';

import {
  getProgramAvailability,
  sortedPrograms,
  nextUpcomingProgram,
  parseProgramDate,
  formatProgramStartDate,
} from '../shared/program-availability';

import type { WODTemplateType } from '../shared/wod-template-type';
import {
  wodTemplateTypeFrom,
  wodTemplateTypeDisplayName,
  wodTemplateTypeRequiresTimer,
} from '../shared/wod-template-type';

import type { Program } from '../types';

// ============================================================================
// CelebrationEvent
// ============================================================================

describe('CelebrationEvent', () => {
  describe('getCelebrationTitle', () => {
    it('returns Workout Complete! for workoutCompleted', () => {
      const event: CelebrationEvent = { kind: 'workoutCompleted', durationSeconds: 3600 };
      expect(getCelebrationTitle(event)).toBe('Workout Complete!');
    });

    it('returns New Personal Record! for newPersonalRecord', () => {
      const event: CelebrationEvent = {
        kind: 'newPersonalRecord',
        exerciseName: 'Back Squat',
        weightKg: 100,
      };
      expect(getCelebrationTitle(event)).toBe('New Personal Record!');
    });

    it('returns Program Complete! for programCompleted', () => {
      const event: CelebrationEvent = { kind: 'programCompleted', programName: 'GZCLP' };
      expect(getCelebrationTitle(event)).toBe('Program Complete!');
    });

    it('returns Weight Milestone! for weightMilestone', () => {
      const event: CelebrationEvent = {
        kind: 'weightMilestone',
        exerciseName: 'Deadlift',
        thresholdKg: 200,
      };
      expect(getCelebrationTitle(event)).toBe('Weight Milestone!');
    });

    it('returns New Conditioning PR! for newConditioningPR', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: 'Fran',
        value: 180,
        scoringType: 'time',
      };
      expect(getCelebrationTitle(event)).toBe('New Conditioning PR!');
    });
  });

  describe('getCelebrationSubtitle', () => {
    it('returns minutes for workoutCompleted with duration > 60s', () => {
      const event: CelebrationEvent = { kind: 'workoutCompleted', durationSeconds: 3600 };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('60 min');
    });

    it('returns saved text for workoutCompleted with 0 seconds', () => {
      const event: CelebrationEvent = { kind: 'workoutCompleted', durationSeconds: 0 };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('saved');
    });

    it('returns exercise name and weight for newPersonalRecord', () => {
      const event: CelebrationEvent = {
        kind: 'newPersonalRecord',
        exerciseName: 'Back Squat',
        weightKg: 100,
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('Back Squat');
    });

    it('returns program name for programCompleted', () => {
      const event: CelebrationEvent = { kind: 'programCompleted', programName: 'Starting Strength' };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('Starting Strength');
    });

    it('returns exercise name and threshold for weightMilestone', () => {
      const event: CelebrationEvent = {
        kind: 'weightMilestone',
        exerciseName: 'Deadlift',
        thresholdKg: 200,
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('Deadlift');
    });

    it('returns exercise name and value for newConditioningPR (time)', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: 'Fran',
        value: 180,
        scoringType: 'time',
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('Fran');
      expect(subtitle).toContain('3:00');
    });

    it('formats reps scoring type for newConditioningPR', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: 'Cindy',
        value: 20,
        scoringType: 'reps',
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('20 reps');
    });

    it('formats weight scoring type for newConditioningPR', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: '1RM Bench',
        value: 100,
        scoringType: 'weight',
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('100.0 kg');
    });

    it('formats distance scoring type for newConditioningPR', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: '5K Run',
        value: 2000,
        scoringType: 'distance',
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('2000m');
    });

    it('formats roundsAndReps scoring type for newConditioningPR', () => {
      const event: CelebrationEvent = {
        kind: 'newConditioningPR',
        exerciseName: 'Cindy AMRAP',
        value: 30015,
        scoringType: 'roundsAndReps',
      };
      const subtitle = getCelebrationSubtitle(event);
      expect(subtitle).toContain('3 rounds');
      expect(subtitle).toContain('15 reps');
    });
  });
});

// ============================================================================
// ProgramAvailability
// ============================================================================

function makeProgram(overrides: Partial<Program> = {}): Program {
  return {
    id: 'p1',
    name: 'Test Program',
    sessions: [],
    ...overrides,
  };
}

describe('ProgramAvailability', () => {
  describe('getProgramAvailability', () => {
    it('returns active for program with no dates', () => {
      const program = makeProgram();
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('active');
    });

    it('returns upcoming for program with future start date', () => {
      const program = makeProgram({ startDate: '2026-04-01' });
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('upcoming');
      if (status.kind === 'upcoming') {
        expect(status.startDate).toBeInstanceOf(Date);
      }
    });

    it('returns past for program with end date in past', () => {
      const program = makeProgram({ endDate: '2026-01-01' });
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('past');
    });

    it('returns active for program with start today', () => {
      const program = makeProgram({ startDate: '2026-03-14' });
      // Use local date constructor to avoid UTC-vs-local timezone issues
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('active');
    });

    it('returns active for program with end date today', () => {
      const program = makeProgram({ endDate: '2026-03-14' });
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('active');
    });

    it('returns active when past start and before end', () => {
      const program = makeProgram({ startDate: '2026-01-01', endDate: '2026-12-31' });
      const status = getProgramAvailability(program, new Date(2026, 2, 14));
      expect(status.kind).toBe('active');
    });
  });

  describe('sortedPrograms', () => {
    it('sorts active before upcoming before past', () => {
      const now = new Date(2026, 2, 14);
      const programs: Program[] = [
        makeProgram({ id: 'past', name: 'Past', endDate: '2026-01-01' }),
        makeProgram({ id: 'upcoming', name: 'Upcoming', startDate: '2026-04-01' }),
        makeProgram({ id: 'active', name: 'Active' }),
      ];
      const sorted = sortedPrograms(programs, now);
      expect(sorted[0].id).toBe('active');
      expect(sorted[1].id).toBe('upcoming');
      expect(sorted[2].id).toBe('past');
    });
  });

  describe('nextUpcomingProgram', () => {
    it('returns the earliest upcoming program', () => {
      const now = new Date(2026, 2, 14);
      const programs: Program[] = [
        makeProgram({ id: 'later', name: 'Later', startDate: '2026-06-01' }),
        makeProgram({ id: 'sooner', name: 'Sooner', startDate: '2026-04-01' }),
        makeProgram({ id: 'active', name: 'Active' }),
      ];
      const next = nextUpcomingProgram(programs, now);
      expect(next?.id).toBe('sooner');
    });

    it('returns undefined when no upcoming programs', () => {
      const now = new Date(2026, 2, 14);
      const programs: Program[] = [
        makeProgram({ id: 'active', name: 'Active' }),
      ];
      const next = nextUpcomingProgram(programs, now);
      expect(next).toBeUndefined();
    });
  });

  describe('parseProgramDate', () => {
    it('parses valid date string', () => {
      const date = parseProgramDate('2026-03-14');
      expect(date).toBeInstanceOf(Date);
      expect(date?.getFullYear()).toBe(2026);
    });

    it('returns null for invalid date string', () => {
      const date = parseProgramDate('not-a-date');
      expect(date).toBeNull();
    });

    it('returns null for empty string', () => {
      const date = parseProgramDate('');
      expect(date).toBeNull();
    });
  });

  describe('formatProgramStartDate', () => {
    it('formats date to readable string', () => {
      const date = new Date(2026, 2, 14); // March 14, 2026
      const formatted = formatProgramStartDate(date);
      expect(typeof formatted).toBe('string');
      expect(formatted.length).toBeGreaterThan(0);
    });
  });
});

// ============================================================================
// WODTemplateType
// ============================================================================

describe('WODTemplateType', () => {
  describe('wodTemplateTypeFrom', () => {
    it('returns strength for "strength"', () => {
      expect(wodTemplateTypeFrom('strength')).toBe('strength');
    });

    it('returns amrap for "amrap"', () => {
      expect(wodTemplateTypeFrom('amrap')).toBe('amrap');
    });

    it('returns emom for "emom"', () => {
      expect(wodTemplateTypeFrom('emom')).toBe('emom');
    });

    it('returns forTime for "forTime"', () => {
      expect(wodTemplateTypeFrom('forTime')).toBe('forTime');
    });

    it('returns circuit for "circuit"', () => {
      expect(wodTemplateTypeFrom('circuit')).toBe('circuit');
    });

    it('defaults to strength for unknown value', () => {
      expect(wodTemplateTypeFrom('unknown')).toBe('strength');
    });
  });

  describe('wodTemplateTypeDisplayName', () => {
    it('returns Strength for strength', () => {
      expect(wodTemplateTypeDisplayName('strength')).toBe('Strength');
    });

    it('returns AMRAP for amrap', () => {
      expect(wodTemplateTypeDisplayName('amrap')).toBe('AMRAP');
    });

    it('returns EMOM for emom', () => {
      expect(wodTemplateTypeDisplayName('emom')).toBe('EMOM');
    });

    it('returns For Time for forTime', () => {
      expect(wodTemplateTypeDisplayName('forTime')).toBe('For Time');
    });

    it('returns Circuit for circuit', () => {
      expect(wodTemplateTypeDisplayName('circuit')).toBe('Circuit');
    });
  });

  describe('wodTemplateTypeRequiresTimer', () => {
    it('amrap requires timer', () => {
      expect(wodTemplateTypeRequiresTimer('amrap')).toBe(true);
    });

    it('emom requires timer', () => {
      expect(wodTemplateTypeRequiresTimer('emom')).toBe(true);
    });

    it('forTime requires timer', () => {
      expect(wodTemplateTypeRequiresTimer('forTime')).toBe(true);
    });

    it('strength does not require timer', () => {
      expect(wodTemplateTypeRequiresTimer('strength')).toBe(false);
    });

    it('circuit does not require timer', () => {
      expect(wodTemplateTypeRequiresTimer('circuit')).toBe(false);
    });
  });
});

// ============================================================================
// Top-level barrel (static import)
// ============================================================================

import {
  estimated1RM,
  generateOfflineWorkout as generateOfflineWorkoutBarrel,
  BENCHMARK_CATALOG as BENCHMARK_CATALOG_BARREL,
  calculateReadinessScore as calculateReadinessScoreBarrel,
  getProgramAvailability as getProgramAvailabilityBarrel,
  getSourceLabel as getSourceLabelBarrel,
} from '../index';

describe('Top-level domain barrel', () => {
  it('re-exports estimated1RM from calculations subdomain', () => {
    expect(typeof estimated1RM).toBe('function');
  });

  it('re-exports generateOfflineWorkout from ai-workout subdomain', () => {
    expect(typeof generateOfflineWorkoutBarrel).toBe('function');
  });

  it('re-exports BENCHMARK_CATALOG from benchmarks subdomain', () => {
    expect(Array.isArray(BENCHMARK_CATALOG_BARREL)).toBe(true);
    expect(BENCHMARK_CATALOG_BARREL.length).toBeGreaterThan(0);
  });

  it('re-exports calculateReadinessScore from readiness subdomain', () => {
    expect(typeof calculateReadinessScoreBarrel).toBe('function');
  });

  it('re-exports getProgramAvailability from shared subdomain', () => {
    expect(typeof getProgramAvailabilityBarrel).toBe('function');
  });

  it('re-exports getSourceLabel from history subdomain', () => {
    expect(typeof getSourceLabelBarrel).toBe('function');
  });
});

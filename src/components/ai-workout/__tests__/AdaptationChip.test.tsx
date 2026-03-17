/**
 * AdaptationChip.test.tsx
 *
 * Tests for the buildAdaptationText static helper.
 * Covers all combinations: phase + injury + readiness, subsets, and none → null.
 */

import { buildAdaptationText } from '../AdaptationChip';
import type { InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '@/src/repositories/ReadinessRepo';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

function makeInjury(overrides: Partial<InjuryProfileRecord> = {}): InjuryProfileRecord {
  return {
    id: 'inj-1',
    uid: 'user-1',
    bodyLocation: 'rightKnee',
    recoveryPhase: 'rehab',
    injuryDate: '2026-01-01T00:00:00.000Z',
    location: 'Right knee',
    ...overrides,
  };
}

function makeReadiness(score: number): ReadinessSurveyRecord {
  return {
    id: '2026-03-15',
    uid: 'user-1',
    date: '2026-03-15',
    sleepQuality: 7,
    energyLevel: 6,
    stressLevel: 4,
    sorenessLevel: 3,
    result: { score, tier: score >= 0.7 ? 'high' : score >= 0.4 ? 'neutral' : 'low' },
  };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('buildAdaptationText', () => {
  it('returns null when no adaptations apply', () => {
    const result = buildAdaptationText(undefined, undefined, undefined);
    expect(result).toBeNull();
  });

  it('returns null when no adaptations apply (empty arrays, null readiness)', () => {
    const result = buildAdaptationText(undefined, [], null);
    expect(result).toBeNull();
  });

  it('returns cycle phase only', () => {
    const result = buildAdaptationText('luteal', undefined, undefined);
    expect(result).toBe('Adapting for: Luteal phase');
  });

  it('returns all three items when all present', () => {
    const injury = makeInjury({ location: 'Right knee' });
    const readiness = makeReadiness(0.7);
    const result = buildAdaptationText('follicular', [injury], readiness);
    expect(result).toBe('Adapting for: Follicular phase · Right knee · Readiness 7/10');
  });

  it('returns injury only', () => {
    const injury = makeInjury({ location: 'Lower back' });
    const result = buildAdaptationText(undefined, [injury], undefined);
    expect(result).toBe('Adapting for: Lower back');
  });

  it('returns readiness only', () => {
    const readiness = makeReadiness(0.5);
    const result = buildAdaptationText(undefined, undefined, readiness);
    expect(result).toBe('Adapting for: Readiness 5/10');
  });

  it('returns multiple injuries', () => {
    const injuries = [
      makeInjury({ id: 'inj-1', location: 'Right knee' }),
      makeInjury({ id: 'inj-2', bodyLocation: 'leftShoulder', location: 'Left shoulder' }),
    ];
    const result = buildAdaptationText(undefined, injuries, undefined);
    expect(result).toBe('Adapting for: Right knee · Left shoulder');
  });

  it('excludes resolved injuries', () => {
    const injuries = [
      makeInjury({ id: 'inj-1', location: 'Right knee', recoveryPhase: 'resolved' }),
      makeInjury({ id: 'inj-2', location: 'Left shoulder', recoveryPhase: 'lightLoad' }),
    ];
    const result = buildAdaptationText(undefined, injuries, undefined);
    expect(result).toBe('Adapting for: Left shoulder');
  });

  it('returns null when only resolved injuries', () => {
    const injuries = [makeInjury({ recoveryPhase: 'resolved' })];
    const result = buildAdaptationText(undefined, injuries, undefined);
    expect(result).toBeNull();
  });

  it('uses bodyLocation display name when location is missing', () => {
    const injury = makeInjury({ location: undefined });
    const result = buildAdaptationText(undefined, [injury], undefined);
    // bodyLocation 'rightKnee' → 'Right Knee'
    expect(result).toBe('Adapting for: Right Knee');
  });

  it('correctly labels all cycle phases', () => {
    expect(buildAdaptationText('menstrual', undefined, undefined)).toBe('Adapting for: Menstrual phase');
    expect(buildAdaptationText('follicular', undefined, undefined)).toBe('Adapting for: Follicular phase');
    expect(buildAdaptationText('ovulation', undefined, undefined)).toBe('Adapting for: Ovulation phase');
    expect(buildAdaptationText('luteal', undefined, undefined)).toBe('Adapting for: Luteal phase');
  });

  it('rounds readiness score to nearest integer out of 10', () => {
    const readiness = makeReadiness(0.65);
    const result = buildAdaptationText(undefined, undefined, readiness);
    expect(result).toBe('Adapting for: Readiness 7/10');
  });
});

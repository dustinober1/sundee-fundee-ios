/**
 * useOnboardingFlow tests — RED phase
 *
 * Tests for ONBOARDING_STEPS, getNextStep, getTotalSteps, getPreviousStep, getStepIndex
 */

import {
  ONBOARDING_STEPS,
  getNextStep,
  getTotalSteps,
  getPreviousStep,
  getStepIndex,
} from '../useOnboardingFlow';
import type { OnboardingDraft } from '../OnboardingContext';

const baseDraft: OnboardingDraft = {
  name: '',
  experienceLevel: null,
  primaryGoal: null,
  gender: null,
  cycleOptIn: false,
};

describe('ONBOARDING_STEPS', () => {
  it('contains the 5 expected steps in order', () => {
    expect(ONBOARDING_STEPS).toEqual([
      'step-name',
      'step-experience',
      'step-goal',
      'step-gender',
      'step-cycle',
    ]);
  });
});

describe('getStepIndex', () => {
  it('returns 0 for step-name', () => {
    expect(getStepIndex('step-name')).toBe(0);
  });

  it('returns 4 for step-cycle', () => {
    expect(getStepIndex('step-cycle')).toBe(4);
  });

  it('returns -1 for unknown step', () => {
    expect(getStepIndex('unknown')).toBe(-1);
  });
});

describe('getNextStep', () => {
  it('returns step-experience after step-name', () => {
    expect(getNextStep('step-name', baseDraft)).toBe('step-experience');
  });

  it('returns step-goal after step-experience', () => {
    expect(getNextStep('step-experience', baseDraft)).toBe('step-goal');
  });

  it('returns step-gender after step-goal', () => {
    expect(getNextStep('step-goal', baseDraft)).toBe('step-gender');
  });

  it('returns step-cycle after step-gender when gender is female', () => {
    const draft = { ...baseDraft, gender: 'female' as const };
    expect(getNextStep('step-gender', draft)).toBe('step-cycle');
  });

  it('returns step-cycle after step-gender when gender is other', () => {
    const draft = { ...baseDraft, gender: 'other' as const };
    expect(getNextStep('step-gender', draft)).toBe('step-cycle');
  });

  it('returns null after step-gender when gender is male (skips cycle step)', () => {
    const draft = { ...baseDraft, gender: 'male' as const };
    expect(getNextStep('step-gender', draft)).toBeNull();
  });

  it('returns null after step-cycle (final step)', () => {
    expect(getNextStep('step-cycle', baseDraft)).toBeNull();
  });

  it('returns null for unknown step', () => {
    expect(getNextStep('unknown', baseDraft)).toBeNull();
  });
});

describe('getTotalSteps', () => {
  it('returns 4 for male gender', () => {
    expect(getTotalSteps('male')).toBe(4);
  });

  it('returns 5 for female gender', () => {
    expect(getTotalSteps('female')).toBe(5);
  });

  it('returns 5 for other gender', () => {
    expect(getTotalSteps('other')).toBe(5);
  });

  it('returns 5 when gender is null (default, non-male)', () => {
    expect(getTotalSteps(null)).toBe(5);
  });
});

describe('getPreviousStep', () => {
  it('returns null for step-name (first step)', () => {
    expect(getPreviousStep('step-name')).toBeNull();
  });

  it('returns step-name before step-experience', () => {
    expect(getPreviousStep('step-experience')).toBe('step-name');
  });

  it('returns step-experience before step-goal', () => {
    expect(getPreviousStep('step-goal')).toBe('step-experience');
  });

  it('returns step-goal before step-gender', () => {
    expect(getPreviousStep('step-gender')).toBe('step-goal');
  });

  it('returns step-gender before step-cycle', () => {
    expect(getPreviousStep('step-cycle')).toBe('step-gender');
  });

  it('returns null for unknown step', () => {
    expect(getPreviousStep('unknown')).toBeNull();
  });
});

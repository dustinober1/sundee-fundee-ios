/**
 * useOnboardingFlow — Step navigation logic for the onboarding wizard.
 *
 * Exports:
 *   - ONBOARDING_STEPS: ordered array of all step route names
 *   - getStepIndex: index of a step name in ONBOARDING_STEPS (-1 if unknown)
 *   - getNextStep: returns next step route name, or null if flow is complete
 *   - getTotalSteps: returns 4 for male users, 5 for all others
 *   - getPreviousStep: returns previous step route name, or null for first step
 *
 * Key rule: male users skip step-cycle entirely (cycle tracking is opt-in
 * for users with menstrual cycles). When gender is 'male', getNextStep
 * returns null from step-gender (signals completeOnboarding should be called).
 */
import type { OnboardingDraft } from './OnboardingContext';
import type { Gender } from '@/src/domain/types';

// ─── Step Definitions ─────────────────────────────────────────────────────────

export const ONBOARDING_STEPS = [
  'step-name',
  'step-experience',
  'step-goal',
  'step-gender',
  'step-cycle',
] as const;

export type OnboardingStepName = (typeof ONBOARDING_STEPS)[number];

// ─── Navigation Helpers ───────────────────────────────────────────────────────

/**
 * Returns the index of a step in ONBOARDING_STEPS.
 * Returns -1 if the step name is not found.
 */
export function getStepIndex(stepName: string): number {
  return (ONBOARDING_STEPS as readonly string[]).indexOf(stepName);
}

/**
 * Returns the next step route name given the current step and current draft.
 *
 * Special cases:
 *   - 'step-gender' + draft.gender === 'male' → null (skip cycle, signal completion)
 *   - 'step-cycle' → null (final step for female/other users)
 *   - unknown step → null
 */
export function getNextStep(currentStep: string, draft: OnboardingDraft): string | null {
  // Male users skip the cycle step — signal completion directly from gender step
  if (currentStep === 'step-gender' && draft.gender === 'male') {
    return null;
  }

  // step-cycle is always the final step for non-male users
  if (currentStep === 'step-cycle') {
    return null;
  }

  const index = getStepIndex(currentStep);
  if (index === -1) {
    return null;
  }

  const nextIndex = index + 1;
  if (nextIndex >= ONBOARDING_STEPS.length) {
    return null;
  }

  return ONBOARDING_STEPS[nextIndex];
}

/**
 * Returns the total number of steps shown to the user.
 * Male users see 4 steps (cycle step is skipped).
 * All other users see 5 steps.
 */
export function getTotalSteps(gender: Gender | null): number {
  return gender === 'male' ? 4 : 5;
}

/**
 * Returns the previous step route name given the current step.
 * Returns null for step-name (first step — no back button).
 * Returns null for unknown steps.
 */
export function getPreviousStep(currentStep: string): string | null {
  const index = getStepIndex(currentStep);
  if (index <= 0) {
    return null;
  }
  return ONBOARDING_STEPS[index - 1];
}

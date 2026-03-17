/**
 * OnboardingContext — In-memory accumulator for onboarding wizard state.
 *
 * Provides:
 *   - OnboardingDraft: the data being collected across steps
 *   - OnboardingContext: React context with draft + setters + completeOnboarding
 *   - OnboardingProvider: wraps onboarding screens, should be mounted by (onboarding) layout
 *   - useOnboarding: hook to access context from any step screen
 *
 * Design rules (from locked decisions):
 *   - NO partial saves during the flow — all data written atomically on final step
 *   - Guests go through the same flow as authenticated users
 *   - After completion, hasCompletedOnboarding is set to true in the persisted profile
 */
import React, { createContext, useContext, useState, useCallback } from 'react';
import type { ExperienceLevel, PrimaryGoal } from '@/src/repositories/OnboardingProfileRepo';
import { getOnboardingProfileRepo } from '@/src/repositories/OnboardingProfileRepo';
import type { Gender } from '@/src/domain/types';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface OnboardingDraft {
  name: string;
  experienceLevel: ExperienceLevel | null;
  primaryGoal: PrimaryGoal | null;
  gender: Gender | null;
  cycleOptIn: boolean;
}

export interface OnboardingContextValue {
  draft: OnboardingDraft;
  setName: (name: string) => void;
  setExperienceLevel: (level: ExperienceLevel) => void;
  setPrimaryGoal: (goal: PrimaryGoal) => void;
  setGender: (gender: Gender) => void;
  setCycleOptIn: (optIn: boolean) => void;
  /** Atomically saves all draft data via OnboardingProfileRepo. Call only on final step. */
  completeOnboarding: (uid: string, isGuest: boolean) => Promise<void>;
}

// ─── Initial State ────────────────────────────────────────────────────────────

const initialDraft: OnboardingDraft = {
  name: '',
  experienceLevel: null,
  primaryGoal: null,
  gender: null,
  cycleOptIn: false,
};

// ─── Context ──────────────────────────────────────────────────────────────────

const OnboardingContext = createContext<OnboardingContextValue | null>(null);

// ─── Provider ─────────────────────────────────────────────────────────────────

interface OnboardingProviderProps {
  children: React.ReactNode;
}

export function OnboardingProvider({ children }: OnboardingProviderProps): React.JSX.Element {
  const [draft, setDraft] = useState<OnboardingDraft>(initialDraft);

  const setName = useCallback((name: string) => {
    setDraft((prev) => ({ ...prev, name }));
  }, []);

  const setExperienceLevel = useCallback((level: ExperienceLevel) => {
    setDraft((prev) => ({ ...prev, experienceLevel: level }));
  }, []);

  const setPrimaryGoal = useCallback((goal: PrimaryGoal) => {
    setDraft((prev) => ({ ...prev, primaryGoal: goal }));
  }, []);

  const setGender = useCallback((gender: Gender) => {
    setDraft((prev) => ({ ...prev, gender }));
  }, []);

  const setCycleOptIn = useCallback((optIn: boolean) => {
    setDraft((prev) => ({ ...prev, cycleOptIn: optIn }));
  }, []);

  /**
   * Atomically saves all draft data on final step completion.
   * No partial saves happen during the flow — only this one call persists data.
   */
  const completeOnboarding = useCallback(
    async (uid: string, isGuest: boolean): Promise<void> => {
      const repo = getOnboardingProfileRepo(isGuest);
      await repo.saveProfile(uid, {
        name: draft.name,
        experienceLevel: draft.experienceLevel ?? undefined,
        primaryGoal: draft.primaryGoal ?? undefined,
        gender: draft.gender ?? undefined,
        cycleOptIn: draft.cycleOptIn,
        hasCompletedOnboarding: true,
      });
    },
    [draft]
  );

  const value: OnboardingContextValue = {
    draft,
    setName,
    setExperienceLevel,
    setPrimaryGoal,
    setGender,
    setCycleOptIn,
    completeOnboarding,
  };

  return (
    <OnboardingContext.Provider value={value}>
      {children}
    </OnboardingContext.Provider>
  );
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

/**
 * Returns the onboarding context from the nearest OnboardingProvider.
 * Throws if called outside an OnboardingProvider.
 */
export function useOnboarding(): OnboardingContextValue {
  const ctx = useContext(OnboardingContext);
  if (!ctx) {
    throw new Error(
      'useOnboarding must be used within an OnboardingProvider. ' +
        'Ensure your component is wrapped in <OnboardingProvider>.'
    );
  }
  return ctx;
}

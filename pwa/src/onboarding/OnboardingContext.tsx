/**
 * OnboardingContext — In-memory accumulator for onboarding wizard state.
 * Adapted from the original — identical API, no platform dependencies.
 */
import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import type { ExperienceLevel, PrimaryGoal } from '../repositories/OnboardingProfileRepo';
import { getOnboardingProfileRepo } from '../repositories/OnboardingProfileRepo';
import type { Gender } from '../domain/types';

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
  completeOnboarding: (uid: string, isGuest: boolean) => Promise<void>;
}

const initialDraft: OnboardingDraft = {
  name: '',
  experienceLevel: null,
  primaryGoal: null,
  gender: null,
  cycleOptIn: false,
};

const OnboardingCtx = createContext<OnboardingContextValue | null>(null);

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [draft, setDraft] = useState<OnboardingDraft>(initialDraft);

  const setName = useCallback((name: string) => setDraft((p) => ({ ...p, name })), []);
  const setExperienceLevel = useCallback((experienceLevel: ExperienceLevel) => setDraft((p) => ({ ...p, experienceLevel })), []);
  const setPrimaryGoal = useCallback((primaryGoal: PrimaryGoal) => setDraft((p) => ({ ...p, primaryGoal })), []);
  const setGender = useCallback((gender: Gender) => setDraft((p) => ({ ...p, gender })), []);
  const setCycleOptIn = useCallback((cycleOptIn: boolean) => setDraft((p) => ({ ...p, cycleOptIn })), []);

  const completeOnboarding = useCallback(
    async (uid: string, isGuest: boolean) => {
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
    [draft],
  );

  return (
    <OnboardingCtx.Provider
      value={{ draft, setName, setExperienceLevel, setPrimaryGoal, setGender, setCycleOptIn, completeOnboarding }}
    >
      {children}
    </OnboardingCtx.Provider>
  );
}

export function useOnboarding(): OnboardingContextValue {
  const ctx = useContext(OnboardingCtx);
  if (!ctx) throw new Error('useOnboarding must be used within an OnboardingProvider.');
  return ctx;
}

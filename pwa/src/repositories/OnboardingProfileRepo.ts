import type { ExperienceLevel, PrimaryGoal } from './UserRepository';
import type { Gender } from '../domain/types';
import { FirestoreOnboardingProfileRepo } from './FirestoreOnboardingProfileRepo';
import { LocalOnboardingProfileRepo } from './LocalOnboardingProfileRepo';

export type { ExperienceLevel, PrimaryGoal };

export interface OnboardingProfile {
  name?: string;
  experienceLevel?: ExperienceLevel;
  primaryGoal?: PrimaryGoal;
  gender?: Gender;
  cycleOptIn?: boolean;
  hasCompletedOnboarding?: boolean;
}

export interface OnboardingProfileRepository {
  saveProfile(uid: string, profile: OnboardingProfile): Promise<void>;
  getProfile(uid: string): Promise<OnboardingProfile | null>;
}

export function getOnboardingProfileRepo(isGuest: boolean): OnboardingProfileRepository {
  return isGuest ? new LocalOnboardingProfileRepo() : new FirestoreOnboardingProfileRepo();
}

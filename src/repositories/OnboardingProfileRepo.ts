/**
 * OnboardingProfileRepository interface and factory function.
 *
 * Defines the contract for onboarding profile persistence.
 * Implementations:
 *   - FirestoreOnboardingProfileRepo: authenticated users (/users/{uid})
 *   - LocalOnboardingProfileRepo: guest users (@sundee/onboarding_profile key)
 */
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

/**
 * Returns the appropriate OnboardingProfileRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getOnboardingProfileRepo(isGuest: boolean): OnboardingProfileRepository {
  return isGuest
    ? new LocalOnboardingProfileRepo()
    : new FirestoreOnboardingProfileRepo();
}

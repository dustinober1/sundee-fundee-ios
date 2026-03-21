import type { OnboardingProfile, OnboardingProfileRepository } from './OnboardingProfileRepo';

const PROFILE_KEY = '@sundee/onboarding_profile';

export class LocalOnboardingProfileRepo implements OnboardingProfileRepository {
  async saveProfile(_uid: string, profile: OnboardingProfile): Promise<void> {
    localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
  }

  async getProfile(_uid: string): Promise<OnboardingProfile | null> {
    const raw = localStorage.getItem(PROFILE_KEY);
    return raw ? (JSON.parse(raw) as OnboardingProfile) : null;
  }
}

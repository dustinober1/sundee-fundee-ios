/**
 * LocalOnboardingProfileRepo — AsyncStorage implementation of OnboardingProfileRepository.
 *
 * Persists onboarding profile locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/onboarding_profile'.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { OnboardingProfile, OnboardingProfileRepository } from './OnboardingProfileRepo';

const ONBOARDING_KEY = '@sundee/onboarding_profile';

export class LocalOnboardingProfileRepo implements OnboardingProfileRepository {
  /**
   * Stores the onboarding profile to AsyncStorage as a JSON string.
   * Note: uid parameter is accepted for interface compliance but not used
   * (local storage always has at most one guest profile).
   */
  async saveProfile(_uid: string, profile: OnboardingProfile): Promise<void> {
    await AsyncStorage.setItem(ONBOARDING_KEY, JSON.stringify(profile));
  }

  /**
   * Retrieves and parses the onboarding profile from AsyncStorage.
   * Returns null if no profile is stored.
   */
  async getProfile(_uid: string): Promise<OnboardingProfile | null> {
    const raw = await AsyncStorage.getItem(ONBOARDING_KEY);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as OnboardingProfile;
  }
}

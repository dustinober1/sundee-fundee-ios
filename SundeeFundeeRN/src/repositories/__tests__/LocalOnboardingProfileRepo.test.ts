/**
 * Tests for LocalOnboardingProfileRepo — AsyncStorage implementation of OnboardingProfileRepository.
 */
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
  getAllKeys: jest.fn().mockResolvedValue([]),
  multiGet: jest.fn().mockResolvedValue([]),
  multiRemove: jest.fn().mockResolvedValue(undefined),
}));

import AsyncStorage from '@react-native-async-storage/async-storage';
import { LocalOnboardingProfileRepo } from '../LocalOnboardingProfileRepo';
import type { OnboardingProfile } from '../OnboardingProfileRepo';

const testProfile: OnboardingProfile = {
  name: 'Guest User',
  experienceLevel: 'beginner',
  primaryGoal: 'general',
  gender: 'other',
  cycleOptIn: false,
  hasCompletedOnboarding: true,
};

const ONBOARDING_KEY = '@sundee/onboarding_profile';

describe('LocalOnboardingProfileRepo', () => {
  let repo: LocalOnboardingProfileRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalOnboardingProfileRepo();
  });

  it('saveProfile stores onboarding profile to AsyncStorage under "@sundee/onboarding_profile"', async () => {
    await repo.saveProfile('guest-uid', testProfile);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      ONBOARDING_KEY,
      JSON.stringify(testProfile)
    );
  });

  it('getProfile retrieves and parses onboarding profile from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testProfile));

    const result = await repo.getProfile('guest-uid');

    expect(AsyncStorage.getItem).toHaveBeenCalledWith(ONBOARDING_KEY);
    expect(result).toEqual(testProfile);
  });

  it('getProfile returns null when no profile stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getProfile('guest-uid');

    expect(result).toBeNull();
  });
});

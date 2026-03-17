/**
 * Tests for LocalUserRepo — AsyncStorage implementation of UserRepository.
 */

jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
}));

import AsyncStorage from '@react-native-async-storage/async-storage';
import { LocalUserRepo } from '../LocalUserRepo';
import type { UserProfile } from '../UserRepository';

const testProfile: UserProfile = {
  uid: 'guest-uid',
  email: null,
  displayName: null,
  isAnonymous: true,
  createdAt: '2026-03-14T00:00:00.000Z',
  lastSignInAt: '2026-03-14T00:00:00.000Z',
  authProvider: 'anonymous',
};

const USER_PROFILE_KEY = 'user_profile';

describe('LocalUserRepo', () => {
  let repo: LocalUserRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalUserRepo();
  });

  it('createOrUpdateUser stores user profile to AsyncStorage under key "user_profile"', async () => {
    await repo.createOrUpdateUser(testProfile);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      USER_PROFILE_KEY,
      JSON.stringify(testProfile)
    );
  });

  it('getUser retrieves and parses user profile from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testProfile));

    const result = await repo.getUser('guest-uid');

    expect(AsyncStorage.getItem).toHaveBeenCalledWith(USER_PROFILE_KEY);
    expect(result).toEqual(testProfile);
  });

  it('getUser returns null when no profile stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getUser('guest-uid');

    expect(result).toBeNull();
  });

  it('deleteUser removes "user_profile" key from AsyncStorage', async () => {
    await repo.deleteUser('guest-uid');

    expect(AsyncStorage.removeItem).toHaveBeenCalledWith(USER_PROFILE_KEY);
  });
});

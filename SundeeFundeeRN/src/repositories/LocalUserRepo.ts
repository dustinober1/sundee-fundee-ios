/**
 * LocalUserRepo — AsyncStorage implementation of UserRepository.
 *
 * Persists user profile locally for guest (anonymous) users who do not have
 * a Firestore account. Data is stored under the key 'user_profile'.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { UserProfile, UserRepository } from './UserRepository';

const USER_PROFILE_KEY = 'user_profile';

export class LocalUserRepo implements UserRepository {
  /**
   * Stores the user profile to AsyncStorage as a JSON string.
   */
  async createOrUpdateUser(profile: UserProfile): Promise<void> {
    await AsyncStorage.setItem(USER_PROFILE_KEY, JSON.stringify(profile));
  }

  /**
   * Retrieves and parses the user profile from AsyncStorage.
   * Returns null if no profile is stored.
   * Note: uid parameter is accepted for interface compliance but not used
   * (local storage always has at most one guest profile).
   */
  async getUser(_uid: string): Promise<UserProfile | null> {
    const raw = await AsyncStorage.getItem(USER_PROFILE_KEY);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as UserProfile;
  }

  /**
   * Removes the user profile from AsyncStorage.
   */
  async deleteUser(_uid: string): Promise<void> {
    await AsyncStorage.removeItem(USER_PROFILE_KEY);
  }
}

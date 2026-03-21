import type { UserProfile, UserRepository } from './UserRepository';

const USER_PROFILE_KEY = 'user_profile';

export class LocalUserRepo implements UserRepository {
  async createOrUpdateUser(profile: UserProfile): Promise<void> {
    localStorage.setItem(USER_PROFILE_KEY, JSON.stringify(profile));
  }

  async getUser(_uid: string): Promise<UserProfile | null> {
    const raw = localStorage.getItem(USER_PROFILE_KEY);
    return raw ? (JSON.parse(raw) as UserProfile) : null;
  }

  async deleteUser(_uid: string): Promise<void> {
    localStorage.removeItem(USER_PROFILE_KEY);
  }
}

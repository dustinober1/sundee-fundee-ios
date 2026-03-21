/**
 * UserRepository interface and UserProfile type.
 * Identical to the original — no platform-specific code.
 */
import type { Gender } from '../domain/types';

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type PrimaryGoal = 'strength' | 'muscle' | 'endurance' | 'weightLoss' | 'general';

export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  isAnonymous: boolean;
  createdAt: string;
  lastSignInAt: string;
  authProvider: 'apple' | 'google' | 'email' | 'anonymous';
  name?: string;
  experienceLevel?: ExperienceLevel;
  primaryGoal?: PrimaryGoal;
  gender?: Gender;
  cycleOptIn?: boolean;
  hasCompletedOnboarding?: boolean;
}

export interface UserRepository {
  createOrUpdateUser(profile: UserProfile): Promise<void>;
  getUser(uid: string): Promise<UserProfile | null>;
  deleteUser(uid: string): Promise<void>;
}

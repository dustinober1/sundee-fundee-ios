/**
 * UserRepository interface and UserProfile type.
 *
 * Defines the contract for user data persistence.
 * Implementations:
 *   - FirestoreUserRepo: authenticated users (syncs to Firestore /users/{uid})
 *   - LocalUserRepo: guest users (persists to AsyncStorage)
 */
import type { Gender } from '../domain/types';

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type PrimaryGoal = 'strength' | 'muscle' | 'endurance' | 'weightLoss' | 'general';

export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  isAnonymous: boolean;
  /** ISO 8601 timestamp of account creation */
  createdAt: string;
  /** ISO 8601 timestamp of last sign-in */
  lastSignInAt: string;
  authProvider: 'apple' | 'google' | 'email' | 'anonymous';
  /** Onboarding fields — optional so existing code is not broken */
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

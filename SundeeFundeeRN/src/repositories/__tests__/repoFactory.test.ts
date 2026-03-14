/**
 * Tests for repository factory functions.
 * Verifies that isGuest=true returns Local implementations and isGuest=false returns Firestore.
 */
import { getOnboardingProfileRepo } from '../OnboardingProfileRepo';
import { getWorkoutRepo } from '../WorkoutRepo';
import { getSettingsRepo } from '../SettingsRepo';
import { getReadinessRepo } from '../ReadinessRepo';
import { FirestoreOnboardingProfileRepo } from '../FirestoreOnboardingProfileRepo';
import { LocalOnboardingProfileRepo } from '../LocalOnboardingProfileRepo';
import { FirestoreWorkoutRepo } from '../FirestoreWorkoutRepo';
import { LocalWorkoutRepo } from '../LocalWorkoutRepo';
import { FirestoreSettingsRepo } from '../FirestoreSettingsRepo';
import { LocalSettingsRepo } from '../LocalSettingsRepo';
import { FirestoreReadinessRepo } from '../FirestoreReadinessRepo';
import { LocalReadinessRepo } from '../LocalReadinessRepo';

describe('Repository Factory Functions', () => {
  describe('getOnboardingProfileRepo', () => {
    it('returns LocalOnboardingProfileRepo when isGuest is true', () => {
      const repo = getOnboardingProfileRepo(true);
      expect(repo).toBeInstanceOf(LocalOnboardingProfileRepo);
    });

    it('returns FirestoreOnboardingProfileRepo when isGuest is false', () => {
      const repo = getOnboardingProfileRepo(false);
      expect(repo).toBeInstanceOf(FirestoreOnboardingProfileRepo);
    });
  });

  describe('getWorkoutRepo', () => {
    it('returns LocalWorkoutRepo when isGuest is true', () => {
      const repo = getWorkoutRepo(true);
      expect(repo).toBeInstanceOf(LocalWorkoutRepo);
    });

    it('returns FirestoreWorkoutRepo when isGuest is false', () => {
      const repo = getWorkoutRepo(false);
      expect(repo).toBeInstanceOf(FirestoreWorkoutRepo);
    });
  });

  describe('getSettingsRepo', () => {
    it('returns LocalSettingsRepo when isGuest is true', () => {
      const repo = getSettingsRepo(true);
      expect(repo).toBeInstanceOf(LocalSettingsRepo);
    });

    it('returns FirestoreSettingsRepo when isGuest is false', () => {
      const repo = getSettingsRepo(false);
      expect(repo).toBeInstanceOf(FirestoreSettingsRepo);
    });
  });

  describe('getReadinessRepo', () => {
    it('returns LocalReadinessRepo when isGuest is true', () => {
      const repo = getReadinessRepo(true);
      expect(repo).toBeInstanceOf(LocalReadinessRepo);
    });

    it('returns FirestoreReadinessRepo when isGuest is false', () => {
      const repo = getReadinessRepo(false);
      expect(repo).toBeInstanceOf(FirestoreReadinessRepo);
    });
  });
});

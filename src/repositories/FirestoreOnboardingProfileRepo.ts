/**
 * FirestoreOnboardingProfileRepo — Firestore implementation of OnboardingProfileRepository.
 *
 * Writes onboarding profile fields to /users/{uid} in Firestore with merge semantics.
 * Used for authenticated users so profile syncs across devices.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { OnboardingProfile, OnboardingProfileRepository } from './OnboardingProfileRepo';

export class FirestoreOnboardingProfileRepo implements OnboardingProfileRepository {
  /**
   * Saves onboarding profile fields to /users/{uid}.
   * Uses { merge: true } to avoid overwriting other fields (e.g., auth fields set by FirestoreUserRepo).
   */
  async saveProfile(uid: string, profile: OnboardingProfile): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .set(profile, { merge: true });
  }

  /**
   * Retrieves the onboarding profile fields from /users/{uid}.
   * Returns null if the document does not exist.
   */
  async getProfile(uid: string): Promise<OnboardingProfile | null> {
    const db = getFirestoreInstance();
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as OnboardingProfile;
  }
}

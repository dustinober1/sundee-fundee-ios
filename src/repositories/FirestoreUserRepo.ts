/**
 * FirestoreUserRepo — Firestore implementation of UserRepository.
 *
 * Writes user documents to /users/{uid} in Firestore with merge semantics.
 * Used for authenticated users (Apple, Google, Email) to satisfy AUTH-07:
 * "Authenticated user data syncs to Firestore and is visible on a second device after sign-in."
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { UserProfile, UserRepository } from './UserRepository';

export class FirestoreUserRepo implements UserRepository {
  /**
   * Creates or updates a user document at /users/{uid}.
   * Uses { merge: true } to avoid overwriting fields set by other clients.
   */
  async createOrUpdateUser(profile: UserProfile): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(profile.uid)
      .set(profile, { merge: true });
  }

  /**
   * Retrieves a user profile from /users/{uid}.
   * Returns null if the document does not exist.
   */
  async getUser(uid: string): Promise<UserProfile | null> {
    const db = getFirestoreInstance();
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as UserProfile;
  }

  /**
   * Deletes a user document from /users/{uid}.
   */
  async deleteUser(uid: string): Promise<void> {
    const db = getFirestoreInstance();
    await db.collection('users').doc(uid).delete();
  }
}

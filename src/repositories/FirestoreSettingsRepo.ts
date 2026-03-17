/**
 * FirestoreSettingsRepo — Firestore implementation of SettingsRepository.
 *
 * Merges settings fields into /users/{uid} (same document as profile).
 * This avoids an extra Firestore read on startup since settings and profile
 * are loaded together.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { AppSettings, SettingsRepository } from './SettingsRepo';

export class FirestoreSettingsRepo implements SettingsRepository {
  /**
   * Merges app settings into /users/{uid}.
   * Uses { merge: true } to avoid overwriting profile or auth fields.
   */
  async saveSettings(uid: string, settings: AppSettings): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .set(settings, { merge: true });
  }

  /**
   * Retrieves settings from /users/{uid}.
   * Returns null if the document does not exist.
   */
  async getSettings(uid: string): Promise<AppSettings | null> {
    const db = getFirestoreInstance();
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as AppSettings;
  }
}

import { doc, setDoc, getDoc } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { AppSettings, SettingsRepository } from './SettingsRepo';

export class FirestoreSettingsRepo implements SettingsRepository {
  async saveSettings(uid: string, settings: AppSettings): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid), settings, { merge: true });
  }

  async getSettings(uid: string): Promise<AppSettings | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid));
    return snap.exists() ? (snap.data() as AppSettings) : null;
  }
}

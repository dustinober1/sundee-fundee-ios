import { doc, setDoc, getDoc, deleteDoc } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { UserProfile, UserRepository } from './UserRepository';

export class FirestoreUserRepo implements UserRepository {
  async createOrUpdateUser(profile: UserProfile): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', profile.uid), profile, { merge: true });
  }

  async getUser(uid: string): Promise<UserProfile | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid));
    return snap.exists() ? (snap.data() as UserProfile) : null;
  }

  async deleteUser(uid: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid));
  }
}

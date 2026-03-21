import { doc, setDoc, getDoc } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { OnboardingProfile, OnboardingProfileRepository } from './OnboardingProfileRepo';

export class FirestoreOnboardingProfileRepo implements OnboardingProfileRepository {
  async saveProfile(uid: string, profile: OnboardingProfile): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid), profile, { merge: true });
  }

  async getProfile(uid: string): Promise<OnboardingProfile | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid));
    return snap.exists() ? (snap.data() as OnboardingProfile) : null;
  }
}

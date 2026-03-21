import { doc, setDoc, getDoc, getDocs, deleteDoc, collection, query, orderBy, limit as firestoreLimit } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { WorkoutRecord, WorkoutRepository } from './WorkoutRepo';

export class FirestoreWorkoutRepo implements WorkoutRepository {
  async saveWorkout(uid: string, record: WorkoutRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'workouts', record.id), record);
  }

  async getWorkout(uid: string, id: string): Promise<WorkoutRecord | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid, 'workouts', id));
    return snap.exists() ? (snap.data() as WorkoutRecord) : null;
  }

  async getHistory(uid: string, limit = 50): Promise<WorkoutRecord[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'workouts'),
      orderBy('completedAt', 'desc'),
      firestoreLimit(limit),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as WorkoutRecord);
  }

  async deleteWorkout(uid: string, id: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'workouts', id));
  }
}

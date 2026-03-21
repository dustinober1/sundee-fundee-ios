import { doc, setDoc, getDocs, collection, query, where, writeBatch } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { ExerciseMaxRepository } from './ExerciseMaxRepo';

export class FirestoreExerciseMaxRepo implements ExerciseMaxRepository {
  async getMaxes(uid: string, exerciseId: string): Promise<ExerciseMax[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'exerciseMaxes'),
      where('exerciseId', '==', exerciseId),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as ExerciseMax);
  }

  async getAllMaxes(uid: string): Promise<ExerciseMax[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'exerciseMaxes'));
    return snapshot.docs.map((d) => d.data() as ExerciseMax);
  }

  async saveMax(uid: string, max: ExerciseMax): Promise<void> {
    const compositeId = `${max.exerciseId}_${max.repRange}`;
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'exerciseMaxes', compositeId), max);
  }

  async deleteMaxesForExercise(uid: string, exerciseId: string): Promise<void> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'exerciseMaxes'),
      where('exerciseId', '==', exerciseId),
    );
    const snapshot = await getDocs(q);
    if (snapshot.empty) return;
    const batch = writeBatch(db);
    snapshot.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  async getMax1RMHistory(uid: string, exerciseId: string): Promise<{ date: string; estimated1RM: number }[]> {
    const maxes = await this.getMaxes(uid, exerciseId);
    return maxes
      .sort((a, b) => a.achievedAt.localeCompare(b.achievedAt))
      .map((m) => ({ date: m.achievedAt, estimated1RM: m.estimated1RM }));
  }
}

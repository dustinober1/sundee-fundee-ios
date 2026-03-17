/**
 * FirestoreExerciseMaxRepo — Firestore implementation of ExerciseMaxRepository.
 *
 * Writes exercise PR maxes to /users/{uid}/exerciseMaxes/{compositeId} subcollection,
 * where compositeId = `${exerciseId}_${repRange}`.
 * Used for authenticated users to sync PR maxes across devices.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { ExerciseMaxRepository } from './ExerciseMaxRepo';

export class FirestoreExerciseMaxRepo implements ExerciseMaxRepository {
  /**
   * Returns all maxes for the specified exercise from Firestore.
   * Queries by exerciseId field across the exerciseMaxes subcollection.
   */
  async getMaxes(uid: string, exerciseId: string): Promise<ExerciseMax[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('exerciseMaxes')
      .where('exerciseId', '==', exerciseId)
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => ExerciseMax }) => doc.data() as ExerciseMax
    );
  }

  /**
   * Returns all maxes across all exercises from Firestore.
   */
  async getAllMaxes(uid: string): Promise<ExerciseMax[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('exerciseMaxes')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => ExerciseMax }) => doc.data() as ExerciseMax
    );
  }

  /**
   * Upserts a max record to /users/{uid}/exerciseMaxes/{compositeId}.
   * The compositeId ensures one document per exerciseId + repRange combination.
   * Note: Firestore implementation always writes (caller is responsible for
   * checking if the new weight is an improvement before calling saveMax).
   */
  async saveMax(uid: string, max: ExerciseMax): Promise<void> {
    const compositeId = `${max.exerciseId}_${max.repRange}`;
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('exerciseMaxes')
      .doc(compositeId)
      .set(max);
  }

  /**
   * Deletes all maxes for the specified exercise from Firestore.
   * Queries all docs matching exerciseId and deletes via batch.
   */
  async deleteMaxesForExercise(uid: string, exerciseId: string): Promise<void> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('exerciseMaxes')
      .where('exerciseId', '==', exerciseId)
      .get();
    if (snapshot.empty) {
      return;
    }
    const batch = db.batch();
    snapshot.docs.forEach((doc: { ref: unknown }) => {
      batch.delete(doc.ref as Parameters<typeof batch.delete>[0]);
    });
    await batch.commit();
  }

  /**
   * Returns time-ordered estimated1RM values for an exercise.
   * Sorted ascending by achievedAt for charting progress over time.
   */
  async getMax1RMHistory(
    uid: string,
    exerciseId: string
  ): Promise<{ date: string; estimated1RM: number }[]> {
    const maxes = await this.getMaxes(uid, exerciseId);
    return maxes
      .sort((a, b) => a.achievedAt.localeCompare(b.achievedAt))
      .map((m) => ({ date: m.achievedAt, estimated1RM: m.estimated1RM }));
  }
}

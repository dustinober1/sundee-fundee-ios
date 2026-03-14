/**
 * FirestoreWorkoutRepo — Firestore implementation of WorkoutRepository.
 *
 * Writes workout records to /users/{uid}/workouts/{id} subcollection.
 * Used for authenticated users to satisfy WORK-11: workout history syncs across devices.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { WorkoutRecord, WorkoutRepository } from './WorkoutRepo';

export class FirestoreWorkoutRepo implements WorkoutRepository {
  /**
   * Saves a workout record to /users/{uid}/workouts/{id}.
   */
  async saveWorkout(uid: string, record: WorkoutRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('workouts')
      .doc(record.id)
      .set(record);
  }

  /**
   * Retrieves a single workout record by id.
   * Returns null if the document does not exist.
   */
  async getWorkout(uid: string, id: string): Promise<WorkoutRecord | null> {
    const db = getFirestoreInstance();
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('workouts')
      .doc(id)
      .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as WorkoutRecord;
  }

  /**
   * Retrieves workout history ordered by completedAt descending.
   * @param limit - Maximum number of records to return (default 50)
   */
  async getHistory(uid: string, limit = 50): Promise<WorkoutRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('workouts')
      .orderBy('completedAt', 'desc')
      .limit(limit)
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => WorkoutRecord }) => doc.data() as WorkoutRecord
    );
  }

  /**
   * Deletes a workout record from /users/{uid}/workouts/{id}.
   */
  async deleteWorkout(uid: string, id: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('workouts')
      .doc(id)
      .delete();
  }
}

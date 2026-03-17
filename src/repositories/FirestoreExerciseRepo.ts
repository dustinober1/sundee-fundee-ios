/**
 * FirestoreExerciseRepo — Firestore implementation of ExerciseRepository.
 *
 * Writes custom exercise records to /users/{uid}/customExercises/{exerciseId} subcollection.
 * Used for authenticated users to sync custom exercises across devices.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { Exercise } from '../domain/exercises/exercise-types';
import type { ExerciseRepository } from './ExerciseRepo';

export class FirestoreExerciseRepo implements ExerciseRepository {
  /**
   * Returns all custom exercises from /users/{uid}/customExercises.
   */
  async getCustomExercises(uid: string): Promise<Exercise[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('customExercises')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => Exercise }) => doc.data() as Exercise
    );
  }

  /**
   * Saves a custom exercise to /users/{uid}/customExercises/{exerciseId}.
   * Overwrites any existing document with the same id.
   */
  async saveCustomExercise(uid: string, exercise: Exercise): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('customExercises')
      .doc(exercise.id)
      .set(exercise);
  }

  /**
   * Deletes a custom exercise from /users/{uid}/customExercises/{exerciseId}.
   */
  async deleteCustomExercise(uid: string, exerciseId: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('customExercises')
      .doc(exerciseId)
      .delete();
  }
}

/**
 * ExerciseRepository interface and factory function.
 *
 * Defines the contract for custom exercise persistence.
 * Implementations:
 *   - FirestoreExerciseRepo: authenticated users (/users/{uid}/customExercises/{exerciseId})
 *   - LocalExerciseRepo: guest users (@sundee/custom-exercises key)
 */
import type { Exercise } from '../domain/exercises/exercise-types';
import { FirestoreExerciseRepo } from './FirestoreExerciseRepo';
import { LocalExerciseRepo } from './LocalExerciseRepo';

export interface ExerciseRepository {
  getCustomExercises(uid: string): Promise<Exercise[]>;
  saveCustomExercise(uid: string, exercise: Exercise): Promise<void>;
  deleteCustomExercise(uid: string, exerciseId: string): Promise<void>;
}

/**
 * Returns the appropriate ExerciseRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getExerciseRepo(isGuest: boolean): ExerciseRepository {
  return isGuest
    ? new LocalExerciseRepo()
    : new FirestoreExerciseRepo();
}

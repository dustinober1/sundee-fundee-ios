/**
 * ExerciseMaxRepository interface and factory function.
 *
 * Defines the contract for exercise PR max persistence.
 * Implementations:
 *   - FirestoreExerciseMaxRepo: authenticated users (/users/{uid}/exerciseMaxes/{compositeId})
 *   - LocalExerciseMaxRepo: guest users (@sundee/exercise-maxes key)
 */
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import { FirestoreExerciseMaxRepo } from './FirestoreExerciseMaxRepo';
import { LocalExerciseMaxRepo } from './LocalExerciseMaxRepo';

export interface ExerciseMaxRepository {
  getMaxes(uid: string, exerciseId: string): Promise<ExerciseMax[]>;
  getAllMaxes(uid: string): Promise<ExerciseMax[]>;
  saveMax(uid: string, max: ExerciseMax): Promise<void>;
  deleteMaxesForExercise(uid: string, exerciseId: string): Promise<void>;
  getMax1RMHistory(uid: string, exerciseId: string): Promise<{ date: string; estimated1RM: number }[]>;
}

/**
 * Returns the appropriate ExerciseMaxRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getExerciseMaxRepo(isGuest: boolean): ExerciseMaxRepository {
  return isGuest
    ? new LocalExerciseMaxRepo()
    : new FirestoreExerciseMaxRepo();
}

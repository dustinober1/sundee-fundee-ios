import type { Exercise } from '../domain/exercises/exercise-types';
import { FirestoreExerciseRepo } from './FirestoreExerciseRepo';
import { LocalExerciseRepo } from './LocalExerciseRepo';

export interface ExerciseRepository {
  getCustomExercises(uid: string): Promise<Exercise[]>;
  saveCustomExercise(uid: string, exercise: Exercise): Promise<void>;
  deleteCustomExercise(uid: string, exerciseId: string): Promise<void>;
}

export function getExerciseRepo(isGuest: boolean): ExerciseRepository {
  return isGuest ? new LocalExerciseRepo() : new FirestoreExerciseRepo();
}

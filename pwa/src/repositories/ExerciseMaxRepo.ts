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

export function getExerciseMaxRepo(isGuest: boolean): ExerciseMaxRepository {
  return isGuest ? new LocalExerciseMaxRepo() : new FirestoreExerciseMaxRepo();
}

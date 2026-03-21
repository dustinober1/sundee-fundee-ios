import type { GeneratedWorkout } from '../domain/ai-workout/generated-workout';
import { FirestoreWorkoutRepo } from './FirestoreWorkoutRepo';
import { LocalWorkoutRepo } from './LocalWorkoutRepo';

export interface CompletedSet {
  weight: number;
  reps: number;
  isPersonalRecord: boolean;
}

export interface CompletedExercise {
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  sets: CompletedSet[];
}

export interface WorkoutRecord {
  id: string;
  uid: string;
  completedAt: string;
  durationSeconds: number;
  source: 'ai' | 'program' | 'custom';
  workout?: GeneratedWorkout;
  exercises?: CompletedExercise[];
  workoutName?: string;
  timerMode?: 'forTime' | 'amrap' | 'emom' | 'none';
  totalVolume?: number;
  exerciseCount?: number;
}

export interface WorkoutRepository {
  saveWorkout(uid: string, record: WorkoutRecord): Promise<void>;
  getWorkout(uid: string, id: string): Promise<WorkoutRecord | null>;
  getHistory(uid: string, limit?: number): Promise<WorkoutRecord[]>;
  deleteWorkout(uid: string, id: string): Promise<void>;
}

export function getWorkoutRepo(isGuest: boolean): WorkoutRepository {
  return isGuest ? new LocalWorkoutRepo() : new FirestoreWorkoutRepo();
}

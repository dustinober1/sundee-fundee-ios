/**
 * WorkoutRepository interface and factory function.
 *
 * Defines the contract for workout record persistence.
 * Implementations:
 *   - FirestoreWorkoutRepo: authenticated users (subcollection /users/{uid}/workouts)
 *   - LocalWorkoutRepo: guest users (@sundee/workouts key)
 */
import type { GeneratedWorkout } from '../domain/ai-workout/generated-workout';
import { FirestoreWorkoutRepo } from './FirestoreWorkoutRepo';
import { LocalWorkoutRepo } from './LocalWorkoutRepo';

/** A single completed set within a custom or program workout exercise. */
export interface CompletedSet {
  weight: number;
  reps: number;
  isPersonalRecord: boolean;
}

/** A completed exercise with all sets, as recorded during a custom or program workout. */
export interface CompletedExercise {
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  sets: CompletedSet[];
}

export interface WorkoutRecord {
  id: string;
  uid: string;
  /** ISO 8601 timestamp of workout completion */
  completedAt: string;
  durationSeconds: number;
  source: 'ai' | 'program' | 'custom';
  /** AI-generated workout data. Required for source='ai' records; undefined for custom/program. */
  workout?: GeneratedWorkout;
  /** Custom or program workout exercises. Required for source='custom'/'program'; undefined for AI. */
  exercises?: CompletedExercise[];
  /** User-visible workout name (e.g. program name or custom workout title). */
  workoutName?: string;
  /** Timer mode used during the workout session. */
  timerMode?: 'forTime' | 'amrap' | 'emom' | 'none';
  /** Pre-computed total training volume (sum of weight × reps across all sets). */
  totalVolume?: number;
  /** Total number of unique exercises in the workout. */
  exerciseCount?: number;
}

export interface WorkoutRepository {
  saveWorkout(uid: string, record: WorkoutRecord): Promise<void>;
  getWorkout(uid: string, id: string): Promise<WorkoutRecord | null>;
  getHistory(uid: string, limit?: number): Promise<WorkoutRecord[]>;
  deleteWorkout(uid: string, id: string): Promise<void>;
}

/**
 * Returns the appropriate WorkoutRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getWorkoutRepo(isGuest: boolean): WorkoutRepository {
  return isGuest
    ? new LocalWorkoutRepo()
    : new FirestoreWorkoutRepo();
}

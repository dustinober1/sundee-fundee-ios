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

export interface WorkoutRecord {
  id: string;
  uid: string;
  /** ISO 8601 timestamp of workout completion */
  completedAt: string;
  durationSeconds: number;
  source: 'ai' | 'program' | 'custom';
  workout: GeneratedWorkout;
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

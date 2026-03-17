/**
 * LocalWorkoutRepo — AsyncStorage implementation of WorkoutRepository.
 *
 * Persists workout records locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/workouts' as a JSON array.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { WorkoutRecord, WorkoutRepository } from './WorkoutRepo';

const WORKOUTS_KEY = '@sundee/workouts';

export class LocalWorkoutRepo implements WorkoutRepository {
  /**
   * Saves a workout record to AsyncStorage.
   * If a record with the same id already exists, it is replaced.
   */
  async saveWorkout(_uid: string, record: WorkoutRecord): Promise<void> {
    const existing = await this.loadAll();
    const filtered = existing.filter((r) => r.id !== record.id);
    filtered.push(record);
    await AsyncStorage.setItem(WORKOUTS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves a single workout record by id.
   * Returns null if not found.
   */
  async getWorkout(_uid: string, id: string): Promise<WorkoutRecord | null> {
    const all = await this.loadAll();
    return all.find((r) => r.id === id) ?? null;
  }

  /**
   * Retrieves workout history sorted by completedAt descending.
   * @param limit - Maximum number of records to return (default 50)
   */
  async getHistory(_uid: string, limit = 50): Promise<WorkoutRecord[]> {
    const all = await this.loadAll();
    const sorted = all.sort((a, b) => b.completedAt.localeCompare(a.completedAt));
    return sorted.slice(0, limit);
  }

  /**
   * Deletes a workout record from AsyncStorage.
   */
  async deleteWorkout(_uid: string, id: string): Promise<void> {
    const existing = await this.loadAll();
    const filtered = existing.filter((r) => r.id !== id);
    await AsyncStorage.setItem(WORKOUTS_KEY, JSON.stringify(filtered));
  }

  private async loadAll(): Promise<WorkoutRecord[]> {
    const raw = await AsyncStorage.getItem(WORKOUTS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as WorkoutRecord[];
  }
}

/**
 * LocalExerciseRepo — AsyncStorage implementation of ExerciseRepository.
 *
 * Persists custom exercise records locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/custom-exercises' as a JSON array.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Exercise } from '../domain/exercises/exercise-types';
import type { ExerciseRepository } from './ExerciseRepo';

const EXERCISES_KEY = '@sundee/custom-exercises';

export class LocalExerciseRepo implements ExerciseRepository {
  /**
   * Returns all custom exercises from AsyncStorage.
   * Returns empty array when no exercises are stored.
   */
  async getCustomExercises(_uid: string): Promise<Exercise[]> {
    return this.loadAll();
  }

  /**
   * Saves a custom exercise to AsyncStorage.
   * If an exercise with the same id already exists, it is replaced.
   */
  async saveCustomExercise(_uid: string, exercise: Exercise): Promise<void> {
    const existing = await this.loadAll();
    const filtered = existing.filter((e) => e.id !== exercise.id);
    filtered.push(exercise);
    await AsyncStorage.setItem(EXERCISES_KEY, JSON.stringify(filtered));
  }

  /**
   * Deletes a custom exercise from AsyncStorage by id.
   * Does nothing if the exercise is not found.
   */
  async deleteCustomExercise(_uid: string, exerciseId: string): Promise<void> {
    const existing = await this.loadAll();
    const filtered = existing.filter((e) => e.id !== exerciseId);
    await AsyncStorage.setItem(EXERCISES_KEY, JSON.stringify(filtered));
  }

  private async loadAll(): Promise<Exercise[]> {
    const raw = await AsyncStorage.getItem(EXERCISES_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as Exercise[];
  }
}

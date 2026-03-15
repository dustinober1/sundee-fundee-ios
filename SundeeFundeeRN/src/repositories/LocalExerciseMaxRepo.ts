/**
 * LocalExerciseMaxRepo — AsyncStorage implementation of ExerciseMaxRepository.
 *
 * Persists exercise PR maxes locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/exercise-maxes' as a JSON array.
 *
 * Upsert logic: saveMax only replaces an existing max for the same
 * exerciseId + repRange when the new weight is strictly higher.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { ExerciseMaxRepository } from './ExerciseMaxRepo';

const MAXES_KEY = '@sundee/exercise-maxes';

export class LocalExerciseMaxRepo implements ExerciseMaxRepository {
  /**
   * Returns all maxes for the specified exercise.
   */
  async getMaxes(_uid: string, exerciseId: string): Promise<ExerciseMax[]> {
    const all = await this.loadAll();
    return all.filter((m) => m.exerciseId === exerciseId);
  }

  /**
   * Returns all maxes across all exercises.
   */
  async getAllMaxes(_uid: string): Promise<ExerciseMax[]> {
    return this.loadAll();
  }

  /**
   * Upserts a max record. Replaces an existing record for the same
   * exerciseId + repRange only when the new weight is strictly higher.
   * If no existing record, adds the new max.
   */
  async saveMax(_uid: string, max: ExerciseMax): Promise<void> {
    const all = await this.loadAll();
    const existingIndex = all.findIndex(
      (m) => m.exerciseId === max.exerciseId && m.repRange === max.repRange
    );

    if (existingIndex >= 0) {
      if (max.weight <= all[existingIndex].weight) {
        // New weight is not an improvement — skip
        return;
      }
      all[existingIndex] = max;
    } else {
      all.push(max);
    }

    await AsyncStorage.setItem(MAXES_KEY, JSON.stringify(all));
  }

  /**
   * Removes all maxes for the specified exercise.
   */
  async deleteMaxesForExercise(_uid: string, exerciseId: string): Promise<void> {
    const all = await this.loadAll();
    const filtered = all.filter((m) => m.exerciseId !== exerciseId);
    await AsyncStorage.setItem(MAXES_KEY, JSON.stringify(filtered));
  }

  /**
   * Returns time-ordered estimated1RM values for an exercise.
   * Sorted ascending by achievedAt for charting progress over time.
   */
  async getMax1RMHistory(
    _uid: string,
    exerciseId: string
  ): Promise<{ date: string; estimated1RM: number }[]> {
    const all = await this.loadAll();
    return all
      .filter((m) => m.exerciseId === exerciseId)
      .sort((a, b) => a.achievedAt.localeCompare(b.achievedAt))
      .map((m) => ({ date: m.achievedAt, estimated1RM: m.estimated1RM }));
  }

  private async loadAll(): Promise<ExerciseMax[]> {
    const raw = await AsyncStorage.getItem(MAXES_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as ExerciseMax[];
  }
}

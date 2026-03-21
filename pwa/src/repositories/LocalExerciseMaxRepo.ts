import type { ExerciseMax } from '../domain/pr-detection/pr-types';
import type { ExerciseMaxRepository } from './ExerciseMaxRepo';

const MAXES_KEY = '@sundee/exercise-maxes';

export class LocalExerciseMaxRepo implements ExerciseMaxRepository {
  async getMaxes(_uid: string, exerciseId: string): Promise<ExerciseMax[]> {
    return this.loadAll().filter((m) => m.exerciseId === exerciseId);
  }

  async getAllMaxes(_uid: string): Promise<ExerciseMax[]> {
    return this.loadAll();
  }

  async saveMax(_uid: string, max: ExerciseMax): Promise<void> {
    const compositeId = `${max.exerciseId}_${max.repRange}`;
    const all = this.loadAll().filter(
      (m) => `${m.exerciseId}_${m.repRange}` !== compositeId,
    );
    all.push(max);
    localStorage.setItem(MAXES_KEY, JSON.stringify(all));
  }

  async deleteMaxesForExercise(_uid: string, exerciseId: string): Promise<void> {
    const filtered = this.loadAll().filter((m) => m.exerciseId !== exerciseId);
    localStorage.setItem(MAXES_KEY, JSON.stringify(filtered));
  }

  async getMax1RMHistory(_uid: string, exerciseId: string): Promise<{ date: string; estimated1RM: number }[]> {
    return this.loadAll()
      .filter((m) => m.exerciseId === exerciseId)
      .sort((a, b) => a.achievedAt.localeCompare(b.achievedAt))
      .map((m) => ({ date: m.achievedAt, estimated1RM: m.estimated1RM }));
  }

  private loadAll(): ExerciseMax[] {
    const raw = localStorage.getItem(MAXES_KEY);
    return raw ? (JSON.parse(raw) as ExerciseMax[]) : [];
  }
}

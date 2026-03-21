import type { Exercise } from '../domain/exercises/exercise-types';
import type { ExerciseRepository } from './ExerciseRepo';

const EXERCISES_KEY = '@sundee/custom-exercises';

export class LocalExerciseRepo implements ExerciseRepository {
  async getCustomExercises(_uid: string): Promise<Exercise[]> {
    const raw = localStorage.getItem(EXERCISES_KEY);
    return raw ? (JSON.parse(raw) as Exercise[]) : [];
  }

  async saveCustomExercise(_uid: string, exercise: Exercise): Promise<void> {
    const all = await this.getCustomExercises('');
    const filtered = all.filter((e) => e.id !== exercise.id);
    filtered.push(exercise);
    localStorage.setItem(EXERCISES_KEY, JSON.stringify(filtered));
  }

  async deleteCustomExercise(_uid: string, exerciseId: string): Promise<void> {
    const all = await this.getCustomExercises('');
    localStorage.setItem(EXERCISES_KEY, JSON.stringify(all.filter((e) => e.id !== exerciseId)));
  }
}

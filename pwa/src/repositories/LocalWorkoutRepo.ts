import type { WorkoutRecord, WorkoutRepository } from './WorkoutRepo';

const WORKOUTS_KEY = '@sundee/workouts';

export class LocalWorkoutRepo implements WorkoutRepository {
  async saveWorkout(_uid: string, record: WorkoutRecord): Promise<void> {
    const existing = this.loadAll();
    const filtered = existing.filter((r) => r.id !== record.id);
    filtered.push(record);
    localStorage.setItem(WORKOUTS_KEY, JSON.stringify(filtered));
  }

  async getWorkout(_uid: string, id: string): Promise<WorkoutRecord | null> {
    return this.loadAll().find((r) => r.id === id) ?? null;
  }

  async getHistory(_uid: string, limit = 50): Promise<WorkoutRecord[]> {
    const all = this.loadAll();
    return all.sort((a, b) => b.completedAt.localeCompare(a.completedAt)).slice(0, limit);
  }

  async deleteWorkout(_uid: string, id: string): Promise<void> {
    const filtered = this.loadAll().filter((r) => r.id !== id);
    localStorage.setItem(WORKOUTS_KEY, JSON.stringify(filtered));
  }

  private loadAll(): WorkoutRecord[] {
    const raw = localStorage.getItem(WORKOUTS_KEY);
    return raw ? (JSON.parse(raw) as WorkoutRecord[]) : [];
  }
}

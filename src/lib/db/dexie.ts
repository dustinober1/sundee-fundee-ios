import Dexie, { Table } from 'dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet, SetMetrics } from '@/types';

export class StrengthDatabase extends Dexie {
  users!: Table<User, string>;
  oneRepMaxes!: Table<OneRepMax, string>;
  activeCycles!: Table<ActiveCycle, string>;
  completedWorkouts!: Table<CompletedWorkout, string>;
  completedSets!: Table<CompletedSet, string>;
  setMetrics!: Table<SetMetrics, string>;

  constructor() {
    super('StrengthApp');

    this.version(1).stores({
      users: 'id, name, createdAt',
      oneRepMaxes: 'id, userId, exerciseId, date',
      activeCycles: 'id, userId, programId, status',
      completedWorkouts: 'id, userId, activeCycleId, completedAt',
      completedSets: 'id, workoutId, exerciseId',
      setMetrics: 'id, setId'
    });
  }
}

export const db = new StrengthDatabase();

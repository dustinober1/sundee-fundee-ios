import Dexie, { Table } from 'dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet, SetMetrics } from '@/types';
import type { PeriodLog, SymptomLog, BBTLog, SymptomDefinition, CycleSettings } from '@/types';
import type { ProgramV2 } from '@/types/programV2';

export interface UserProgramPreference {
  id: string;
  userId: string;
  programId: string;
  viewMode: 'session-cards' | 'week-calendar' | 'compact-list';
  currentSessionId?: string;
}

export class StrengthDatabase extends Dexie {
  users!: Table<User, string>;
  oneRepMaxes!: Table<OneRepMax, string>;
  activeCycles!: Table<ActiveCycle, string>;
  completedWorkouts!: Table<CompletedWorkout, string>;
  completedSets!: Table<CompletedSet, string>;
  setMetrics!: Table<SetMetrics, string>;
  periodLogs!: Table<PeriodLog, string>;
  symptomLogs!: Table<SymptomLog, string>;
  bbtLogs!: Table<BBTLog, string>;
  symptomDefinitions!: Table<SymptomDefinition, string>;
  cycleSettings!: Table<CycleSettings, string>;
  programs!: Table<ProgramV2, string>;
  userProgramPreferences!: Table<UserProgramPreference, string>;

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

    this.version(2).stores({
      users: 'id, name, createdAt',
      oneRepMaxes: 'id, userId, exerciseId, date',
      activeCycles: 'id, userId, programId, status',
      completedWorkouts: 'id, userId, activeCycleId, completedAt',
      completedSets: 'id, workoutId, exerciseId',
      setMetrics: 'id, setId',
      periodLogs: 'id, userId, startDate',
      symptomLogs: 'id, userId, date',
      bbtLogs: 'id, userId, date',
      symptomDefinitions: 'id, category',
      cycleSettings: 'id, userId'
    });

    this.version(3).stores({
      users: 'id, name, createdAt',
      oneRepMaxes: 'id, userId, exerciseId, date',
      activeCycles: 'id, userId, programId, status, currentPhase, currentSessionId',
      completedWorkouts: 'id, userId, activeCycleId, sessionId, completedAt',
      completedSets: 'id, workoutId, exerciseId',
      setMetrics: 'id, setId',
      periodLogs: 'id, userId, startDate',
      symptomLogs: 'id, userId, date',
      bbtLogs: 'id, userId, date',
      symptomDefinitions: 'id, category',
      cycleSettings: 'id, userId',
      programs: 'id, category, difficulty',
      userProgramPreferences: 'id, userId, programId, [userId+programId]'
    });
  }
}

export const db = new StrengthDatabase();

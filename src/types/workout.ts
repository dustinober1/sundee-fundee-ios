export type WeightOverrideReason = 'injured' | 'fatigued' | 'just_because' | 'other';

export interface CompletedSet {
  id: string;
  workoutId: string;
  exerciseId: string;
  setNumber: number;
  prescribedWeight?: number;
  actualWeight: number;
  prescribedReps: number;
  actualReps: number;
  rpe?: number;
  restSeconds?: number;
  overrideReason?: WeightOverrideReason;
  createdAt: Date;
}

export type PRType = 'weight' | 'volume';

export interface PersonalRecord {
  id: string;
  userId: string;
  exerciseId: string;
  type: PRType;
  value: number;
  workoutId: string;
  date: Date;
}

export interface SetMetrics {
  id: string;
  setId: string;
  tempoEccentric?: number;
  tempoConcentric?: number;
  tempoPause?: number;
  heartRate?: number;
  notes?: string;
}

export interface CompletedWorkout {
  id: string;
  userId: string;
  activeCycleId: string;
  programId: string;
  week: number;
  day?: number;
  sessionId?: string;
  completedAt: Date;
  duration?: number;
  notes?: string;
}

export interface OneRepMax {
  id: string;
  userId: string;
  exerciseId: string;
  weight: number;
  date: Date;
}

export interface ActiveCycle {
  id: string;
  userId: string;
  programId: string;
  cycleName: string;
  startDate: Date;
  currentWeek: number;
  currentSessionId?: string;
  currentPhase?: string;
  status: 'active' | 'completed' | 'paused';
}

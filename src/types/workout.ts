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
  createdAt: Date;
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
  day: number;
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
  status: 'active' | 'completed' | 'paused';
}

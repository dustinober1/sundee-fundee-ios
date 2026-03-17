export interface LoggedSet {
  id: string;
  weight: number;
  reps: number;
  completed: boolean;
  completedAt?: string;
  isPersonalRecord?: boolean;
}

export interface ActiveExercise {
  id: string;
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  sets: LoggedSet[];
  restSeconds?: number;
  order: number;
}

export interface WorkoutSession {
  id: string;
  startedAt: string;
  exercises: ActiveExercise[];
  timerMode?: 'forTime' | 'amrap' | 'emom' | 'none';
  timerConfig?: {
    durationSeconds?: number;
    intervalSeconds?: number;
  };
}

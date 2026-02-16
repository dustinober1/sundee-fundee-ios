export type ProgramCategory =
  | 'back-squat'
  | 'front-squat'
  | 'bench-press'
  | 'deadlift'
  | 'box-jump'
  | 'burpees';

export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced';

export interface Exercise {
  exercise: string;
  sets: number;
  reps: number;
  percent1RM: number;
  restMinutes?: number;
  rpeTarget?: number;
}

export interface Day {
  day: number;
  exercises: Exercise[];
}

export interface Week {
  week: number;
  days: Day[];
}

export interface Program {
  id: string;
  name: string;
  category: ProgramCategory;
  description: string;
  durationWeeks: number;
  daysPerWeek: number;
  exercises: string[];
  difficulty: DifficultyLevel;
  weeks: Week[];
}

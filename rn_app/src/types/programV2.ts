import type { DifficultyLevel, ProgramCategory } from './program';

export interface Phase {
  id: string;
  name: string;
  goal: string;
  weekRange: [number, number];
}

export interface ExerciseV2 {
  exercise: string;
  variant?: string;
  sets: number | 'AMRAP';
  reps: number | [number, number] | 'AMRAP';
  percent1RM: number;
  restMinutes?: number;
  notes?: string;
}

export interface Session {
  sessionId: string;
  sessionName: string;
  sessionType: 'support' | 'anchor' | 'testing';
  focus: string;
  exercises: ExerciseV2[];
}

export interface WeekV2 {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: Session[];
}

export interface ProgramV2 {
  id: string;
  name: string;
  category: ProgramCategory;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: DifficultyLevel;
  phases: Phase[];
  weeks: WeekV2[];
}

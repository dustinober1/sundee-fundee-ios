/**
 * Program types — mirrors Swift Program model exactly.
 * CRITICAL: uses `phaseId` (not `phaseID`) and `sessionId` (not `sessionID`)
 * to match Swift CodingKeys.
 */

/**
 * Matches Swift ExerciseValue enum encoding:
 * - number → .fixed(Int)
 * - [number, number] → .range(Int, Int)
 * - "AMRAP" → .amrap
 * - string → .text(String)
 */
export type ExerciseValue = number | [number, number] | 'AMRAP' | string;

export interface ProgramExercise {
  exercise: string;
  variant?: string | null;
  sets: ExerciseValue;
  reps: ExerciseValue;
  percent1RM?: number | null;
  restMinutes?: number | null;
  notes?: string | null;
  bodyweightOnly?: boolean | null;
}

export interface ProgramSession {
  sessionId: string;
  sessionName: string;
  sessionType: string;
  focus: string;
  exercises: ProgramExercise[];
}

export interface ProgramWeek {
  week: number;
  phaseId?: string | null;
  isTestWeek?: boolean | null;
  sessions: ProgramSession[];
}

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: [number, number];
}

export interface ProgramCycleAdjustmentPhaseSettings {
  loadMultiplier: number;
  setsMultiplier: number;
  repsMultiplier: number;
}

export interface ProgramCycleAdjustmentProfile {
  fallbackPhase: string;
  lowConfidenceScale: number;
  phaseSettings: Record<string, ProgramCycleAdjustmentPhaseSettings>;
}

export type ProgramStatus = 'draft' | 'published';
export type ProgramDuration = 4 | 8 | 12;
export type ProgramCategory = 'strength' | 'hypertrophy' | 'powerlifting' | 'general';
export type ProgramDifficulty = 'beginner' | 'intermediate' | 'advanced';

export interface ProgramFormData {
  id: string;
  name: string;
  category: string;
  description: string;
  durationWeeks: ProgramDuration;
  sessionsPerWeek: number;
  difficulty: string;
  status: ProgramStatus;
  startDate?: string | null;
  endDate?: string | null;
  createdAt?: string;
  updatedAt?: string;
  phases: ProgramPhase[];
  weeks: ProgramWeek[];
  cycleAdjustmentProfile?: ProgramCycleAdjustmentProfile | null;
}

/** Lightweight program record for list views (no weeks/phases JSON) */
export interface ProgramListItem {
  id: string;
  name: string;
  category: string;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: string;
  status: ProgramStatus;
  startDate?: string | null;
  endDate?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

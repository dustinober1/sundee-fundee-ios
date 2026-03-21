export const TRACKED_REP_RANGES = [1, 3, 5, 8, 10] as const;

export type TrackedRepRange = typeof TRACKED_REP_RANGES[number];

export interface ExerciseMax {
  exerciseId: string;
  exerciseName: string;
  repRange: TrackedRepRange;
  weight: number;
  estimated1RM: number;
  achievedAt: string;
}

export interface PRCheckResult {
  isWeightPR: boolean;
  is1RMPR: boolean;
  repRange: TrackedRepRange | null;
  previousBest: number | null;
  newValue: number;
}

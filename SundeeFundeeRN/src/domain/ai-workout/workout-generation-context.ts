/**
 * WorkoutGenerationContext
 * Ported from SundeeFundee/Domain/AIWorkout/WorkoutGenerationContext.swift
 *
 * Captures all user preferences and context data for workout generation.
 * Pure type definitions — no framework dependencies.
 */

import type { WorkoutFocus, EnergyLevel, EquipmentAccess } from '../types';

// ---------------------------------------------------------------------------
// Sub-model types
// ---------------------------------------------------------------------------

export interface ExerciseMax {
  name: string;
  weightLb: number;
}

export interface RecentWorkoutSummary {
  date: Date;
  focus: string;
  exercises: string[];
  durationMinutes: number;
}

export interface InjurySummary {
  location: string;
  phase: string;
  restrictions: string[];
}

export interface BenchmarkSummary {
  name: string;
  bestScore: number;
  scoringType: string;
}

export interface PainActivitySummary {
  injuryID: string;
  lastPainLevel: number;
  lastRecordedDate: Date;
}

export interface QuestionnaireAnswers {
  timeMinutes: number;
  focus: WorkoutFocus;
  energyLevel: EnergyLevel;
  equipment: EquipmentAccess;
  desiredSkills: string[] | null;
}

// ---------------------------------------------------------------------------
// WorkoutGenerationContext
// ---------------------------------------------------------------------------

export interface WorkoutGenerationContext {
  userID: string;
  timeMinutes: number;
  focus: WorkoutFocus;
  energyLevel: EnergyLevel;
  equipment: EquipmentAccess;

  maxes: ExerciseMax[];
  recentWorkouts: RecentWorkoutSummary[];
  cyclePhase: string | null;
  readinessTier: string | null;
  activeInjuries: InjurySummary[];
  experienceLevel: string;
  primaryGoal: string;
  gender: string;
  weightUnit: string;

  desiredSkills: string[];
  benchmarkSummaries: BenchmarkSummary[];
  bodyWeightKg: number | null;
  recentPainActivity: PainActivitySummary[];
  workoutCompletionRate: number | null;
  travelModeEnabled: boolean;
}

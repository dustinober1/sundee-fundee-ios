/**
 * GeneratedWorkout & GeneratedExercise
 * Ported from SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift
 *
 * Pure TypeScript interfaces and pure functions.
 * Computed properties from Swift become standalone functions here.
 * No framework dependencies.
 */

import type { WorkoutFocus, EnergyLevel, EquipmentAccess } from '../types';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ExerciseEquipmentType = 'barbell' | 'dumbbell' | 'kettlebell' | 'other';

export interface GeneratedExercise {
  id: string;
  name: string;
  sets: number;
  /** Rep scheme: "8-10", "5", "AMRAP", "45s", etc. */
  reps: string;
  weightLb: number | null;
  restMinutes: number | null;
  notes: string | null;
  reasoning: string | null;
  bodyweightOnly: boolean;
}

export interface QuestionnaireAnswers {
  timeMinutes: number;
  focus: WorkoutFocus;
  energyLevel: EnergyLevel;
  equipment: EquipmentAccess;
  desiredSkills: string[] | null;
}

export interface GeneratedWorkout {
  id: string;
  createdAt: Date;
  isFavorite: boolean;
  isCompleted: boolean;
  coachingSummary: string;
  exercises: GeneratedExercise[];
  questionnaire: QuestionnaireAnswers;
}

// ---------------------------------------------------------------------------
// Pure functions (formerly computed properties / static methods in Swift)
// ---------------------------------------------------------------------------

/**
 * Infer the primary equipment type from an exercise name.
 * Matches Swift GeneratedExercise.equipmentType computed property.
 */
export function getEquipmentType(name: string): ExerciseEquipmentType {
  const n = name.toLowerCase();
  if (
    n.includes('kettlebell') ||
    n.includes('kb ') ||
    n.includes('kb swing') ||
    n.includes('kb snatch')
  ) {
    return 'kettlebell';
  }
  if (
    n.includes('dumbbell') ||
    n.includes('db ') ||
    n.includes('goblet') ||
    n.includes('lateral raise')
  ) {
    return 'dumbbell';
  }
  if (
    n.includes('barbell') ||
    n.includes('bench press') ||
    n.includes('back squat') ||
    n.includes('front squat') ||
    n.includes('deadlift') ||
    n.includes('strict press') ||
    n.includes('military press') ||
    n.includes('barbell row') ||
    n.includes('hip thrust') ||
    n.includes('romanian deadlift') ||
    n.includes('overhead press')
  ) {
    return 'barbell';
  }
  return 'other';
}

/**
 * Estimate total workout duration in minutes from an exercise list.
 * Matches Swift GeneratedWorkout.totalEstimatedMinutes computed property.
 */
export function totalEstimatedMinutes(exercises: GeneratedExercise[]): number {
  const setTime = exercises.reduce((total, ex) => {
    const repTime = 0.5; // ~30s per set average
    const rest = ex.restMinutes ?? 1.5;
    return total + ex.sets * (repTime + rest);
  }, 0);
  return Math.max(1, Math.round(setTime));
}

/**
 * Extract distinct muscle groups from an exercise list, sorted alphabetically.
 * Matches Swift GeneratedWorkout.extractMuscleGroups static method.
 */
export function extractMuscleGroups(exercises: GeneratedExercise[]): string[] {
  const groups = new Set<string>();
  for (const ex of exercises) {
    const name = ex.name.toLowerCase();
    if (name.includes('squat') || name.includes('lunge') || name.includes('leg press')) {
      groups.add('Quads');
    }
    if (name.includes('deadlift') || name.includes('hip thrust') || name.includes('glute')) {
      groups.add('Glutes');
    }
    if (
      name.includes('bench') ||
      name.includes('push') ||
      name.includes('chest') ||
      name.includes('fly')
    ) {
      groups.add('Chest');
    }
    if (name.includes('row') || name.includes('pull') || name.includes('lat')) {
      groups.add('Back');
    }
    if (
      name.includes('press') &&
      (name.includes('overhead') || name.includes('shoulder') || name.includes('military'))
    ) {
      groups.add('Shoulders');
    }
    if (name.includes('curl') || name.includes('bicep')) {
      groups.add('Biceps');
    }
    if (name.includes('tricep') || name.includes('extension') || name.includes('dip')) {
      groups.add('Triceps');
    }
    if (
      name.includes('core') ||
      name.includes('plank') ||
      name.includes('crunch') ||
      name.includes('ab')
    ) {
      groups.add('Core');
    }
    if (name.includes('calf')) {
      groups.add('Calves');
    }
    if (name.includes('hamstring') || name.includes('romanian') || name.includes('nordic')) {
      groups.add('Hamstrings');
    }
  }
  return Array.from(groups).sort();
}

/**
 * Remove cycle phase and injury references from a coaching summary for sharing.
 * Matches Swift GeneratedWorkout.stripHealthReferences static method.
 */
export function stripHealthReferences(summary: string): string {
  let result = summary;
  const healthPatterns = [
    /Adjusted for \w+ phase\./g,
    /Exercises modified for .+ injury considerations\./g,
  ];
  for (const pattern of healthPatterns) {
    result = result.replace(pattern, '');
  }
  return result.replace(/  /g, ' ').trim();
}

/**
 * Strip weight and identifying data for anonymous sharing.
 * Matches Swift GeneratedWorkout.strippedForSharing() method.
 * Returns a new workout with a fresh ID.
 */
export function strippedForSharing(workout: GeneratedWorkout): GeneratedWorkout {
  const strippedExercises: GeneratedExercise[] = workout.exercises.map((ex) => ({
    ...ex,
    id: ex.id,
    weightLb: null,
    reasoning: null,
  }));
  return {
    ...workout,
    id: crypto.randomUUID(),
    isFavorite: false,
    isCompleted: false,
    coachingSummary: stripHealthReferences(workout.coachingSummary),
    exercises: strippedExercises,
  };
}

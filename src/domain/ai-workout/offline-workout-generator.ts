/**
 * OfflineWorkoutGenerator
 * Ported from SundeeFundee/Domain/AIWorkout/OfflineWorkoutGenerator.swift
 *
 * Template-based workout generation for offline fallback.
 * All functions are pure — no side effects, no storage access.
 *
 * Pipeline: selectTemplates → scaleForTime → applyWeights → applyEnergyLevel
 *           → applyInjurySubstitutions → applyCyclePhase → buildCoachingSummary
 */

import type { WorkoutFocus, EquipmentAccess, EnergyLevel } from '../types';
import { workoutFocusDisplayName } from '../types';
import {
  snapBarbellWeightLb,
  snapDumbbellWeightLb,
  snapKettlebellWeightLb,
  roundToNearestFive,
} from '../calculations/weight-calculations';
import type { GeneratedExercise, GeneratedWorkout } from './generated-workout';
import { getEquipmentType } from './generated-workout';
import type { WorkoutGenerationContext, InjurySummary, ExerciseMax } from './workout-generation-context';

// ---------------------------------------------------------------------------
// ExerciseTemplate
// ---------------------------------------------------------------------------

export interface ExerciseTemplate {
  name: string;
  defaultSets: number;
  defaultReps: string;
  defaultRestMinutes: number;
  bodyweightOnly: boolean;
  muscleGroups: string[];
  requiresBarbell: boolean;
  requiresDumbbells: boolean;
  maxKey: string | null;
}

function makeTemplate(
  name: string,
  opts: Partial<ExerciseTemplate> = {},
): ExerciseTemplate {
  return {
    name,
    defaultSets: opts.defaultSets ?? 3,
    defaultReps: opts.defaultReps ?? '8-10',
    defaultRestMinutes: opts.defaultRestMinutes ?? 2.0,
    bodyweightOnly: opts.bodyweightOnly ?? false,
    muscleGroups: opts.muscleGroups ?? [],
    requiresBarbell: opts.requiresBarbell ?? false,
    requiresDumbbells: opts.requiresDumbbells ?? false,
    maxKey: opts.maxKey ?? null,
  };
}

// ---------------------------------------------------------------------------
// Static template arrays — ported directly from Swift
// ---------------------------------------------------------------------------

const upperBodyTemplates: ExerciseTemplate[] = [
  makeTemplate('Flat Barbell Bench Press', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['chest', 'triceps', 'shoulders'], requiresBarbell: true, maxKey: 'Flat Barbell Bench Press' }),
  makeTemplate('Dumbbell Bench Press', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 2.0, muscleGroups: ['chest', 'triceps'], requiresDumbbells: true }),
  makeTemplate('Strict Press / Military Press', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['shoulders', 'triceps'], requiresBarbell: true, maxKey: 'Strict Press / Military Press' }),
  makeTemplate('Dumbbell Overhead Press', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 2.0, muscleGroups: ['shoulders'], requiresDumbbells: true }),
  makeTemplate('Barbell Row', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 2.5, muscleGroups: ['back', 'biceps'], requiresBarbell: true }),
  makeTemplate('Dumbbell Row', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 1.5, muscleGroups: ['back', 'biceps'], requiresDumbbells: true }),
  makeTemplate('Pull-Up', { defaultSets: 3, defaultReps: 'AMRAP', defaultRestMinutes: 2.0, bodyweightOnly: true, muscleGroups: ['back', 'biceps'] }),
  makeTemplate('Push-Ups', { defaultSets: 3, defaultReps: '15-20', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['chest', 'triceps'] }),
  makeTemplate('Lateral Raises', { defaultSets: 3, defaultReps: '12-15', defaultRestMinutes: 1.0, muscleGroups: ['shoulders'], requiresDumbbells: true }),
  makeTemplate('Tricep Dips', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ['triceps', 'chest'] }),
];

const lowerBodyTemplates: ExerciseTemplate[] = [
  makeTemplate('Back Squat', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['quads', 'glutes'], requiresBarbell: true, maxKey: 'Back Squat' }),
  makeTemplate('Front Squat', { defaultSets: 3, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['quads'], requiresBarbell: true, maxKey: 'Front Squat' }),
  makeTemplate('Conventional Deadlift (No Straps)', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.5, muscleGroups: ['back', 'glutes', 'hamstrings'], requiresBarbell: true, maxKey: 'Conventional Deadlift (No Straps)' }),
  makeTemplate('Romanian Deadlift (No Straps)', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 2.5, muscleGroups: ['hamstrings', 'glutes'], requiresBarbell: true }),
  makeTemplate('Goblet Squat', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 2.0, muscleGroups: ['quads', 'glutes'], requiresDumbbells: true }),
  makeTemplate('Walking Lunges', { defaultSets: 3, defaultReps: '10', defaultRestMinutes: 1.5, muscleGroups: ['quads', 'glutes'], requiresDumbbells: true }),
  makeTemplate('Hip Thrust', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 2.0, muscleGroups: ['glutes'], requiresBarbell: true }),
  makeTemplate('Air Squats', { defaultSets: 3, defaultReps: '20', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['quads', 'glutes'] }),
  makeTemplate('Bodyweight Lunges', { defaultSets: 3, defaultReps: '12', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['quads', 'glutes'] }),
  makeTemplate('Glute Bridge', { defaultSets: 3, defaultReps: '15', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['glutes'] }),
];

const pushTemplates: ExerciseTemplate[] = [
  makeTemplate('Flat Barbell Bench Press', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['chest'], requiresBarbell: true, maxKey: 'Flat Barbell Bench Press' }),
  makeTemplate('Strict Press / Military Press', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.0, muscleGroups: ['shoulders'], requiresBarbell: true, maxKey: 'Strict Press / Military Press' }),
  makeTemplate('Dumbbell Bench Press', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 2.0, muscleGroups: ['chest'], requiresDumbbells: true }),
  makeTemplate('Dumbbell Overhead Press', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 2.0, muscleGroups: ['shoulders'], requiresDumbbells: true }),
  makeTemplate('Push-Ups', { defaultSets: 3, defaultReps: '15-20', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['chest', 'triceps'] }),
  makeTemplate('Tricep Dips', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ['triceps'] }),
  makeTemplate('Lateral Raises', { defaultSets: 3, defaultReps: '12-15', defaultRestMinutes: 1.0, muscleGroups: ['shoulders'], requiresDumbbells: true }),
];

const pullTemplates: ExerciseTemplate[] = [
  makeTemplate('Conventional Deadlift (No Straps)', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 3.5, muscleGroups: ['back', 'hamstrings'], requiresBarbell: true, maxKey: 'Conventional Deadlift (No Straps)' }),
  makeTemplate('Barbell Row', { defaultSets: 4, defaultReps: '5', defaultRestMinutes: 2.5, muscleGroups: ['back'], requiresBarbell: true }),
  makeTemplate('Pull-Up', { defaultSets: 3, defaultReps: 'AMRAP', defaultRestMinutes: 2.0, bodyweightOnly: true, muscleGroups: ['back', 'biceps'] }),
  makeTemplate('Dumbbell Row', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 1.5, muscleGroups: ['back'], requiresDumbbells: true }),
  makeTemplate('Face Pulls', { defaultSets: 3, defaultReps: '15', defaultRestMinutes: 1.0, muscleGroups: ['shoulders', 'back'] }),
  makeTemplate('Dumbbell Curl', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 1.0, muscleGroups: ['biceps'], requiresDumbbells: true }),
];

const coreTemplates: ExerciseTemplate[] = [
  makeTemplate('Plank Hold', { defaultSets: 3, defaultReps: '45s', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['core'] }),
  makeTemplate('Dead Bug', { defaultSets: 3, defaultReps: '10', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['core'] }),
  makeTemplate('Russian Twist', { defaultSets: 3, defaultReps: '20', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['core'] }),
  makeTemplate('Hanging Leg Raise', { defaultSets: 3, defaultReps: '10-12', defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ['core'] }),
  makeTemplate('Ab Wheel Rollout', { defaultSets: 3, defaultReps: '8-10', defaultRestMinutes: 1.5, muscleGroups: ['core'] }),
  makeTemplate('Bird-Dogs', { defaultSets: 3, defaultReps: '10', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['core'] }),
];

const conditioningTemplates: ExerciseTemplate[] = [
  makeTemplate('Burpees', { defaultSets: 4, defaultReps: '10', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['full body'] }),
  makeTemplate('Kettlebell Swings', { defaultSets: 4, defaultReps: '15', defaultRestMinutes: 1.0, muscleGroups: ['glutes', 'hamstrings'], requiresDumbbells: true }),
  makeTemplate('Box Jumps', { defaultSets: 3, defaultReps: '10', defaultRestMinutes: 1.5, bodyweightOnly: true, muscleGroups: ['quads', 'glutes'] }),
  makeTemplate('Mountain Climbers', { defaultSets: 3, defaultReps: '30', defaultRestMinutes: 1.0, bodyweightOnly: true, muscleGroups: ['core'] }),
  makeTemplate('Jump Rope', { defaultSets: 4, defaultReps: '60s', defaultRestMinutes: 0.5, bodyweightOnly: true, muscleGroups: ['calves'] }),
  makeTemplate('Battle Ropes', { defaultSets: 3, defaultReps: '30s', defaultRestMinutes: 1.0, muscleGroups: ['shoulders', 'core'] }),
];

// ---------------------------------------------------------------------------
// Template selection
// ---------------------------------------------------------------------------

export function selectTemplates(
  focus: WorkoutFocus,
  equipment: EquipmentAccess,
): ExerciseTemplate[] {
  let pool: ExerciseTemplate[];
  switch (focus) {
    case 'upper_body':
      pool = upperBodyTemplates;
      break;
    case 'lower_body':
      pool = lowerBodyTemplates;
      break;
    case 'full_body':
      pool = [...upperBodyTemplates, ...lowerBodyTemplates];
      break;
    case 'push':
      pool = pushTemplates;
      break;
    case 'pull':
      pool = pullTemplates;
      break;
    case 'core':
      pool = coreTemplates;
      break;
    case 'conditioning':
      pool = conditioningTemplates;
      break;
    case 'strength':
      pool = [...pushTemplates, ...pullTemplates, ...lowerBodyTemplates];
      break;
    case 'olympic_lifts':
      pool = [...conditioningTemplates, ...upperBodyTemplates];
      break;
    case 'gymnastics':
      pool = [...pullTemplates, ...coreTemplates];
      break;
    case 'mobility':
      pool = coreTemplates;
      break;
    case 'stretching':
      pool = coreTemplates;
      break;
  }
  return filterForEquipment(pool, equipment);
}

export function filterForEquipment(
  templates: ExerciseTemplate[],
  equipment: EquipmentAccess,
): ExerciseTemplate[] {
  return templates.filter((template) => {
    switch (equipment) {
      case 'full_gym':
        return true;
      case 'home_dumbbells':
        return !template.requiresBarbell;
      case 'hotel_gym':
        return !template.requiresBarbell;
      case 'bodyweight_only':
        return template.bodyweightOnly;
      case 'outdoor':
        return template.bodyweightOnly;
    }
  });
}

// ---------------------------------------------------------------------------
// Time scaling
// ---------------------------------------------------------------------------

export function scaleForTime(
  templates: ExerciseTemplate[],
  targetMinutes: number,
): ExerciseTemplate[] {
  if (templates.length === 0) return [];
  const estimatedTimePerExercise = 5.0; // ~5 min per exercise (sets + rest)
  const targetCount = Math.max(3, Math.round(targetMinutes / estimatedTimePerExercise));
  const count = Math.min(targetCount, templates.length);
  return templates.slice(0, count);
}

// ---------------------------------------------------------------------------
// Weight application
// ---------------------------------------------------------------------------

/**
 * Snap an exercise weight to a physically loadable value based on equipment type.
 */
function withSnappedWeight(exercise: GeneratedExercise): GeneratedExercise {
  if (exercise.weightLb == null || exercise.weightLb <= 0 || exercise.bodyweightOnly) {
    return exercise;
  }
  const equipType = getEquipmentType(exercise.name);
  switch (equipType) {
    case 'barbell':
      return { ...exercise, weightLb: snapBarbellWeightLb(exercise.weightLb) };
    case 'dumbbell':
      return { ...exercise, weightLb: snapDumbbellWeightLb(exercise.weightLb) };
    case 'kettlebell':
      return { ...exercise, weightLb: snapKettlebellWeightLb(exercise.weightLb) };
    case 'other':
      return exercise;
  }
}

export function defaultPercentage(reps: string): number {
  if (reps === '5' || reps === '3') return 0.80;
  if (reps.includes('8') || reps.includes('10')) return 0.70;
  if (reps.includes('12') || reps.includes('15')) return 0.60;
  return 0.65;
}

export function applyWeights(
  exercises: ExerciseTemplate[],
  maxes: ExerciseMax[],
  equipment: EquipmentAccess,
): GeneratedExercise[] {
  const maxDict = new Map<string, number>(maxes.map((m) => [m.name, m.weightLb]));

  return exercises.map((template) => {
    let weightLb: number | null = null;
    if (!template.bodyweightOnly) {
      if (template.maxKey != null) {
        const orm = maxDict.get(template.maxKey);
        if (orm != null) {
          const percentage = defaultPercentage(template.defaultReps);
          const raw = orm * percentage;
          weightLb = template.requiresBarbell
            ? snapBarbellWeightLb(raw)
            : roundToNearestFive(raw);
        } else if (template.requiresDumbbells) {
          // Default to 25 lb dumbbell (conservative default)
          weightLb = snapDumbbellWeightLb(25);
        } else if (equipment === 'home_dumbbells') {
          weightLb = snapDumbbellWeightLb(25);
        }
      } else if (template.requiresDumbbells) {
        weightLb = snapDumbbellWeightLb(25);
      } else if (equipment === 'home_dumbbells') {
        weightLb = snapDumbbellWeightLb(25);
      }
    }

    const exercise: GeneratedExercise = {
      id: crypto.randomUUID(),
      name: template.name,
      sets: template.defaultSets,
      reps: template.defaultReps,
      weightLb,
      restMinutes: template.defaultRestMinutes,
      notes: null,
      reasoning: null,
      bodyweightOnly: template.bodyweightOnly,
    };
    return withSnappedWeight(exercise);
  });
}

// ---------------------------------------------------------------------------
// Energy level adjustment
// ---------------------------------------------------------------------------

export function applyEnergyLevel(
  exercises: GeneratedExercise[],
  energy: EnergyLevel,
): GeneratedExercise[] {
  let multiplier: number;
  switch (energy) {
    case 'low':
      multiplier = 0.85;
      break;
    case 'medium':
      multiplier = 1.0;
      break;
    case 'high':
      multiplier = 1.05;
      break;
  }

  if (multiplier === 1.0) return exercises;

  return exercises.map((ex) => {
    if (ex.weightLb == null) return ex;
    const raw = roundToNearestFive(ex.weightLb * multiplier);
    return withSnappedWeight({ ...ex, weightLb: raw });
  });
}

// ---------------------------------------------------------------------------
// Injury substitutions
// ---------------------------------------------------------------------------

const CONTRAINDICATED_KEYWORDS: Record<string, string[]> = {
  knee: ['squat', 'lunge', 'leg press', 'step-up'],
  shoulder: ['press', 'bench', 'overhead', 'clean', 'snatch', 'jerk'],
  back: ['deadlift', 'good morning', 'hinge', 'row'],
  spine: ['deadlift', 'good morning', 'hinge', 'row'],
  hip: ['deadlift', 'hinge', 'lunge', 'hip thrust'],
  wrist: ['clean', 'snatch', 'jerk'],
  ankle: ['jump', 'run', 'calf'],
};

const SUBSTITUTION_MAP: Record<string, string> = {
  'Back Squat': 'Goblet Squat',
  'Front Squat': 'Goblet Squat',
  'Flat Barbell Bench Press': 'Push-Ups',
  'Strict Press / Military Press': 'Lateral Raises',
  'Conventional Deadlift (No Straps)': 'Hip Thrust',
  'Barbell Row': 'Dumbbell Row',
  'Walking Lunges': 'Step-Ups',
};

function contraindicatedKeywords(location: string): string[] {
  const loc = location.toLowerCase();
  for (const [key, keywords] of Object.entries(CONTRAINDICATED_KEYWORDS)) {
    if (loc.includes(key)) return keywords;
  }
  return [];
}

function findSubstitute(exerciseName: string, avoidingLocations: string[]): string | null {
  const sub = SUBSTITUTION_MAP[exerciseName];
  if (sub == null) return null;
  const subLower = sub.toLowerCase();
  const stillContraindicated = avoidingLocations.some((loc) =>
    contraindicatedKeywords(loc).some((kw) => subLower.includes(kw)),
  );
  return stillContraindicated ? null : sub;
}

export function applyInjurySubstitutions(
  exercises: GeneratedExercise[],
  injuries: InjurySummary[],
): GeneratedExercise[] {
  if (injuries.length === 0) return exercises;

  const injuredLocations = injuries.map((i) => i.location.toLowerCase());

  return exercises.reduce<GeneratedExercise[]>((acc, exercise) => {
    const name = exercise.name.toLowerCase();
    const isContraindicated = injuredLocations.some((loc) =>
      contraindicatedKeywords(loc).some((kw) => name.includes(kw)),
    );

    if (isContraindicated) {
      const sub = findSubstitute(exercise.name, injuredLocations);
      if (sub != null) {
        acc.push({
          ...exercise,
          name: sub,
          notes: `Substituted for ${exercise.name} due to injury`,
        });
      }
      // Else: remove (no safe substitute)
    } else {
      acc.push(exercise);
    }
    return acc;
  }, []);
}

// ---------------------------------------------------------------------------
// Cycle phase adjustment
// ---------------------------------------------------------------------------

export function applyCyclePhase(
  exercises: GeneratedExercise[],
  phase: string | null,
  readiness: string | null,
): GeneratedExercise[] {
  if (phase == null) return exercises;

  let loadMultiplier: number;
  switch (phase) {
    case 'menstrual':
      loadMultiplier = 0.90;
      break;
    case 'follicular':
      loadMultiplier = 1.00;
      break;
    case 'ovulation':
      loadMultiplier = 1.12;
      break;
    case 'luteal':
      loadMultiplier = 0.97;
      break;
    default:
      loadMultiplier = 1.00;
  }

  let readinessMultiplier: number;
  switch (readiness) {
    case 'low':
      readinessMultiplier = 0.85;
      break;
    case 'high':
      readinessMultiplier = 1.10;
      break;
    default:
      readinessMultiplier = 1.0;
  }

  const combined = loadMultiplier * readinessMultiplier;
  if (combined === 1.0) return exercises;

  return exercises.map((ex) => {
    if (ex.weightLb == null) return ex;
    const raw = roundToNearestFive(ex.weightLb * combined);
    return withSnappedWeight({ ...ex, weightLb: raw });
  });
}

// ---------------------------------------------------------------------------
// Coaching summary
// ---------------------------------------------------------------------------

export function buildCoachingSummary(
  context: WorkoutGenerationContext,
  exerciseCount: number,
  droppedForInjury = 0,
): string {
  const parts: string[] = [];

  const focusName = workoutFocusDisplayName(context.focus).toLowerCase();
  parts.push(
    `Generated offline: ${exerciseCount}-exercise ${focusName} session targeting ~${context.timeMinutes} minutes.`,
  );

  switch (context.energyLevel) {
    case 'low':
      parts.push('Weights reduced for low energy day.');
      break;
    case 'high':
      parts.push('Slightly increased intensity for high energy.');
      break;
    case 'medium':
      break;
  }

  if (context.cyclePhase != null) {
    parts.push(`Adjusted for ${context.cyclePhase} phase.`);
  }

  if (context.activeInjuries.length > 0) {
    const locations = context.activeInjuries.map((i) => i.location).join(', ');
    parts.push(`Exercises modified for ${locations} injury considerations.`);
  }

  if (droppedForInjury > 0) {
    const exerciseWord = droppedForInjury === 1 ? 'exercise was' : 'exercises were';
    parts.push(
      `${droppedForInjury} ${exerciseWord} removed due to injury constraints with no safe substitute available.`,
    );
  }

  if (context.travelModeEnabled) {
    parts.push('Travel mode: exercises selected for minimal space and equipment.');
  }

  return parts.join(' ');
}

// ---------------------------------------------------------------------------
// Public API — generateOfflineWorkout
// ---------------------------------------------------------------------------

/**
 * Generate an offline workout from templates based on user context.
 * Returns a GeneratedWorkout that matches what the iOS Swift app would produce.
 */
export function generateOfflineWorkout(context: WorkoutGenerationContext): GeneratedWorkout {
  const templates = selectTemplates(context.focus, context.equipment);
  const scaled = scaleForTime(templates, context.timeMinutes);
  const withWeights = applyWeights(scaled, context.maxes, context.equipment);
  const adjusted = applyEnergyLevel(withWeights, context.energyLevel);
  const adapted = applyInjurySubstitutions(adjusted, context.activeInjuries);
  const droppedCount = adjusted.length - adapted.length;
  const phaseAdjusted = applyCyclePhase(adapted, context.cyclePhase, context.readinessTier);

  const summary = buildCoachingSummary(context, phaseAdjusted.length, droppedCount);

  return {
    id: crypto.randomUUID(),
    createdAt: new Date(),
    isFavorite: false,
    isCompleted: false,
    coachingSummary: summary,
    exercises: phaseAdjusted,
    questionnaire: {
      timeMinutes: context.timeMinutes,
      focus: context.focus,
      energyLevel: context.energyLevel,
      equipment: context.equipment,
      desiredSkills: context.desiredSkills.length === 0 ? null : context.desiredSkills,
    },
  };
}

import { db } from '@/lib/db/dexie';
import { detectPlateau as checkPlateau } from '@/lib/calculations';
import { roundToNearestFive } from '@/lib/utils';

export interface PlateauWarning {
  hasPlateau: boolean;
  message: string;
  recommendation: string;
}

export async function detectPlateauForCycle(activeCycleId: string): Promise<PlateauWarning> {
  const cycle = await db.activeCycles.get(activeCycleId);
  if (!cycle) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // Get recent workouts for this cycle
  const workouts = await db.completedWorkouts
    .where('activeCycleId')
    .equals(activeCycleId)
    .reverse()
    .limit(5)
    .toArray();

  if (workouts.length < 3) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // Get sets from these workouts
  const setPromises = workouts.map(w =>
    db.completedSets.where('workoutId').equals(w.id).toArray()
  );
  const allSets = await Promise.all(setPromises);
  const weights = allSets.flat().map(s => s.actualWeight);

  const hasPlateau = checkPlateau(weights);

  if (hasPlateau) {
    return {
      hasPlateau: true,
      message: 'Your weight has plateaued',
      recommendation: 'Consider a deload week or changing your training intensity'
    };
  }

  return { hasPlateau: false, message: '', recommendation: '' };
}

/**
 * Detect per-exercise plateau by checking if the last 3 sessions for a specific exercise
 * ALL had at least one set where actualReps < prescribedReps.
 *
 * Unlike detectPlateauForCycle (which checks weight variance), this function checks
 * rep completion failure — the correct signal for a progressive overload plateau.
 *
 * @param exerciseId - The exercise to check
 * @param activeCycleId - The active cycle to scope workouts to
 * @returns PlateauWarning with hasPlateau=true if 3 consecutive sessions failed
 */
export async function detectPlateauForExercise(
  exerciseId: string,
  activeCycleId: string
): Promise<PlateauWarning> {
  // Get last 3 workouts for this cycle (most recent first)
  const workouts = await db.completedWorkouts
    .where('activeCycleId')
    .equals(activeCycleId)
    .reverse()
    .limit(3)
    .toArray();

  if (workouts.length < 3) {
    return { hasPlateau: false, message: '', recommendation: '' };
  }

  // For each workout, check if this exercise had any set with actualReps < prescribedReps
  const sessionFailures: boolean[] = await Promise.all(
    workouts.map(async (workout) => {
      const sets = await db.completedSets
        .where('workoutId')
        .equals(workout.id)
        .and(s => s.exerciseId === exerciseId)
        .toArray();

      // If no sets for this exercise in this workout, it's not a failure
      if (sets.length === 0) return false;

      // Session is "failed" if ANY set had actualReps < prescribedReps
      return sets.some(s => s.actualReps < s.prescribedReps);
    })
  );

  // Plateau only if ALL 3 sessions failed
  const hasPlateau = sessionFailures.every(failed => failed);

  if (hasPlateau) {
    return {
      hasPlateau: true,
      message: "You've missed prescribed reps on this exercise for 3 sessions in a row.",
      recommendation: 'Recommended deload: reduce weight by 10% for next session.'
    };
  }

  return { hasPlateau: false, message: '', recommendation: '' };
}

/**
 * Calculate deload weight: 10% reduction from current weight, rounded to nearest 5 lbs.
 * Used when plateau is detected to prescribe a recovery weight.
 *
 * @param currentWeight - Current working weight in lbs
 * @returns Deload weight (90% of current), rounded to nearest 5 lbs
 */
export function getDeloadWeight(currentWeight: number): number {
  return roundToNearestFive(currentWeight * 0.9);
}

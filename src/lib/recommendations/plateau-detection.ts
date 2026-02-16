import { db } from '@/lib/db/dexie';
import { detectPlateau as checkPlateau } from '@/lib/calculations';

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

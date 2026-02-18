import { db } from '@/lib/db/dexie';
import { useUser } from '@/contexts/user-context';

/**
 * Hook for detecting personal records (PRs) during or after a workout.
 *
 * Provides two PR checks:
 * - Weight PR: new weight exceeds best recorded 1RM for the exercise
 * - Volume PR: current session's total volume (weight × reps) for an exercise
 *   exceeds the best single-session volume from prior history
 *
 * Edge cases handled:
 * - Weight PR: requires currentMax > 0 (no PR triggered on first-ever lift)
 * - Volume PR: requires at least 1 prior session to exist (avoids spam on first session)
 */
export function usePRDetection() {
  const { oneRepMaxes } = useUser();

  /**
   * Check if a new weight represents a weight PR for an exercise.
   * Compares against the user's highest recorded 1RM for that exercise.
   *
   * Returns false if there is no prior 1RM record (don't celebrate first-ever lift).
   *
   * @param exerciseId - The exercise to check
   * @param newWeight - The new weight being lifted
   * @returns true if newWeight exceeds the best recorded 1RM
   */
  function checkWeightPR(exerciseId: string, newWeight: number): boolean {
    const currentMax = oneRepMaxes
      .filter(orm => orm.exerciseId === exerciseId)
      .reduce((max, orm) => Math.max(max, orm.weight), 0);

    // If no prior 1RM exists (currentMax = 0), don't trigger PR on first lift
    return newWeight > currentMax && currentMax > 0;
  }

  /**
   * Check if the current session represents a volume PR for an exercise.
   * Volume = sum of (actualWeight × actualReps) across all sets in a session.
   *
   * Compares current session volume against the best single-session volume
   * from all prior sessions (excluding the current workout).
   *
   * Returns false if no prior sessions exist (avoids spam on first session).
   *
   * @param workoutId - Current workout ID (excluded from historical comparison)
   * @param exerciseId - The exercise to check
   * @param currentSessionSets - Sets completed in the current session
   * @returns true if currentSessionSets volume exceeds best historical single-session volume
   */
  async function checkVolumePR(
    workoutId: string,
    exerciseId: string,
    currentSessionSets: Array<{ actualWeight: number; actualReps: number }>
  ): Promise<boolean> {
    // Calculate current session volume for this exercise
    const currentVolume = currentSessionSets.reduce(
      (sum, s) => sum + s.actualWeight * s.actualReps,
      0
    );

    if (currentVolume === 0) return false;

    // Get ALL historical completed sets for this exercise (excluding current workout)
    const allSets = await db.completedSets
      .where('exerciseId')
      .equals(exerciseId)
      .and(s => s.workoutId !== workoutId)
      .toArray();

    // No prior data = no PR (avoid spam on first session)
    if (allSets.length === 0) return false;

    // Group by workoutId and find best single-session volume
    const volumeByWorkout = new Map<string, number>();
    for (const s of allSets) {
      const prev = volumeByWorkout.get(s.workoutId) ?? 0;
      volumeByWorkout.set(s.workoutId, prev + s.actualWeight * s.actualReps);
    }
    const bestHistoricalVolume = Math.max(0, ...volumeByWorkout.values());

    return currentVolume > bestHistoricalVolume;
  }

  return { checkWeightPR, checkVolumePR };
}

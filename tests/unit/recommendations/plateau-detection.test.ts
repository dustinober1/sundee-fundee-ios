import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import { detectPlateauForCycle } from '@/lib/recommendations/plateau-detection';
import { saveCompletedWorkout, saveCompletedSet } from '@/lib/db';
import { generateId } from '@/lib/utils';
import type { User, ActiveCycle, CompletedWorkout, CompletedSet } from '@/types';

describe('Plateau Detection', () => {
  let userId: string;
  let cycleId: string;

  beforeEach(async () => {
    await db.delete();
    await db.open();

    // Create test user
    userId = generateId();
    await db.users.add({
      id: userId,
      name: 'Test User',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength',
      createdAt: new Date()
    });

    // Create active cycle
    cycleId = generateId();
    await db.activeCycles.add({
      id: cycleId,
      userId,
      programId: 'back-squat-5x5-linear',
      cycleName: 'Back Squat 5x5',
      startDate: new Date(),
      currentWeek: 1,
      status: 'active'
    });
  });

  it('returns no plateau when no workouts exist', async () => {
    const result = await detectPlateauForCycle(cycleId);
    expect(result.hasPlateau).toBe(false);
  });

  it('returns no plateau with less than 3 workouts', async () => {
    // Add 2 workouts
    for (let i = 0; i < 2; i++) {
      const workoutId = generateId();
      await db.completedWorkouts.add({
        id: workoutId,
        userId,
        activeCycleId: cycleId,
        programId: 'back-squat-5x5-linear',
        week: 1,
        day: i + 1,
        completedAt: new Date()
      });
    }

    const result = await detectPlateauForCycle(cycleId);
    expect(result.hasPlateau).toBe(false);
  });

  it('detects plateau after 3 stagnant workouts', async () => {
    // Log 3 workouts at same weight
    for (let i = 0; i < 3; i++) {
      const workoutId = generateId();
      await db.completedWorkouts.add({
        id: workoutId,
        userId,
        activeCycleId: cycleId,
        programId: 'back-squat-5x5-linear',
        week: 1,
        day: i + 1,
        completedAt: new Date(Date.now() - (2 - i) * 86400000) // Past days
      });

      await db.completedSets.add({
        id: generateId(),
        workoutId,
        exerciseId: 'back-squat',
        setNumber: 1,
        actualWeight: 225,
        actualReps: 5,
        prescribedReps: 5,
        createdAt: new Date()
      });
    }

    const result = await detectPlateauForCycle(cycleId);
    expect(result.hasPlateau).toBe(true);
    expect(result.recommendation).toContain('deload');
  });

  it('does not detect plateau with progress', async () => {
    // Log 3 workouts with increasing weight
    const weights = [225, 230, 235];
    for (let i = 0; i < 3; i++) {
      const workoutId = generateId();
      await db.completedWorkouts.add({
        id: workoutId,
        userId,
        activeCycleId: cycleId,
        programId: 'back-squat-5x5-linear',
        week: 1,
        day: i + 1,
        completedAt: new Date(Date.now() - (2 - i) * 86400000)
      });

      await db.completedSets.add({
        id: generateId(),
        workoutId,
        exerciseId: 'back-squat',
        setNumber: 1,
        actualWeight: weights[i],
        actualReps: 5,
        prescribedReps: 5,
        createdAt: new Date()
      });
    }

    const result = await detectPlateauForCycle(cycleId);
    expect(result.hasPlateau).toBe(false);
  });

  it('returns empty result for unknown cycle', async () => {
    const result = await detectPlateauForCycle('unknown-cycle-id');
    expect(result.hasPlateau).toBe(false);
    expect(result.message).toBe('');
  });
});

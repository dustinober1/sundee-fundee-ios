import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import {
  detectPlateauForCycle,
  detectPlateauForExercise,
  getDeloadWeight,
} from '@/lib/recommendations/plateau-detection';
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

// ---------------------------------------------------------------------------
// detectPlateauForExercise — per-exercise, rep-based plateau detection
// ---------------------------------------------------------------------------

describe('detectPlateauForExercise', () => {
  const exerciseId = 'squat';
  let userId: string;
  let cycleId: string;

  beforeEach(async () => {
    await db.delete();
    await db.open();

    userId = generateId();
    await db.users.add({
      id: userId,
      name: 'Athlete',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength',
      createdAt: new Date(),
    });

    cycleId = generateId();
    await db.activeCycles.add({
      id: cycleId,
      userId,
      programId: 'squat-program',
      cycleName: 'Squat Program',
      startDate: new Date(),
      currentWeek: 1,
      status: 'active',
    });
  });

  /** Helper: add a workout + sets for the exercise */
  async function addWorkoutWithSets(
    sets: Array<{ actualReps: number; prescribedReps: number }>
  ): Promise<string> {
    const workoutId = generateId();
    await db.completedWorkouts.add({
      id: workoutId,
      userId,
      activeCycleId: cycleId,
      programId: 'squat-program',
      week: 1,
      completedAt: new Date(),
    });
    for (let i = 0; i < sets.length; i++) {
      await db.completedSets.add({
        id: generateId(),
        workoutId,
        exerciseId,
        setNumber: i + 1,
        actualWeight: 225,
        actualReps: sets[i].actualReps,
        prescribedReps: sets[i].prescribedReps,
        createdAt: new Date(),
      });
    }
    return workoutId;
  }

  it('returns hasPlateau=false when no workouts exist', async () => {
    const result = await detectPlateauForExercise(exerciseId, cycleId);
    expect(result.hasPlateau).toBe(false);
  });

  it('returns hasPlateau=false with only 2 failed sessions (not enough)', async () => {
    // 2 sessions: both have failed reps
    await addWorkoutWithSets([{ actualReps: 3, prescribedReps: 5 }]);
    await addWorkoutWithSets([{ actualReps: 4, prescribedReps: 5 }]);

    const result = await detectPlateauForExercise(exerciseId, cycleId);
    expect(result.hasPlateau).toBe(false);
  });

  it('returns hasPlateau=true when 3 consecutive sessions all had failed reps', async () => {
    // 3 sessions: all fail
    await addWorkoutWithSets([{ actualReps: 3, prescribedReps: 5 }]);
    await addWorkoutWithSets([{ actualReps: 4, prescribedReps: 5 }]);
    await addWorkoutWithSets([{ actualReps: 4, prescribedReps: 5 }]);

    const result = await detectPlateauForExercise(exerciseId, cycleId);
    expect(result.hasPlateau).toBe(true);
    expect(result.message).toContain('3 sessions in a row');
    expect(result.recommendation).toContain('deload');
  });

  it('returns hasPlateau=false when 3 sessions but one was successful', async () => {
    // Session 1: fail, Session 2: success, Session 3: fail
    await addWorkoutWithSets([{ actualReps: 3, prescribedReps: 5 }]); // fail
    await addWorkoutWithSets([{ actualReps: 5, prescribedReps: 5 }]); // success
    await addWorkoutWithSets([{ actualReps: 4, prescribedReps: 5 }]); // fail

    const result = await detectPlateauForExercise(exerciseId, cycleId);
    expect(result.hasPlateau).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// getDeloadWeight — 10% deload rounded to nearest 5
// ---------------------------------------------------------------------------

describe('getDeloadWeight', () => {
  it('200 lbs → 180 (200 * 0.9 = 180)', () => {
    expect(getDeloadWeight(200)).toBe(180);
  });

  it('225 lbs → 205 (225 * 0.9 = 202.5 → round(40.5)*5 = 41*5 = 205)', () => {
    expect(getDeloadWeight(225)).toBe(205);
  });

  it('135 lbs → 120 (135 * 0.9 = 121.5 → round(24.3)*5 = 24*5 = 120)', () => {
    expect(getDeloadWeight(135)).toBe(120);
  });
});

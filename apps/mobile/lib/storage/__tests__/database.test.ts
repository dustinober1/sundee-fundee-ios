import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { createUser, getUser, updateUser, saveOneRepMax, getLatest1RM, saveActiveCycle, getActiveCycles } from '../database';
import { clear } from '../async-storage';
import type { User, OneRepMax, ActiveCycle } from '@/types';

describe('Database Operations', () => {
  afterEach(async () => {
    await clear();
  });

  describe('User operations', () => {
    it('should create and retrieve user', async () => {
      const user = await createUser({
        name: 'Test User',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });

      expect(user.id).toBeDefined();
      expect(user.name).toBe('Test User');
      expect(user.experienceLevel).toBe('beginner');
      expect(user.primaryGoal).toBe('strength');
      expect(user.createdAt).toBeInstanceOf(Date);

      const retrieved = await getUser();
      expect(retrieved).toEqual(user);
    });

    it('should update user', async () => {
      const user = await createUser({
        name: 'Test User',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });

      await updateUser(user.id, { name: 'Updated Name' });

      const updated = await getUser();
      expect(updated?.name).toBe('Updated Name');
      expect(updated?.id).toBe(user.id);
    });

    it('should not update user if ID does not match', async () => {
      const user = await createUser({
        name: 'Test User',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });

      await updateUser('wrong-id', { name: 'Should Not Update' });

      const notUpdated = await getUser();
      expect(notUpdated?.name).toBe('Test User');
    });

    it('should return null when no user exists', async () => {
      const user = await getUser();
      expect(user).toBeNull();
    });

    it('should create user with all fields', async () => {
      const user = await createUser({
        name: 'Advanced User',
        experienceLevel: 'advanced',
        primaryGoal: 'hypertrophy',
      });

      expect(user.experienceLevel).toBe('advanced');
      expect(user.primaryGoal).toBe('hypertrophy');
    });
  });

  describe('1RM operations', () => {
    it('should save and retrieve latest 1RM', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const old1RM: OneRepMax = {
        id: '1',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 225,
        date: new Date('2024-01-01'),
      };

      const new1RM: OneRepMax = {
        id: '2',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 235,
        date: new Date('2024-02-01'),
      };

      await saveOneRepMax(old1RM);
      await saveOneRepMax(new1RM);

      const latest = await getLatest1RM(user.id, 'back-squat');
      expect(latest?.weight).toBe(235);
      expect(latest?.id).toBe('2');
    });

    it('should return undefined when no 1RM exists', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const latest = await getLatest1RM(user.id, 'back-squat');
      expect(latest).toBeUndefined();
    });

    it('should filter 1RMs by exercise ID', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const squat1RM: OneRepMax = {
        id: '1',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 225,
        date: new Date('2024-01-01'),
      };

      const bench1RM: OneRepMax = {
        id: '2',
        userId: user.id,
        exerciseId: 'bench-press',
        weight: 185,
        date: new Date('2024-01-01'),
      };

      await saveOneRepMax(squat1RM);
      await saveOneRepMax(bench1RM);

      const squatLatest = await getLatest1RM(user.id, 'back-squat');
      const benchLatest = await getLatest1RM(user.id, 'bench-press');

      expect(squatLatest?.weight).toBe(225);
      expect(benchLatest?.weight).toBe(185);
    });

    it('should filter 1RMs by user ID', async () => {
      const user1 = await createUser({
        name: 'User 1',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const user2Id = 'user2-id';

      const user1RM: OneRepMax = {
        id: '1',
        userId: user1.id,
        exerciseId: 'back-squat',
        weight: 225,
        date: new Date('2024-01-01'),
      };

      const user2RM: OneRepMax = {
        id: '2',
        userId: user2Id,
        exerciseId: 'back-squat',
        weight: 315,
        date: new Date('2024-01-01'),
      };

      await saveOneRepMax(user1RM);
      await saveOneRepMax(user2RM);

      const latest = await getLatest1RM(user1.id, 'back-squat');
      expect(latest?.weight).toBe(225);
    });

    it('should save multiple 1RMs for the same exercise', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const first1RM: OneRepMax = {
        id: '1',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 200,
        date: new Date('2024-01-01'),
      };

      const second1RM: OneRepMax = {
        id: '2',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 210,
        date: new Date('2024-01-15'),
      };

      const third1RM: OneRepMax = {
        id: '3',
        userId: user.id,
        exerciseId: 'back-squat',
        weight: 220,
        date: new Date('2024-02-01'),
      };

      await saveOneRepMax(first1RM);
      await saveOneRepMax(second1RM);
      await saveOneRepMax(third1RM);

      const latest = await getLatest1RM(user.id, 'back-squat');
      expect(latest?.weight).toBe(220);
    });
  });

  describe('Active cycle operations', () => {
    it('should save and retrieve active cycles', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const cycle: ActiveCycle = {
        id: '1',
        userId: user.id,
        programId: 'back-squat-5x5',
        cycleName: 'My Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      await saveActiveCycle(cycle);

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(1);
      expect(activeCycles[0]).toEqual(cycle);
    });

    it('should retrieve only active cycles', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const activeCycle: ActiveCycle = {
        id: '1',
        userId: user.id,
        programId: 'back-squat-5x5',
        cycleName: 'Active Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      const completedCycle: ActiveCycle = {
        id: '2',
        userId: user.id,
        programId: 'bench-press',
        cycleName: 'Completed Cycle',
        startDate: new Date(),
        currentWeek: 8,
        status: 'completed',
      };

      const pausedCycle: ActiveCycle = {
        id: '3',
        userId: user.id,
        programId: 'deadlift',
        cycleName: 'Paused Cycle',
        startDate: new Date(),
        currentWeek: 3,
        status: 'paused',
      };

      await saveActiveCycle(activeCycle);
      await saveActiveCycle(completedCycle);
      await saveActiveCycle(pausedCycle);

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(1);
      expect(activeCycles[0].status).toBe('active');
      expect(activeCycles[0].id).toBe('1');
    });

    it('should update existing cycle', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const cycle: ActiveCycle = {
        id: '1',
        userId: user.id,
        programId: 'back-squat-5x5',
        cycleName: 'My Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      await saveActiveCycle(cycle);

      const updatedCycle: ActiveCycle = {
        ...cycle,
        currentWeek: 2,
        status: 'completed',
      };

      await saveActiveCycle(updatedCycle);

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(0); // No longer active
    });

    it('should filter cycles by user ID', async () => {
      const user1 = await createUser({
        name: 'User 1',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const user2Id = 'user2-id';

      const user1Cycle: ActiveCycle = {
        id: '1',
        userId: user1.id,
        programId: 'back-squat-5x5',
        cycleName: 'User 1 Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      const user2Cycle: ActiveCycle = {
        id: '2',
        userId: user2Id,
        programId: 'bench-press',
        cycleName: 'User 2 Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      await saveActiveCycle(user1Cycle);
      await saveActiveCycle(user2Cycle);

      const user1Cycles = await getActiveCycles(user1.id);
      expect(user1Cycles).toHaveLength(1);
      expect(user1Cycles[0].cycleName).toBe('User 1 Cycle');
    });

    it('should return empty array when no cycles exist', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(0);
    });

    it('should handle multiple active cycles for same user', async () => {
      const user = await createUser({
        name: 'Test',
        experienceLevel: 'intermediate',
        primaryGoal: 'strength',
      });

      const cycle1: ActiveCycle = {
        id: '1',
        userId: user.id,
        programId: 'back-squat-5x5',
        cycleName: 'Squat Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      const cycle2: ActiveCycle = {
        id: '2',
        userId: user.id,
        programId: 'bench-press',
        cycleName: 'Bench Cycle',
        startDate: new Date(),
        currentWeek: 1,
        status: 'active',
      };

      await saveActiveCycle(cycle1);
      await saveActiveCycle(cycle2);

      const activeCycles = await getActiveCycles(user.id);
      expect(activeCycles).toHaveLength(2);
    });
  });
});

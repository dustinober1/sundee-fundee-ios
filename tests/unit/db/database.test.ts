import { describe, it, expect, beforeEach } from 'vitest';
import { db } from '@/lib/db/dexie';
import { createUser, getUser, getActiveCycles } from '@/lib/db';

describe('Database Operations', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should create and retrieve user', async () => {
    const user = await createUser({
      name: 'Test User',
      experienceLevel: 'beginner',
      primaryGoal: 'strength'
    });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('Test User');

    const retrieved = await getUser();
    expect(retrieved).toEqual(user);
  });

  it('should return undefined when no user exists', async () => {
    const user = await getUser();
    expect(user).toBeUndefined();
  });

  it('should retrieve active cycles for user', async () => {
    const user = await createUser({
      name: 'Test User',
      experienceLevel: 'intermediate',
      primaryGoal: 'hypertrophy'
    });

    await db.activeCycles.add({
      id: 'cycle-1',
      userId: user.id,
      programId: 'back-squat-5x5',
      cycleName: 'Back Squat 5x5',
      startDate: new Date(),
      currentWeek: 1,
      status: 'active'
    });

    await db.activeCycles.add({
      id: 'cycle-2',
      userId: user.id,
      programId: 'bench-press',
      cycleName: 'Bench Press',
      startDate: new Date(),
      currentWeek: 3,
      status: 'completed'
    });

    const activeCycles = await getActiveCycles(user.id);
    expect(activeCycles).toHaveLength(1);
    expect(activeCycles[0].status).toBe('active');
  });
});

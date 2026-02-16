import { beforeEach, describe, expect, it } from 'vitest';
import { db } from '@/lib/db/dexie';
import type { ProgramV2 } from '@/types/programV2';

describe('V2 Database Schema', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should store ProgramV2 in programs table', async () => {
    const program: ProgramV2 = {
      id: 'test-v2-program',
      name: 'Test V2 Program',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [],
      weeks: [],
    };

    await db.programs.add(program);
    const retrieved = await db.programs.get('test-v2-program');

    expect(retrieved).toBeDefined();
    expect(retrieved?.sessionsPerWeek).toBe(3);
  });

  it('should have userProgramPreferences table', async () => {
    await db.userProgramPreferences.add({
      id: 'pref-1',
      userId: 'user-1',
      programId: 'back-squat-complete-cycle',
      viewMode: 'session-cards',
    });

    const preference = await db.userProgramPreferences.get('pref-1');
    expect(preference?.viewMode).toBe('session-cards');
  });
});

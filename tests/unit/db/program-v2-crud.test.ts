import { beforeEach, describe, expect, it } from 'vitest';
import { db } from '@/lib/db/dexie';
import { getCurrentSession, getProgramV2, saveProgramV2 } from '@/lib/db';
import type { ProgramV2 } from '@/types/programV2';

describe('ProgramV2 CRUD', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('should save and retrieve ProgramV2', async () => {
    const program: ProgramV2 = {
      id: 'test-program',
      name: 'Test',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [
        {
          id: 'phase-1',
          name: 'Phase 1',
          goal: 'Build muscle',
          weekRange: [1, 4],
        },
      ],
      weeks: [
        {
          week: 1,
          phaseId: 'phase-1',
          sessions: [
            {
              sessionId: 'w1-a',
              sessionName: 'Session A',
              sessionType: 'support',
              focus: 'Test',
              exercises: [],
            },
          ],
        },
      ],
    };

    await saveProgramV2(program);
    const retrieved = await getProgramV2('test-program');

    expect(retrieved).toEqual(program);
  });

  it('should get current session for active cycle', async () => {
    await saveProgramV2({
      id: 'test-program',
      name: 'Test',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [],
      weeks: [
        {
          week: 1,
          sessions: [
            {
              sessionId: 'w1-a',
              sessionName: 'Session A',
              sessionType: 'support',
              focus: 'Test',
              exercises: [],
            },
          ],
        },
      ],
    });

    const session = await getCurrentSession('test-program', 1, 'w1-a');
    expect(session?.sessionId).toBe('w1-a');
  });
});

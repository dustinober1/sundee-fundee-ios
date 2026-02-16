import { describe, expect, it } from 'vitest';
import type { ExerciseV2, ProgramV2, Session } from '@/types/programV2';

describe('ProgramV2 Types', () => {
  it('should accept valid ProgramV2 structure', () => {
    const program: ProgramV2 = {
      id: 'test-program',
      name: 'Test Program',
      category: 'back-squat',
      description: 'Test description',
      durationWeeks: 8,
      sessionsPerWeek: 3,
      difficulty: 'intermediate',
      phases: [
        {
          id: 'phase-1',
          name: 'Test Phase',
          goal: 'Test goal',
          weekRange: [1, 4],
        },
      ],
      weeks: [],
    };

    expect(program.phases[0].weekRange).toEqual([1, 4]);
  });

  it('should accept ExerciseV2 with rep range', () => {
    const exercise: ExerciseV2 = {
      exercise: 'pause-squat',
      sets: 3,
      reps: [2, 3],
      percent1RM: 0.65,
      restMinutes: 3,
    };

    expect(Array.isArray(exercise.reps)).toBe(true);
  });

  it('should accept ExerciseV2 with AMRAP reps', () => {
    const exercise: ExerciseV2 = {
      exercise: 'pause-squat',
      sets: 'AMRAP',
      reps: 'AMRAP',
      percent1RM: 0.65,
      restMinutes: 3,
    };

    expect(exercise.sets).toBe('AMRAP');
  });

  it('should accept Session with all required fields', () => {
    const session: Session = {
      sessionId: 'w1-a',
      sessionName: 'Support Session A',
      sessionType: 'support',
      focus: 'Positional Strength',
      exercises: [],
    };

    expect(session.sessionType).toBe('support');
  });
});

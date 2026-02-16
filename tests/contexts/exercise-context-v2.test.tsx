import { describe, expect, it } from 'vitest';
import { renderHook } from '@testing-library/react';
import { ExerciseProvider, useExercise } from '@/contexts/exercise-context';

describe('ExerciseContext V2', () => {
  it('returns ProgramV2 from getProgram', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider,
    });

    const program = result.current.getProgram('back-squat-complete-cycle');
    expect(program).toBeDefined();
    expect(program?.sessionsPerWeek).toBe(3);
  });

  it('gets session by ID', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider,
    });

    const session = result.current.getSession('back-squat-complete-cycle', 1, 'w1-a');
    expect(session).toBeDefined();
    expect(session?.sessionType).toBe('support');
  });

  it('returns phase for week', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider,
    });

    const phase = result.current.getPhaseForWeek('back-squat-complete-cycle', 1);
    expect(phase).toBeDefined();
    expect(phase?.name).toBe('Hypertrophy & Positional Foundation');
  });

  it('calculates phase progress', () => {
    const { result } = renderHook(() => useExercise(), {
      wrapper: ExerciseProvider,
    });

    const progress = result.current.getPhaseProgress('back-squat-complete-cycle', 1, 'phase-1');
    expect(progress).toBeGreaterThan(0);
    expect(progress).toBeLessThanOrEqual(100);
  });
});

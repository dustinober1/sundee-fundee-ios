import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { ReactNode } from 'react';
import { ExerciseProvider, useExercise } from '@/contexts/exercise-context';

describe('Exercise Context', () => {
  const wrapper = ({ children }: { children: ReactNode }) => (
    <ExerciseProvider>{children}</ExerciseProvider>
  );

  it('loads all programs', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    expect(result.current.programs.length).toBeGreaterThan(0);
  });

  it('finds program by ID', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const program = result.current.getProgram('back-squat-complete-cycle');
    expect(program).toBeDefined();
  });

  it('gets specific week', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const week = result.current.getWeek('back-squat-complete-cycle', 1);
    expect(week).toBeDefined();
    expect(week?.week).toBe(1);
    expect(week?.sessions).toHaveLength(3);
  });

  it('returns undefined for legacy day lookup on V2 data', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const day = result.current.getDay('back-squat-complete-cycle', 1, 1);
    expect(day).toBeUndefined();
  });

  it('calculates prescribed weight', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const exercise = {
      exercise: 'back-squat',
      sets: 5,
      reps: 5,
      percent1RM: 0.65
    };

    const weight = result.current.calculatePrescribedWeight(exercise, 300);
    expect(weight).toBe(195);
  });

  it('returns undefined for unknown program', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const program = result.current.getProgram('unknown-program');
    expect(program).toBeUndefined();
  });

  it('returns undefined for invalid week', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const week = result.current.getWeek('back-squat-complete-cycle', 99);
    expect(week).toBeUndefined();
  });
});

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

    const program = result.current.getProgram('back-squat-5x5-linear');
    expect(program).toBeDefined();
  });

  it('gets specific week', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const week = result.current.getWeek('back-squat-5x5-linear', 1);
    expect(week).toBeDefined();
    expect(week?.week).toBe(1);
  });

  it('gets specific day', () => {
    const { result } = renderHook(() => useExercise(), { wrapper });

    const day = result.current.getDay('back-squat-5x5-linear', 1, 1);
    expect(day).toBeDefined();
    expect(day?.day).toBe(1);
    expect(day?.exercises).toHaveLength(1);
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

    const week = result.current.getWeek('back-squat-5x5-linear', 99);
    expect(week).toBeUndefined();
  });
});

import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TestDayInterface } from '@/components/program/test-day-interface';
import type { ExerciseV2 } from '@/types/programV2';

const mockWarmupExercises: ExerciseV2[] = [
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.30, restMinutes: 2 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.50, restMinutes: 3 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.60, restMinutes: 3 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.70, restMinutes: 5 }
];

const mockWorkingSets: ExerciseV2[] = [
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.80, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.90, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 0.95, restMinutes: 5 },
  { exercise: 'back-squat', sets: 1, reps: 1, percent1RM: 1.02, restMinutes: 5, notes: 'New 1RM Attempt' }
];

describe('TestDayInterface', () => {
  it('displays warm-up section', () => {
    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Warm-up')).toBeInTheDocument();
  });

  it('displays working sets section', () => {
    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Working Sets')).toBeInTheDocument();
  });

  it('calls onComplete when test is complete', async () => {
    const user = userEvent.setup();
    const onComplete = vi.fn();

    render(
      <TestDayInterface
        warmupExercises={mockWarmupExercises}
        workingSets={mockWorkingSets}
        oneRepMax={300}
        onComplete={onComplete}
      />
    );

    for (let i = 0; i < mockWarmupExercises.length; i++) {
      await user.click(screen.getAllByRole('checkbox')[i]);
    }

    for (let i = 0; i < mockWorkingSets.length; i++) {
      await user.click(screen.getAllByRole('checkbox')[mockWarmupExercises.length + i]);
    }

    expect(onComplete).toHaveBeenCalled();
  });
});

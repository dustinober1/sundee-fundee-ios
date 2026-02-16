import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExerciseCardV2 } from '@/components/program/exercise-card-v2';
import type { ExerciseV2 } from '@/types/programV2';

const mockExercise: ExerciseV2 = {
  exercise: 'pause-squat',
  variant: 'pause',
  sets: 3,
  reps: 8,
  percent1RM: 0.65,
  restMinutes: 3
};

describe('ExerciseCardV2', () => {
  it('displays exercise name with variant', () => {
    render(
      <ExerciseCardV2
        exercise={mockExercise}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText(/Pause.*Squat/i)).toBeInTheDocument();
  });

  it('displays sets and reps', () => {
    render(
      <ExerciseCardV2
        exercise={mockExercise}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('3 sets')).toBeInTheDocument();
    expect(screen.getByText('8 reps')).toBeInTheDocument();
  });

  it('displays rep range as "2-3 reps"', () => {
    const exerciseWithRange: ExerciseV2 = {
      ...mockExercise,
      reps: [2, 3]
    };

    render(
      <ExerciseCardV2
        exercise={exerciseWithRange}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('2-3 reps')).toBeInTheDocument();
  });

  it('displays notes when present', () => {
    const exerciseWithNotes: ExerciseV2 = {
      ...mockExercise,
      notes: 'Arms extended forward'
    };

    render(
      <ExerciseCardV2
        exercise={exerciseWithNotes}
        prescribedWeight={195}
        onSetChange={() => {}}
      />
    );

    expect(screen.getByText('Arms extended forward')).toBeInTheDocument();
  });
});

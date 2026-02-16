import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { WorkoutSessionView } from '@/components/program/workout-session-view';
import type { Session } from '@/types/programV2';

const mockSession: Session = {
  sessionId: 'w1-a',
  sessionName: 'Support Session A',
  sessionType: 'support',
  focus: 'Positional Strength',
  exercises: [
    {
      exercise: 'pause-squat',
      sets: 3,
      reps: 8,
      percent1RM: 0.65,
      restMinutes: 3
    }
  ]
};

describe('WorkoutSessionView', () => {
  it('displays phase banner', () => {
    render(
      <WorkoutSessionView
        session={mockSession}
        phaseName="Hypertrophy Phase"
        phaseGoal="Build muscle"
        phaseProgress={25}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Hypertrophy Phase')).toBeInTheDocument();
  });

  it('displays session name and focus', () => {
    render(
      <WorkoutSessionView
        session={mockSession}
        phaseName="Test Phase"
        phaseGoal="Test"
        phaseProgress={0}
        oneRepMax={300}
        onComplete={() => {}}
      />
    );

    expect(screen.getByText('Support Session A')).toBeInTheDocument();
    expect(screen.getByText('Positional Strength')).toBeInTheDocument();
  });
});

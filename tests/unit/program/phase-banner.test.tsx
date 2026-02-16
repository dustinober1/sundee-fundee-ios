import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { PhaseBanner } from '@/components/program/phase-banner';

describe('PhaseBanner', () => {
  it('displays phase name and goal', () => {
    render(
      <PhaseBanner
        phaseName="Hypertrophy & Positional Foundation"
        phaseGoal="Build muscle and master the upright torso"
        progress={25}
      />
    );

    expect(screen.getByText('Hypertrophy & Positional Foundation')).toBeInTheDocument();
    expect(screen.getByText(/Build muscle/)).toBeInTheDocument();
  });

  it('shows progress percentage', () => {
    render(
      <PhaseBanner
        phaseName="Test Phase"
        phaseGoal="Test goal"
        progress={50}
      />
    );

    expect(screen.getByText('50%')).toBeInTheDocument();
  });

  it('shows progress bar at correct width', () => {
    const { container } = render(
      <PhaseBanner
        phaseName="Test Phase"
        phaseGoal="Test goal"
        progress={75}
      />
    );

    const progressBar = container.querySelector('[role="progressbar"]');
    expect(progressBar).toHaveStyle({ width: '75%' });
  });
});

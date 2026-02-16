import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { RecommendationCard } from '@/components/cycle/recommendation-card';
import type { PhaseRecommendation } from '@/types';

const recommendation: PhaseRecommendation = {
  phase: 'follicular',
  title: 'Follicular Phase',
  description: 'Energy and endurance begin to rise.',
  trainingFocus: 'Building strength and endurance',
  intensityRecommendation: 'moderate',
  exercisesToEmphasize: ['compound movements', 'strength training'],
  exercisesToAvoid: ['max effort attempts']
};

describe('RecommendationCard', () => {
  it('renders recommendation content', () => {
    render(<RecommendationCard recommendation={recommendation} />);

    expect(screen.getByText('Training Guidance')).toBeInTheDocument();
    expect(screen.getByText('Follicular Phase')).toBeInTheDocument();
    expect(screen.getByText('Energy and endurance begin to rise.')).toBeInTheDocument();
    expect(screen.getByText('Focus: Building strength and endurance')).toBeInTheDocument();
    expect(screen.getByText('Intensity: moderate')).toBeInTheDocument();
  });

  it('renders emphasize and avoid sections', () => {
    render(<RecommendationCard recommendation={recommendation} />);

    expect(screen.getByText('Focus on')).toBeInTheDocument();
    expect(screen.getByText('compound movements')).toBeInTheDocument();
    expect(screen.getByText('strength training')).toBeInTheDocument();
    expect(screen.getByText('Consider avoiding')).toBeInTheDocument();
    expect(screen.getByText('max effort attempts')).toBeInTheDocument();
  });

  it('hides optional sections when arrays are empty', () => {
    render(
      <RecommendationCard
        recommendation={{ ...recommendation, exercisesToEmphasize: [], exercisesToAvoid: [] }}
      />
    );

    expect(screen.queryByText('Focus on')).not.toBeInTheDocument();
    expect(screen.queryByText('Consider avoiding')).not.toBeInTheDocument();
  });
});

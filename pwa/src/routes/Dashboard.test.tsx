/**
 * Regression tests for Dashboard navigation routes.
 * Confirms that Start Workout and AI Workout links resolve to the
 * canonical router paths: /workout-session and /ai-workout/config.
 */
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router';

// Mock auth context
vi.mock('../auth/AuthContext', () => ({
  useSession: vi.fn(() => ({ user: null, isGuest: true })),
}));

// Mock entitlement context
vi.mock('../entitlements/EntitlementContext', () => ({
  useEntitlementContext: vi.fn(() => ({ isPremium: false })),
}));

// Mock WODRepo
vi.mock('../repositories/WODRepo', () => ({
  getWODRepo: vi.fn(() => ({
    getWODForDate: vi.fn(() => Promise.resolve(null)),
  })),
}));

// Mock OnboardingProfileRepo
vi.mock('../repositories/OnboardingProfileRepo', () => ({
  getOnboardingProfileRepo: vi.fn(() => ({
    getProfile: vi.fn(() => Promise.resolve(null)),
  })),
}));

// Mock SkeletonCard (not under test)
vi.mock('../components/SkeletonCard', () => ({
  SkeletonCard: vi.fn(() => null),
}));

import { Dashboard } from './Dashboard';

describe('Dashboard navigation routes', () => {
  it('Start Workout link navigates to /workout-session', () => {
    render(
      <MemoryRouter>
        <Dashboard />
      </MemoryRouter>,
    );

    const startWorkoutLink = screen.getByText('Start Workout').closest('a');
    expect(startWorkoutLink).toHaveAttribute('href', '/workout-session');
  });

  it('AI Workout card navigates to /ai-workout/config', async () => {
    render(
      <MemoryRouter>
        <Dashboard />
      </MemoryRouter>,
    );

    // AI Workout is inside the isLoading conditional — wait for async fetch to resolve
    const aiWorkoutLink = (await screen.findByText('AI Workout')).closest('a');
    expect(aiWorkoutLink).toHaveAttribute('href', '/ai-workout/config');
  });
});

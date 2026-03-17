/**
 * Tests for AI Workout preview screen — AdaptationChip receives correct
 * adaptation context from shared state.
 *
 * Strategy: call setSharedWorkout before rendering the preview screen, then
 * verify AdaptationChip receives the correct props by checking testID and
 * text content. Use clearSharedWorkout() in afterEach to isolate tests.
 */
import React from 'react';
import { render, waitFor } from '@testing-library/react-native';

// ─── Mock: AuthContext ────────────────────────────────────────────────────────

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: () => ({ user: { uid: 'test-uid' }, isGuest: false }),
}));

// ─── Mock: expo-router ────────────────────────────────────────────────────────

const mockRouterPush = jest.fn();
const mockRouterBack = jest.fn();
jest.mock('expo-router', () => ({
  useRouter: () => ({ push: mockRouterPush, back: mockRouterBack }),
}));

// ─── Mock: WorkoutRepo ────────────────────────────────────────────────────────

jest.mock('@/src/repositories/WorkoutRepo', () => ({
  getWorkoutRepo: () => ({ saveWorkout: jest.fn() }),
}));

// ─── Import screen and shared state AFTER all mocks ──────────────────────────

import AIWorkoutPreviewScreen from '../preview';
import { setSharedWorkout, clearSharedWorkout } from '../config';
import type { GeneratedWorkout } from '@/src/domain/ai-workout/generated-workout';
import type { WorkoutGenerationContext } from '@/src/domain/ai-workout/workout-generation-context';
import type { InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '@/src/repositories/ReadinessRepo';

// ─── Mock fixtures ────────────────────────────────────────────────────────────

const mockWorkout: GeneratedWorkout = {
  id: 'workout-1',
  createdAt: new Date('2026-03-15T10:00:00Z'),
  isFavorite: false,
  isCompleted: false,
  coachingSummary: 'Great session tailored to your cycle phase.',
  exercises: [
    {
      id: 'ex-1',
      name: 'Barbell Squat',
      sets: 3,
      reps: '8-10',
      weightLb: 135,
      restMinutes: 2,
      notes: null,
      reasoning: null,
      bodyweightOnly: false,
    },
    {
      id: 'ex-2',
      name: 'Romanian Deadlift',
      sets: 3,
      reps: '10-12',
      weightLb: 95,
      restMinutes: 90,
      notes: null,
      reasoning: null,
      bodyweightOnly: false,
    },
  ],
  questionnaire: {
    timeMinutes: 45,
    focus: 'lower_body',
    energyLevel: 'medium',
    equipment: 'full_gym',
    desiredSkills: null,
  },
};

const mockContext: WorkoutGenerationContext = {
  userID: 'test-uid',
  timeMinutes: 45,
  focus: 'lower_body',
  energyLevel: 'medium',
  equipment: 'full_gym',
  maxes: [],
  recentWorkouts: [],
  cyclePhase: 'luteal',
  readinessTier: 'neutral',
  activeInjuries: [{ location: 'Left Shoulder', phase: 'acute', restrictions: [] }],
  experienceLevel: 'intermediate',
  primaryGoal: 'general_fitness',
  gender: 'female',
  weightUnit: 'lb',
  desiredSkills: [],
  benchmarkSummaries: [],
  bodyWeightKg: null,
  recentPainActivity: [],
  workoutCompletionRate: null,
  travelModeEnabled: false,
};

const mockInjury: InjuryProfileRecord = {
  id: 'inj-1',
  uid: 'test-uid',
  bodyLocation: 'leftShoulder',
  location: 'Left Shoulder',
  recoveryPhase: 'acute',
  notes: '',
  createdAt: '2026-01-01',
  updatedAt: '2026-01-01',
  injuryDate: '2026-01-01',
  painLogs: [],
};

const mockReadiness: ReadinessSurveyRecord = {
  id: 'r-1',
  uid: 'test-uid',
  date: '2026-03-15',
  result: {
    score: 0.7,
    tier: 'neutral',
    sleep: 7,
    energy: 6,
    stress: 4,
    soreness: 5,
  },
};

// ─── Tests ───────────────────────────────────────────────────────────────────

afterEach(() => {
  clearSharedWorkout();
  jest.clearAllMocks();
});

describe('AIWorkoutPreviewScreen — AdaptationChip receives adaptation context', () => {
  it('renders AdaptationChip with cycle phase, injury location, and readiness when all present', async () => {
    setSharedWorkout(mockWorkout, false, mockContext, 'luteal', [mockInjury], mockReadiness);

    const { getByTestId, getByText } = render(<AIWorkoutPreviewScreen />);

    await waitFor(() => {
      expect(getByTestId('adaptation-chip')).toBeTruthy();
    });

    // Chip text includes cycle phase, injury location, and readiness score
    expect(getByText(/Luteal phase/)).toBeTruthy();
    expect(getByText(/Left Shoulder/)).toBeTruthy();
    expect(getByText(/Readiness 7\/10/)).toBeTruthy();
  });

  it('does not render AdaptationChip when no adaptation context exists', async () => {
    setSharedWorkout(mockWorkout, false, mockContext, undefined, [], null);

    const { queryByTestId } = render(<AIWorkoutPreviewScreen />);

    await waitFor(() => {
      expect(queryByTestId('start-workout-button')).toBeTruthy();
    });

    expect(queryByTestId('adaptation-chip')).toBeNull();
  });

  it('renders AdaptationChip with cycle phase only when no injuries or readiness', async () => {
    setSharedWorkout(mockWorkout, false, mockContext, 'follicular', [], null);

    const { getByTestId, getByText } = render(<AIWorkoutPreviewScreen />);

    await waitFor(() => {
      expect(getByTestId('adaptation-chip')).toBeTruthy();
    });

    expect(getByText(/Follicular phase/)).toBeTruthy();
  });

  it('shows empty state when no shared workout exists', async () => {
    clearSharedWorkout();

    const { getByText } = render(<AIWorkoutPreviewScreen />);

    await waitFor(() => {
      expect(getByText('No workout generated yet.')).toBeTruthy();
    });
  });
});

/**
 * Tests for WorkoutDetailScreen weight unit rendering.
 *
 * Verifies that CompletedExerciseSection, AIExerciseSection, and the Volume
 * MetaStat all respect the user's weightUnit preference (lb vs kg) rather
 * than hardcoding " lbs".
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports
// ---------------------------------------------------------------------------

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: jest.fn(),
}));

jest.mock('expo-router', () => ({
  useLocalSearchParams: jest.fn(),
  useRouter: jest.fn(),
}));

jest.mock('@/src/repositories/WorkoutRepo', () => ({
  getWorkoutRepo: jest.fn(),
}));

jest.mock('@/src/repositories/SettingsRepo', () => ({
  getSettingsRepo: jest.fn(),
}));

jest.mock('@/src/components/history/HistoryCard', () => ({
  formatDuration: jest.fn(() => '1h 0m'),
}));

jest.mock('@/src/theme/colors', () => ({
  CREAM: '#F4F0DF',
  CREAM_LIGHT: '#FAF7EE',
  NAVY: '#0D1A40',
  NAVY_MEDIUM: '#3A4A6B',
  ORANGE: '#F2731A',
  ORANGE_LIGHT: '#FDE8D5',
  ORANGE_DARK: '#C45A10',
  RED: '#DC2626',
}));

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import React from 'react';
import { render, screen, waitFor } from '@testing-library/react-native';
import { useSession } from '@/src/auth/AuthContext';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import { getSettingsRepo } from '@/src/repositories/SettingsRepo';
import WorkoutDetailScreen from '../workout-detail';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const mockUser = { uid: 'user1' };

function buildCompletedWorkoutRecord() {
  return {
    id: 'w1',
    uid: 'user1',
    completedAt: '2024-06-15T10:00:00Z',
    durationSeconds: 3600,
    source: 'custom' as const,
    workoutName: 'Morning Lift',
    totalVolume: 1000,
    exercises: [
      {
        exerciseId: 'squat',
        exerciseName: 'Squat',
        muscleGroup: 'Legs',
        sets: [
          { weight: 132.3, reps: 5, isPersonalRecord: false, completed: true },
          { weight: 0, reps: 5, isPersonalRecord: false, completed: true },
        ],
      },
    ],
  };
}

function buildAiWorkoutRecord() {
  return {
    id: 'w2',
    uid: 'user1',
    completedAt: '2024-06-15T10:00:00Z',
    durationSeconds: 3600,
    source: 'ai' as const,
    workoutName: 'AI Workout',
    exercises: [],
    workout: {
      exercises: [
        {
          id: 'e1',
          name: 'Deadlift',
          sets: 3,
          reps: '5',
          weightLb: 220,
          bodyweightOnly: false,
          notes: null,
        },
      ],
    },
  };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function setupMocks({
  weightUnit = 'lb' as 'lb' | 'kg',
  record = buildCompletedWorkoutRecord() as unknown,
}: {
  weightUnit?: 'lb' | 'kg';
  record?: unknown;
} = {}) {
  (useSession as jest.Mock).mockReturnValue({ user: mockUser, isGuest: false });
  (useLocalSearchParams as jest.Mock).mockReturnValue({ workoutId: 'w1' });
  (useRouter as jest.Mock).mockReturnValue({ back: jest.fn() });

  const mockGetWorkout = jest.fn().mockResolvedValue(record);
  (getWorkoutRepo as jest.Mock).mockReturnValue({ getWorkout: mockGetWorkout });

  const mockGetSettings = jest.fn().mockResolvedValue({
    weightUnit,
    notificationsEnabled: true,
    defaultRestDuration: 90,
  });
  (getSettingsRepo as jest.Mock).mockReturnValue({ getSettings: mockGetSettings });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('WorkoutDetailScreen — weight unit rendering', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('Test 1: CompletedExerciseSection renders weight with "kg" suffix when weightUnit is kg', async () => {
    setupMocks({ weightUnit: 'kg' });
    render(<WorkoutDetailScreen />);

    // 132.3 lbs = 60.0 kg (nearest 0.5 kg)
    await waitFor(() => {
      expect(screen.getByText('60.0 kg')).toBeTruthy();
    });
  });

  it('Test 2: CompletedExerciseSection renders weight with "lbs" suffix when weightUnit is lb', async () => {
    setupMocks({ weightUnit: 'lb' });
    render(<WorkoutDetailScreen />);

    await waitFor(() => {
      expect(screen.getByText('132.3 lbs')).toBeTruthy();
    });
  });

  it('Test 3: AIExerciseSection renders weightLb converted to kg when weightUnit is kg', async () => {
    setupMocks({ weightUnit: 'kg', record: buildAiWorkoutRecord() });
    render(<WorkoutDetailScreen />);

    // 220 lbs = 99.8 kg → nearest 0.5 = 100.0 kg
    await waitFor(() => {
      expect(screen.getByText(/100\.0 kg/)).toBeTruthy();
    });
  });

  it('Test 4: MetaStat Volume uses formatWeight (shows kg when unit is kg)', async () => {
    setupMocks({ weightUnit: 'kg' });
    render(<WorkoutDetailScreen />);

    // Volume is 1000 lbs → 453.6 kg → nearest 0.5 = 453.5 kg
    await waitFor(() => {
      expect(screen.getByText(/453\.5 kg/)).toBeTruthy();
    });
  });

  it('Test 5: Zero-weight sets render as dash regardless of unit', async () => {
    setupMocks({ weightUnit: 'kg' });
    render(<WorkoutDetailScreen />);

    // The zero-weight set should show a dash, not "0 kg" or "0 lbs"
    await waitFor(() => {
      expect(screen.getAllByText('—').length).toBeGreaterThan(0);
    });
  });
});

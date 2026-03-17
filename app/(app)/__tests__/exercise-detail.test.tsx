/**
 * exercise-detail.test.tsx — Tests for ExerciseDetailScreen weight unit rendering.
 *
 * Verifies that PR badge value, chart yLabels, and RepRangePRTable all
 * respect the user's weightUnit preference (lb vs kg).
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

jest.mock('@/src/repositories/ExerciseMaxRepo', () => ({
  getExerciseMaxRepo: jest.fn(),
}));

jest.mock('@/src/repositories/WorkoutRepo', () => ({
  getWorkoutRepo: jest.fn(),
}));

jest.mock('@/src/repositories/SettingsRepo', () => ({
  getSettingsRepo: jest.fn(),
  DEFAULT_SETTINGS: { weightUnit: 'lb', notificationsEnabled: true, defaultRestDuration: 90 },
}));

// Mock react-native-gifted-charts (used by ProgressChart)
jest.mock('react-native-gifted-charts', () => ({
  LineChart: jest.fn(({ yAxisLabelTexts }) => {
    const React = require('react');
    const { Text, View } = require('react-native');
    return React.createElement(View, null,
      React.createElement(Text, { testID: 'chart-yaxis' }, yAxisLabelTexts ? yAxisLabelTexts[0] : '')
    );
  }),
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
  GREY: '#9CA3AF',
}));

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import React from 'react';
import { render, screen, waitFor } from '@testing-library/react-native';
import { useSession } from '@/src/auth/AuthContext';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import { getSettingsRepo } from '@/src/repositories/SettingsRepo';
import ExerciseDetailScreen from '../exercise-detail';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const mockUser = { uid: 'user1' };

function buildExerciseMax() {
  return {
    id: 'em1',
    exerciseId: 'squat',
    repRange: 1,
    weight: 225,
    estimatedOneRepMax: 225,
    achievedAt: '2026-01-01',
    uid: 'user1',
  };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function setupMocks({ weightUnit = 'lb' as 'lb' | 'kg' } = {}) {
  (useSession as jest.Mock).mockReturnValue({ user: mockUser, isGuest: false });
  (useLocalSearchParams as jest.Mock).mockReturnValue({
    exerciseId: 'squat',
    exerciseName: 'Squat',
  });
  (useRouter as jest.Mock).mockReturnValue({ back: jest.fn() });

  const mockGetMaxes = jest.fn().mockResolvedValue([buildExerciseMax()]);
  (getExerciseMaxRepo as jest.Mock).mockReturnValue({ getMaxes: mockGetMaxes });

  const mockGetHistory = jest.fn().mockResolvedValue([]);
  (getWorkoutRepo as jest.Mock).mockReturnValue({ getHistory: mockGetHistory });

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

describe('ExerciseDetailScreen — weight unit rendering', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('Test 1: PR badge shows lbs when weightUnit is lb', async () => {
    setupMocks({ weightUnit: 'lb' });
    render(<ExerciseDetailScreen />);

    await waitFor(() => {
      // 225 lbs -> "225.0 lbs" — appears in PR badge and RepRangePRTable
      expect(screen.getAllByText('225.0 lbs').length).toBeGreaterThanOrEqual(1);
    });
  });

  it('Test 2: PR badge shows kg when weightUnit is kg', async () => {
    setupMocks({ weightUnit: 'kg' });
    render(<ExerciseDetailScreen />);

    await waitFor(() => {
      // 225 lbs = 102.058... kg -> nearest 0.5 = 102.0 kg (round(102.058*2)/2 = round(204.116)/2 = 204/2 = 102.0)
      // appears in PR badge and RepRangePRTable
      expect(screen.getAllByText('102.0 kg').length).toBeGreaterThanOrEqual(1);
    });
  });

  it('Test 3: 1RM chart yLabel says "kg (estimated)" when weightUnit is kg', async () => {
    setupMocks({ weightUnit: 'kg' });
    render(<ExerciseDetailScreen />);

    await waitFor(() => {
      expect(screen.getByText('kg (estimated)')).toBeTruthy();
    });
  });

  it('Test 4: 1RM chart yLabel says "lbs (estimated)" when weightUnit is lb', async () => {
    setupMocks({ weightUnit: 'lb' });
    render(<ExerciseDetailScreen />);

    await waitFor(() => {
      expect(screen.getByText('lbs (estimated)')).toBeTruthy();
    });
  });
});

/**
 * Tests for ExerciseRow weight unit rendering in ProgramSessionScreen.
 *
 * Verifies that ExerciseRow uses the user's weightUnit preference when
 * displaying target weights — both for percentage-based and range-based
 * exercise weights.
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports
// ---------------------------------------------------------------------------

const mockFormatTargetWeight = jest.fn((weight: number | null, percentage: number, unit?: string) => {
  if (weight === null) return `${Math.round(percentage * 100)}%`;
  return unit === 'kg' ? `${weight} kg-display` : `${weight} lbs-display`;
});

const mockFormatWeight = jest.fn((lbs: number, unit: string) => {
  return unit === 'kg' ? `${lbs} kg-display` : `${lbs} lbs-display`;
});

jest.mock('@/src/components/programs/target-weight', () => ({
  calculateTargetWeight: jest.fn((name: string, pct: number) => {
    // Return a value proportional to percentage for range tests
    if (name === 'Back Squat') return Math.round(300 * pct);
    return null;
  }),
  formatTargetWeight: mockFormatTargetWeight,
}));

jest.mock('@/src/utils/formatWeight', () => ({
  formatWeight: mockFormatWeight,
}));

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: jest.fn(),
}));

jest.mock('expo-router', () => ({
  useFocusEffect: jest.fn(),
  useRouter: jest.fn(),
}));

jest.mock('@/src/repositories/ProgramRepo', () => ({
  getProgramRepo: jest.fn(),
}));

jest.mock('@/src/repositories/ExerciseMaxRepo', () => ({
  getExerciseMaxRepo: jest.fn(),
}));

jest.mock('@/src/repositories/WorkoutRepo', () => ({
  getWorkoutRepo: jest.fn(),
}));

jest.mock('@/src/repositories/SettingsRepo', () => ({
  getSettingsRepo: jest.fn(),
  DEFAULT_SETTINGS: { weightUnit: 'lb' },
}));

jest.mock('@/src/theme/colors', () => ({
  CREAM: '#F4F0DF',
  CREAM_LIGHT: '#FAF7EE',
  NAVY: '#0D1A40',
  NAVY_MEDIUM: '#3A4A6B',
  ORANGE: '#F2731A',
  ORANGE_LIGHT: '#FDE8D5',
  ORANGE_DARK: '#C45A10',
  GREY: '#888888',
  GREY_LIGHT: '#CCCCCC',
}));

// ---------------------------------------------------------------------------
// Imports (after mocks)
// ---------------------------------------------------------------------------

import React from 'react';
import { render } from '@testing-library/react-native';
import { ExerciseRow } from '../session';
import type { ProgramExercise } from '@/src/domain/types/index';
import type { ExerciseMax } from '@/src/domain/pr-detection/pr-types';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const percentageExercise: ProgramExercise = {
  id: 'e1',
  name: 'Back Squat',
  sets: 3,
  reps: { kind: 'fixed', value: 5 },
  weight: { kind: 'fixed', value: 0.75 }, // 75% of 1RM
};

const rangeExercise: ProgramExercise = {
  id: 'e2',
  name: 'Back Squat',
  sets: 3,
  reps: { kind: 'fixed', value: 5 },
  weight: { kind: 'range', lo: 0.70, hi: 0.80 }, // 70-80% of 1RM
};

const squat1RM: ExerciseMax = {
  exerciseId: 'back-squat',
  exerciseName: 'Back Squat',
  repRange: 1,
  weight: 300,
  estimated1RM: 300,
  achievedAt: '2026-01-01',
};

const maxes: ExerciseMax[] = [squat1RM];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('ExerciseRow weight unit rendering', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders target weight in lbs when weightUnit is lb', () => {
    render(<ExerciseRow exercise={percentageExercise} maxes={maxes} weightUnit="lb" />);
    expect(mockFormatTargetWeight).toHaveBeenCalledWith(
      expect.any(Number),
      0.75,
      'lb'
    );
  });

  it('renders target weight in kg when weightUnit is kg', () => {
    render(<ExerciseRow exercise={percentageExercise} maxes={maxes} weightUnit="kg" />);
    expect(mockFormatTargetWeight).toHaveBeenCalledWith(
      expect.any(Number),
      0.75,
      'kg'
    );
  });

  it('renders weight range in lbs when weightUnit is lb', () => {
    render(<ExerciseRow exercise={rangeExercise} maxes={maxes} weightUnit="lb" />);
    // formatWeight should be called with unit='lb' for range display
    expect(mockFormatWeight).toHaveBeenCalledWith(expect.any(Number), 'lb');
  });

  it('renders weight range in kg when weightUnit is kg', () => {
    render(<ExerciseRow exercise={rangeExercise} maxes={maxes} weightUnit="kg" />);
    // formatWeight should be called with unit='kg' for range display
    expect(mockFormatWeight).toHaveBeenCalledWith(expect.any(Number), 'kg');
  });
});

/**
 * Tests for AI Workout config screen — profile wiring, settings wiring,
 * maxes mapping, recentWorkouts mapping, and fallback behavior.
 *
 * Strategy: render the screen, wait for loadAdaptationContext to complete,
 * press "Generate Workout", and inspect the WorkoutGenerationContext captured
 * in the shared workout state (set via setSharedWorkout before navigation).
 *
 * Note: callGenerateWorkoutFunction uses a dynamic import() which Jest in
 * CommonJS mode does not transform. We mock generateOfflineWorkout to capture
 * the context passed to it (offline fallback path), which receives the same
 * WorkoutGenerationContext regardless of online/offline path.
 */
import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';
import { Alert } from 'react-native';

// ─── Mock: AuthContext ────────────────────────────────────────────────────────

const mockUseSession = jest.fn();
jest.mock('@/src/auth/AuthContext', () => ({
  useSession: () => mockUseSession(),
}));

// ─── Mock: EntitlementContext ─────────────────────────────────────────────────

const mockUseEntitlementContext = jest.fn();
jest.mock('@/src/entitlements/EntitlementContext', () => ({
  useEntitlementContext: () => mockUseEntitlementContext(),
}));

// ─── Mock: expo-router ────────────────────────────────────────────────────────

const mockRouterPush = jest.fn();
jest.mock('expo-router', () => ({
  useRouter: () => ({ push: mockRouterPush }),
}));

// ─── Mock: expo-network (offline — ensures generateOfflineWorkout is called) ──
// Using offline mode so we avoid the dynamic import() for callCloudFunction.

jest.mock('expo-network', () => ({
  getNetworkStateAsync: jest.fn().mockResolvedValue({
    isConnected: false,
    isInternetReachable: false,
  }),
}));

// ─── Mock: generateOfflineWorkout — capture the context passed to it ──────────

const mockCapturedContexts: unknown[] = [];
jest.mock('@/src/domain/ai-workout/offline-workout-generator', () => ({
  generateOfflineWorkout: jest.fn((ctx: unknown) => {
    mockCapturedContexts.push(ctx);
    return {
      id: 'offline-1',
      createdAt: new Date(),
      isFavorite: false,
      isCompleted: false,
      coachingSummary: 'Offline workout',
      exercises: [],
      questionnaire: { timeMinutes: 30, focus: 'full_body', energyLevel: 'medium', equipment: 'full_gym', desiredSkills: null },
    };
  }),
}));

// ─── Mock: OnboardingProfileRepo ─────────────────────────────────────────────

const mockGetProfile = jest.fn();
jest.mock('@/src/repositories/OnboardingProfileRepo', () => ({
  getOnboardingProfileRepo: () => ({ getProfile: mockGetProfile }),
}));

// ─── Mock: SettingsRepo ───────────────────────────────────────────────────────

const mockGetSettings = jest.fn();
jest.mock('@/src/repositories/SettingsRepo', () => ({
  getSettingsRepo: () => ({ getSettings: mockGetSettings }),
}));

// ─── Mock: ExerciseMaxRepo ────────────────────────────────────────────────────

const mockGetAllMaxes = jest.fn();
jest.mock('@/src/repositories/ExerciseMaxRepo', () => ({
  getExerciseMaxRepo: () => ({ getAllMaxes: mockGetAllMaxes }),
}));

// ─── Mock: WorkoutRepo ────────────────────────────────────────────────────────

const mockGetHistory = jest.fn();
jest.mock('@/src/repositories/WorkoutRepo', () => ({
  getWorkoutRepo: () => ({ getHistory: mockGetHistory }),
}));

// ─── Mock: CycleRepo ─────────────────────────────────────────────────────────

jest.mock('@/src/repositories/CycleRepo', () => ({
  getCycleRepo: () => ({
    getPeriodLogs: jest.fn().mockResolvedValue([]),
    getCycleSettings: jest.fn().mockResolvedValue(null),
  }),
  recordToPeriodLog: jest.fn((r: unknown) => r),
}));

// ─── Mock: InjuryRepo ────────────────────────────────────────────────────────

jest.mock('@/src/repositories/InjuryRepo', () => ({
  getInjuryRepo: () => ({
    getInjuries: jest.fn().mockResolvedValue([]),
  }),
}));

// ─── Mock: ReadinessRepo ─────────────────────────────────────────────────────

jest.mock('@/src/repositories/ReadinessRepo', () => ({
  getReadinessRepo: () => ({
    getSurveyForDate: jest.fn().mockResolvedValue(null),
  }),
}));

// ─── Mock: PaywallModal ───────────────────────────────────────────────────────

jest.mock('@/src/components/paywall/PaywallModal', () => ({
  PaywallModal: () => null,
}));

// ─── Mock: AdaptationChip ────────────────────────────────────────────────────

jest.mock('@/src/components/ai-workout/AdaptationChip', () => ({
  AdaptationChip: () => null,
}));

// ─── Mock: ConfigCards ────────────────────────────────────────────────────────

jest.mock('@/src/components/ai-workout/ConfigCards', () => ({
  ConfigCards: () => null,
}));

// ─── Alert mock ───────────────────────────────────────────────────────────────

jest.spyOn(Alert, 'alert').mockImplementation(jest.fn());

// ─── Import screen AFTER all mocks ───────────────────────────────────────────

import AIWorkoutConfigScreen, { injuryToSummary } from '../config';
import { generateOfflineWorkout } from '@/src/domain/ai-workout/offline-workout-generator';

// ─── Helpers ─────────────────────────────────────────────────────────────────

const premiumSession = {
  user: { uid: 'user-123', displayName: 'Test User', email: 'test@example.com', isAnonymous: false },
  isLoading: false,
  isGuest: false,
  signOut: jest.fn(),
};

const premiumEntitlements = { isPremium: true, isLoading: false };

function setupDefaultMocks(): void {
  mockCapturedContexts.length = 0;
  mockUseSession.mockReturnValue(premiumSession);
  mockUseEntitlementContext.mockReturnValue(premiumEntitlements);
  mockGetProfile.mockResolvedValue(null);
  mockGetSettings.mockResolvedValue(null);
  mockGetAllMaxes.mockResolvedValue([]);
  mockGetHistory.mockResolvedValue([]);
}

/**
 * Renders the config screen, waits for the adaptation context to load,
 * then presses "Generate Workout" and waits for generateOfflineWorkout to
 * be called (which captures the WorkoutGenerationContext).
 */
async function renderAndGenerate(): Promise<unknown> {
  const { getByTestId } = render(<AIWorkoutConfigScreen />);

  // Wait for all async loads in loadAdaptationContext to complete
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 50));
  });

  await waitFor(() => {
    expect(getByTestId('generate-workout-button')).toBeTruthy();
  });

  await act(async () => {
    fireEvent.press(getByTestId('generate-workout-button'));
  });

  await waitFor(() => {
    expect(generateOfflineWorkout).toHaveBeenCalled();
  });

  // Return the most recently captured context
  return mockCapturedContexts[mockCapturedContexts.length - 1];
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('AIWorkoutConfigScreen — profile wiring', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCapturedContexts.length = 0;
    setupDefaultMocks();
  });

  it('passes real gender, experienceLevel, primaryGoal from profile into context', async () => {
    mockGetProfile.mockResolvedValue({
      gender: 'male',
      experienceLevel: 'advanced',
      primaryGoal: 'strength',
      cycleOptIn: false,
    });

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.gender).toBe('male');
    expect(context.experienceLevel).toBe('advanced');
    expect(context.primaryGoal).toBe('strength');
  });

  it('uses fallback values when profile is null', async () => {
    mockGetProfile.mockResolvedValue(null);

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.gender).toBe('female');
    expect(context.experienceLevel).toBe('intermediate');
    expect(context.primaryGoal).toBe('general_fitness');
  });
});

describe('AIWorkoutConfigScreen — settings wiring', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCapturedContexts.length = 0;
    setupDefaultMocks();
  });

  it('passes real weightUnit from settings into context', async () => {
    mockGetSettings.mockResolvedValue({ weightUnit: 'kg', notificationsEnabled: true, defaultRestDuration: 90 });

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.weightUnit).toBe('kg');
  });

  it('defaults weightUnit to lb when settings is null', async () => {
    mockGetSettings.mockResolvedValue(null);

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.weightUnit).toBe('lb');
  });
});

describe('AIWorkoutConfigScreen — exercise maxes mapping', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCapturedContexts.length = 0;
    setupDefaultMocks();
  });

  it('maps exercise maxes as { name: exerciseId, weightLb: weight }', async () => {
    mockGetAllMaxes.mockResolvedValue([
      { exerciseId: 'barbell-squat', exerciseName: 'Barbell Back Squat', repRange: 1, weight: 225, estimated1RM: 225, achievedAt: '2026-01-01' },
      { exerciseId: 'bench-press', exerciseName: 'Bench Press', repRange: 5, weight: 185, estimated1RM: 210, achievedAt: '2026-01-02' },
    ]);

    const context = await renderAndGenerate() as Record<string, unknown>;
    const maxes = context.maxes as Array<{ name: string; weightLb: number }>;
    expect(maxes).toHaveLength(2);
    expect(maxes[0]).toEqual({ name: 'barbell-squat', weightLb: 225 });
    expect(maxes[1]).toEqual({ name: 'bench-press', weightLb: 185 });
  });

  it('passes empty maxes array when no maxes exist', async () => {
    mockGetAllMaxes.mockResolvedValue([]);

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.maxes).toEqual([]);
  });
});

describe('AIWorkoutConfigScreen — recent workouts mapping', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockCapturedContexts.length = 0;
    setupDefaultMocks();
  });

  it('maps recent custom/program workouts to recentWorkouts with correct shape', async () => {
    mockGetHistory.mockResolvedValue([
      {
        id: 'w1',
        uid: 'user-123',
        completedAt: '2026-03-10T10:00:00Z',
        durationSeconds: 2700,
        source: 'custom',
        exercises: [
          { exerciseId: 'squat', exerciseName: 'Squat', muscleGroup: 'legs', sets: [] },
          { exerciseId: 'deadlift', exerciseName: 'Deadlift', muscleGroup: 'back', sets: [] },
        ],
      },
    ]);

    const context = await renderAndGenerate() as Record<string, unknown>;
    const rws = context.recentWorkouts as Array<{ date: Date; durationMinutes: number; exercises: string[]; focus: string }>;
    expect(rws).toHaveLength(1);
    expect(rws[0].date).toBeInstanceOf(Date);
    expect(rws[0].durationMinutes).toBe(45); // 2700 / 60
    expect(rws[0].exercises).toEqual(['Squat', 'Deadlift']);
  });

  it('maps AI workout exercises from workout.exercises[].name and focus from questionnaire', async () => {
    mockGetHistory.mockResolvedValue([
      {
        id: 'w2',
        uid: 'user-123',
        completedAt: '2026-03-11T08:00:00Z',
        durationSeconds: 1800,
        source: 'ai',
        workout: {
          id: 'gen-99',
          createdAt: new Date(),
          isFavorite: false,
          isCompleted: true,
          coachingSummary: 'Great session',
          exercises: [
            { id: 'e1', name: 'Overhead Press', sets: 3, reps: '8-10', weightLb: 65, restMinutes: 2, notes: null, reasoning: null, bodyweightOnly: false },
          ],
          questionnaire: { timeMinutes: 30, focus: 'upper_body', energyLevel: 'high', equipment: 'full_gym', desiredSkills: null },
        },
      },
    ]);

    const context = await renderAndGenerate() as Record<string, unknown>;
    const rws = context.recentWorkouts as Array<{ exercises: string[]; focus: string }>;
    expect(rws).toHaveLength(1);
    expect(rws[0].exercises).toEqual(['Overhead Press']);
    expect(rws[0].focus).toBe('upper_body');
  });

  it('limits recent workouts to 5 even when more are returned', async () => {
    const makeRecord = (i: number) => ({
      id: `w${i}`,
      uid: 'user-123',
      completedAt: `2026-03-${String(i).padStart(2, '0')}T10:00:00Z`,
      durationSeconds: 1800,
      source: 'custom' as const,
      exercises: [],
    });

    mockGetHistory.mockResolvedValue([1, 2, 3, 4, 5, 6, 7].map(makeRecord));

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect((context.recentWorkouts as unknown[]).length).toBe(5);
  });

  it('passes empty recentWorkouts when history is empty', async () => {
    mockGetHistory.mockResolvedValue([]);

    const context = await renderAndGenerate() as Record<string, unknown>;
    expect(context.recentWorkouts).toEqual([]);
  });
});

describe('injuryToSummary helper', () => {
  it('maps location from location field when present', () => {
    const record = {
      id: 'inj-1',
      uid: 'user-123',
      bodyLocation: 'knee',
      location: 'left knee',
      recoveryPhase: 'active_recovery' as const,
      notes: '',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    };
    const summary = injuryToSummary(record);
    expect(summary.location).toBe('left knee');
    expect(summary.phase).toBe('active_recovery');
    expect(summary.restrictions).toEqual([]);
  });

  it('falls back to bodyLocation when location is not present', () => {
    const record = {
      id: 'inj-2',
      uid: 'user-123',
      bodyLocation: 'shoulder',
      recoveryPhase: 'pain_management' as const,
      notes: '',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    };
    const summary = injuryToSummary(record as Parameters<typeof injuryToSummary>[0]);
    expect(summary.location).toBe('shoulder');
  });
});

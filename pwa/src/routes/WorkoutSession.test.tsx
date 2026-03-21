/**
 * Component tests for WorkoutSessionScreen.
 * Verifies the session renders and the Finish button is present and calls saveWorkout.
 *
 * Mocking notes: WorkoutSession has many dependencies (auth, repos, notifications,
 * install prompt). All are mocked here so the component can render in jsdom.
 */
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('react-router', () => ({
  useNavigate: vi.fn(),
}));

vi.mock('../auth/AuthContext', () => ({
  useSession: vi.fn(),
}));

const mockSaveWorkout = vi.fn().mockResolvedValue(undefined);
vi.mock('../repositories/WorkoutRepo', () => ({
  getWorkoutRepo: vi.fn(() => ({
    saveWorkout: mockSaveWorkout,
    getWorkouts: vi.fn().mockResolvedValue([]),
  })),
}));

vi.mock('../repositories/ExerciseMaxRepo', () => ({
  getExerciseMaxRepo: vi.fn(() => ({
    getMaxes: vi.fn().mockResolvedValue([]),
    saveMax: vi.fn().mockResolvedValue(undefined),
  })),
}));

vi.mock('../repositories/SettingsRepo', () => ({
  getSettingsRepo: vi.fn(() => ({
    getSettings: vi.fn().mockResolvedValue(null),
  })),
  DEFAULT_SETTINGS: {
    weightUnit: 'lb',
    defaultRestDuration: 90,
    restTimerAlertsEnabled: true,
    workoutRemindersEnabled: false,
    wodAlertsEnabled: true,
    subscriptionAlertsEnabled: true,
    reminderHour: 7,
    reminderMinute: 0,
  },
}));

vi.mock('../hooks/useInstallPrompt', () => ({
  useInstallPrompt: vi.fn(() => ({
    androidPrompt: null,
    isIOS: false,
    isStandalone: false,
    isDismissed: false,
    showPrompt: false,
    triggerAndroid: vi.fn(),
    dismiss: vi.fn(),
  })),
}));

vi.mock('../notifications/web-push', () => ({
  scheduleNotification: vi.fn(() => 0),
  requestNotificationPermission: vi.fn().mockResolvedValue('denied'),
  showLocalNotification: vi.fn().mockResolvedValue(undefined),
  isNotificationSupported: vi.fn(() => false),
}));

import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { WorkoutSessionScreen } from './WorkoutSession';

// Provide a functional localStorage mock (jsdom in this environment lacks it)
const localStorageStore: Record<string, string> = {};
const localStorageMock = {
  getItem: (key: string) => localStorageStore[key] ?? null,
  setItem: (key: string, value: string) => { localStorageStore[key] = value; },
  removeItem: (key: string) => { delete localStorageStore[key]; },
  clear: () => { Object.keys(localStorageStore).forEach((k) => delete localStorageStore[k]); },
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock, writable: true });

const mockNavigate = vi.fn();

beforeEach(() => {
  vi.clearAllMocks();
  localStorageMock.clear();
  (useNavigate as ReturnType<typeof vi.fn>).mockReturnValue(mockNavigate);
  (useSession as ReturnType<typeof vi.fn>).mockReturnValue({
    user: { uid: 'test-uid', email: 'test@example.com', emailVerified: true, isAnonymous: false },
    isGuest: false,
    isLoading: false,
    signOut: vi.fn(),
  });
});

describe('WorkoutSessionScreen', () => {
  it('renders the workout session UI with elapsed timer and Finish button', async () => {
    render(<WorkoutSessionScreen />);

    // The session must load asynchronously (useEffect), wait for Finish button
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /finish/i })).toBeInTheDocument();
    });

    // Elapsed timer rendered (format: 0:00)
    expect(screen.getByText(/0:0/)).toBeInTheDocument();
  });

  it('renders the Add Exercise button in the empty state', async () => {
    render(<WorkoutSessionScreen />);

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /\+ add exercise/i })).toBeInTheDocument();
    });
  });

  it('calls saveWorkout and navigates home when Finish is clicked with an empty session', async () => {
    render(<WorkoutSessionScreen />);

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /finish/i })).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole('button', { name: /finish/i }));

    await waitFor(() => {
      expect(mockSaveWorkout).toHaveBeenCalledWith(
        'test-uid',
        expect.objectContaining({
          uid: 'test-uid',
          source: 'custom',
        }),
      );
      expect(mockNavigate).toHaveBeenCalledWith('/');
    });
  });
});

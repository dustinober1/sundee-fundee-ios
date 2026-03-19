/**
 * Tests for useRestTimer hook.
 *
 * expo-notifications is manually mocked via jest.mock().
 * AppState.addEventListener is spied on to simulate foreground/background.
 */

// jest.mock must be hoisted before any imports
jest.mock('expo-notifications', () => ({
  scheduleNotificationAsync: jest.fn().mockResolvedValue('mock-notification-id'),
  cancelScheduledNotificationAsync: jest.fn().mockResolvedValue(undefined),
  getPermissionsAsync: jest.fn().mockResolvedValue({ status: 'granted' }),
  requestPermissionsAsync: jest.fn().mockResolvedValue({ status: 'granted' }),
  SchedulableTriggerInputTypes: {
    TIME_INTERVAL: 'timeInterval',
  },
}));

import { renderHook, act } from '@testing-library/react-native';
import { AppState } from 'react-native';
import * as Notifications from 'expo-notifications';

import { useRestTimer } from '../useRestTimer';

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('useRestTimer', () => {
  let addEventListenerSpy: jest.SpyInstance;

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();

    // Restore default mock implementations after clearAllMocks
    (Notifications.scheduleNotificationAsync as jest.Mock).mockResolvedValue('mock-notification-id');
    (Notifications.cancelScheduledNotificationAsync as jest.Mock).mockResolvedValue(undefined);
    (Notifications.getPermissionsAsync as jest.Mock).mockResolvedValue({ status: 'granted' });
    (Notifications.requestPermissionsAsync as jest.Mock).mockResolvedValue({ status: 'granted' });

    // Spy on AppState.addEventListener so we can simulate foreground/background
    addEventListenerSpy = jest
      .spyOn(AppState, 'addEventListener')
      .mockImplementation((_event: string, handler: (state: string) => void) => {
        return { remove: jest.fn() };
      });
  });

  afterEach(() => {
    jest.useRealTimers();
    addEventListenerSpy.mockRestore();
  });

  it('starts with no timer state and zero remaining seconds', () => {
    const { result } = renderHook(() => useRestTimer(90));
    expect(result.current.timerState).toBeNull();
    expect(result.current.remainingSeconds).toBe(0);
    expect(result.current.isActive).toBe(false);
  });

  it('start(90) creates timer state with mode rest and durationMs 90000', async () => {
    const { result } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    expect(result.current.timerState).not.toBeNull();
    expect(result.current.timerState!.mode).toBe('rest');
    expect(result.current.timerState!.durationMs).toBe(90_000);
    expect(result.current.isActive).toBe(true);
  });

  it('start() uses defaultSeconds when no override provided', async () => {
    const { result } = renderHook(() => useRestTimer(60));

    await act(async () => {
      await result.current.start();
    });

    expect(result.current.timerState).not.toBeNull();
    expect(result.current.timerState!.durationMs).toBe(60_000);
  });

  it('start() schedules a notification with correct seconds', async () => {
    const { result } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    expect(Notifications.scheduleNotificationAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        trigger: expect.objectContaining({ seconds: 90 }),
      }),
    );
  });

  it('skip() clears timer state to null', async () => {
    const { result } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    expect(result.current.isActive).toBe(true);

    act(() => {
      result.current.skip();
    });

    expect(result.current.timerState).toBeNull();
    expect(result.current.remainingSeconds).toBe(0);
    expect(result.current.isActive).toBe(false);
  });

  it('skip() cancels the scheduled notification', async () => {
    const { result } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    act(() => {
      result.current.skip();
    });

    expect(Notifications.cancelScheduledNotificationAsync).toHaveBeenCalledWith(
      'mock-notification-id',
    );
  });

  it('remainingSeconds decreases over time', async () => {
    const { result } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    const initialRemaining = result.current.remainingSeconds;
    expect(initialRemaining).toBe(90);

    act(() => {
      jest.advanceTimersByTime(2000); // advance 2 seconds
    });

    expect(result.current.remainingSeconds).toBeLessThan(initialRemaining);
    expect(result.current.remainingSeconds).toBeLessThanOrEqual(88);
  });

  it('cleanup cancels notification on unmount', async () => {
    const { result, unmount } = renderHook(() => useRestTimer(90));

    await act(async () => {
      await result.current.start(90);
    });

    await act(async () => {
      unmount();
    });

    expect(Notifications.cancelScheduledNotificationAsync).toHaveBeenCalled();
  });

  it('timer auto-clears when countdown reaches zero', async () => {
    const { result } = renderHook(() => useRestTimer(2));

    await act(async () => {
      await result.current.start(2);
    });

    expect(result.current.isActive).toBe(true);

    act(() => {
      jest.advanceTimersByTime(3000); // advance past 2 second timer
    });

    expect(result.current.timerState).toBeNull();
    expect(result.current.remainingSeconds).toBe(0);
    expect(result.current.isActive).toBe(false);
  });
});

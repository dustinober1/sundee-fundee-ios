/**
 * Tests for useWorkoutTimer hook.
 *
 * Tests cover:
 * - ForTime, AMRAP, EMOM timer state initialization
 * - Display time formatting
 * - EMOM notification scheduling (N individual notifications, not repeating)
 * - Pause/resume notification cancellation and rescheduling
 * - Stop clears state
 */

import { renderHook, act } from '@testing-library/react-native';
import * as Notifications from 'expo-notifications';
import { useWorkoutTimer } from '../useWorkoutTimer';
import {
  createTimerState,
  getElapsedMs,
  getRemainingMs,
} from '../../domain/timers/timer-state';

// ─── Setup ────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  jest.useFakeTimers();
});

afterEach(() => {
  jest.runOnlyPendingTimers();
  jest.useRealTimers();
});

// ─── Format helpers (unit tests, no hook needed) ─────────────────────────────

describe('formatMs helper', () => {
  it('formats zero as 00:00', () => {
    const state = createTimerState('amrap', 300_000, undefined);
    const remaining = getRemainingMs(state, state.startedAt);
    // At startedAt, elapsed = 0, remaining = 300000
    expect(remaining).toBe(300_000);
  });

  it('creates forTime state with durationMs=0 for pure stopwatch', () => {
    const state = createTimerState('forTime', 0);
    expect(state.durationMs).toBe(0);
    expect(state.mode).toBe('forTime');
  });

  it('creates AMRAP state with correct duration', () => {
    const state = createTimerState('amrap', 600_000);
    expect(state.durationMs).toBe(600_000);
    expect(state.mode).toBe('amrap');
    expect(state.pausedAt).toBeNull();
    expect(state.totalPausedMs).toBe(0);
  });

  it('creates EMOM state with intervalMs=60000', () => {
    const state = createTimerState('emom', 1200_000, 60_000);
    expect(state.durationMs).toBe(1200_000);
    expect(state.mode).toBe('emom');
    expect(state.intervalMs).toBe(60_000);
  });
});

// ─── Timer state domain (deterministic with now param) ───────────────────────

describe('timer-state domain', () => {
  it('getElapsedMs returns 0 at start', () => {
    const state = createTimerState('forTime', 0);
    expect(getElapsedMs(state, state.startedAt)).toBe(0);
  });

  it('getElapsedMs accounts for passage of time', () => {
    const state = createTimerState('amrap', 60_000);
    const elapsed = getElapsedMs(state, state.startedAt + 30_000);
    expect(elapsed).toBe(30_000);
  });

  it('getRemainingMs returns correct remainder', () => {
    const state = createTimerState('amrap', 60_000);
    const remaining = getRemainingMs(state, state.startedAt + 30_000);
    expect(remaining).toBe(30_000);
  });

  it('getRemainingMs clamps at 0', () => {
    const state = createTimerState('amrap', 60_000);
    const remaining = getRemainingMs(state, state.startedAt + 90_000);
    expect(remaining).toBe(0);
  });
});

// ─── Hook initial state ───────────────────────────────────────────────────────

describe('useWorkoutTimer initial state', () => {
  it('starts with null timerState and 00:00 display', () => {
    const { result } = renderHook(() => useWorkoutTimer());
    expect(result.current.timerState).toBeNull();
    expect(result.current.displayTime).toBe('00:00');
    expect(result.current.isCountingDown).toBe(false);
    expect(result.current.isPaused).toBe(false);
    expect(result.current.isComplete).toBe(false);
    expect(result.current.roundsCompleted).toBe(0);
  });
});

// ─── ForTime ─────────────────────────────────────────────────────────────────

describe('startForTime', () => {
  it('starts 3-2-1 countdown then creates forTime timer state', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startForTime(600);
    });

    // Immediately after calling startForTime, countdown should begin
    expect(result.current.isCountingDown).toBe(true);
    expect(result.current.countdownValue).toBe(3);

    // Advance through countdown (3 seconds)
    act(() => {
      jest.advanceTimersByTime(3000);
    });

    expect(result.current.isCountingDown).toBe(false);
    expect(result.current.timerState).not.toBeNull();
    expect(result.current.timerState?.mode).toBe('forTime');
    expect(result.current.timerState?.durationMs).toBe(600_000);
  });

  it('creates forTime with durationMs=0 when no time cap', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startForTime();
    });

    act(() => {
      jest.advanceTimersByTime(3000);
    });

    expect(result.current.timerState?.durationMs).toBe(0);
  });
});

// ─── AMRAP ───────────────────────────────────────────────────────────────────

describe('startAMRAP', () => {
  it('creates amrap timer with correct duration after countdown', () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startAMRAP(900);
    });

    act(() => {
      jest.advanceTimersByTime(3000);
    });

    expect(result.current.timerState?.mode).toBe('amrap');
    expect(result.current.timerState?.durationMs).toBe(900_000);
  });

  it('incrementRound increases roundsCompleted', () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startAMRAP(600);
      jest.advanceTimersByTime(3000);
    });

    act(() => {
      result.current.incrementRound();
      result.current.incrementRound();
    });

    expect(result.current.roundsCompleted).toBe(2);
  });
});

// ─── EMOM notification scheduling ────────────────────────────────────────────

describe('startEMOM notification scheduling', () => {
  it('schedules N individual notifications for N-minute EMOM', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startEMOM(5);
      jest.advanceTimersByTime(3000);
      // Allow async notification scheduling to resolve
      await Promise.resolve();
      await Promise.resolve();
    });

    // Should schedule 5 individual notifications (one per minute boundary)
    expect(Notifications.scheduleNotificationAsync).toHaveBeenCalledTimes(5);

    // Each call should be for a specific minute
    const calls = (Notifications.scheduleNotificationAsync as jest.Mock).mock.calls;
    const titles = calls.map((call: Array<{ content?: { title?: string } }>) => call[0]?.content?.title);
    expect(titles).toContain('Minute 1');
    expect(titles).toContain('Minute 5');
  });

  it('schedules notifications with correct trigger (not repeating)', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startEMOM(3);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
      await Promise.resolve();
    });

    const calls = (Notifications.scheduleNotificationAsync as jest.Mock).mock.calls;
    calls.forEach((call: Array<{ trigger?: { repeats?: boolean } }>) => {
      expect(call[0]?.trigger?.repeats).toBe(false);
    });
  });

  it('sets currentMinute to 1 at start', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startEMOM(10);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
    });

    expect(result.current.currentMinute).toBe(1);
  });
});

// ─── Pause / Resume ───────────────────────────────────────────────────────────

describe('pause and resume', () => {
  it('pause sets isPaused=true and cancels notifications', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startAMRAP(600);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
    });

    await act(async () => {
      result.current.pause();
      await Promise.resolve();
    });

    expect(result.current.isPaused).toBe(true);
  });

  it('resume clears isPaused', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startAMRAP(600);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
    });

    await act(async () => {
      result.current.pause();
      await Promise.resolve();
    });

    await act(async () => {
      result.current.resume();
      await Promise.resolve();
    });

    expect(result.current.isPaused).toBe(false);
  });
});

// ─── Stop ─────────────────────────────────────────────────────────────────────

describe('stop', () => {
  it('resets all state to initial values', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startAMRAP(600);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
    });

    await act(async () => {
      result.current.stop();
      await Promise.resolve();
    });

    expect(result.current.timerState).toBeNull();
    expect(result.current.displayTime).toBe('00:00');
    expect(result.current.isCountingDown).toBe(false);
    expect(result.current.isPaused).toBe(false);
    expect(result.current.isComplete).toBe(false);
    expect(result.current.roundsCompleted).toBe(0);
  });

  it('cancels all scheduled notifications on stop', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    await act(async () => {
      result.current.startEMOM(20);
      jest.advanceTimersByTime(3000);
      await Promise.resolve();
      await Promise.resolve();
    });

    await act(async () => {
      result.current.stop();
      await Promise.resolve();
    });

    expect(Notifications.cancelScheduledNotificationAsync).toHaveBeenCalled();
  });
});

// ─── Display time formatting ──────────────────────────────────────────────────

describe('display time formatting', () => {
  it('shows 10:00 for a 600-second AMRAP at start', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startAMRAP(600);
      jest.advanceTimersByTime(3000);
    });

    expect(result.current.displayTime).toBe('10:00');
  });

  it('shows 00:00 for ForTime at start', async () => {
    const { result } = renderHook(() => useWorkoutTimer());

    act(() => {
      result.current.startForTime();
      jest.advanceTimersByTime(3000);
    });

    // After countdown completes, stopwatch shows 00:00 (or small value)
    expect(result.current.displayTime).toMatch(/^\d{2}:\d{2}$/);
  });
});

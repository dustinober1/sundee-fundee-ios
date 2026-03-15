/**
 * useRestTimer — manages rest timer countdown with expo-notifications support.
 *
 * Provides:
 *   - start(seconds?) — begins countdown, schedules local notification
 *   - skip() — cancels timer and pending notification
 *   - remainingSeconds — live countdown display value
 *   - isActive — whether a timer is currently running
 *   - AppState listener to re-sync after backgrounding
 */

import { useState, useEffect, useRef, useCallback } from 'react';
import { AppState, type AppStateStatus } from 'react-native';
import * as Notifications from 'expo-notifications';
import { createTimerState, getRemainingMs } from '../domain/timers/timer-state';
import type { TimerState } from '../domain/timers/timer-state';

// ─── Constants ────────────────────────────────────────────────────────────────

const TICK_INTERVAL_MS = 100;

// ─── Types ────────────────────────────────────────────────────────────────────

export interface UseRestTimerReturn {
  timerState: TimerState | null;
  remainingSeconds: number;
  isActive: boolean;
  start: (seconds?: number) => Promise<void>;
  skip: () => void;
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

/**
 * @param defaultSeconds - Default rest duration when start() is called without an argument
 */
export function useRestTimer(defaultSeconds = 90): UseRestTimerReturn {
  const [timerState, setTimerState] = useState<TimerState | null>(null);
  const [remainingSeconds, setRemainingSeconds] = useState(0);

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const notificationIdRef = useRef<string | null>(null);
  const timerStateRef = useRef<TimerState | null>(null);

  // Keep ref in sync with state for use inside interval callback
  useEffect(() => {
    timerStateRef.current = timerState;
  }, [timerState]);

  // ── Tick: update remainingSeconds from timer state ───────────────────────
  const startTick = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }
    intervalRef.current = setInterval(() => {
      const state = timerStateRef.current;
      if (!state) {
        clearInterval(intervalRef.current!);
        intervalRef.current = null;
        return;
      }
      const remainingMs = getRemainingMs(state);
      setRemainingSeconds(Math.ceil(remainingMs / 1000));
      if (remainingMs <= 0) {
        // Timer finished naturally
        clearInterval(intervalRef.current!);
        intervalRef.current = null;
        setTimerState(null);
        setRemainingSeconds(0);
      }
    }, TICK_INTERVAL_MS);
  }, []);

  // ── Cancel notification helper ───────────────────────────────────────────
  const cancelNotification = useCallback(async (): Promise<void> => {
    if (notificationIdRef.current) {
      try {
        await Notifications.cancelScheduledNotificationAsync(notificationIdRef.current);
      } catch {
        // Non-fatal
      }
      notificationIdRef.current = null;
    }
  }, []);

  // ── start ────────────────────────────────────────────────────────────────
  const start = useCallback(
    async (seconds?: number): Promise<void> => {
      const duration = seconds ?? defaultSeconds;

      // Cancel any existing timer
      await cancelNotification();
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }

      // Request notification permission on first use
      const { status } = await Notifications.getPermissionsAsync();
      if (status !== 'granted') {
        await Notifications.requestPermissionsAsync();
      }

      // Schedule local notification for rest completion
      try {
        const notificationId = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Rest complete!',
            body: 'Time to lift.',
            sound: true,
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
            seconds: duration,
          },
        });
        notificationIdRef.current = notificationId;
      } catch {
        // Notifications unavailable — timer still works visually
      }

      const newState = createTimerState('rest', duration * 1000);
      setTimerState(newState);
      setRemainingSeconds(duration);
      startTick();
    },
    [defaultSeconds, cancelNotification, startTick],
  );

  // ── skip ─────────────────────────────────────────────────────────────────
  const skip = useCallback((): void => {
    void cancelNotification();
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setTimerState(null);
    setRemainingSeconds(0);
  }, [cancelNotification]);

  // ── AppState listener: re-sync when app comes back to foreground ─────────
  useEffect(() => {
    const subscription = AppState.addEventListener(
      'change',
      (nextState: AppStateStatus) => {
        if (nextState === 'active' && timerStateRef.current) {
          // Force re-render to recalculate remaining time from timestamps
          const state = timerStateRef.current;
          const remainingMs = getRemainingMs(state);
          if (remainingMs <= 0) {
            setTimerState(null);
            setRemainingSeconds(0);
          } else {
            setRemainingSeconds(Math.ceil(remainingMs / 1000));
            // Restart tick to resume smooth updates
            startTick();
          }
        }
      },
    );

    return () => {
      subscription.remove();
    };
  }, [startTick]);

  // ── Cleanup on unmount ───────────────────────────────────────────────────
  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
      void cancelNotification();
    };
  }, [cancelNotification]);

  return {
    timerState,
    remainingSeconds,
    isActive: timerState !== null,
    start,
    skip,
  };
}

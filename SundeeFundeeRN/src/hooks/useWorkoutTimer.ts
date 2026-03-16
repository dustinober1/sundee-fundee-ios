import { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import * as Notifications from 'expo-notifications';
import { createAudioPlayer } from 'expo-audio';
import {
  TimerMode,
  TimerState,
  createTimerState,
  getElapsedMs,
  getRemainingMs,
  pauseTimer,
  resumeTimer,
  isTimerComplete,
  getEMOMCurrentMinute,
} from '../domain/timers/timer-state';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface WorkoutTimerState {
  timerState: TimerState | null;
  displayTime: string;
  isCountingDown: boolean;
  countdownValue: number;
  isPaused: boolean;
  isComplete: boolean;
  currentMinute: number;
  roundsCompleted: number;
}

export interface WorkoutTimerControls {
  startForTime: (timeCapSeconds?: number) => void;
  startAMRAP: (durationSeconds: number) => void;
  startEMOM: (totalMinutes: number) => void;
  pause: () => void;
  resume: () => void;
  stop: () => void;
  incrementRound: () => void;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatMs(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

function formatElapsedMs(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

async function scheduleEMOMNotifications(
  startedAt: number,
  totalMinutes: number,
  remainingStartMinute = 1,
): Promise<string[]> {
  const ids: string[] = [];
  for (let minute = remainingStartMinute; minute <= totalMinutes; minute++) {
    const triggerMs = startedAt + minute * 60_000;
    const secondsFromNow = Math.ceil((triggerMs - Date.now()) / 1000);
    if (secondsFromNow > 0) {
      try {
        const id = await Notifications.scheduleNotificationAsync({
          content: {
            title: `Minute ${minute}`,
            body: 'Start next round!',
            sound: true,
          },
          trigger: { seconds: secondsFromNow, repeats: false } as Notifications.NotificationTriggerInput,
        });
        ids.push(id);
      } catch {
        // Best-effort — notification scheduling failures are non-fatal
      }
    }
  }
  return ids;
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

export function useWorkoutTimer(): WorkoutTimerState & WorkoutTimerControls {
  const [timerState, setTimerState] = useState<TimerState | null>(null);
  const [displayTime, setDisplayTime] = useState('00:00');
  const [isCountingDown, setIsCountingDown] = useState(false);
  const [countdownValue, setCountdownValue] = useState(3);
  const [isComplete, setIsComplete] = useState(false);
  const [currentMinute, setCurrentMinute] = useState(1);
  const [roundsCompleted, setRoundsCompleted] = useState(0);

  const scheduledNotificationIds = useRef<string[]>([]);
  const tickIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const countdownIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const pendingStartRef = useRef<(() => void) | null>(null);

  // ── Cleanup helpers ──────────────────────────────────────────────────────

  const clearTickInterval = useCallback(() => {
    if (tickIntervalRef.current !== null) {
      clearInterval(tickIntervalRef.current);
      tickIntervalRef.current = null;
    }
  }, []);

  const clearCountdownInterval = useCallback(() => {
    if (countdownIntervalRef.current !== null) {
      clearInterval(countdownIntervalRef.current);
      countdownIntervalRef.current = null;
    }
  }, []);

  const cancelAllNotifications = useCallback(async () => {
    if (scheduledNotificationIds.current.length > 0) {
      await Promise.all(
        scheduledNotificationIds.current.map((id) =>
          Notifications.cancelScheduledNotificationAsync(id).catch(() => {}),
        ),
      );
      scheduledNotificationIds.current = [];
    }
  }, []);

  // ── Sound helpers ────────────────────────────────────────────────────────

  const playSound = useCallback((source: number) => {
    try {
      const player = createAudioPlayer(source);
      player.play();
    } catch {
      // Sound is best-effort — silence failures gracefully
    }
  }, []);

  const playBeep = useCallback(() => {
    playSound(require('../assets/sounds/beep.mp3'));
  }, [playSound]);

  const playGoSound = useCallback(() => {
    playSound(require('../assets/sounds/go.mp3'));
  }, [playSound]);

  const playCompleteSound = useCallback(() => {
    playSound(require('../assets/sounds/complete.mp3'));
  }, [playSound]);

  // ── Tick logic ───────────────────────────────────────────────────────────

  const startTick = useCallback((state: TimerState) => {
    clearTickInterval();
    tickIntervalRef.current = setInterval(() => {
      setTimerState((current) => {
        if (current === null) return null;
        const elapsed = getElapsedMs(current);
        const remaining = getRemainingMs(current);

        if (current.mode === 'forTime') {
          setDisplayTime(formatElapsedMs(elapsed));
        } else {
          setDisplayTime(formatMs(remaining));
        }

        if (current.mode === 'emom') {
          setCurrentMinute(getEMOMCurrentMinute(current));
        }

        if (isTimerComplete(current)) {
          setIsComplete(true);
          clearInterval(tickIntervalRef.current!);
          tickIntervalRef.current = null;
          playCompleteSound();
        }

        return current;
      });
    }, 100);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clearTickInterval]);

  // ── 3-2-1-Go countdown ───────────────────────────────────────────────────

  const runCountdown = useCallback(
    (onComplete: () => void) => {
      setIsCountingDown(true);
      setCountdownValue(3);
      let count = 3;
      playBeep();

      countdownIntervalRef.current = setInterval(() => {
        count -= 1;
        if (count > 0) {
          setCountdownValue(count);
          playBeep();
        } else {
          clearCountdownInterval();
          setIsCountingDown(false);
          playGoSound();
          onComplete();
        }
      }, 1000);
    },
    [clearCountdownInterval, playBeep, playGoSound],
  );

  // ── Start methods ────────────────────────────────────────────────────────

  const startForTime = useCallback(
    (timeCapSeconds?: number) => {
      const launch = () => {
        const durationMs = timeCapSeconds ? timeCapSeconds * 1000 : 0;
        const state = createTimerState('forTime', durationMs);
        setTimerState(state);
        setDisplayTime('00:00');
        setIsComplete(false);
        setRoundsCompleted(0);
        startTick(state);
      };
      runCountdown(launch);
    },
    [runCountdown, startTick],
  );

  const startAMRAP = useCallback(
    (durationSeconds: number) => {
      const launch = () => {
        const durationMs = durationSeconds * 1000;
        const state = createTimerState('amrap', durationMs);
        setTimerState(state);
        setDisplayTime(formatMs(durationMs));
        setIsComplete(false);
        setRoundsCompleted(0);
        startTick(state);
      };
      runCountdown(launch);
    },
    [runCountdown, startTick],
  );

  const startEMOM = useCallback(
    (totalMinutes: number) => {
      const launch = async () => {
        const durationMs = totalMinutes * 60_000;
        const state = createTimerState('emom', durationMs, 60_000);
        setTimerState(state);
        setDisplayTime(formatMs(60_000));
        setCurrentMinute(1);
        setIsComplete(false);
        setRoundsCompleted(0);
        startTick(state);
        const ids = await scheduleEMOMNotifications(state.startedAt, totalMinutes);
        scheduledNotificationIds.current = ids;
      };
      runCountdown(launch);
    },
    [runCountdown, startTick],
  );

  // ── Pause / Resume / Stop ────────────────────────────────────────────────

  const pause = useCallback(async () => {
    setTimerState((current) => {
      if (current === null || current.pausedAt !== null) return current;
      clearTickInterval();
      cancelAllNotifications();
      return pauseTimer(current);
    });
  }, [clearTickInterval, cancelAllNotifications]);

  const resume = useCallback(async () => {
    setTimerState((current) => {
      if (current === null || current.pausedAt === null) return current;
      const resumed = resumeTimer(current);

      startTick(resumed);

      // Reschedule EMOM notifications for remaining minutes
      if (resumed.mode === 'emom' && resumed.intervalMs) {
        const totalMinutes = resumed.durationMs / 60_000;
        const elapsedMinutes = Math.floor(getElapsedMs(resumed) / 60_000);
        const nextMinute = elapsedMinutes + 1;
        scheduleEMOMNotifications(resumed.startedAt, totalMinutes, nextMinute).then((ids) => {
          scheduledNotificationIds.current = ids;
        });
      }

      return resumed;
    });
  }, [startTick, cancelAllNotifications]);

  const stop = useCallback(async () => {
    clearTickInterval();
    clearCountdownInterval();
    await cancelAllNotifications();
    setTimerState(null);
    setDisplayTime('00:00');
    setIsCountingDown(false);
    setCountdownValue(3);
    setIsComplete(false);
    setCurrentMinute(1);
    setRoundsCompleted(0);
    pendingStartRef.current = null;
  }, [clearTickInterval, clearCountdownInterval, cancelAllNotifications]);

  const incrementRound = useCallback(() => {
    setRoundsCompleted((prev) => prev + 1);
  }, []);

  // ── AppState listener (foreground recalculation) ─────────────────────────

  useEffect(() => {
    const subscription = AppState.addEventListener(
      'change',
      (nextState: AppStateStatus) => {
        if (nextState === 'active') {
          setTimerState((current) => {
            if (current === null || current.pausedAt !== null) return current;
            // Force recalculation by triggering a state update
            const elapsed = getElapsedMs(current);
            const remaining = getRemainingMs(current);
            if (current.mode === 'forTime') {
              setDisplayTime(formatElapsedMs(elapsed));
            } else {
              setDisplayTime(formatMs(remaining));
            }
            if (current.mode === 'emom') {
              setCurrentMinute(getEMOMCurrentMinute(current));
            }
            if (isTimerComplete(current)) {
              setIsComplete(true);
              clearTickInterval();
              playCompleteSound();
            }
            return current;
          });
        }
      },
    );
    return () => subscription.remove();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clearTickInterval]);

  // ── Cleanup on unmount ───────────────────────────────────────────────────

  useEffect(() => {
    return () => {
      clearTickInterval();
      clearCountdownInterval();
      cancelAllNotifications();
    };
  }, [clearTickInterval, clearCountdownInterval, cancelAllNotifications]);

  // ── Derived state ────────────────────────────────────────────────────────

  const isPaused = timerState !== null && timerState.pausedAt !== null;

  return {
    timerState,
    displayTime,
    isCountingDown,
    countdownValue,
    isPaused,
    isComplete,
    currentMinute,
    roundsCompleted,
    startForTime,
    startAMRAP,
    startEMOM,
    pause,
    resume,
    stop,
    incrementRound,
  };
}

'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import type { RestTimerSettings, TimerStatus } from '@/types/rest-timer';
import { DEFAULT_REST_TIMER_SETTINGS } from '@/types/rest-timer';

const SETTINGS_STORAGE_KEY = 'rest-timer-settings';

interface UseRestTimerReturn {
  status: TimerStatus;
  durationSeconds: number;
  remainingSeconds: number;
  startedAt: number | null;
  isExpanded: boolean;
  exerciseName: string | null;
  settings: RestTimerSettings;
  startRest: (durationSeconds: number, exerciseName?: string) => void;
  pause: () => void;
  resume: () => void;
  addTime: (seconds: number) => void;
  subtractTime: (seconds: number) => void;
  cancel: () => void;
  skip: () => void;
  setExpanded: (expanded: boolean) => void;
  setSettings: (settings: Partial<RestTimerSettings>) => void;
}

export function useRestTimer(): UseRestTimerReturn {
  // Timer state
  const [status, setStatus] = useState<TimerStatus>('idle');
  const [durationSeconds, setDurationSeconds] = useState(0);
  const [remainingSeconds, setRemainingSeconds] = useState(0);
  const [startedAt, setStartedAt] = useState<number | null>(null);
  const [isExpanded, setIsExpanded] = useState(false);
  const [exerciseName, setExerciseName] = useState<string | null>(null);

  // Settings with localStorage persistence
  const [settings, setSettingsState] = useState<RestTimerSettings>(() => {
    if (typeof window === 'undefined') {
      return DEFAULT_REST_TIMER_SETTINGS;
    }
    try {
      const stored = localStorage.getItem(SETTINGS_STORAGE_KEY);
      if (stored) {
        return { ...DEFAULT_REST_TIMER_SETTINGS, ...JSON.parse(stored) };
      }
    } catch {
      // Ignore parsing errors
    }
    return DEFAULT_REST_TIMER_SETTINGS;
  });

  // Refs for interval and visibility handling
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const timestampRef = useRef<number | null>(null);
  const remainingWhenHiddenRef = useRef<number | null>(null);
  const notificationPermissionRequested = useRef(false);

  // Persist settings to localStorage
  useEffect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
    }
  }, [settings]);

  // Clear interval on unmount
  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  // Update settings
  const setSettings = useCallback((newSettings: Partial<RestTimerSettings>) => {
    setSettingsState((prev) => ({ ...prev, ...newSettings }));
  }, []);

  // Trigger notification (sound, vibration, or both)
  const triggerNotification = useCallback(() => {
    const { notificationType } = settings;

    if (notificationType === 'none') return;

    // Vibration
    if (
      (notificationType === 'vibrate' || notificationType === 'both') &&
      typeof navigator !== 'undefined' &&
      navigator.vibrate
    ) {
      navigator.vibrate([200, 100, 200]);
    }

    // Sound
    if (notificationType === 'sound' || notificationType === 'both') {
      // Play audio - the audio file will be handled by the context/consumer
      // We'll dispatch a custom event that the audio handler can listen to
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('rest-timer-complete'));
      }
    }

    // Web Notification
    if (typeof window !== 'undefined' && 'Notification' in window) {
      if (Notification.permission === 'granted') {
        new Notification('Rest Complete!', {
          body: exerciseName
            ? `Time to continue with ${exerciseName}`
            : 'Time for your next set!',
          icon: '/icons/icon-192x192.png',
        });
      } else if (
        Notification.permission !== 'denied' &&
        !notificationPermissionRequested.current
      ) {
        notificationPermissionRequested.current = true;
        Notification.requestPermission().then((permission) => {
          if (permission === 'granted') {
            new Notification('Rest Complete!', {
              body: exerciseName
                ? `Time to continue with ${exerciseName}`
                : 'Time for your next set!',
              icon: '/icons/icon-192x192.png',
            });
          }
        });
      }
    }
  }, [settings, exerciseName]);

  // Calculate remaining seconds based on timestamp
  const calculateRemainingFromTimestamp = useCallback(() => {
    if (!timestampRef.current) return remainingSeconds;

    const elapsed = Math.floor((Date.now() - timestampRef.current) / 1000);
    return Math.max(0, durationSeconds - elapsed);
  }, [durationSeconds, remainingSeconds]);

  // Start the countdown interval
  const startInterval = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }

    intervalRef.current = setInterval(() => {
      setRemainingSeconds((prev) => {
        const newRemaining = prev - 1;
        if (newRemaining <= 0) {
          if (intervalRef.current) {
            clearInterval(intervalRef.current);
            intervalRef.current = null;
          }
          setStatus('complete');
          // Use setTimeout to defer the notification to avoid setState during render
          setTimeout(() => triggerNotification(), 0);
          return 0;
        }
        return newRemaining;
      });
    }, 1000);
  }, [triggerNotification]);

  // Handle visibility change (background/foreground)
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // Store remaining time when going to background
        remainingWhenHiddenRef.current = remainingSeconds;
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
          intervalRef.current = null;
        }
      } else {
        // Recalculate when coming back to foreground
        if (status === 'running' && timestampRef.current) {
          const remaining = calculateRemainingFromTimestamp();
          setRemainingSeconds(remaining);

          if (remaining <= 0) {
            setStatus('complete');
            triggerNotification();
          } else {
            startInterval();
          }
        }
        remainingWhenHiddenRef.current = null;
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [
    status,
    remainingSeconds,
    calculateRemainingFromTimestamp,
    startInterval,
    triggerNotification,
  ]);

  // Start a new rest timer
  const startRest = useCallback(
    (duration: number, exercise?: string) => {
      const durationValue = Math.max(1, duration);
      const now = Date.now();

      setStatus('running');
      setDurationSeconds(durationValue);
      setRemainingSeconds(durationValue);
      setStartedAt(now);
      timestampRef.current = now;
      setExerciseName(exercise || null);
      setIsExpanded(true);

      // Request notification permission on first start
      if (
        typeof window !== 'undefined' &&
        'Notification' in window &&
        Notification.permission === 'default' &&
        !notificationPermissionRequested.current
      ) {
        notificationPermissionRequested.current = true;
        Notification.requestPermission();
      }

      startInterval();
    },
    [startInterval]
  );

  // Pause the timer
  const pause = useCallback(() => {
    if (status !== 'running') return;

    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setStatus('paused');
  }, [status]);

  // Resume from paused state
  const resume = useCallback(() => {
    if (status !== 'paused') return;

    // Adjust timestamp to account for pause duration
    if (timestampRef.current) {
      const elapsedBeforePause = durationSeconds - remainingSeconds;
      timestampRef.current = Date.now() - elapsedBeforePause * 1000;
    }

    setStatus('running');
    startInterval();
  }, [status, durationSeconds, remainingSeconds, startInterval]);

  // Add time to the timer
  const addTime = useCallback(
    (seconds: number) => {
      if (status !== 'running' && status !== 'paused') return;

      const newDuration = durationSeconds + seconds;
      setDurationSeconds(newDuration);
      setRemainingSeconds((prev) => prev + seconds);

      // Adjust timestamp for accurate background handling
      if (timestampRef.current) {
        timestampRef.current -= seconds * 1000;
      }
    },
    [status, durationSeconds]
  );

  // Subtract time from the timer
  const subtractTime = useCallback(
    (seconds: number) => {
      if (status !== 'running' && status !== 'paused') return;

      const newRemaining = Math.max(0, remainingSeconds - seconds);
      const newDuration = Math.max(0, durationSeconds - seconds);

      setDurationSeconds(newDuration);
      setRemainingSeconds(newRemaining);

      // Adjust timestamp for accurate background handling
      if (timestampRef.current) {
        timestampRef.current += seconds * 1000;
      }

      // If running and subtracting to zero, complete immediately
      if (status === 'running' && newRemaining <= 0) {
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
          intervalRef.current = null;
        }
        setStatus('complete');
        triggerNotification();
      }
    },
    [status, remainingSeconds, durationSeconds, triggerNotification]
  );

  // Cancel the timer and reset to idle
  const cancel = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setStatus('idle');
    setDurationSeconds(0);
    setRemainingSeconds(0);
    setStartedAt(null);
    timestampRef.current = null;
    setExerciseName(null);
    setIsExpanded(false);
  }, []);

  // Skip the remaining rest time
  const skip = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setStatus('complete');
    setRemainingSeconds(0);
  }, []);

  // Set expanded state
  const setExpanded = useCallback((expanded: boolean) => {
    setIsExpanded(expanded);
  }, []);

  return {
    // State
    status,
    durationSeconds,
    remainingSeconds,
    startedAt,
    isExpanded,
    exerciseName,
    settings,
    // Actions
    startRest,
    pause,
    resume,
    addTime,
    subtractTime,
    cancel,
    skip,
    setExpanded,
    setSettings,
  };
}

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useRestTimer } from '@/hooks/useRestTimer';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: vi.fn((key: string) => store[key] || null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = value;
    }),
    removeItem: vi.fn((key: string) => {
      delete store[key];
    }),
    clear: vi.fn(() => {
      store = {};
    }),
  };
})();

Object.defineProperty(global, 'localStorage', {
  value: localStorageMock,
});

// Mock navigator.vibrate
Object.defineProperty(global.navigator, 'vibrate', {
  value: vi.fn(() => true),
  writable: true,
});

// Mock Notification as a proper class constructor
class MockNotification {
  static permission: NotificationPermission = 'granted';
  static requestPermission = vi.fn().mockResolvedValue('granted');
  close = vi.fn();

  constructor(_title: string, _options?: NotificationOptions) {}
}

vi.stubGlobal('Notification', MockNotification);

describe('useRestTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    localStorageMock.clear();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('initial state', () => {
    it('starts with idle status', () => {
      const { result } = renderHook(() => useRestTimer());
      expect(result.current.status).toBe('idle');
    });

    it('starts with zero remaining seconds', () => {
      const { result } = renderHook(() => useRestTimer());
      expect(result.current.remainingSeconds).toBe(0);
    });
  });

  describe('startRest', () => {
    it('sets status to running', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      expect(result.current.status).toBe('running');
    });

    it('sets duration and remaining seconds', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(90, 'Back Squat');
      });

      expect(result.current.durationSeconds).toBe(90);
      expect(result.current.remainingSeconds).toBe(90);
    });

    it('stores exercise name', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Bench Press');
      });

      expect(result.current.exerciseName).toBe('Bench Press');
    });

    it('counts down each second', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      expect(result.current.remainingSeconds).toBe(60);

      act(() => {
        vi.advanceTimersByTime(1000);
      });

      expect(result.current.remainingSeconds).toBe(59);
    });
  });

  describe('pause and resume', () => {
    it('pauses the timer', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(10000);
      });

      act(() => {
        result.current.pause();
      });

      expect(result.current.status).toBe('paused');
      expect(result.current.remainingSeconds).toBe(50);

      // Timer should not advance while paused
      act(() => {
        vi.advanceTimersByTime(5000);
      });

      expect(result.current.remainingSeconds).toBe(50);
    });

    it('resumes from paused state', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(10000);
        result.current.pause();
      });

      act(() => {
        result.current.resume();
      });

      expect(result.current.status).toBe('running');

      act(() => {
        vi.advanceTimersByTime(5000);
      });

      expect(result.current.remainingSeconds).toBe(45);
    });
  });

  describe('addTime and subtractTime', () => {
    it('adds time to remaining seconds', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        result.current.addTime(30);
      });

      expect(result.current.remainingSeconds).toBe(90);
      expect(result.current.durationSeconds).toBe(90);
    });

    it('subtracts time from remaining seconds', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        result.current.subtractTime(30);
      });

      expect(result.current.remainingSeconds).toBe(30);
      expect(result.current.durationSeconds).toBe(30);
    });

    it('does not go below zero', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        result.current.subtractTime(100);
      });

      expect(result.current.remainingSeconds).toBe(0);
    });
  });

  describe('cancel', () => {
    it('resets timer to idle state', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        result.current.cancel();
      });

      expect(result.current.status).toBe('idle');
      expect(result.current.remainingSeconds).toBe(0);
      expect(result.current.exerciseName).toBeNull();
    });
  });

  describe('skip', () => {
    it('marks timer as complete', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        result.current.skip();
      });

      expect(result.current.status).toBe('complete');
    });
  });

  describe('completion', () => {
    it('sets status to complete when timer reaches zero', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(3, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(3000);
      });

      expect(result.current.status).toBe('complete');
      expect(result.current.remainingSeconds).toBe(0);
    });
  });
});

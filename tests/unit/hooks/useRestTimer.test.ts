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

  describe('Visibility API handling', () => {
    it('stores remaining time when app goes to background', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(10000);
      });

      expect(result.current.remainingSeconds).toBe(50);

      // Simulate going to background
      act(() => {
        Object.defineProperty(document, 'hidden', {
          value: true,
          configurable: true,
        });
        document.dispatchEvent(new Event('visibilitychange'));
      });

      // Timer should stop advancing while hidden
      act(() => {
        vi.advanceTimersByTime(5000);
      });

      // Should still be 50 (not advanced while hidden)
      expect(result.current.remainingSeconds).toBe(50);
    });

    it('recalculates remaining time when app returns to foreground', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(10000);
      });

      expect(result.current.remainingSeconds).toBe(50);

      // Simulate going to background
      act(() => {
        Object.defineProperty(document, 'hidden', {
          value: true,
          configurable: true,
        });
        document.dispatchEvent(new Event('visibilitychange'));
      });

      // Advance time while "hidden" (simulating 20 seconds passing)
      act(() => {
        vi.advanceTimersByTime(20000);
      });

      // Simulate coming back to foreground
      act(() => {
        Object.defineProperty(document, 'hidden', {
          value: false,
          configurable: true,
        });
        document.dispatchEvent(new Event('visibilitychange'));
      });

      // Should have recalculated based on elapsed time (50 - 20 = 30)
      expect(result.current.remainingSeconds).toBe(30);
      expect(result.current.status).toBe('running');
    });

    it('completes timer if elapsed time exceeds duration while in background', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(10, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      expect(result.current.remainingSeconds).toBe(8);

      // Simulate going to background
      act(() => {
        Object.defineProperty(document, 'hidden', {
          value: true,
          configurable: true,
        });
        document.dispatchEvent(new Event('visibilitychange'));
      });

      // Advance time well past the timer duration (simulating 15 seconds passing)
      act(() => {
        vi.advanceTimersByTime(15000);
      });

      // Simulate coming back to foreground
      act(() => {
        Object.defineProperty(document, 'hidden', {
          value: false,
          configurable: true,
        });
        document.dispatchEvent(new Event('visibilitychange'));
      });

      // Timer should be complete
      expect(result.current.status).toBe('complete');
      expect(result.current.remainingSeconds).toBe(0);
    });
  });

  describe('localStorage persistence', () => {
    it('persists settings to localStorage when settings change', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ defaultRestSeconds: 120, notificationType: 'sound' });
      });

      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'rest-timer-settings',
        expect.stringContaining('"defaultRestSeconds":120')
      );
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'rest-timer-settings',
        expect.stringContaining('"notificationType":"sound"')
      );
    });

    it('loads settings from localStorage on initialization', () => {
      // Pre-populate localStorage with custom settings
      localStorageMock.setItem(
        'rest-timer-settings',
        JSON.stringify({ defaultRestSeconds: 150, notificationType: 'vibrate' })
      );

      const { result } = renderHook(() => useRestTimer());

      expect(result.current.settings.defaultRestSeconds).toBe(150);
      expect(result.current.settings.notificationType).toBe('vibrate');
    });

    it('falls back to default settings if localStorage is empty', () => {
      const { result } = renderHook(() => useRestTimer());

      expect(result.current.settings.defaultRestSeconds).toBe(180);
      expect(result.current.settings.notificationType).toBe('both');
    });

    it('handles malformed localStorage data gracefully', () => {
      localStorageMock.setItem('rest-timer-settings', 'invalid-json');

      const { result } = renderHook(() => useRestTimer());

      // Should fall back to defaults
      expect(result.current.settings.defaultRestSeconds).toBe(180);
    });
  });

  describe('Web Notifications', () => {
    it('requests notification permission on first start when permission is default', () => {
      // Reset permission to default
      MockNotification.permission = 'default';

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      expect(MockNotification.requestPermission).toHaveBeenCalled();
    });

    it('does not request permission if already granted', () => {
      MockNotification.permission = 'granted';
      vi.clearAllMocks();

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      expect(MockNotification.requestPermission).not.toHaveBeenCalled();
    });

    it('triggers notification when timer completes with granted permission', () => {
      MockNotification.permission = 'granted';

      // Track when Notification constructor is called
      let notificationCallCount = 0;
      let lastNotificationTitle: string | undefined;
      let lastNotificationBody: string | undefined;

      // Create a proper class-based mock
      class NotificationSpy {
        static permission: NotificationPermission = 'granted';
        static requestPermission = vi.fn().mockResolvedValue('granted');
        close = vi.fn();

        constructor(title: string, options?: NotificationOptions) {
          notificationCallCount++;
          lastNotificationTitle = title;
          lastNotificationBody = options?.body;
        }
      }

      vi.stubGlobal('Notification', NotificationSpy);

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(2, 'Bench Press');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      // Notification constructor should have been called
      expect(notificationCallCount).toBeGreaterThan(0);
      expect(lastNotificationTitle).toBe('Rest Complete!');
      // Body should contain either the exercise name or the fallback message
      expect(lastNotificationBody).toMatch(/Bench Press|next set/);

      // Restore original mock
      vi.stubGlobal('Notification', MockNotification);
    });
  });

  describe('Audio/vibration alerts', () => {
    it('triggers vibration when timer completes with vibrate setting', () => {
      const vibrateSpy = vi.spyOn(navigator, 'vibrate');

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'vibrate' });
      });

      act(() => {
        result.current.startRest(2, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      expect(vibrateSpy).toHaveBeenCalledWith([200, 100, 200]);
    });

    it('triggers vibration with both setting', () => {
      const vibrateSpy = vi.spyOn(navigator, 'vibrate');

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'both' });
      });

      act(() => {
        result.current.startRest(2, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      expect(vibrateSpy).toHaveBeenCalledWith([200, 100, 200]);
    });

    it('does not vibrate with none setting', () => {
      const vibrateSpy = vi.spyOn(navigator, 'vibrate');
      vibrateSpy.mockClear();

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'none' });
      });

      act(() => {
        result.current.startRest(2, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      expect(vibrateSpy).not.toHaveBeenCalled();
    });

    it('dispatches custom event for sound notification', () => {
      const eventHandler = vi.fn();
      window.addEventListener('rest-timer-complete', eventHandler);

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'sound' });
      });

      act(() => {
        result.current.startRest(2, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      expect(eventHandler).toHaveBeenCalled();

      window.removeEventListener('rest-timer-complete', eventHandler);
    });

    it('dispatches custom event with both setting', () => {
      const eventHandler = vi.fn();
      window.addEventListener('rest-timer-complete', eventHandler);

      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'both' });
      });

      act(() => {
        result.current.startRest(2, 'Back Squat');
      });

      act(() => {
        vi.advanceTimersByTime(2000);
      });

      // Advance timers to execute the setTimeout in triggerNotification
      act(() => {
        vi.advanceTimersByTime(10);
      });

      expect(eventHandler).toHaveBeenCalled();

      window.removeEventListener('rest-timer-complete', eventHandler);
    });
  });

  describe('setExpanded', () => {
    it('sets isExpanded to true', () => {
      const { result } = renderHook(() => useRestTimer());

      expect(result.current.isExpanded).toBe(false);

      act(() => {
        result.current.setExpanded(true);
      });

      expect(result.current.isExpanded).toBe(true);
    });

    it('sets isExpanded to false', () => {
      const { result } = renderHook(() => useRestTimer());

      // First expand
      act(() => {
        result.current.startRest(60, 'Back Squat');
      });

      expect(result.current.isExpanded).toBe(true);

      // Then collapse
      act(() => {
        result.current.setExpanded(false);
      });

      expect(result.current.isExpanded).toBe(false);
    });
  });

  describe('setSettings', () => {
    it('updates settings state', () => {
      const { result } = renderHook(() => useRestTimer());

      expect(result.current.settings.defaultRestSeconds).toBe(180);

      act(() => {
        result.current.setSettings({ defaultRestSeconds: 240 });
      });

      expect(result.current.settings.defaultRestSeconds).toBe(240);
    });

    it('merges partial settings with existing settings', () => {
      const { result } = renderHook(() => useRestTimer());

      const originalNotificationType = result.current.settings.notificationType;

      act(() => {
        result.current.setSettings({ defaultRestSeconds: 120 });
      });

      expect(result.current.settings.defaultRestSeconds).toBe(120);
      expect(result.current.settings.notificationType).toBe(originalNotificationType);
    });

    it('updates notification type', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.setSettings({ notificationType: 'none' });
      });

      expect(result.current.settings.notificationType).toBe('none');
    });
  });
});

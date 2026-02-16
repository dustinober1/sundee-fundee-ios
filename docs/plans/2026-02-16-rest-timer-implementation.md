# Rest Timer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a rest timer feature that auto-starts after logging sets, supports manual trigger, runs in background with notifications, and provides a floating pill UI with expandable controls.

**Architecture:** React Context for global timer state, custom hook for timing logic with Visibility API, Web Notifications for background alerts, floating pill component with expandable overlay for controls.

**Tech Stack:** React 19, TypeScript, Web Notifications API, Page Visibility API, localStorage, shadcn/ui components

---

## Task 1: Type Definitions

**Files:**
- Create: `src/types/rest-timer.ts`

**Step 1: Create rest timer types**

Create: `src/types/rest-timer.ts`

```typescript
export type TimerStatus = 'idle' | 'running' | 'paused' | 'complete';

export type NotificationType = 'sound' | 'vibrate' | 'both' | 'none';

export interface RestTimerState {
  status: TimerStatus;
  durationSeconds: number;
  remainingSeconds: number;
  startedAt: number | null;
  isExpanded: boolean;
  exerciseName: string | null;
}

export interface RestTimerSettings {
  notificationType: NotificationType;
  defaultRestSeconds: number;
  autoStartEnabled: boolean;
}

export const DEFAULT_REST_TIMER_SETTINGS: RestTimerSettings = {
  notificationType: 'both',
  defaultRestSeconds: 180,
  autoStartEnabled: true,
};
```

**Step 2: Commit**

Run:
```bash
git add src/types/rest-timer.ts
git commit -m "feat: add rest timer type definitions

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Timer Logic Hook

**Files:**
- Create: `src/hooks/useRestTimer.ts`
- Create: `tests/unit/hooks/useRestTimer.test.ts`

**Step 1: Write failing tests for timer hook**

Create: `tests/unit/hooks/useRestTimer.test.ts`

```typescript
import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useRestTimer } from '@/hooks/useRestTimer';

describe('useRestTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
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
        result.current.addTime(30);
      });

      expect(result.current.remainingSeconds).toBe(90);
      expect(result.current.durationSeconds).toBe(90);
    });

    it('subtracts time from remaining seconds', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
        result.current.subtractTime(30);
      });

      expect(result.current.remainingSeconds).toBe(30);
      expect(result.current.durationSeconds).toBe(30);
    });

    it('does not go below zero', () => {
      const { result } = renderHook(() => useRestTimer());

      act(() => {
        result.current.startRest(60, 'Back Squat');
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
```

**Step 2: Run tests to verify they fail**

Run: `npm run test:run tests/unit/hooks/useRestTimer.test.ts`
Expected: FAIL with "Cannot find module '@/hooks/useRestTimer'"

**Step 3: Create the timer hook implementation**

Create: `src/hooks/useRestTimer.ts`

```typescript
'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import {
  TimerStatus,
  RestTimerState,
  RestTimerSettings,
  DEFAULT_REST_TIMER_SETTINGS,
} from '@/types/rest-timer';

const SETTINGS_KEY = 'restTimerSettings';

function loadSettings(): RestTimerSettings {
  if (typeof window === 'undefined') return DEFAULT_REST_TIMER_SETTINGS;

  try {
    const stored = localStorage.getItem(SETTINGS_KEY);
    if (stored) {
      return { ...DEFAULT_REST_TIMER_SETTINGS, ...JSON.parse(stored) };
    }
  } catch {
    // Ignore parse errors
  }
  return DEFAULT_REST_TIMER_SETTINGS;
}

function saveSettings(settings: RestTimerSettings): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}

export function useRestTimer() {
  const [state, setState] = useState<RestTimerState>({
    status: 'idle',
    durationSeconds: 0,
    remainingSeconds: 0,
    startedAt: null,
    isExpanded: false,
    exerciseName: null,
  });

  const [settings, setSettingsState] = useState<RestTimerSettings>(loadSettings);

  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const hiddenAtRef = useRef<number | null>(null);

  // Cleanup interval on unmount
  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  // Visibility API handling
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // Store when we went hidden
        hiddenAtRef.current = Date.now();
        // Stop the interval to save resources
        if (intervalRef.current) {
          clearInterval(intervalRef.current);
          intervalRef.current = null;
        }
      } else {
        // Recalculate remaining time based on elapsed time while hidden
        if (state.status === 'running' && state.startedAt && hiddenAtRef.current) {
          const elapsed = Math.floor((Date.now() - state.startedAt) / 1000);
          const newRemaining = Math.max(0, state.durationSeconds - elapsed);

          setState(prev => ({
            ...prev,
            remainingSeconds: newRemaining,
          }));

          if (newRemaining === 0) {
            handleTimerComplete();
          } else {
            // Restart the interval
            startInterval();
          }
        }
        hiddenAtRef.current = null;
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [state.status, state.startedAt, state.durationSeconds]);

  const handleTimerComplete = useCallback(() => {
    setState(prev => ({
      ...prev,
      status: 'complete',
      remainingSeconds: 0,
    }));

    // Trigger notification
    triggerNotification();
  }, [settings]);

  const triggerNotification = useCallback(() => {
    if (settings.notificationType === 'none') return;

    // Play sound
    if (settings.notificationType === 'sound' || settings.notificationType === 'both') {
      const audio = new Audio('/audio/chime.mp3');
      audio.play().catch(() => {
        // Ignore autoplay errors
      });
    }

    // Vibrate
    if (settings.notificationType === 'vibrate' || settings.notificationType === 'both') {
      if ('vibrate' in navigator) {
        navigator.vibrate([200, 100, 200]);
      }
    }

    // Show notification if app is hidden
    if (document.hidden && 'Notification' in window) {
      if (Notification.permission === 'granted') {
        new Notification('Rest Complete!', {
          body: 'Time to get back to your workout.',
          icon: '/icon-192.png',
        });
      }
    }
  }, [settings.notificationType]);

  const startInterval = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }

    intervalRef.current = setInterval(() => {
      setState(prev => {
        if (prev.status !== 'running' || !prev.startedAt) return prev;

        const elapsed = Math.floor((Date.now() - prev.startedAt) / 1000);
        const newRemaining = Math.max(0, prev.durationSeconds - elapsed);

        if (newRemaining === 0) {
          // Clear interval before state update to prevent race
          if (intervalRef.current) {
            clearInterval(intervalRef.current);
            intervalRef.current = null;
          }
          // Use setTimeout to trigger notification after state update
          setTimeout(() => triggerNotification(), 0);
          return {
            ...prev,
            status: 'complete',
            remainingSeconds: 0,
          };
        }

        return {
          ...prev,
          remainingSeconds: newRemaining,
        };
      });
    }, 1000);
  }, [triggerNotification]);

  const startRest = useCallback((seconds: number, exerciseName?: string) => {
    // Request notification permission on first use
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }

    setState({
      status: 'running',
      durationSeconds: seconds,
      remainingSeconds: seconds,
      startedAt: Date.now(),
      isExpanded: false,
      exerciseName: exerciseName || null,
    });

    startInterval();
  }, [startInterval]);

  const pause = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setState(prev => {
      if (prev.status !== 'running') return prev;

      // Calculate accurate remaining time before pausing
      if (prev.startedAt) {
        const elapsed = Math.floor((Date.now() - prev.startedAt) / 1000);
        const newRemaining = Math.max(0, prev.durationSeconds - elapsed);
        return {
          ...prev,
          status: 'paused',
          remainingSeconds: newRemaining,
        };
      }

      return { ...prev, status: 'paused' };
    });
  }, []);

  const resume = useCallback(() => {
    setState(prev => {
      if (prev.status !== 'paused') return prev;

      // Reset startedAt to account for already elapsed time
      const elapsed = prev.durationSeconds - prev.remainingSeconds;
      const newStartedAt = Date.now() - (elapsed * 1000);

      return {
        ...prev,
        status: 'running',
        startedAt: newStartedAt,
      };
    });

    startInterval();
  }, [startInterval]);

  const addTime = useCallback((seconds: number) => {
    setState(prev => {
      const newDuration = prev.durationSeconds + seconds;
      const newRemaining = prev.remainingSeconds + seconds;

      // Adjust startedAt to reflect new duration
      let newStartedAt = prev.startedAt;
      if (prev.startedAt && prev.status === 'running') {
        newStartedAt = prev.startedAt + (seconds * 1000);
      }

      return {
        ...prev,
        durationSeconds: newDuration,
        remainingSeconds: newRemaining,
        startedAt: newStartedAt,
      };
    });
  }, []);

  const subtractTime = useCallback((seconds: number) => {
    setState(prev => {
      const newRemaining = Math.max(0, prev.remainingSeconds - seconds);
      const newDuration = Math.max(0, prev.durationSeconds - seconds);

      return {
        ...prev,
        durationSeconds: newDuration,
        remainingSeconds: newRemaining,
      };
    });
  }, []);

  const cancel = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setState({
      status: 'idle',
      durationSeconds: 0,
      remainingSeconds: 0,
      startedAt: null,
      isExpanded: false,
      exerciseName: null,
    });
  }, []);

  const skip = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    setState(prev => ({
      ...prev,
      status: 'complete',
      remainingSeconds: 0,
    }));
  }, []);

  const setExpanded = useCallback((isExpanded: boolean) => {
    setState(prev => ({ ...prev, isExpanded }));
  }, []);

  const setSettings = useCallback((newSettings: Partial<RestTimerSettings>) => {
    setSettingsState(prev => {
      const updated = { ...prev, ...newSettings };
      saveSettings(updated);
      return updated;
    });
  }, []);

  return {
    ...state,
    settings,
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
```

**Step 4: Run tests to verify they pass**

Run: `npm run test:run tests/unit/hooks/useRestTimer.test.ts`
Expected: All tests PASS

**Step 5: Commit**

Run:
```bash
git add src/hooks/useRestTimer.ts tests/unit/hooks/useRestTimer.test.ts
git commit -m "feat: add useRestTimer hook with core timer logic

- Start, pause, resume, cancel, skip controls
- Add/subtract time during countdown
- Visibility API for background handling
- Web Notifications support
- localStorage settings persistence

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Rest Timer Context

**Files:**
- Create: `src/contexts/RestTimerContext.tsx`
- Create: `tests/integration/contexts/RestTimerContext.test.tsx`

**Step 1: Write failing tests for context**

Create: `tests/integration/contexts/RestTimerContext.test.tsx`

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ReactNode } from 'react';
import {
  RestTimerProvider,
  useRestTimerContext,
} from '@/contexts/RestTimerContext';

function TestComponent() {
  const {
    status,
    remainingSeconds,
    exerciseName,
    startRest,
    pause,
    resume,
    cancel,
  } = useRestTimerContext();

  return (
    <div>
      <span data-testid="status">{status}</span>
      <span data-testid="remaining">{remainingSeconds}</span>
      <span data-testid="exercise">{exerciseName}</span>
      <button onClick={() => startRest(60, 'Test Exercise')}>Start</button>
      <button onClick={pause}>Pause</button>
      <button onClick={resume}>Resume</button>
      <button onClick={cancel}>Cancel</button>
    </div>
  );
}

function renderWithProvider(ui: ReactNode) {
  return render(<RestTimerProvider>{ui}</RestTimerProvider>);
}

describe('RestTimerContext', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('provides timer state to children', () => {
    renderWithProvider(<TestComponent />);

    expect(screen.getByTestId('status').textContent).toBe('idle');
    expect(screen.getByTestId('remaining').textContent).toBe('0');
  });

  it('allows starting rest timer', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderWithProvider(<TestComponent />);

    await user.click(screen.getByText('Start'));

    expect(screen.getByTestId('status').textContent).toBe('running');
    expect(screen.getByTestId('remaining').textContent).toBe('60');
    expect(screen.getByTestId('exercise').textContent).toBe('Test Exercise');
  });

  it('allows pausing and resuming', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderWithProvider(<TestComponent />);

    await user.click(screen.getByText('Start'));

    await vi.advanceTimersByTimeAsync(10000);

    await user.click(screen.getByText('Pause'));
    expect(screen.getByTestId('status').textContent).toBe('paused');

    await user.click(screen.getByText('Resume'));
    expect(screen.getByTestId('status').textContent).toBe('running');
  });

  it('allows canceling timer', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    renderWithProvider(<TestComponent />);

    await user.click(screen.getByText('Start'));
    await user.click(screen.getByText('Cancel'));

    expect(screen.getByTestId('status').textContent).toBe('idle');
    expect(screen.getByTestId('remaining').textContent).toBe('0');
    expect(screen.getByTestId('exercise').textContent).toBe('');
  });
});
```

**Step 2: Run tests to verify they fail**

Run: `npm run test:run tests/integration/contexts/RestTimerContext.test.tsx`
Expected: FAIL with "Cannot find module '@/contexts/RestTimerContext'"

**Step 3: Create the context**

Create: `src/contexts/RestTimerContext.tsx`

```typescript
'use client';

import { createContext, useContext, ReactNode } from 'react';
import { useRestTimer } from '@/hooks/useRestTimer';

interface RestTimerContextValue extends ReturnType<typeof useRestTimer> {}

const RestTimerContext = createContext<RestTimerContextValue | null>(null);

interface RestTimerProviderProps {
  children: ReactNode;
}

export function RestTimerProvider({ children }: RestTimerProviderProps) {
  const timer = useRestTimer();

  return (
    <RestTimerContext.Provider value={timer}>
      {children}
    </RestTimerContext.Provider>
  );
}

export function useRestTimerContext(): RestTimerContextValue {
  const context = useContext(RestTimerContext);
  if (!context) {
    throw new Error('useRestTimerContext must be used within a RestTimerProvider');
  }
  return context;
}
```

**Step 4: Run tests to verify they pass**

Run: `npm run test:run tests/integration/contexts/RestTimerContext.test.tsx`
Expected: All tests PASS

**Step 5: Commit**

Run:
```bash
git add src/contexts/RestTimerContext.tsx tests/integration/contexts/RestTimerContext.test.tsx
git commit -m "feat: add RestTimerContext for global timer state

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Rest Timer Pill Component

**Files:**
- Create: `src/components/rest-timer/RestTimerPill.tsx`
- Create: `tests/unit/components/RestTimerPill.test.tsx`

**Step 1: Write failing tests for pill component**

Create: `tests/unit/components/RestTimerPill.test.tsx`

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RestTimerPill } from '@/components/rest-timer/RestTimerPill';

// Mock the context hook
const mockContext = {
  status: 'running' as const,
  remainingSeconds: 90,
  durationSeconds: 180,
  exerciseName: 'Back Squat',
  isExpanded: false,
  setExpanded: vi.fn(),
};

vi.mock('@/contexts/RestTimerContext', () => ({
  useRestTimerContext: () => mockContext,
}));

describe('RestTimerPill', () => {
  it('renders when timer is running', () => {
    render(<RestTimerPill />);

    expect(screen.getByText(/1:30/)).toBeInTheDocument();
    expect(screen.getByText(/Back Squat/)).toBeInTheDocument();
  });

  it('does not render when timer is idle', () => {
    mockContext.status = 'idle';
    mockContext.remainingSeconds = 0;

    render(<RestTimerPill />);

    expect(screen.queryByText(/Back Squat/)).not.toBeInTheDocument();
  });

  it('calls setExpanded when clicked', async () => {
    const user = userEvent.setup();
    mockContext.status = 'running';
    mockContext.remainingSeconds = 90;

    render(<RestTimerPill />);

    await user.click(screen.getByRole('button'));

    expect(mockContext.setExpanded).toHaveBeenCalledWith(true);
  });

  it('formats time correctly for minutes and seconds', () => {
    mockContext.remainingSeconds = 125; // 2:05

    render(<RestTimerPill />);

    expect(screen.getByText(/2:05/)).toBeInTheDocument();
  });

  it('shows 0:xx for times under a minute', () => {
    mockContext.remainingSeconds = 45;

    render(<RestTimerPill />);

    expect(screen.getByText(/0:45/)).toBeInTheDocument();
  });
});
```

**Step 2: Run tests to verify they fail**

Run: `npm run test:run tests/unit/components/RestTimerPill.test.tsx`
Expected: FAIL with "Cannot find module"

**Step 3: Create the pill component**

Create: `src/components/rest-timer/RestTimerPill.tsx`

```typescript
'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { cn } from '@/lib/utils';
import { Timer, ChevronUp } from 'lucide-react';

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export function RestTimerPill() {
  const { status, remainingSeconds, exerciseName, isExpanded, setExpanded } =
    useRestTimerContext();

  // Don't render if idle or complete
  if (status === 'idle' || status === 'complete') {
    return null;
  }

  // Calculate progress percentage
  const progress = 1 - remainingSeconds / 180; // Simplified, max 3 min arc

  return (
    <button
      onClick={() => setExpanded(true)}
      className={cn(
        'fixed bottom-20 left-1/2 -translate-x-1/2 z-40',
        'flex items-center gap-2 px-4 py-2 rounded-full',
        'bg-primary text-primary-foreground shadow-lg',
        'transition-all duration-200',
        'hover:scale-105 active:scale-95',
        remainingSeconds <= 10 && 'animate-pulse'
      )}
      aria-label={`Rest timer: ${formatTime(remainingSeconds)} remaining`}
    >
      <Timer className="h-4 w-4" />
      <span className="font-mono text-sm font-medium">
        {formatTime(remainingSeconds)}
      </span>
      {exerciseName && (
        <span className="text-xs opacity-80 max-w-24 truncate">
          Rest: {exerciseName}
        </span>
      )}
      <ChevronUp className="h-4 w-4 opacity-60" />
    </button>
  );
}
```

**Step 4: Run tests to verify they pass**

Run: `npm run test:run tests/unit/components/RestTimerPill.test.tsx`
Expected: All tests PASS

**Step 5: Commit**

Run:
```bash
git add src/components/rest-timer/RestTimerPill.tsx tests/unit/components/RestTimerPill.test.tsx
git commit -m "feat: add RestTimerPill component

- Floating pill UI at bottom of screen
- Shows remaining time and exercise name
- Expands on tap for full controls
- Pulses animation when < 10 seconds

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Rest Timer Expanded Overlay

**Files:**
- Create: `src/components/rest-timer/RestTimerExpanded.tsx`
- Create: `tests/unit/components/RestTimerExpanded.test.tsx`

**Step 1: Write failing tests for expanded overlay**

Create: `tests/unit/components/RestTimerExpanded.test.tsx`

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RestTimerExpanded } from '@/components/rest-timer/RestTimerExpanded';

const mockContext = {
  status: 'running' as const,
  remainingSeconds: 90,
  durationSeconds: 180,
  exerciseName: 'Back Squat',
  isExpanded: true,
  pause: vi.fn(),
  resume: vi.fn(),
  addTime: vi.fn(),
  subtractTime: vi.fn(),
  cancel: vi.fn(),
  skip: vi.fn(),
  setExpanded: vi.fn(),
};

vi.mock('@/contexts/RestTimerContext', () => ({
  useRestTimerContext: () => mockContext,
}));

describe('RestTimerExpanded', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders when expanded', () => {
    render(<RestTimerExpanded />);

    expect(screen.getByText(/1:30/)).toBeInTheDocument();
    expect(screen.getByText(/Back Squat/)).toBeInTheDocument();
  });

  it('does not render when not expanded', () => {
    mockContext.isExpanded = false;

    render(<RestTimerExpanded />);

    expect(screen.queryByText(/Back Squat/)).not.toBeInTheDocument();
  });

  it('shows pause button when running', () => {
    mockContext.isExpanded = true;
    mockContext.status = 'running';

    render(<RestTimerExpanded />);

    expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument();
  });

  it('shows resume button when paused', () => {
    mockContext.status = 'paused';

    render(<RestTimerExpanded />);

    expect(screen.getByRole('button', { name: /resume/i })).toBeInTheDocument();
  });

  it('calls addTime when +30s button clicked', async () => {
    const user = userEvent.setup();
    mockContext.status = 'running';

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /\+30s/i }));

    expect(mockContext.addTime).toHaveBeenCalledWith(30);
  });

  it('calls subtractTime when -30s button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /-30s/i }));

    expect(mockContext.subtractTime).toHaveBeenCalledWith(30);
  });

  it('calls skip when skip button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /skip/i }));

    expect(mockContext.skip).toHaveBeenCalled();
  });

  it('calls cancel and closes when cancel button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /cancel/i }));

    expect(mockContext.cancel).toHaveBeenCalled();
    expect(mockContext.setExpanded).toHaveBeenCalledWith(false);
  });
});
```

**Step 2: Run tests to verify they fail**

Run: `npm run test:run tests/unit/components/RestTimerExpanded.test.tsx`
Expected: FAIL with "Cannot find module"

**Step 3: Create the expanded overlay component**

Create: `src/components/rest-timer/RestTimerExpanded.tsx`

```typescript
'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { X, Play, Pause, SkipForward, Plus, Minus } from 'lucide-react';

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export function RestTimerExpanded() {
  const {
    status,
    remainingSeconds,
    durationSeconds,
    exerciseName,
    isExpanded,
    pause,
    resume,
    addTime,
    subtractTime,
    cancel,
    skip,
    setExpanded,
  } = useRestTimerContext();

  if (!isExpanded) {
    return null;
  }

  const handleClose = () => {
    setExpanded(false);
  };

  const handleCancel = () => {
    cancel();
    setExpanded(false);
  };

  // Calculate progress for circular indicator
  const progress = durationSeconds > 0 ? remainingSeconds / durationSeconds : 0;
  const circumference = 2 * Math.PI * 90; // radius = 90
  const strokeDashoffset = circumference * (1 - progress);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
      onClick={handleClose}
    >
      <div
        className={cn(
          'bg-card rounded-2xl p-6 w-[90%] max-w-sm',
          'flex flex-col items-center gap-6',
          'animate-in fade-in zoom-in-95 duration-200'
        )}
        onClick={e => e.stopPropagation()}
      >
        {/* Close button */}
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 p-2 rounded-full hover:bg-muted"
          aria-label="Close"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Circular progress with time */}
        <div className="relative w-48 h-48">
          <svg className="w-full h-full -rotate-90">
            {/* Background circle */}
            <circle
              cx="96"
              cy="96"
              r="90"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-muted"
            />
            {/* Progress circle */}
            <circle
              cx="96"
              cy="96"
              r="90"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-primary transition-all duration-1000"
              strokeLinecap="round"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-4xl font-mono font-bold">
              {formatTime(remainingSeconds)}
            </span>
          </div>
        </div>

        {/* Exercise info */}
        <div className="text-center">
          <p className="font-medium">{exerciseName || 'Rest'}</p>
          <p className="text-sm text-muted-foreground">
            Prescribed: {formatTime(durationSeconds)}
          </p>
        </div>

        {/* Time adjustment buttons */}
        <div className="flex items-center gap-4">
          <Button
            variant="outline"
            size="sm"
            onClick={() => subtractTime(30)}
            disabled={remainingSeconds < 30}
          >
            <Minus className="h-4 w-4 mr-1" />
            30s
          </Button>
          <Button variant="outline" size="sm" onClick={() => addTime(30)}>
            <Plus className="h-4 w-4 mr-1" />
            30s
          </Button>
        </div>

        {/* Control buttons */}
        <div className="flex items-center gap-4">
          {status === 'running' ? (
            <Button variant="secondary" onClick={pause}>
              <Pause className="h-4 w-4 mr-2" />
              Pause
            </Button>
          ) : (
            <Button variant="secondary" onClick={resume}>
              <Play className="h-4 w-4 mr-2" />
              Resume
            </Button>
          )}
          <Button variant="default" onClick={skip}>
            <SkipForward className="h-4 w-4 mr-2" />
            Skip
          </Button>
        </div>

        {/* Cancel button */}
        <Button variant="ghost" onClick={handleCancel}>
          Cancel
        </Button>
      </div>
    </div>
  );
}
```

**Step 4: Run tests to verify they pass**

Run: `npm run test:run tests/unit/components/RestTimerExpanded.test.tsx`
Expected: All tests PASS

**Step 5: Commit**

Run:
```bash
git add src/components/rest-timer/RestTimerExpanded.tsx tests/unit/components/RestTimerExpanded.test.tsx
git commit -m "feat: add RestTimerExpanded overlay component

- Full-screen overlay with backdrop blur
- Circular progress indicator
- Pause/resume, add/subtract time, skip, cancel
- Large time display

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Rest Timer Settings Component

**Files:**
- Create: `src/components/rest-timer/RestTimerSettings.tsx`

**Step 1: Create settings component**

Create: `src/components/rest-timer/RestTimerSettings.tsx`

```typescript
'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Switch } from '@/components/ui/switch';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { NotificationType } from '@/types/rest-timer';

export function RestTimerSettings() {
  const { settings, setSettings } = useRestTimerContext();

  return (
    <div className="space-y-6">
      <div className="space-y-3">
        <Label className="text-base">Notification Type</Label>
        <RadioGroup
          value={settings.notificationType}
          onValueChange={(value: NotificationType) =>
            setSettings({ notificationType: value })
          }
          className="grid grid-cols-2 gap-2"
        >
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="sound" id="sound" />
            <Label htmlFor="sound" className="font-normal">
              Sound only
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="vibrate" id="vibrate" />
            <Label htmlFor="vibrate" className="font-normal">
              Vibration only
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="both" id="both" />
            <Label htmlFor="both" className="font-normal">
              Both
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="none" id="none" />
            <Label htmlFor="none" className="font-normal">
              None
            </Label>
          </div>
        </RadioGroup>
      </div>

      <div className="space-y-3">
        <Label className="text-base">Default Rest Time</Label>
        <Select
          value={String(settings.defaultRestSeconds)}
          onValueChange={value =>
            setSettings({ defaultRestSeconds: parseInt(value, 10) })
          }
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="60">1 minute</SelectItem>
            <SelectItem value="90">1.5 minutes</SelectItem>
            <SelectItem value="120">2 minutes</SelectItem>
            <SelectItem value="180">3 minutes</SelectItem>
            <SelectItem value="240">4 minutes</SelectItem>
            <SelectItem value="300">5 minutes</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label className="text-base">Auto-start after set</Label>
          <p className="text-sm text-muted-foreground">
            Automatically start timer when you log a set
          </p>
        </div>
        <Switch
          checked={settings.autoStartEnabled}
          onCheckedChange={checked =>
            setSettings({ autoStartEnabled: checked })
          }
        />
      </div>
    </div>
  );
}
```

**Step 2: Commit**

Run:
```bash
git add src/components/rest-timer/RestTimerSettings.tsx
git commit -m "feat: add RestTimerSettings component

- Notification type selection (sound/vibrate/both/none)
- Default rest time dropdown
- Auto-start toggle

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Component Index and Exports

**Files:**
- Create: `src/components/rest-timer/index.ts`

**Step 1: Create index file**

Create: `src/components/rest-timer/index.ts`

```typescript
export { RestTimerPill } from './RestTimerPill';
export { RestTimerExpanded } from './RestTimerExpanded';
export { RestTimerSettings } from './RestTimerSettings';
```

**Step 2: Commit**

Run:
```bash
git add src/components/rest-timer/index.ts
git commit -m "feat: add rest-timer component exports

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Add Audio File

**Files:**
- Create: `public/audio/chime.mp3`

**Step 1: Add placeholder audio file**

Note: For the implementation, you'll need to add an actual audio file. For now, create a placeholder.

Run:
```bash
mkdir -p public/audio
touch public/audio/.gitkeep
```

**Step 2: Commit**

Run:
```bash
git add public/audio/.gitkeep
git commit -m "chore: add audio directory for rest timer chime

Note: Add actual chime.mp3 file before deployment

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: Integrate Rest Timer into Workout Page

**Files:**
- Modify: `src/app/workout/[id]/page.tsx`

**Step 1: Add RestTimerProvider and components to workout page**

Read the current workout page first to understand its structure, then add:

1. Import `RestTimerProvider` and wrap the page content
2. Import `RestTimerPill` and `RestTimerExpanded` and render them

In `src/app/workout/[id]/page.tsx`, add at the top of the component:

```typescript
import { RestTimerProvider } from '@/contexts/RestTimerContext';
import { RestTimerPill, RestTimerExpanded } from '@/components/rest-timer';
```

Wrap the main content with the provider:

```typescript
return (
  <RestTimerProvider>
    {/* existing page content */}
    <RestTimerPill />
    <RestTimerExpanded />
  </RestTimerProvider>
);
```

**Step 2: Commit**

Run:
```bash
git add src/app/workout/[id]/page.tsx
git commit -m "feat: integrate rest timer into workout page

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: Auto-Start Timer from Set Logger

**Files:**
- Modify: `src/app/workout/[id]/page.tsx` (or wherever set logging happens)

**Step 1: Add auto-start trigger when logging sets**

Find the set completion handler and add timer start:

```typescript
import { useRestTimerContext } from '@/contexts/RestTimerContext';

// Inside the component:
const { startRest, settings } = useRestTimerContext();

// In the handleSetComplete function:
const handleSetComplete = (exercise: Exercise) => {
  // ... existing set logging logic

  // Auto-start rest timer if enabled
  if (settings.autoStartEnabled) {
    const restSeconds = (exercise.restMinutes || 3) * 60;
    startRest(restSeconds, exercise.name);
  }
};
```

**Step 2: Commit**

Run:
```bash
git add src/app/workout/[id]/page.tsx
git commit -m "feat: auto-start rest timer after set completion

Triggers timer with program's prescribed rest time
when user logs a completed set

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: Run Full Test Suite

**Step 1: Run all tests**

Run:
```bash
npm run test:run
```

Expected: All tests PASS

**Step 2: Fix any failures**

If tests fail, debug and fix issues before proceeding.

---

## Task 12: Manual Testing

**Step 1: Start dev server**

Run:
```bash
npm run dev
```

**Step 2: Test rest timer functionality**

1. Navigate to `/workout/[id]`
2. Log a completed set
3. Verify timer pill appears at bottom
4. Tap pill to expand
5. Test pause/resume
6. Test add/subtract time
7. Test skip and cancel
8. Background app during timer, verify notification

---

## Task 13: Final Commit

**Step 1: Ensure all changes are committed**

Run:
```bash
git status
```

If any uncommitted changes:

Run:
```bash
git add .
git commit -m "feat: complete rest timer feature implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

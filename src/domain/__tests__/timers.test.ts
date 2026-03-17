import {
  createTimerState,
  getElapsedMs,
  getRemainingMs,
  pauseTimer,
  resumeTimer,
  isTimerComplete,
  getEMOMCurrentMinute,
} from '../timers/timer-state';
import type { TimerState } from '../timers/timer-state';

// Deterministic base time for tests
const BASE_NOW = 1_000_000;

function makeTimer(
  mode: Parameters<typeof createTimerState>[0],
  durationMs: number,
  intervalMs?: number,
  startedAt = BASE_NOW,
): TimerState {
  return {
    startedAt,
    pausedAt: null,
    totalPausedMs: 0,
    durationMs,
    mode,
    intervalMs,
  };
}

describe('createTimerState', () => {
  it('creates a timer with correct mode and durationMs', () => {
    const before = Date.now();
    const state = createTimerState('rest', 90_000);
    const after = Date.now();

    expect(state.mode).toBe('rest');
    expect(state.durationMs).toBe(90_000);
    expect(state.pausedAt).toBeNull();
    expect(state.totalPausedMs).toBe(0);
    expect(state.startedAt).toBeGreaterThanOrEqual(before);
    expect(state.startedAt).toBeLessThanOrEqual(after);
  });

  it('stores optional intervalMs', () => {
    const state = createTimerState('emom', 600_000, 60_000);
    expect(state.intervalMs).toBe(60_000);
  });
});

describe('getElapsedMs', () => {
  it('returns elapsed time from startedAt', () => {
    const state = makeTimer('rest', 90_000);
    const now = BASE_NOW + 10_000;
    expect(getElapsedMs(state, now)).toBe(10_000);
  });

  it('subtracts totalPausedMs from elapsed', () => {
    const state: TimerState = {
      ...makeTimer('rest', 90_000),
      totalPausedMs: 5_000,
    };
    const now = BASE_NOW + 15_000;
    expect(getElapsedMs(state, now)).toBe(10_000);
  });

  it('uses pausedAt instead of now when timer is paused', () => {
    const pausedAt = BASE_NOW + 7_000;
    const state: TimerState = {
      ...makeTimer('rest', 90_000),
      pausedAt,
    };
    // Even passing a later "now", it should use pausedAt
    const laterNow = BASE_NOW + 20_000;
    expect(getElapsedMs(state, laterNow)).toBe(7_000);
  });

  it('returns 0 when called at exact start time', () => {
    const state = makeTimer('rest', 90_000);
    expect(getElapsedMs(state, BASE_NOW)).toBe(0);
  });
});

describe('getRemainingMs', () => {
  it('returns durationMs minus elapsed for rest mode', () => {
    const state = makeTimer('rest', 90_000);
    const now = BASE_NOW + 30_000;
    expect(getRemainingMs(state, now)).toBe(60_000);
  });

  it('clamps to 0 when elapsed exceeds duration', () => {
    const state = makeTimer('rest', 90_000);
    const now = BASE_NOW + 100_000;
    expect(getRemainingMs(state, now)).toBe(0);
  });

  it('returns 0 for forTime mode (durationMs = 0)', () => {
    const state = makeTimer('forTime', 0);
    const now = BASE_NOW + 30_000;
    expect(getRemainingMs(state, now)).toBe(0);
  });

  it('counts down from durationMs for amrap mode', () => {
    const state = makeTimer('amrap', 600_000);
    const now = BASE_NOW + 120_000;
    expect(getRemainingMs(state, now)).toBe(480_000);
  });
});

describe('pauseTimer', () => {
  it('sets pausedAt to current time', () => {
    const state = makeTimer('rest', 90_000);
    const now = BASE_NOW + 10_000;
    const paused = pauseTimer(state, now);
    expect(paused.pausedAt).toBe(now);
  });

  it('does not change other fields when pausing', () => {
    const state = makeTimer('rest', 90_000);
    const paused = pauseTimer(state, BASE_NOW + 5_000);
    expect(paused.totalPausedMs).toBe(0);
    expect(paused.startedAt).toBe(BASE_NOW);
    expect(paused.durationMs).toBe(90_000);
  });

  it('returns a new object (immutable)', () => {
    const state = makeTimer('rest', 90_000);
    const paused = pauseTimer(state, BASE_NOW + 5_000);
    expect(paused).not.toBe(state);
  });
});

describe('resumeTimer', () => {
  it('accumulates pause duration into totalPausedMs', () => {
    const pausedAt = BASE_NOW + 10_000;
    const state: TimerState = {
      ...makeTimer('rest', 90_000),
      pausedAt,
    };
    const resumeNow = BASE_NOW + 15_000; // paused for 5s
    const resumed = resumeTimer(state, resumeNow);
    expect(resumed.totalPausedMs).toBe(5_000);
    expect(resumed.pausedAt).toBeNull();
  });

  it('accumulates multiple pause periods', () => {
    const state: TimerState = {
      ...makeTimer('rest', 90_000),
      pausedAt: BASE_NOW + 20_000,
      totalPausedMs: 5_000, // already paused 5s before
    };
    const resumed = resumeTimer(state, BASE_NOW + 25_000); // paused another 5s
    expect(resumed.totalPausedMs).toBe(10_000);
  });

  it('clears pausedAt after resuming', () => {
    const state: TimerState = {
      ...makeTimer('rest', 90_000),
      pausedAt: BASE_NOW + 10_000,
    };
    const resumed = resumeTimer(state, BASE_NOW + 15_000);
    expect(resumed.pausedAt).toBeNull();
  });
});

describe('isTimerComplete', () => {
  it('returns true when elapsed >= duration for rest mode', () => {
    const state = makeTimer('rest', 90_000);
    expect(isTimerComplete(state, BASE_NOW + 90_000)).toBe(true);
    expect(isTimerComplete(state, BASE_NOW + 100_000)).toBe(true);
  });

  it('returns false when elapsed < duration', () => {
    const state = makeTimer('rest', 90_000);
    expect(isTimerComplete(state, BASE_NOW + 89_999)).toBe(false);
  });

  it('returns false for forTime mode regardless of elapsed (duration = 0)', () => {
    const state = makeTimer('forTime', 0);
    expect(isTimerComplete(state, BASE_NOW + 999_999)).toBe(false);
  });

  it('returns true for amrap when countdown reaches 0', () => {
    const state = makeTimer('amrap', 600_000);
    expect(isTimerComplete(state, BASE_NOW + 600_000)).toBe(true);
    expect(isTimerComplete(state, BASE_NOW + 599_999)).toBe(false);
  });
});

describe('getEMOMCurrentMinute', () => {
  it('returns 1 at start', () => {
    const state = makeTimer('emom', 600_000);
    expect(getEMOMCurrentMinute(state, BASE_NOW)).toBe(1);
  });

  it('returns 2 at 60 seconds', () => {
    const state = makeTimer('emom', 600_000);
    expect(getEMOMCurrentMinute(state, BASE_NOW + 60_000)).toBe(2);
  });

  it('returns 3 at 2 minutes', () => {
    const state = makeTimer('emom', 600_000);
    expect(getEMOMCurrentMinute(state, BASE_NOW + 120_000)).toBe(3);
  });

  it('accounts for paused time in minute calculation', () => {
    const state: TimerState = {
      ...makeTimer('emom', 600_000),
      totalPausedMs: 30_000, // paused for 30s
    };
    // At BASE_NOW + 90s, but 30s was paused, so effective elapsed = 60s => minute 2
    expect(getEMOMCurrentMinute(state, BASE_NOW + 90_000)).toBe(2);
  });
});

describe('pauseTimer accepts optional now parameter', () => {
  it('uses Date.now() when no now provided and timer is not paused', () => {
    const state = makeTimer('rest', 90_000, undefined, Date.now() - 5_000);
    const paused = pauseTimer(state);
    expect(paused.pausedAt).not.toBeNull();
    expect(paused.pausedAt!).toBeGreaterThan(state.startedAt);
  });
});

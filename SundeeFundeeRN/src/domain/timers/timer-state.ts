export type TimerMode = 'rest' | 'forTime' | 'amrap' | 'emom';

export interface TimerState {
  /** Unix timestamp (ms) when the timer was started or last resumed. */
  startedAt: number;
  /** Unix timestamp (ms) when the timer was paused, or null if running. */
  pausedAt: number | null;
  /** Accumulated pause duration in milliseconds across all pause/resume cycles. */
  totalPausedMs: number;
  /** Total intended duration in milliseconds. 0 for forTime (stopwatch) mode. */
  durationMs: number;
  /** Timer operational mode. */
  mode: TimerMode;
  /** Interval duration in ms, used for EMOM interval boundaries. */
  intervalMs?: number;
}

/**
 * Create a new timer state with startedAt set to now.
 */
export function createTimerState(
  mode: TimerMode,
  durationMs: number,
  intervalMs?: number,
): TimerState {
  return {
    startedAt: Date.now(),
    pausedAt: null,
    totalPausedMs: 0,
    durationMs,
    mode,
    intervalMs,
  };
}

/**
 * Get elapsed active milliseconds, excluding any paused time.
 *
 * If the timer is currently paused, uses pausedAt as the reference point
 * (so elapsed stays frozen while paused). Accepts optional `now` for
 * deterministic testing.
 */
export function getElapsedMs(state: TimerState, now?: number): number {
  const referenceTime = state.pausedAt ?? (now ?? Date.now());
  return referenceTime - state.startedAt - state.totalPausedMs;
}

/**
 * Get remaining milliseconds until the timer completes.
 *
 * Returns 0 for forTime mode (durationMs = 0) and clamps to 0 minimum.
 */
export function getRemainingMs(state: TimerState, now?: number): number {
  return Math.max(0, state.durationMs - getElapsedMs(state, now));
}

/**
 * Pause the timer by recording the current time.
 * Returns a new TimerState (immutable).
 */
export function pauseTimer(state: TimerState, now?: number): TimerState {
  return {
    ...state,
    pausedAt: now ?? Date.now(),
  };
}

/**
 * Resume the timer by accumulating the pause duration into totalPausedMs
 * and clearing pausedAt.
 * Returns a new TimerState (immutable).
 */
export function resumeTimer(state: TimerState, now?: number): TimerState {
  if (state.pausedAt === null) {
    return state;
  }
  const pauseDuration = (now ?? Date.now()) - state.pausedAt;
  return {
    ...state,
    pausedAt: null,
    totalPausedMs: state.totalPausedMs + pauseDuration,
  };
}

/**
 * Returns true when the timer has completed.
 *
 * forTime mode (durationMs = 0) never auto-completes — user stops manually.
 * All other modes complete when elapsed >= durationMs.
 */
export function isTimerComplete(state: TimerState, now?: number): boolean {
  if (state.durationMs === 0) {
    return false;
  }
  return getElapsedMs(state, now) >= state.durationMs;
}

/**
 * Returns the current EMOM minute number (1-indexed).
 * Minute 1 is [0, 60s), minute 2 is [60s, 120s), etc.
 */
export function getEMOMCurrentMinute(state: TimerState, now?: number): number {
  const elapsed = getElapsedMs(state, now);
  return Math.floor(elapsed / 60_000) + 1;
}

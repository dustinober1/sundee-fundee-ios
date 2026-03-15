/* istanbul ignore file */
export type { TimerState, TimerMode } from './timer-state';
export {
  createTimerState,
  getElapsedMs,
  getRemainingMs,
  pauseTimer,
  resumeTimer,
  isTimerComplete,
  getEMOMCurrentMinute,
} from './timer-state';

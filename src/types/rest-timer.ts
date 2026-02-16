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

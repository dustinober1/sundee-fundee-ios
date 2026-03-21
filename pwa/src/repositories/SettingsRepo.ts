import { FirestoreSettingsRepo } from './FirestoreSettingsRepo';
import { LocalSettingsRepo } from './LocalSettingsRepo';

export interface AppSettings {
  weightUnit: 'lb' | 'kg';
  defaultRestDuration: number;
  restTimerAlertsEnabled: boolean;
  workoutRemindersEnabled: boolean;
  wodAlertsEnabled: boolean;
  subscriptionAlertsEnabled: boolean;
  reminderHour: number;
  reminderMinute: number;
}

export const DEFAULT_SETTINGS: AppSettings = {
  weightUnit: 'lb',
  defaultRestDuration: 90,
  restTimerAlertsEnabled: true,
  workoutRemindersEnabled: false,
  wodAlertsEnabled: true,
  subscriptionAlertsEnabled: true,
  reminderHour: 7,
  reminderMinute: 0,
};

export interface SettingsRepository {
  saveSettings(uid: string, settings: AppSettings): Promise<void>;
  getSettings(uid: string): Promise<AppSettings | null>;
}

export function getSettingsRepo(isGuest: boolean): SettingsRepository {
  return isGuest ? new LocalSettingsRepo() : new FirestoreSettingsRepo();
}

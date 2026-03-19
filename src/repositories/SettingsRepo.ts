/**
 * SettingsRepository interface and factory function.
 *
 * Defines the contract for app settings persistence.
 * Implementations:
 *   - FirestoreSettingsRepo: authenticated users (merged into /users/{uid})
 *   - LocalSettingsRepo: guest users (@sundee/settings key)
 *
 * Note: Settings are merged into /users/{uid} (same doc as profile) to avoid
 * an extra Firestore read on startup.
 */
import { FirestoreSettingsRepo } from './FirestoreSettingsRepo';
import { LocalSettingsRepo } from './LocalSettingsRepo';

export interface AppSettings {
  weightUnit: 'lb' | 'kg';
  /** Default rest timer duration in seconds. Defaults to 90. */
  defaultRestDuration: number;
  /** Whether to send a local notification when the rest timer completes. Defaults to true. */
  restTimerAlertsEnabled: boolean;
  /** Whether to send daily workout reminder notifications. Defaults to false. */
  workoutRemindersEnabled: boolean;
  /** Whether to send WOD availability alerts. Defaults to true. */
  wodAlertsEnabled: boolean;
  /** Whether to send subscription renewal/expiry alerts. Defaults to true. */
  subscriptionAlertsEnabled: boolean;
  /** Hour of day (0–23) for the daily workout reminder. Defaults to 7 (7 AM). */
  reminderHour: number;
  /** Minute (0–59) for the daily workout reminder. Defaults to 0. */
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

/**
 * Returns the appropriate SettingsRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getSettingsRepo(isGuest: boolean): SettingsRepository {
  return isGuest
    ? new LocalSettingsRepo()
    : new FirestoreSettingsRepo();
}

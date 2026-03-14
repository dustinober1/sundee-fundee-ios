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
  notificationsEnabled: boolean;
}

export const DEFAULT_SETTINGS: AppSettings = {
  weightUnit: 'lb',
  notificationsEnabled: true,
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

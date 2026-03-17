/**
 * LocalSettingsRepo — AsyncStorage implementation of SettingsRepository.
 *
 * Persists app settings locally for guest (anonymous) users.
 * Data is stored under the key '@sundee/settings'.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { AppSettings, SettingsRepository } from './SettingsRepo';

const SETTINGS_KEY = '@sundee/settings';

export class LocalSettingsRepo implements SettingsRepository {
  /**
   * Stores app settings to AsyncStorage as a JSON string.
   */
  async saveSettings(_uid: string, settings: AppSettings): Promise<void> {
    await AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
  }

  /**
   * Retrieves and parses app settings from AsyncStorage.
   * Returns null if no settings are stored.
   */
  async getSettings(_uid: string): Promise<AppSettings | null> {
    const raw = await AsyncStorage.getItem(SETTINGS_KEY);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as AppSettings;
  }
}

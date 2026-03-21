import type { AppSettings, SettingsRepository } from './SettingsRepo';

const SETTINGS_KEY = '@sundee/settings';

export class LocalSettingsRepo implements SettingsRepository {
  async saveSettings(_uid: string, settings: AppSettings): Promise<void> {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
  }

  async getSettings(_uid: string): Promise<AppSettings | null> {
    const raw = localStorage.getItem(SETTINGS_KEY);
    return raw ? (JSON.parse(raw) as AppSettings) : null;
  }
}

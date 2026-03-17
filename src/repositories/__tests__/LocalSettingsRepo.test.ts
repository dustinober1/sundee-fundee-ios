/**
 * Tests for LocalSettingsRepo — AsyncStorage implementation of SettingsRepository.
 */
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
  getAllKeys: jest.fn().mockResolvedValue([]),
  multiGet: jest.fn().mockResolvedValue([]),
  multiRemove: jest.fn().mockResolvedValue(undefined),
}));

import AsyncStorage from '@react-native-async-storage/async-storage';
import { LocalSettingsRepo } from '../LocalSettingsRepo';
import type { AppSettings } from '../SettingsRepo';

const SETTINGS_KEY = '@sundee/settings';

const testSettings: AppSettings = {
  weightUnit: 'lb',
  notificationsEnabled: true,
};

describe('LocalSettingsRepo', () => {
  let repo: LocalSettingsRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalSettingsRepo();
  });

  it('saveSettings stores settings to AsyncStorage under "@sundee/settings"', async () => {
    await repo.saveSettings('guest-uid', testSettings);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      SETTINGS_KEY,
      JSON.stringify(testSettings)
    );
  });

  it('getSettings retrieves and parses settings from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testSettings));

    const result = await repo.getSettings('guest-uid');

    expect(AsyncStorage.getItem).toHaveBeenCalledWith(SETTINGS_KEY);
    expect(result).toEqual(testSettings);
  });

  it('getSettings returns null when no settings stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getSettings('guest-uid');

    expect(result).toBeNull();
  });
});

/**
 * Tests for AppSettings interface and DEFAULT_SETTINGS in SettingsRepo.
 */

import { DEFAULT_SETTINGS } from '../SettingsRepo';
import type { AppSettings } from '../SettingsRepo';

describe('AppSettings', () => {
  describe('DEFAULT_SETTINGS', () => {
    it('has weightUnit defaulting to lb', () => {
      expect(DEFAULT_SETTINGS.weightUnit).toBe('lb');
    });

    it('has defaultRestDuration defaulting to 90', () => {
      expect(DEFAULT_SETTINGS.defaultRestDuration).toBe(90);
    });

    it('has restTimerAlertsEnabled defaulting to true', () => {
      expect(DEFAULT_SETTINGS.restTimerAlertsEnabled).toBe(true);
    });

    it('has workoutRemindersEnabled defaulting to false', () => {
      expect(DEFAULT_SETTINGS.workoutRemindersEnabled).toBe(false);
    });

    it('has wodAlertsEnabled defaulting to true', () => {
      expect(DEFAULT_SETTINGS.wodAlertsEnabled).toBe(true);
    });

    it('has subscriptionAlertsEnabled defaulting to true', () => {
      expect(DEFAULT_SETTINGS.subscriptionAlertsEnabled).toBe(true);
    });

    it('has reminderHour defaulting to 7', () => {
      expect(DEFAULT_SETTINGS.reminderHour).toBe(7);
    });

    it('has reminderMinute defaulting to 0', () => {
      expect(DEFAULT_SETTINGS.reminderMinute).toBe(0);
    });

    it('does NOT have notificationsEnabled (old field removed)', () => {
      expect('notificationsEnabled' in DEFAULT_SETTINGS).toBe(false);
    });
  });

  describe('AppSettings type shape', () => {
    it('new settings object satisfies AppSettings type', () => {
      const settings: AppSettings = {
        weightUnit: 'kg',
        defaultRestDuration: 120,
        restTimerAlertsEnabled: false,
        workoutRemindersEnabled: true,
        wodAlertsEnabled: false,
        subscriptionAlertsEnabled: false,
        reminderHour: 8,
        reminderMinute: 30,
      };
      expect(settings).toBeDefined();
    });
  });
});

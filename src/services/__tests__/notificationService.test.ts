/**
 * Tests for notificationService.
 *
 * expo-notifications is manually mocked below to ensure SchedulableTriggerInputTypes is available.
 * AsyncStorage and Platform are also manually mocked.
 */

jest.mock('expo-notifications', () => ({
  scheduleNotificationAsync: jest.fn().mockResolvedValue('new-notification-id'),
  cancelScheduledNotificationAsync: jest.fn().mockResolvedValue(undefined),
  getPermissionsAsync: jest.fn().mockResolvedValue({ status: 'granted' }),
  requestPermissionsAsync: jest.fn().mockResolvedValue({ status: 'granted' }),
  SchedulableTriggerInputTypes: {
    TIME_INTERVAL: 'timeInterval',
    DAILY: 'daily',
    WEEKLY: 'weekly',
    DATE: 'date',
  },
}));

jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('react-native', () => ({
  Platform: {
    OS: 'ios',
  },
}));

jest.mock('@react-native-firebase/firestore', () => {
  const mockSet = jest.fn().mockResolvedValue(undefined);
  const mockDoc = jest.fn().mockReturnValue({ set: mockSet });
  const mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });
  const mockFirestore = jest.fn().mockReturnValue({ collection: mockCollection });
  return { default: mockFirestore, __mockSet: mockSet };
});

jest.mock('../../firebase/firestore', () => ({
  getFirestoreInstance: jest.fn().mockReturnValue({
    collection: jest.fn().mockReturnValue({
      doc: jest.fn().mockReturnValue({
        set: jest.fn().mockResolvedValue(undefined),
      }),
    }),
  }),
  isWeb: false,
}));

import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import { scheduleDailyReminder, cancelDailyReminder, registerFCMToken } from '../notificationService';

const DAILY_REMINDER_KEY = '@sundee/daily_reminder_id';

describe('scheduleDailyReminder', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (Notifications.scheduleNotificationAsync as jest.Mock).mockResolvedValue('new-notification-id');
  });

  it('cancels existing reminder before scheduling new one', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue('old-notification-id');

    await scheduleDailyReminder(8, 0, null);

    expect(Notifications.cancelScheduledNotificationAsync).toHaveBeenCalledWith(
      'old-notification-id',
    );
  });

  it('does not call cancel if no existing reminder ID', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await scheduleDailyReminder(8, 0, null);

    expect(Notifications.cancelScheduledNotificationAsync).not.toHaveBeenCalled();
  });

  it('schedules notification with DAILY trigger type and repeats:true', async () => {
    await scheduleDailyReminder(8, 30, null);

    expect(Notifications.scheduleNotificationAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        trigger: expect.objectContaining({
          hour: 8,
          minute: 30,
          repeats: true,
        }),
      }),
    );
  });

  it('schedules with "Time to train" title', async () => {
    await scheduleDailyReminder(8, 0, null);

    expect(Notifications.scheduleNotificationAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        content: expect.objectContaining({
          title: 'Time to train',
        }),
      }),
    );
  });

  it('uses getGenericCopy() body when cyclePhase is null', async () => {
    await scheduleDailyReminder(8, 0, null);

    const call = (Notifications.scheduleNotificationAsync as jest.Mock).mock.calls[0][0];
    expect(typeof call.content.body).toBe('string');
    expect(call.content.body.length).toBeGreaterThan(0);
  });

  it('uses getCycleAwareCopy() body when cyclePhase is provided', async () => {
    await scheduleDailyReminder(8, 0, 'menstrual');

    const call = (Notifications.scheduleNotificationAsync as jest.Mock).mock.calls[0][0];
    expect(call.content.body).toContain('Menstrual');
  });

  it('stores the returned notification ID in AsyncStorage', async () => {
    await scheduleDailyReminder(8, 0, null);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(DAILY_REMINDER_KEY, 'new-notification-id');
  });
});

describe('cancelDailyReminder', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('cancels the stored notification ID', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue('stored-id');

    await cancelDailyReminder();

    expect(Notifications.cancelScheduledNotificationAsync).toHaveBeenCalledWith('stored-id');
  });

  it('removes the ID from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue('stored-id');

    await cancelDailyReminder();

    expect(AsyncStorage.removeItem).toHaveBeenCalledWith(DAILY_REMINDER_KEY);
  });

  it('does nothing when no stored ID', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await cancelDailyReminder();

    expect(Notifications.cancelScheduledNotificationAsync).not.toHaveBeenCalled();
  });
});

describe('registerFCMToken', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('skips when isGuest is true', async () => {
    const { getFirestoreInstance } = require('../../firebase/firestore');

    await registerFCMToken('uid-123', true);

    expect(getFirestoreInstance).not.toHaveBeenCalled();
  });

  it('skips when Platform.OS is web', async () => {
    const { Platform } = require('react-native');
    Platform.OS = 'web';

    const { getFirestoreInstance } = require('../../firebase/firestore');
    jest.clearAllMocks();

    await registerFCMToken('uid-123', false);

    expect(getFirestoreInstance).not.toHaveBeenCalled();

    // Reset
    Platform.OS = 'ios';
  });
});

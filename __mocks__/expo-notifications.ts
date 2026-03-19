/**
 * Mock for expo-notifications.
 *
 * Provides Jest stubs for notification scheduling and permission requests.
 */

export const scheduleNotificationAsync = jest.fn().mockResolvedValue('mock-notification-id');

export const cancelScheduledNotificationAsync = jest.fn().mockResolvedValue(undefined);

export const cancelAllScheduledNotificationsAsync = jest.fn().mockResolvedValue(undefined);

export const getAllScheduledNotificationsAsync = jest.fn().mockResolvedValue([]);

export const requestPermissionsAsync = jest.fn().mockResolvedValue({ status: 'granted' });

export const getPermissionsAsync = jest.fn().mockResolvedValue({ status: 'granted' });

export const setNotificationHandler = jest.fn();

export const addNotificationReceivedListener = jest.fn().mockReturnValue({ remove: jest.fn() });

export const addNotificationResponseReceivedListener = jest
  .fn()
  .mockReturnValue({ remove: jest.fn() });

export const AndroidImportance = {
  MAX: 5,
  HIGH: 4,
  DEFAULT: 3,
  LOW: 2,
  MIN: 1,
} as const;

export const setNotificationChannelAsync = jest.fn().mockResolvedValue(null);

export const SchedulableTriggerInputTypes = {
  TIME_INTERVAL: 'timeInterval',
  DAILY: 'daily',
  WEEKLY: 'weekly',
  DATE: 'date',
} as const;

/**
 * notificationService — scheduling and FCM token registration.
 *
 * Responsibilities:
 *   - scheduleDailyReminder: cancel-and-reschedule daily workout reminder
 *   - cancelDailyReminder: cancel any stored daily reminder
 *   - registerFCMToken: write FCM push token to Firestore /users/{uid}
 *
 * Platform guards: registerFCMToken skips on web and for guest users.
 */

import * as Notifications from 'expo-notifications';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import { getCycleAwareCopy, getGenericCopy } from '../domain/notifications/notification-copy';
import { getFirestoreInstance } from '../firebase/firestore';
import type { CyclePhase } from '../domain/types';

// ─── Constants ────────────────────────────────────────────────────────────────

const DAILY_REMINDER_KEY = '@sundee/daily_reminder_id';

// ─── Schedule / cancel ────────────────────────────────────────────────────────

/**
 * Cancels any existing daily reminder and schedules a new one at the given time.
 *
 * @param hour       Hour of day (0–23)
 * @param minute     Minute (0–59)
 * @param cyclePhase Current cycle phase for personalised body copy, or null for generic copy
 */
export async function scheduleDailyReminder(
  hour: number,
  minute: number,
  cyclePhase: CyclePhase | null,
): Promise<void> {
  // Cancel existing reminder if one is stored
  const existingId = await AsyncStorage.getItem(DAILY_REMINDER_KEY);
  if (existingId) {
    await Notifications.cancelScheduledNotificationAsync(existingId);
  }

  // Build body copy based on cycle phase
  const body = cyclePhase ? getCycleAwareCopy(cyclePhase) : getGenericCopy();

  // Schedule the new daily reminder
  const newId = await Notifications.scheduleNotificationAsync({
    content: {
      title: 'Time to train',
      body,
      sound: true,
      android: {
        channelId: 'reminders',
      },
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DAILY,
      hour,
      minute,
      repeats: true,
    },
  });

  // Persist the new notification ID
  await AsyncStorage.setItem(DAILY_REMINDER_KEY, newId);
}

/**
 * Cancels the stored daily reminder notification and removes it from AsyncStorage.
 */
export async function cancelDailyReminder(): Promise<void> {
  const storedId = await AsyncStorage.getItem(DAILY_REMINDER_KEY);
  if (!storedId) {
    return;
  }
  await Notifications.cancelScheduledNotificationAsync(storedId);
  await AsyncStorage.removeItem(DAILY_REMINDER_KEY);
}

// ─── FCM token registration ───────────────────────────────────────────────────

/**
 * Obtains the FCM push token and writes it to Firestore /users/{uid}.
 *
 * Guards:
 *   - Skips on web (expo-notifications owns display; no FCM on web)
 *   - Skips for guest users (no Firestore doc)
 *   - Errors are caught and logged — never thrown
 */
export async function registerFCMToken(uid: string, isGuest: boolean): Promise<void> {
  if (Platform.OS === 'web') {
    return;
  }

  if (isGuest) {
    return;
  }

  try {
    // Dynamic require — consistent with initAnalytics/initCrashlytics pattern
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const messaging = require('@react-native-firebase/messaging').default;
    const token: string | null = await messaging().getToken();

    if (token) {
      const db = getFirestoreInstance();
      await db.collection('users').doc(uid).set(
        {
          fcmToken: token,
          fcmTokenUpdatedAt: new Date().toISOString(),
        },
        { merge: true },
      );
    }
  } catch (error) {
    console.warn('[notificationService] Failed to register FCM token:', error);
  }
}

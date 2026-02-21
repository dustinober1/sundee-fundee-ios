import * as Notifications from 'expo-notifications';

let configured = false;

function ensureNotificationHandler(): void {
  if (configured) return;
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: false,
    }),
  });
  configured = true;
}

export async function requestNotificationPermission(): Promise<void> {
  ensureNotificationHandler();
  const current = await Notifications.getPermissionsAsync();
  if (current.status === 'granted') return;

  const requested = await Notifications.requestPermissionsAsync();
  if (requested.status !== 'granted') {
    throw new Error('Notification permission not granted');
  }
}

export async function scheduleRestTimerNotification(
  restSeconds: number,
  exerciseName: string
): Promise<string> {
  await requestNotificationPermission();
  return Notifications.scheduleNotificationAsync({
    content: {
      title: 'Rest complete',
      body: `Start your next ${exerciseName} set.`,
    },
    trigger: {
      seconds: restSeconds,
    },
  });
}

export async function cancelNotification(notificationId: string): Promise<void> {
  await Notifications.cancelScheduledNotificationAsync(notificationId);
}

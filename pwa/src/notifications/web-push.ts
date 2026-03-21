/**
 * Web Push notification utilities for PWA.
 *
 * Provides:
 *   - requestNotificationPermission: asks user for permission
 *   - showLocalNotification: fires a local notification (rest timer, PR, etc.)
 *   - isNotificationSupported: feature detection
 *
 * No external dependencies — uses the standard Notification API + Service Worker.
 */

export function isNotificationSupported(): boolean {
  return 'Notification' in window && 'serviceWorker' in navigator;
}

export async function requestNotificationPermission(): Promise<NotificationPermission> {
  if (!isNotificationSupported()) return 'denied';
  if (Notification.permission === 'granted') return 'granted';
  return Notification.requestPermission();
}

/**
 * Show a local notification via the active service worker.
 * Falls back to `new Notification()` if no SW is registered.
 */
export async function showLocalNotification(
  title: string,
  options?: NotificationOptions,
): Promise<void> {
  if (!isNotificationSupported()) return;
  if (Notification.permission !== 'granted') return;

  try {
    const reg = await navigator.serviceWorker.ready;
    await reg.showNotification(title, {
      icon: '/pwa-192x192.png',
      badge: '/pwa-192x192.png',
      ...options,
    });
  } catch {
    // Fallback for contexts without active SW
    new Notification(title, options);
  }
}

/**
 * Schedule a notification after a delay (e.g. rest timer complete).
 * Returns a timeout ID that can be cleared with clearTimeout().
 */
export function scheduleNotification(
  delayMs: number,
  title: string,
  options?: NotificationOptions,
): ReturnType<typeof setTimeout> {
  return setTimeout(() => showLocalNotification(title, options), delayMs);
}

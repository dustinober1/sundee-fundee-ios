/**
 * Firebase Cloud Messaging initialization.
 *
 * Initializes the FCM messaging module at app startup.
 * Does NOT request permission or retrieve tokens here — that is Phase 20 scope
 * (expo-notifications owns permission flow per architecture decision).
 *
 * Platform behavior:
 * - Web: skipped entirely (RNFB messaging does not apply on web)
 * - iOS/Android: messaging module initialized for background data message handling
 *
 * Guard: module-level `initialized` flag prevents double-init across hot reloads.
 */

import { Platform } from 'react-native';

/** Prevent double-initialization across hot reloads. */
let initialized = false;

/**
 * Initialize Firebase Cloud Messaging.
 * Safe to call multiple times — guards against double-init internally.
 * Does not request permission — permission is handled in Phase 20 via expo-notifications.
 */
export async function initMessaging(): Promise<void> {
  // Web: RNFB messaging does not apply on web platform
  if (Platform.OS === 'web') return;

  // Guard: already initialized
  if (initialized) return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    require('@react-native-firebase/messaging').default;

    initialized = true;
    console.log('[Messaging] Initialized');
  } catch (err) {
    // Messaging initialization failure is non-fatal — log and continue.
    console.warn('[Messaging] Initialization failed:', err);
  }
}

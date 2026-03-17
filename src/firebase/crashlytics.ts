/**
 * Firebase Crashlytics initialization.
 *
 * Enables crash reporting collection at app startup.
 * Auto-collection is also configured via firebase.json react-native section,
 * but this explicit call ensures collection is enabled at runtime.
 *
 * Platform behavior:
 * - Web: skipped entirely (RNFB crashlytics does not apply on web)
 * - iOS/Android: crash collection enabled
 *
 * Guard: module-level `initialized` flag prevents double-init across hot reloads.
 */

import { Platform } from 'react-native';

/** Prevent double-initialization across hot reloads. */
let initialized = false;

/**
 * Initialize Firebase Crashlytics.
 * Safe to call multiple times — guards against double-init internally.
 * Enables crash collection (respects firebase.json auto_collection setting).
 */
export function initCrashlytics(): void {
  // Web: RNFB crashlytics does not apply on web platform
  if (Platform.OS === 'web') return;

  // Guard: already initialized
  if (initialized) return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    crashlytics().setCrashlyticsCollectionEnabled(true);

    initialized = true;
    console.log('[Crashlytics] Initialized');
  } catch (err) {
    // Crashlytics initialization failure is non-fatal — log and continue.
    console.warn('[Crashlytics] Initialization failed:', err);
  }
}

/**
 * Firebase Analytics initialization.
 *
 * Enables analytics collection at app startup.
 * Auto-collection is also configured via firebase.json react-native section,
 * but this explicit call ensures collection is enabled at runtime.
 *
 * Platform behavior:
 * - Web: skipped entirely (RNFB analytics does not apply on web)
 * - iOS/Android: analytics collection enabled
 *
 * Guard: module-level `initialized` flag prevents double-init across hot reloads.
 */

import { Platform } from 'react-native';

/** Prevent double-initialization across hot reloads. */
let initialized = false;

/**
 * Initialize Firebase Analytics.
 * Safe to call multiple times — guards against double-init internally.
 * Enables analytics collection (respects firebase.json auto_collection setting).
 */
export function initAnalytics(): void {
  // Web: RNFB analytics does not apply on web platform
  if (Platform.OS === 'web') return;

  // Guard: already initialized
  if (initialized) return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const analytics = require('@react-native-firebase/analytics').default;
    analytics().setAnalyticsCollectionEnabled(true);

    initialized = true;
    console.log('[Analytics] Initialized');
  } catch (err) {
    // Analytics initialization failure is non-fatal — log and continue.
    console.warn('[Analytics] Initialization failed:', err);
  }
}

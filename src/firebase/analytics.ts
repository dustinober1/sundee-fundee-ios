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

/**
 * Log a custom analytics event.
 *
 * No-op on web — RNFB analytics does not apply on web platform.
 * Failure is non-fatal; missing native module is caught and ignored.
 *
 * @param eventName - Firebase Analytics event name (snake_case, max 40 chars)
 * @param params - Optional event parameters (string, number, or boolean values)
 */
export async function logEvent(
  eventName: string,
  params?: Record<string, string | number | boolean>,
): Promise<void> {
  if (Platform.OS === 'web') return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const analytics = require('@react-native-firebase/analytics').default;
    await analytics().logEvent(eventName, params ?? {});
  } catch {
    // Non-fatal — analytics failure must never crash the app.
  }
}

/**
 * Set persistent user properties for analytics segmentation.
 *
 * Firebase user property values must be strings (max 36 chars).
 * Boolean values are stringified before being sent.
 *
 * No-op on web — RNFB analytics does not apply on web platform.
 *
 * @param props - Typed user properties to persist on the analytics session
 */
export async function setUserProperties(props: {
  subscriptionTier: 'free' | 'premium';
  cycleTrackingEnabled: boolean;
}): Promise<void> {
  if (Platform.OS === 'web') return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const analytics = require('@react-native-firebase/analytics').default;
    await analytics().setUserProperties({
      subscription_tier: props.subscriptionTier,
      cycle_tracking_enabled: String(props.cycleTrackingEnabled),
    });
  } catch {
    // Non-fatal — analytics failure must never crash the app.
  }
}

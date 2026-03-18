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

/**
 * Record a caught error in Crashlytics for crash analysis.
 *
 * Optionally logs a context string before the error for easier triage.
 * No-op on web — RNFB crashlytics does not apply on web platform.
 * Failure is non-fatal; missing native module is caught and ignored.
 *
 * @param error - The Error object to record
 * @param context - Optional context string logged before the error (e.g., 'WorkoutSave')
 */
export function recordError(error: Error, context?: string): void {
  if (Platform.OS === 'web') return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    if (context) {
      crashlytics().log(context);
    }
    crashlytics().recordError(error);
  } catch {
    // Non-fatal — crashlytics failure must never crash the app.
  }
}

/**
 * Set persistent key-value attributes on the Crashlytics session.
 *
 * Attributes appear on every crash report from this session, enabling
 * segmentation by subscription tier, cycle phase, etc.
 *
 * Undefined keys are omitted — only defined keys are sent.
 * No-op on web — RNFB crashlytics does not apply on web platform.
 *
 * @param keys - Typed session attributes to attach to crash reports
 */
export async function setCrashlyticsKeys(keys: {
  subscriptionTier?: 'free' | 'premium';
  cyclePhase?: string;
}): Promise<void> {
  if (Platform.OS === 'web') return;

  const attrs: Record<string, string> = {};
  if (keys.subscriptionTier !== undefined) {
    attrs['subscription_tier'] = keys.subscriptionTier;
  }
  if (keys.cyclePhase !== undefined) {
    attrs['cycle_phase'] = keys.cyclePhase;
  }

  if (Object.keys(attrs).length === 0) return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    await crashlytics().setAttributes(attrs);
  } catch {
    // Non-fatal — crashlytics failure must never crash the app.
  }
}

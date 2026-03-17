/**
 * Firebase App Check initialization.
 *
 * App Check secures all Firebase service calls against unauthenticated access.
 * Must be initialized before any Firestore, Auth, or other Firebase service calls.
 *
 * Platform behavior:
 * - Web: skipped entirely (App Check uses JS SDK not RNF; web not primary target)
 * - iOS: appAttest with DeviceCheck fallback in production; debug token in dev
 * - Android: Play Integrity in production; debug token in dev
 *
 * Guard: module-level `initialized` flag prevents double-init across hot reloads.
 */

import { Platform } from 'react-native';

/** Prevent double-initialization across hot reloads. */
let initialized = false;

/**
 * Initialize Firebase App Check.
 * Safe to call multiple times — guards against double-init internally.
 * Must be called before any Firestore/Auth calls in the app lifecycle.
 */
export async function initAppCheck(): Promise<void> {
  // Web: App Check for RNF does not apply on web platform
  if (Platform.OS === 'web') return;

  // Guard: already initialized
  if (initialized) return;

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const appCheck = require('@react-native-firebase/app-check').default;
    const provider = appCheck().newReactNativeFirebaseAppCheckProvider();

    provider.configure({
      android: {
        provider: __DEV__ ? 'debug' : 'playIntegrity',
        debugToken: __DEV__
          ? (process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN ?? undefined)
          : undefined,
      },
      apple: {
        provider: __DEV__ ? 'debug' : 'appAttestWithDeviceCheckFallback',
        debugToken: __DEV__
          ? (process.env.EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN ?? undefined)
          : undefined,
      },
      web: {
        provider: 'reCaptchaV3',
        siteKey: 'unused',
      },
    });

    await appCheck().initializeAppCheck({
      provider,
      isTokenAutoRefreshEnabled: true,
    });

    initialized = true;
  } catch (err) {
    // App Check initialization failure is non-fatal — log and continue.
    // The app degrades gracefully without App Check (security is reduced, not broken).
    console.warn('[AppCheck] Initialization failed:', err);
  }
}

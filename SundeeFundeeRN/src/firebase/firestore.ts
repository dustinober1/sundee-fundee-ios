/**
 * Platform-aware Firestore instance.
 *
 * On native (iOS/Android): uses @react-native-firebase/firestore which is backed
 * by the native Firebase SDK with built-in offline persistence.
 *
 * On web: uses firebase/firestore JS SDK. The web build falls back to this
 * file since @react-native-firebase/firestore does not compile for web.
 *
 * Usage: always import from this file — never import the platform SDKs directly
 * in feature code.
 */
import { Platform } from 'react-native';

export const isWeb = Platform.OS === 'web';

// ─── Native types ─────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type NativeFirestore = any;

// ─── Web types ────────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type WebFirestore = any;

export type FirestoreInstance = NativeFirestore | WebFirestore;

/**
 * Returns a Firestore instance appropriate for the current platform.
 *
 * On native: @react-native-firebase/firestore (auto-initialized from plist/json)
 * On web: firebase/firestore JS SDK (initialized from EXPO_PUBLIC env vars)
 */
export function getFirestoreInstance(): FirestoreInstance {
  if (isWeb) {
    // Dynamic require to prevent bundling native module on web
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getFirestore } = require('firebase/firestore');
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { getApps, initializeApp } = require('firebase/app');
    const existing = getApps();
    const app = existing.length > 0
      ? existing[0]
      : initializeApp({
          apiKey: process.env.EXPO_PUBLIC_FIREBASE_WEB_API_KEY ?? '',
          authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN ?? '',
          projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID ?? '',
        });
    return getFirestore(app);
  }

  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const firestore = require('@react-native-firebase/firestore').default;
  return firestore();
}

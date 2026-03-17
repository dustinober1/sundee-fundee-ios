import { Platform } from 'react-native';

/**
 * Indicates whether the current platform is web.
 *
 * On web, the Firebase JS SDK is used directly.
 * On native (iOS/Android), @react-native-firebase auto-initializes from
 * GoogleService-Info.plist (iOS) or google-services.json (Android).
 */
export const isWeb = Platform.OS === 'web';

/**
 * On web: initialize Firebase JS SDK from EXPO_PUBLIC environment variables.
 * On native: no-op — @react-native-firebase/app handles initialization via
 * the native config files and the app.json plugin.
 */
export function initializeFirebaseWeb(): void {
  if (!isWeb) return;

  // Dynamically import to avoid bundling firebase/app on native
  // The actual web initialization is deferred to ensure env vars are available
  const config = {
    apiKey: process.env.EXPO_PUBLIC_FIREBASE_WEB_API_KEY,
    authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  };

  // Validate that required config values are present on web
  if (!config.apiKey || !config.projectId) {
    console.warn(
      '[Firebase] Missing EXPO_PUBLIC_FIREBASE_WEB_API_KEY or EXPO_PUBLIC_FIREBASE_PROJECT_ID. ' +
        'Web auth will not function until these are set.'
    );
  }
}

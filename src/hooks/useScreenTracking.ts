/**
 * useScreenTracking
 *
 * Tracks screen views in Firebase Analytics and sets the current screen
 * attribute in Crashlytics on every navigation change.
 *
 * Platform behavior:
 * - Web: no-op — RNFB analytics/crashlytics do not apply on web
 * - iOS/Android: logs screen view + sets Crashlytics current_screen attribute
 *
 * Both Firebase calls are non-fatal: failures are silently caught so that
 * analytics issues never affect app usability.
 *
 * Usage: Call once in the root layout component.
 * ```tsx
 * export default function RootLayout() {
 *   useScreenTracking();
 *   return <Stack />;
 * }
 * ```
 */

import { useEffect } from 'react';
import { Platform } from 'react-native';
import { usePathname } from 'expo-router';

/**
 * Hook that fires analytics and crashlytics screen tracking on pathname change.
 * Place in root layout — runs once per navigation event.
 */
export function useScreenTracking(): void {
  const pathname = usePathname();

  useEffect(() => {
    // Web: RNFB modules do not apply on web platform
    if (Platform.OS === 'web') return;

    const screenName = pathname ?? 'unknown';

    // Track screen view in Firebase Analytics
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const analytics = require('@react-native-firebase/analytics').default;
      void analytics().logScreenView({
        screen_name: screenName,
        screen_class: screenName,
      });
    } catch {
      // Non-fatal — analytics failure must never crash the app.
    }

    // Set current screen attribute in Crashlytics for crash context
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const crashlytics = require('@react-native-firebase/crashlytics').default;
      void crashlytics().setAttribute('current_screen', screenName);
    } catch {
      // Non-fatal — crashlytics failure must never crash the app.
    }
  }, [pathname]);
}

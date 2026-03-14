/**
 * Root layout for Sundee Fundee.
 *
 * Responsibilities:
 * 1. Initialize RevenueCat on mount (iOS and Android only; web deferred to Phase 6)
 * 2. Wrap the app in a SessionProvider stub (real implementation in Plan 02)
 * 3. Render the root Stack navigator via expo-router
 */
import { useEffect } from 'react';
import { Platform } from 'react-native';
import { Stack } from 'expo-router';

// ─── RevenueCat Configuration ─────────────────────────────────────────────────

function configureRevenueCat(): void {
  if (Platform.OS === 'web') {
    // RevenueCat Web Billing (Stripe) is configured in Phase 6.
    // Skip SDK initialization on web in Phase 1.
    return;
  }

  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const Purchases = require('react-native-purchases').default;

    const apiKey =
      Platform.OS === 'ios'
        ? (process.env.EXPO_PUBLIC_RC_APPLE_KEY ?? '')
        : (process.env.EXPO_PUBLIC_RC_GOOGLE_KEY ?? '');

    if (!apiKey) {
      // Expected in development before RevenueCat keys are configured.
      // Entitlement checks will gracefully return false (see useEntitlements.ts).
      console.warn(
        `[RevenueCat] Missing API key for ${Platform.OS}. ` +
          'Set EXPO_PUBLIC_RC_APPLE_KEY (iOS) or EXPO_PUBLIC_RC_GOOGLE_KEY (Android).'
      );
      return;
    }

    Purchases.configure({ apiKey });
  } catch (error) {
    // react-native-purchases not available in this environment
    console.warn('[RevenueCat] SDK not available:', error);
  }
}

// ─── Session Provider Stub ────────────────────────────────────────────────────
// Placeholder until Plan 02 implements the real AuthContext.
// This allows the layout to render without crashing while auth is wired up.

function SessionProvider({ children }: { children: React.ReactNode }): React.JSX.Element {
  return <>{children}</>;
}

// ─── Root Layout ──────────────────────────────────────────────────────────────

export default function RootLayout(): React.JSX.Element {
  useEffect(() => {
    configureRevenueCat();
  }, []);

  return (
    <SessionProvider>
      <Stack
        screenOptions={{
          headerShown: false,
        }}
      />
    </SessionProvider>
  );
}

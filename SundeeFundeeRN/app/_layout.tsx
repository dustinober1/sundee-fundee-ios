/**
 * Root layout for Sundee Fundee.
 *
 * Responsibilities:
 * 1. Initialize RevenueCat on mount (iOS and Android only; web deferred to Phase 6)
 * 2. Wrap the app in SessionProvider (real AuthContext from Plan 02)
 * 3. Wire UserRepository: authenticated users → Firestore, guests → AsyncStorage
 * 4. Render the root Stack navigator via expo-router
 */
import { useCallback, useEffect } from 'react';
import { Platform } from 'react-native';
import { Stack } from 'expo-router';
import type { FirebaseAuthTypes } from '@react-native-firebase/auth';

import { SessionProvider } from '@/src/auth/AuthContext';
import { FirestoreUserRepo } from '@/src/repositories/FirestoreUserRepo';
import { LocalUserRepo } from '@/src/repositories/LocalUserRepo';
import type { UserProfile } from '@/src/repositories/UserRepository';

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

// ─── User Persistence ─────────────────────────────────────────────────────────

/**
 * Derive authProvider from Firebase providerData.
 * Falls back to 'anonymous' when no provider data is available.
 */
function deriveAuthProvider(
  user: FirebaseAuthTypes.User
): UserProfile['authProvider'] {
  if (user.isAnonymous) return 'anonymous';
  const providerId = user.providerData?.[0]?.providerId ?? '';
  if (providerId === 'apple.com') return 'apple';
  if (providerId === 'google.com') return 'google';
  if (providerId === 'password') return 'email';
  return 'email';
}

/**
 * Build a UserProfile from a Firebase User.
 */
function buildUserProfile(user: FirebaseAuthTypes.User): UserProfile {
  return {
    uid: user.uid,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    isAnonymous: user.isAnonymous,
    createdAt: user.metadata?.creationTime ?? new Date().toISOString(),
    lastSignInAt: user.metadata?.lastSignInTime ?? new Date().toISOString(),
    authProvider: deriveAuthProvider(user),
  };
}

// ─── Root Layout ──────────────────────────────────────────────────────────────

export default function RootLayout(): React.JSX.Element {
  useEffect(() => {
    configureRevenueCat();
  }, []);

  /**
   * Called by SessionProvider whenever a user signs in (non-null user).
   * Routes to Firestore (authenticated users) or AsyncStorage (guest users).
   * Errors are non-fatal: a failed write should not crash the app.
   */
  const handleUserSignIn = useCallback(
    async (user: FirebaseAuthTypes.User): Promise<void> => {
      try {
        const profile = buildUserProfile(user);
        if (user.isAnonymous) {
          const repo = new LocalUserRepo();
          await repo.createOrUpdateUser(profile);
        } else {
          const repo = new FirestoreUserRepo();
          await repo.createOrUpdateUser(profile);
        }
      } catch (error) {
        // Log but do not surface — user is already signed in at this point
        console.warn('[RootLayout] Failed to persist user profile:', error);
      }
    },
    []
  );

  return (
    <SessionProvider onUserSignIn={handleUserSignIn}>
      <Stack>
        <Stack.Screen name="sign-in" options={{ headerShown: false }} />
        <Stack.Screen name="verify-email" options={{ headerShown: false }} />
        <Stack.Screen name="(app)" options={{ headerShown: false }} />
      </Stack>
    </SessionProvider>
  );
}

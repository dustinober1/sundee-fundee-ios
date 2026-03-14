/**
 * Root layout for Sundee Fundee.
 *
 * Responsibilities:
 * 1. Initialize RevenueCat on mount (iOS and Android only; web deferred to Phase 6)
 * 2. Wrap the app in SessionProvider (real AuthContext from Plan 02)
 * 3. Wire UserRepository: authenticated users → Firestore, guests → AsyncStorage
 * 4. Check hasCompletedOnboarding and expose it via state for routing decisions
 * 5. Render the root Stack navigator via expo-router (includes onboarding route group)
 */
import { useCallback, useEffect, useState } from 'react';
import { Platform, View } from 'react-native';
import { Stack } from 'expo-router';
import type { AuthUser } from '@/src/firebase/auth';

import { SessionProvider } from '@/src/auth/AuthContext';
import { FirestoreUserRepo } from '@/src/repositories/FirestoreUserRepo';
import { LocalUserRepo } from '@/src/repositories/LocalUserRepo';
import type { UserProfile } from '@/src/repositories/UserRepository';
import { CREAM } from '@/src/theme/colors';

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
  user: AuthUser
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
function buildUserProfile(user: AuthUser): UserProfile {
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
  /**
   * null  = profile not yet loaded (show splash, prevent routing flicker)
   * false = user exists but hasCompletedOnboarding is false
   * true  = onboarding is done, skip to app
   *
   * CRITICAL: Never default to false — this would flash the onboarding flow
   * for returning users while the profile loads.
   */
  const [onboardingComplete, setOnboardingComplete] = useState<boolean | null>(null);

  useEffect(() => {
    configureRevenueCat();
  }, []);

  /**
   * Called by SessionProvider whenever a user signs in (non-null user).
   * Routes to Firestore (authenticated users) or AsyncStorage (guest users).
   * Errors are non-fatal: a failed write should not crash the app.
   *
   * Also reads back hasCompletedOnboarding to gate routing.
   */
  const handleUserSignIn = useCallback(
    async (user: AuthUser): Promise<void> => {
      try {
        const profile = buildUserProfile(user);
        let savedProfile: UserProfile | null;

        if (user.isAnonymous) {
          const repo = new LocalUserRepo();
          await repo.createOrUpdateUser(profile);
          savedProfile = await repo.getUser(user.uid);
        } else {
          const repo = new FirestoreUserRepo();
          await repo.createOrUpdateUser(profile);
          savedProfile = await repo.getUser(user.uid);
        }

        setOnboardingComplete(savedProfile?.hasCompletedOnboarding === true);
      } catch (error) {
        // Log but do not surface — user is already signed in at this point
        // Default to false (show onboarding) rather than crashing
        console.warn('[RootLayout] Failed to persist user profile:', error);
        setOnboardingComplete(false);
      }
    },
    []
  );

  return (
    <SessionProvider onUserSignIn={handleUserSignIn}>
      {/* Show a blank CREAM splash while profile loads to prevent routing flicker */}
      {onboardingComplete === null ? (
        <View style={{ flex: 1, backgroundColor: CREAM }} />
      ) : (
        <Stack>
          <Stack.Screen name="sign-in" options={{ headerShown: false }} />
          <Stack.Screen name="verify-email" options={{ headerShown: false }} />
          <Stack.Screen name="(onboarding)" options={{ headerShown: false }} />
          <Stack.Screen name="(app)" options={{ headerShown: false }} />
        </Stack>
      )}
    </SessionProvider>
  );
}

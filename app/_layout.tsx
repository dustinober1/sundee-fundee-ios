/**
 * Root layout for Sundee Fundee.
 *
 * Responsibilities:
 * 1. Initialize Firebase modules on mount (App Check, Crashlytics, Analytics, Messaging)
 * 2. Wrap the app in SessionProvider (real AuthContext from Plan 02)
 * 3. Wire UserRepository: authenticated users → Firestore, guests → AsyncStorage
 * 4. Check hasCompletedOnboarding and expose it via state for routing decisions
 * 5. Render the root Stack navigator via expo-router (includes onboarding route group)
 * 6. Call Purchases.logIn(user.uid) on non-guest sign-in for RC identity binding
 * 7. Wrap Stack with EntitlementProvider for app-wide premium status access
 * 8. Retry any pending guest-to-auth migration on non-anonymous user sign-in
 */
import { useCallback, useEffect } from 'react';
import { Platform } from 'react-native';
import { Stack } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { AuthUser } from '@/src/firebase/auth';
import { initFirebase } from '@/src/firebase/init';

import { SessionProvider } from '@/src/auth/AuthContext';
import { EntitlementProvider } from '@/src/entitlements/EntitlementContext';
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

// ─── Pending Migration Retry ──────────────────────────────────────────────────

/**
 * Retries a pending guest-to-auth data migration on non-anonymous sign-in.
 *
 * Called when a non-anonymous user signs in. If a previous migration attempt
 * was interrupted (crash, network error), the @sundee/migration_pending flag
 * will still be set. This function retries the migration silently — failure
 * just leaves the flag set for the next launch.
 */
async function retryPendingMigration(uid: string): Promise<void> {
  try {
    const pending = await AsyncStorage.getItem('@sundee/migration_pending');
    if (pending !== 'true') return;
    const { migrateGuestDataToFirestore } = await import(
      '@/src/repositories/migration'
    );
    await migrateGuestDataToFirestore(uid);
  } catch {
    // Silent — retry on next launch
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
  useEffect(() => {
    // Initialize all Firebase modules (App Check, Crashlytics, Analytics, Messaging).
    // App Check is first to secure all subsequent Firebase calls.
    // Moved here from (app)/_layout.tsx so it's ready before the sign-in screen.
    void initFirebase();
    configureRevenueCat();
  }, []);

  /**
   * Called by SessionProvider whenever a user signs in (non-null user).
   * Routes to Firestore (authenticated users) or AsyncStorage (guest users).
   * Wires RevenueCat identity for non-guest, non-web users.
   * Errors are non-fatal: a failed write should not crash the app.
   */
  const handleUserSignIn = useCallback(
    async (user: AuthUser): Promise<void> => {
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

      // Wire RevenueCat identity for authenticated non-guest mobile users.
      // Must run after profile persistence (non-fatal if it fails).
      if (Platform.OS !== 'web' && !user.isAnonymous) {
        try {
          // eslint-disable-next-line @typescript-eslint/no-require-imports
          const Purchases = require('react-native-purchases').default;
          await Purchases.logIn(user.uid);
        } catch {
          // RC logIn failure is non-fatal — entitlement checks will still work
          // via getCustomerInfo fallback in useEntitlements
        }
      }

      // Retry any pending guest-to-auth migration for non-anonymous users.
      // If a previous migration was interrupted, the pending flag will be set.
      // Errors are swallowed — retry happens on next launch.
      if (!user.isAnonymous) {
        void retryPendingMigration(user.uid);
      }
    },
    []
  );

  return (
    <SessionProvider onUserSignIn={handleUserSignIn}>
      <EntitlementProvider>
        <Stack>
          <Stack.Screen name="(app)" options={{ headerShown: false }} />
          <Stack.Screen name="sign-in" options={{ headerShown: false }} />
          <Stack.Screen name="verify-email" options={{ headerShown: false }} />
          <Stack.Screen name="(onboarding)" options={{ headerShown: false }} />
        </Stack>
      </EntitlementProvider>
    </SessionProvider>
  );
}

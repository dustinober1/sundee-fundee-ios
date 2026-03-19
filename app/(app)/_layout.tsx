/**
 * app/(app)/_layout.tsx — Protected route guard.
 *
 * Enforces auth requirements using the redirect pattern (expo-router compatible):
 * - While loading: return null (keeps splash screen visible)
 * - No user: redirect to /sign-in
 * - Unverified email user (not anonymous): redirect to /verify-email
 * - Authenticated/guest, not onboarded: redirect to /(onboarding)/step-name
 * - Authenticated + verified (or guest) + onboarded: render the (tabs) stack
 *
 * Reads hasCompletedOnboarding from the appropriate UserRepository.
 * Uses useSession() from AuthContext — SessionProvider is already mounted at root.
 *
 * Also handles:
 * - Android notification channels (rest-timer + reminders)
 * - Notification tap deep-link listener
 * - FCM token registration after auth resolves
 */

import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import { Redirect, Stack, useRouter } from 'expo-router';
import * as Notifications from 'expo-notifications';
import { useSession } from '@/src/auth/AuthContext';
import { getOnboardingProfileRepo } from '@/src/repositories/OnboardingProfileRepo';
import { registerFCMToken } from '@/src/services/notificationService';

// Configure notifications to display when app is in foreground.
// Called once at module load — safe to call multiple times (idempotent).
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

// ── Android notification channels ──────────────────────────────────────────
// Created at module load (before component mount) so channels are available
// the first time a notification is scheduled.
if (Platform.OS === 'android') {
  void Notifications.setNotificationChannelAsync('rest-timer', {
    name: 'Rest Timer',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    vibrationPattern: [0, 250, 250, 250],
    lightColor: '#F2731A',
  });

  void Notifications.setNotificationChannelAsync('reminders', {
    name: 'Workout Reminders',
    importance: Notifications.AndroidImportance.DEFAULT,
    sound: 'default',
  });
}

export default function AppLayout(): React.JSX.Element | null {
  const { user, isLoading, isGuest } = useSession();
  const router = useRouter();

  /**
   * null  = not yet checked
   * true  = onboarding complete
   * false = onboarding needed
   */
  const [onboardingComplete, setOnboardingComplete] = useState<boolean | null>(null);

  // ── Onboarding check ──────────────────────────────────────────────────────
  useEffect(() => {
    if (!user) {
      setOnboardingComplete(null);
      return;
    }

    let cancelled = false;

    async function checkOnboarding(): Promise<void> {
      if (!user) return;
      try {
        const repo = getOnboardingProfileRepo(isGuest);
        const profile = await repo.getProfile(user.uid);

        if (!cancelled) {
          setOnboardingComplete(profile?.hasCompletedOnboarding === true);
        }
      } catch {
        if (!cancelled) {
          // If we can't read the profile, send to onboarding (safe default)
          setOnboardingComplete(false);
        }
      }
    }

    void checkOnboarding();

    return () => {
      cancelled = true;
    };
  }, [user, isGuest]);

  // ── FCM token registration after auth resolves ────────────────────────────
  useEffect(() => {
    if (!user || isGuest || Platform.OS === 'web') return;

    void registerFCMToken(user.uid, isGuest);

    // Set up token refresh listener
    let unsubscribeTokenRefresh: (() => void) | undefined;
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const messaging = require('@react-native-firebase/messaging').default;
      unsubscribeTokenRefresh = messaging().onTokenRefresh(() => {
        void registerFCMToken(user.uid, isGuest);
      });
    } catch {
      // Non-fatal — messaging not available in web or missing native module
    }

    return () => {
      unsubscribeTokenRefresh?.();
    };
  }, [user, isGuest]);

  // ── Notification response listener — deep-link on tap ────────────────────
  useEffect(() => {
    const sub = Notifications.addNotificationResponseReceivedListener((response) => {
      const url = response.notification.request.content.data?.url as string | undefined;
      if (url) {
        router.push(url as never);
      }
    });

    return () => {
      sub.remove();
    };
  }, [router]);

  // While auth state is being determined, keep splash visible
  if (isLoading) {
    return null;
  }

  // No user — redirect to auth screen
  if (user === null) {
    return <Redirect href="/sign-in" />;
  }

  // Email user who hasn't verified — redirect to verification screen
  if (!user.emailVerified && !user.isAnonymous) {
    return <Redirect href="/verify-email" />;
  }

  // Still loading onboarding status — keep splash visible
  if (onboardingComplete === null) {
    return null;
  }

  // User hasn't completed onboarding — route to onboarding flow
  if (!onboardingComplete) {
    return <Redirect href="/(onboarding)/step-name" />;
  }

  // Authenticated or guest, fully onboarded — render the tab shell
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen
        name="timer-mode"
        options={{ headerShown: false, presentation: 'fullScreenModal' }}
      />
      <Stack.Screen
        name="workout-session"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="exercise-picker"
        options={{ headerShown: false, presentation: 'modal' }}
      />
      <Stack.Screen
        name="workout-detail"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="exercise-detail"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="injuries"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="programs"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="benchmarks"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="wods"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="ai-workout"
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="goodbye"
        options={{ headerShown: false }}
      />
    </Stack>
  );
}

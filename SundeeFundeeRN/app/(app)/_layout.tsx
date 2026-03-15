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
 */

import { useEffect, useState } from 'react';
import { Redirect, Stack } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getOnboardingProfileRepo } from '@/src/repositories/OnboardingProfileRepo';

export default function AppLayout(): React.JSX.Element | null {
  const { user, isLoading, isGuest } = useSession();
  /**
   * null  = not yet checked
   * true  = onboarding complete
   * false = onboarding needed
   */
  const [onboardingComplete, setOnboardingComplete] = useState<boolean | null>(null);

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
    </Stack>
  );
}

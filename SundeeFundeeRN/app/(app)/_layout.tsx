/**
 * app/(app)/_layout.tsx — Protected route guard.
 *
 * Enforces auth requirements using the redirect pattern (expo-router compatible):
 * - While loading: return null (keeps splash screen visible)
 * - No user: redirect to /sign-in
 * - Unverified email user (not anonymous): redirect to /verify-email
 * - Authenticated + verified (or guest): render the (tabs) stack
 *
 * Uses useSession() from AuthContext — SessionProvider is already mounted at root.
 */

import { Redirect, Stack } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';

export default function AppLayout(): React.JSX.Element | null {
  const { user, isLoading } = useSession();

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

  // Authenticated or guest — render the tab shell
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
    </Stack>
  );
}

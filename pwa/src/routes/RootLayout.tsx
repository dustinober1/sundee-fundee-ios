/**
 * RootLayout — top-level layout wrapping all routes.
 * Provides SessionProvider + EntitlementProvider.
 */
import { Outlet } from 'react-router';
import { SessionProvider } from '../auth/AuthContext';
import { EntitlementProvider } from '../entitlements/EntitlementContext';
import { initAnalytics } from '../firebase/analytics';

// Initialize analytics once at app startup
initAnalytics();

export function RootLayout() {
  return (
    <SessionProvider>
      <EntitlementProvider>
        <Outlet />
      </EntitlementProvider>
    </SessionProvider>
  );
}

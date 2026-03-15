/**
 * EntitlementContext — app-wide entitlement state provider.
 *
 * Wraps useEntitlements so every screen can access isPremium / isLoading
 * without independently calling useEntitlements (which would spawn duplicate listeners).
 *
 * Usage:
 *   // In _layout.tsx or a high-level wrapper:
 *   <EntitlementProvider>
 *     <App />
 *   </EntitlementProvider>
 *
 *   // In any component:
 *   const { isPremium, isLoading } = useEntitlementContext();
 */
import React, { createContext, useContext } from 'react';
import { useSession } from '@/src/auth/AuthContext';
import { useEntitlements, type EntitlementState } from './useEntitlements';

// ─── Context ──────────────────────────────────────────────────────────────────

const EntitlementContext = createContext<EntitlementState | null>(null);

// ─── Provider ─────────────────────────────────────────────────────────────────

interface EntitlementProviderProps {
  children: React.ReactNode;
}

/**
 * Provides real-time entitlement state to all descendant components.
 * Must be rendered inside a SessionProvider so it can access the current user UID.
 */
export function EntitlementProvider({
  children,
}: EntitlementProviderProps): React.JSX.Element {
  const { user } = useSession();
  const uid = user?.uid ?? null;
  const entitlementState = useEntitlements(uid);

  return (
    <EntitlementContext.Provider value={entitlementState}>
      {children}
    </EntitlementContext.Provider>
  );
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

/**
 * Returns the current entitlement state from the nearest EntitlementProvider.
 * Throws if called outside an EntitlementProvider.
 */
export function useEntitlementContext(): EntitlementState {
  const ctx = useContext(EntitlementContext);
  if (!ctx) {
    throw new Error(
      'useEntitlementContext must be used within an EntitlementProvider. ' +
        'Ensure your component is wrapped in <EntitlementProvider>.'
    );
  }
  return ctx;
}

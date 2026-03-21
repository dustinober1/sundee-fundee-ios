/**
 * EntitlementContext — app-wide entitlement state provider (Stripe-powered).
 */
import { createContext, useContext, type ReactNode } from 'react';
import { useSession } from '../auth/AuthContext';
import { useEntitlements, type EntitlementState } from './useEntitlements';

const EntitlementContext = createContext<EntitlementState | null>(null);

export function EntitlementProvider({ children }: { children: ReactNode }) {
  const { user } = useSession();
  const entitlementState = useEntitlements(user?.uid ?? null);

  return (
    <EntitlementContext.Provider value={entitlementState}>
      {children}
    </EntitlementContext.Provider>
  );
}

export function useEntitlementContext(): EntitlementState {
  const ctx = useContext(EntitlementContext);
  if (!ctx) {
    throw new Error(
      'useEntitlementContext must be used within an EntitlementProvider.',
    );
  }
  return ctx;
}

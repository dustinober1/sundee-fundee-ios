/**
 * useEntitlements — RevenueCat entitlement hook.
 *
 * Returns the current user's premium entitlement status.
 * RevenueCat is mobile-only in Phase 1; web platform returns { isPremium: false }.
 *
 * The "premium" entitlement identifier matches the RevenueCat dashboard config.
 * Phase 6 will add paywall UI; Phase 1 is infrastructure-only.
 */
import { useState, useEffect } from 'react';
import { Platform } from 'react-native';

const PREMIUM_ENTITLEMENT_ID = 'premium';

export interface EntitlementState {
  isPremium: boolean;
  isLoading: boolean;
}

export function useEntitlements(): EntitlementState {
  const [isPremium, setIsPremium] = useState(false);
  const [isLoading, setIsLoading] = useState(Platform.OS !== 'web');

  useEffect(() => {
    // RevenueCat Web Billing is configured separately in Phase 6 (Stripe integration).
    // On web, always return non-premium until that integration is complete.
    if (Platform.OS === 'web') {
      setIsPremium(false);
      setIsLoading(false);
      return;
    }

    let cancelled = false;

    async function checkEntitlements(): Promise<void> {
      try {
        // Dynamic import to prevent build issues if module is unavailable
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const Purchases = require('react-native-purchases').default;
        const customerInfo = await Purchases.getCustomerInfo();
        const active = customerInfo?.entitlements?.active ?? {};
        if (!cancelled) {
          setIsPremium(PREMIUM_ENTITLEMENT_ID in active);
        }
      } catch (error) {
        // Gracefully degrade — RevenueCat not configured yet (Phase 1 infrastructure)
        if (!cancelled) {
          setIsPremium(false);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    void checkEntitlements();

    return () => {
      cancelled = true;
    };
  }, []);

  return { isPremium, isLoading };
}

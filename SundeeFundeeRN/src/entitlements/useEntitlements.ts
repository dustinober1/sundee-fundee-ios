/**
 * useEntitlements — RevenueCat entitlement hook.
 *
 * Returns the current user's premium entitlement status with real-time updates.
 *
 * - Mobile (iOS/Android): initial getCustomerInfo check + addCustomerInfoUpdateListener
 *   for real-time updates. Listener is cleaned up on unmount.
 * - Web: reads Firestore /users/{uid}.premiumEntitlement.active via onSnapshot
 *   for real-time Firestore-driven entitlement (set by Stripe webhook via Cloud Function).
 *
 * The "premium" entitlement identifier matches the RevenueCat dashboard config.
 */
import { useState, useEffect } from 'react';
import { Platform } from 'react-native';

export const PREMIUM_ENTITLEMENT_ID = 'premium';

export interface EntitlementState {
  isPremium: boolean;
  isLoading: boolean;
}

export function useEntitlements(uid?: string | null): EntitlementState {
  const [isPremium, setIsPremium] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (Platform.OS === 'web') {
      // Web: read Firestore /users/{uid}.premiumEntitlement.active via real-time listener
      if (!uid) {
        setIsPremium(false);
        setIsLoading(false);
        return;
      }

      let unsubscribe: (() => void) | null = null;

      try {
        // Dynamic require to prevent web SDK from bundling on native
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { doc, onSnapshot } = require('firebase/firestore');
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const { getFirestoreInstance } = require('@/src/firebase/firestore');
        const db = getFirestoreInstance();
        const userDocRef = doc(db, 'users', uid);

        unsubscribe = onSnapshot(
          userDocRef,
          (snapshot: { exists: () => boolean; data: () => Record<string, unknown> | undefined }) => {
            if (snapshot.exists()) {
              const data = snapshot.data();
              const premiumEntitlement = data?.premiumEntitlement as
                | { active?: boolean }
                | undefined;
              setIsPremium(premiumEntitlement?.active === true);
            } else {
              setIsPremium(false);
            }
            setIsLoading(false);
          },
          // eslint-disable-next-line @typescript-eslint/no-unused-vars
          (_error: unknown) => {
            // Gracefully degrade on Firestore error
            setIsPremium(false);
            setIsLoading(false);
          }
        );
      } catch {
        setIsPremium(false);
        setIsLoading(false);
      }

      return () => {
        unsubscribe?.();
      };
    }

    // Mobile path: RevenueCat real-time entitlement tracking
    let cancelled = false;
    let subscription: { remove: () => void } | null = null;

    async function checkAndListen(): Promise<void> {
      try {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const Purchases = require('react-native-purchases').default;

        // Initial check
        const customerInfo = await Purchases.getCustomerInfo();
        const active = customerInfo?.entitlements?.active ?? {};
        if (!cancelled) {
          setIsPremium(PREMIUM_ENTITLEMENT_ID in active);
          setIsLoading(false);
        }

        // Real-time listener for subsequent updates
        if (!cancelled) {
          subscription = Purchases.addCustomerInfoUpdateListener(
            (info: { entitlements?: { active?: Record<string, unknown> } }) => {
              if (!cancelled) {
                const activeEntitlements = info?.entitlements?.active ?? {};
                setIsPremium(PREMIUM_ENTITLEMENT_ID in activeEntitlements);
              }
            }
          );
        }
      } catch {
        // Gracefully degrade — RevenueCat not configured
        if (!cancelled) {
          setIsPremium(false);
          setIsLoading(false);
        }
      }
    }

    void checkAndListen();

    return () => {
      cancelled = true;
      subscription?.remove();
    };
  }, [uid]);

  return { isPremium, isLoading };
}

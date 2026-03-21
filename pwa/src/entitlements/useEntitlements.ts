/**
 * useEntitlements — Firestore-based entitlement hook (web-only, Stripe-powered).
 *
 * Reads Firestore /users/{uid}.premiumEntitlement.active via onSnapshot
 * for real-time subscription status. Set by Stripe webhook via Cloud Function.
 */
import { useState, useEffect } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';

export interface EntitlementState {
  isPremium: boolean;
  isLoading: boolean;
}

export function useEntitlements(uid?: string | null): EntitlementState {
  const [isPremium, setIsPremium] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!uid) {
      setIsPremium(false);
      setIsLoading(false);
      return;
    }

    const db = getFirestoreInstance();
    const userDocRef = doc(db, 'users', uid);

    const unsubscribe = onSnapshot(
      userDocRef,
      (snapshot) => {
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
      () => {
        setIsPremium(false);
        setIsLoading(false);
      },
    );

    return () => unsubscribe();
  }, [uid]);

  return { isPremium, isLoading };
}

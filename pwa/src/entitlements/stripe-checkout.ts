/**
 * Stripe Checkout integration for PWA premium subscriptions.
 *
 * Flow:
 *   1. Client calls createCheckoutSession() with user UID
 *   2. Cloud Function creates a Stripe Checkout Session and returns the URL
 *   3. Client redirects to Stripe-hosted checkout page
 *   4. On success, Stripe webhook fires → Cloud Function sets premiumEntitlement.active = true
 *   5. useEntitlements() picks up the Firestore change in real-time
 *
 * For the customer portal (manage subscription, cancel):
 *   1. Client calls createPortalSession() with user UID
 *   2. Cloud Function creates a Stripe Customer Portal session and returns the URL
 *   3. Client redirects to the portal
 */

import { getFunctions, httpsCallable } from 'firebase/functions';
import { getFirebaseApp } from '../firebase/app';
import { logEvent } from '../firebase/analytics';

interface CheckoutSessionResponse {
  url: string;
}

interface PortalSessionResponse {
  url: string;
}

/**
 * Creates a Stripe Checkout session via Cloud Function and redirects to it.
 * @param uid - Firebase Auth UID
 * @param priceId - Stripe Price ID for the subscription plan
 */
export async function redirectToCheckout(uid: string, priceId: string): Promise<void> {
  const functions = getFunctions(getFirebaseApp());
  const createSession = httpsCallable<
    { uid: string; priceId: string; successUrl: string; cancelUrl: string },
    CheckoutSessionResponse
  >(functions, 'createStripeCheckoutSession');

  const { data } = await createSession({
    uid,
    priceId,
    successUrl: `${window.location.origin}/settings?checkout=success`,
    cancelUrl: `${window.location.origin}/settings?checkout=cancelled`,
  });

  void logEvent('begin_checkout', { price_id: priceId });
  window.location.href = data.url;
}

/**
 * Creates a Stripe Customer Portal session for subscription management.
 * @param uid - Firebase Auth UID
 */
export async function redirectToCustomerPortal(uid: string): Promise<void> {
  const functions = getFunctions(getFirebaseApp());
  const createPortal = httpsCallable<
    { uid: string; returnUrl: string },
    PortalSessionResponse
  >(functions, 'createStripePortalSession');

  const { data } = await createPortal({
    uid,
    returnUrl: `${window.location.origin}/settings`,
  });

  window.location.href = data.url;
}

/**
 * Default Stripe Price ID for the premium subscription.
 * Should be configured via environment variable in production.
 */
export const STRIPE_PREMIUM_PRICE_ID = import.meta.env.VITE_STRIPE_PRICE_ID ?? 'price_PLACEHOLDER';

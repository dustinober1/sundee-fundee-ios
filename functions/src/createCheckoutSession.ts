/**
 * createStripeCheckoutSession + createStripePortalSession Cloud Functions (BACK-02)
 *
 * createStripeCheckoutSession:
 *   - Auth-gated onCall function
 *   - Creates (or reuses) a Stripe customer linked to the Firebase UID via metadata.firebaseUID
 *   - Creates a Stripe Checkout session and returns the redirect URL
 *
 * createStripePortalSession:
 *   - Auth-gated onCall function
 *   - Looks up the user's Stripe customer ID from Firestore
 *   - Creates a Stripe Billing Portal session and returns the URL
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as logger from 'firebase-functions/logger';
import Stripe from 'stripe';
import { getFirestore } from 'firebase-admin/firestore';

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');

// ---------------------------------------------------------------------------
// createStripeCheckoutSession
// ---------------------------------------------------------------------------

export const createStripeCheckoutSession = onCall(
  { secrets: [stripeSecretKey], region: 'us-central1' },
  async (request) => {
    // Auth gate
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const uid = request.auth.uid;
    const data = request.data as Record<string, unknown>;
    const { priceId, successUrl, cancelUrl } = data;

    // Input validation
    if (!priceId || typeof priceId !== 'string') {
      throw new HttpsError('invalid-argument', 'priceId is required.');
    }
    if (!successUrl || typeof successUrl !== 'string') {
      throw new HttpsError('invalid-argument', 'successUrl is required.');
    }
    if (!cancelUrl || typeof cancelUrl !== 'string') {
      throw new HttpsError('invalid-argument', 'cancelUrl is required.');
    }

    const stripe = new Stripe(stripeSecretKey.value());

    // Check for existing Stripe customer in Firestore
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(uid).get();
    const existingCustomerId = (userDoc.data() as Record<string, unknown> | undefined)
      ?.premiumEntitlement as Record<string, string> | undefined;
    const stripeCustomerId = existingCustomerId?.stripeCustomerId;

    let customer: { id: string };
    if (stripeCustomerId) {
      logger.info('Reusing existing Stripe customer', { uid, stripeCustomerId });
      customer = await stripe.customers.retrieve(stripeCustomerId) as { id: string };
    } else {
      const email = (request.auth.token as Record<string, unknown> | undefined)?.email as string | undefined;
      customer = await stripe.customers.create({
        email,
        metadata: { firebaseUID: uid },
      });
      logger.info('Created new Stripe customer', { uid, customerId: customer.id });
    }

    // Create Checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customer.id,
      line_items: [{ price: priceId as string, quantity: 1 }],
      mode: 'subscription',
      success_url: successUrl as string,
      cancel_url: cancelUrl as string,
    });

    logger.info('Created Stripe Checkout session', { uid, sessionId: session.id });

    return { url: session.url };
  }
);

// ---------------------------------------------------------------------------
// createStripePortalSession
// ---------------------------------------------------------------------------

export const createStripePortalSession = onCall(
  { secrets: [stripeSecretKey], region: 'us-central1' },
  async (request) => {
    // Auth gate
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const uid = request.auth.uid;
    const data = request.data as Record<string, unknown>;
    const { returnUrl } = data;

    // Input validation
    if (!returnUrl || typeof returnUrl !== 'string') {
      throw new HttpsError('invalid-argument', 'returnUrl is required.');
    }

    // Look up Stripe customer ID
    const db = getFirestore();
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data() as Record<string, unknown> | undefined;
    const premiumEntitlement = userData?.premiumEntitlement as Record<string, string> | undefined;
    const stripeCustomerId = premiumEntitlement?.stripeCustomerId;

    if (!stripeCustomerId) {
      throw new HttpsError('failed-precondition', 'No active subscription found.');
    }

    const stripe = new Stripe(stripeSecretKey.value());

    const portalSession = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: returnUrl,
    });

    logger.info('Created Stripe Billing Portal session', { uid });

    return { url: portalSession.url };
  }
);

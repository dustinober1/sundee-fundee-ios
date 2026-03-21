/**
 * stripeWebhook Cloud Function (BACK-03)
 *
 * onRequest function that receives Stripe webhook events.
 * Verifies the Stripe signature using rawBody before processing.
 *
 * Handles:
 *   - checkout.session.completed → sets premiumEntitlement.active = true in Firestore
 *   - customer.subscription.deleted → sets premiumEntitlement.active = false in Firestore
 *
 * Always responds with { received: true } for valid signatures (Stripe expects a 200).
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as logger from 'firebase-functions/logger';
import Stripe from 'stripe';
import { getFirestore } from 'firebase-admin/firestore';

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

export const stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret], region: 'us-central1' },
  async (request, response) => {
    const sig = (request as unknown as { headers: Record<string, string> }).headers['stripe-signature'];

    if (!sig) {
      logger.warn('stripeWebhook: missing stripe-signature header');
      (response as unknown as { status: (code: number) => { send: (body: string) => void } })
        .status(400)
        .send('Missing stripe-signature header');
      return;
    }

    const stripe = new Stripe(stripeSecretKey.value());
    let event: Stripe.Event;

    try {
      const rawBody = (request as unknown as { rawBody: Buffer }).rawBody;
      event = stripe.webhooks.constructEvent(rawBody, sig, stripeWebhookSecret.value());
    } catch (err) {
      logger.error('stripeWebhook: signature verification failed', { error: err });
      (response as unknown as { status: (code: number) => { send: (body: string) => void } })
        .status(400)
        .send(`Webhook signature verification failed: ${(err as Error).message}`);
      return;
    }

    logger.info('stripeWebhook: received event', { type: event.type });

    const db = getFirestore();

    try {
      if (event.type === 'checkout.session.completed') {
        const session = event.data.object as Stripe.Checkout.Session;
        const customerId = session.customer as string;
        const subscriptionId = session.subscription as string;

        // Retrieve customer to get firebaseUID from metadata
        const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer;
        const uid = customer.metadata?.firebaseUID;

        if (uid) {
          await db.collection('users').doc(uid).set(
            {
              premiumEntitlement: {
                active: true,
                stripeCustomerId: customerId,
                subscriptionId,
                activatedAt: new Date().toISOString(),
              },
            },
            { merge: true }
          );
          logger.info('stripeWebhook: activated premium for user', { uid, customerId });
        } else {
          logger.warn('stripeWebhook: no firebaseUID in customer metadata', { customerId });
        }
      } else if (event.type === 'customer.subscription.deleted') {
        const subscription = event.data.object as Stripe.Subscription;
        const customerId = subscription.customer as string;

        // Retrieve customer to get firebaseUID from metadata
        const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer;
        const uid = customer.metadata?.firebaseUID;

        if (uid) {
          await db.collection('users').doc(uid).set(
            {
              premiumEntitlement: {
                active: false,
                cancelledAt: new Date().toISOString(),
              },
            },
            { merge: true }
          );
          logger.info('stripeWebhook: deactivated premium for user', { uid, customerId });
        } else {
          logger.warn('stripeWebhook: no firebaseUID in customer metadata', { customerId });
        }
      } else {
        logger.info('stripeWebhook: unhandled event type (ignored)', { type: event.type });
      }
    } catch (err) {
      logger.error('stripeWebhook: error processing event', { type: event.type, error: err });
    }

    (response as unknown as { json: (body: unknown) => void }).json({ received: true });
  }
);

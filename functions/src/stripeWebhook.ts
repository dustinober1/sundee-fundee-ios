import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");
const RC_SECRET_API_KEY = defineSecret("RC_SECRET_API_KEY");

const ACTIVE_STATUSES = new Set(["active", "trialing", "past_due"]);

async function grantRCEntitlement(appUserId: string, rcSecretKey: string): Promise<void> {
  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${rcSecretKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ duration: "lifetime" }),
    });
    if (!res.ok) {
      logger.error("RC grant failed", { status: res.status, uid: appUserId });
    }
  } catch (err) {
    logger.error("RC grant error", { err, uid: appUserId });
  }
}

async function revokeRCEntitlement(appUserId: string, rcSecretKey: string): Promise<void> {
  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
  try {
    const res = await fetch(url, {
      method: "DELETE",
      headers: {
        Authorization: `Bearer ${rcSecretKey}`,
      },
    });
    if (!res.ok) {
      logger.error("RC revoke failed", { status: res.status, uid: appUserId });
    }
  } catch (err) {
    logger.error("RC revoke error", { err, uid: appUserId });
  }
}

export const stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, RC_SECRET_API_KEY] },
  async (request, response) => {
    const sig = request.headers["stripe-signature"];
    if (!sig) {
      response.status(400).send("Missing stripe-signature header");
      return;
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        sig as string,
        STRIPE_WEBHOOK_SECRET.value()
      );
    } catch (err) {
      logger.error("Webhook signature verification failed", err);
      response.status(400).send("Webhook signature verification failed");
      return;
    }

    const subscription = event.data.object as Stripe.Subscription;
    const firebaseUID = subscription.metadata?.firebaseUID;

    if (!firebaseUID) {
      logger.warn("No firebaseUID in subscription metadata", { type: event.type });
      response.json({ received: true });
      return;
    }

    const rcKey = RC_SECRET_API_KEY.value();

    if (
      event.type === "customer.subscription.created" ||
      event.type === "customer.subscription.updated"
    ) {
      if (ACTIVE_STATUSES.has(subscription.status)) {
        await grantRCEntitlement(firebaseUID, rcKey);
        try {
          await admin
            .firestore()
            .doc(`users/${firebaseUID}`)
            .set(
              {
                premiumEntitlement: { active: true, expiresAt: null, source: "stripe" },
                stripeSubscriptionId: subscription.id,
              },
              { merge: true }
            );
        } catch (err) {
          logger.error("Firestore grant write failed", { err, uid: firebaseUID });
        }
      } else {
        await revokeRCEntitlement(firebaseUID, rcKey);
        try {
          await admin
            .firestore()
            .doc(`users/${firebaseUID}`)
            .set(
              {
                premiumEntitlement: {
                  active: false,
                  expiresAt: admin.firestore.Timestamp.now(),
                  source: "stripe",
                },
              },
              { merge: true }
            );
        } catch (err) {
          logger.error("Firestore revoke write failed", { err, uid: firebaseUID });
        }
      }
    } else if (event.type === "customer.subscription.deleted") {
      await revokeRCEntitlement(firebaseUID, rcKey);
      try {
        await admin
          .firestore()
          .doc(`users/${firebaseUID}`)
          .set(
            {
              premiumEntitlement: {
                active: false,
                expiresAt: admin.firestore.Timestamp.now(),
                source: "stripe",
              },
            },
            { merge: true }
          );
      } catch (err) {
        logger.error("Firestore revoke write failed", { err, uid: firebaseUID });
      }
    }

    response.json({ received: true });
  }
);

/**
 * deleteAccount Cloud Function
 *
 * Callable function that performs a full account deletion:
 *   1. Revoke RevenueCat entitlement (best-effort)
 *   2. Cancel Stripe subscription if stripeSubscriptionId exists (best-effort)
 *   3. Recursively delete all Firestore data under /users/{uid}
 *   4. Delete Firebase Auth user
 *
 * Requires the caller to be authenticated. Unauthenticated requests
 * are rejected with an HttpsError('unauthenticated') immediately.
 *
 * Steps 1 and 2 are best-effort: errors are logged but do not abort
 * the deletion. The user's data is always removed from Firestore and
 * Auth regardless of external API failures.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const RC_SECRET_API_KEY = defineSecret("RC_SECRET_API_KEY");

/**
 * Revoke the RevenueCat premium entitlement for a user.
 * Best-effort: catches and logs errors, never throws.
 */
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

export const deleteAccount = onCall(
  {
    secrets: [STRIPE_SECRET_KEY, RC_SECRET_API_KEY],
    timeoutSeconds: 540,
  },
  async (request) => {
    // Authentication guard
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated to delete account");
    }

    const uid = request.auth.uid;
    const db = admin.firestore();

    // Step 1: Revoke RevenueCat entitlement (best-effort)
    await revokeRCEntitlement(uid, RC_SECRET_API_KEY.value());

    // Step 2: Cancel Stripe subscription (best-effort)
    try {
      const userDoc = await db.doc(`users/${uid}`).get();
      const userData = userDoc.data();
      const stripeSubscriptionId = userData?.stripeSubscriptionId as string | undefined;

      if (stripeSubscriptionId) {
        const stripe = new Stripe(STRIPE_SECRET_KEY.value());
        await stripe.subscriptions.cancel(stripeSubscriptionId);
      }
    } catch (err) {
      logger.error("Stripe cancel error during account deletion", { err, uid });
    }

    // Step 3: Recursively delete all Firestore data under /users/{uid}
    await db.recursiveDelete(db.doc(`users/${uid}`));

    // Step 4: Delete Firebase Auth user
    await admin.auth().deleteUser(uid);

    return { success: true };
  }
);

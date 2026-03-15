import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Stripe from "stripe";

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

export const createCheckoutSession = onCall(
  { secrets: [STRIPE_SECRET_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const { priceId, successUrl, cancelUrl } = request.data as {
      priceId: string;
      successUrl: string;
      cancelUrl: string;
    };

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      subscription_data: {
        trial_period_days: 7,
        trial_settings: {
          end_behavior: { missing_payment_method: "cancel" },
        },
        metadata: { firebaseUID: request.auth.uid },
      },
      payment_method_collection: "if_required",
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { firebaseUID: request.auth.uid },
    });

    return { url: session.url };
  }
);

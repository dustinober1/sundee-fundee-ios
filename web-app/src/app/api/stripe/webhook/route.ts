import { NextRequest, NextResponse } from "next/server";
import { createStripeClient, subscriptionRecordFromStripe, tierFromPriceId } from "@/lib/stripe";
import { db } from "@/lib/firebase-admin";
import type Stripe from "stripe";

function subscriptionPayload(
  tier: "free" | "plus" | "premium",
  input: {
    status: string | null | undefined;
    stripeCustomerId?: string | null;
    stripeSubscriptionId?: string | null;
    currentPeriodEnd?: number | null;
    cancelAtPeriodEnd?: boolean | null;
  }
) {
  const record = subscriptionRecordFromStripe(tier, input);
  return {
    ...record,
    createdAt: record.createdAt ?? new Date(),
    updatedAt: new Date(),
  };
}

async function upsertSubscriptionByUserId(userId: string, payload: Record<string, unknown>) {
  await db.collection("users").doc(userId).collection("subscription").doc("current").set(payload, { merge: true });
}

async function upsertSubscriptionByStripeId(stripeSubscriptionId: string, payload: Record<string, unknown>) {
  const usersSnapshot = await db.collectionGroup("subscription")
    .where("stripeSubscriptionId", "==", stripeSubscriptionId)
    .limit(1)
    .get();

  if (!usersSnapshot.empty) {
    await usersSnapshot.docs[0].ref.set(payload, { merge: true });
  }
}

export async function POST(req: NextRequest) {
  const stripe = createStripeClient();
  const body = await req.text();
  const sig = req.headers.get("stripe-signature")!;

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      const userId = session.metadata?.userId;
      if (!userId || !session.subscription) break;

      const sub = await stripe.subscriptions.retrieve(session.subscription as string);
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const tier = tierFromPriceId(priceId ?? "") ?? "free";
      await upsertSubscriptionByUserId(userId, subscriptionPayload(tier, {
        status: sub.status,
        stripeCustomerId: typeof session.customer === "string" ? session.customer : null,
        stripeSubscriptionId: typeof session.subscription === "string" ? session.subscription : null,
        currentPeriodEnd: item?.current_period_end ?? null,
        cancelAtPeriodEnd: sub.cancel_at_period_end,
      }));
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted":
    case "customer.subscription.created": {
      const sub = event.data.object as Stripe.Subscription;
      const subItem = sub.items.data[0];
      const priceId = subItem?.price.id;
      const mappedTier = tierFromPriceId(priceId ?? "") ?? "free";
      const tier = sub.status === "canceled" || sub.status === "unpaid" ? "free" : mappedTier;
      await upsertSubscriptionByStripeId(sub.id, subscriptionPayload(tier, {
        status: sub.status,
        stripeCustomerId: typeof sub.customer === "string" ? sub.customer : null,
        stripeSubscriptionId: sub.id,
        currentPeriodEnd: subItem?.current_period_end ?? null,
        cancelAtPeriodEnd: sub.cancel_at_period_end,
      }));
      break;
    }
  }

  return NextResponse.json({ received: true });
}

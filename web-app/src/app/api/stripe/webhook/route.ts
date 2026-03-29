import { NextRequest, NextResponse } from "next/server";
import { createStripeClient, tierFromPriceId } from "@/lib/stripe";
import { db } from "@/lib/firebase-admin";

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
      const session = event.data.object;
      const userId = session.metadata?.userId;
      if (!userId || !session.subscription) break;

      const sub = await stripe.subscriptions.retrieve(session.subscription as string);
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const tier = tierFromPriceId(priceId ?? "") ?? "free";
      const periodEnd = item?.current_period_end ?? 0;

      await db.collection("users").doc(userId).collection("subscription").doc("current").set({
        stripeCustomerId: session.customer as string,
        stripeSubscriptionId: session.subscription as string,
        tier,
        status: "active",
        currentPeriodEnd: new Date(periodEnd * 1000),
        createdAt: new Date(),
        updatedAt: new Date(),
      }, { merge: true });
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object;
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const periodEnd = item?.current_period_end ?? 0;
      const tier = sub.status === "active" ? (tierFromPriceId(priceId ?? "") ?? "free") : "free";

      const usersSnapshot = await db.collectionGroup("subscription")
        .where("stripeSubscriptionId", "==", sub.id)
        .limit(1)
        .get();

      if (!usersSnapshot.empty) {
        await usersSnapshot.docs[0].ref.update({
          tier,
          status: sub.status === "active" ? "active" : "canceled",
          currentPeriodEnd: new Date(periodEnd * 1000),
          updatedAt: new Date(),
        });
      }
      break;
    }
  }

  return NextResponse.json({ received: true });
}

import { NextRequest, NextResponse } from "next/server";
import { createStripeClient, tierFromPriceId } from "@/lib/stripe";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { subscriptions } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function POST(req: NextRequest) {
  const env = await getBindings();
  const stripe = createStripeClient(env.STRIPE_SECRET_KEY);
  const body = await req.text();
  const sig = req.headers.get("stripe-signature")!;

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, env.STRIPE_WEBHOOK_SECRET);
  } catch {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  const db = createDb(env.DB);

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

      await db.insert(subscriptions).values({
        id: crypto.randomUUID(),
        userId,
        stripeCustomerId: session.customer as string,
        stripeSubscriptionId: session.subscription as string,
        tier,
        status: "active",
        currentPeriodEnd: new Date(periodEnd * 1000),
        createdAt: new Date(),
        updatedAt: new Date(),
      }).onConflictDoUpdate({
        target: subscriptions.userId,
        set: {
          stripeSubscriptionId: session.subscription as string,
          tier,
          status: "active",
          currentPeriodEnd: new Date(periodEnd * 1000),
          updatedAt: new Date(),
        },
      });
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object;
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const periodEnd = item?.current_period_end ?? 0;
      const tier = sub.status === "active" ? (tierFromPriceId(priceId ?? "") ?? "free") : "free";

      await db.update(subscriptions)
        .set({
          tier,
          status: sub.status === "active" ? "active" : "canceled",
          currentPeriodEnd: new Date(periodEnd * 1000),
          updatedAt: new Date(),
        })
        .where(eq(subscriptions.stripeSubscriptionId, sub.id));
      break;
    }
  }

  return NextResponse.json({ received: true });
}

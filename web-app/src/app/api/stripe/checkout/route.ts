import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { createStripeClient, STRIPE_PRICES } from "@/lib/stripe";
import { getBindings } from "@/lib/bindings";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();
  const { tier, interval } = body as {
    tier: "plus" | "premium";
    interval: "monthly" | "annual";
  };

  if (!tier || !interval || !STRIPE_PRICES[tier]?.[interval]) {
    return NextResponse.json({ error: "Invalid tier or interval" }, { status: 400 });
  }

  const env = await getBindings();
  const stripe = createStripeClient(env.STRIPE_SECRET_KEY);

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer_email: session.user.email ?? undefined,
    line_items: [{ price: STRIPE_PRICES[tier][interval], quantity: 1 }],
    success_url: `${env.NEXT_PUBLIC_APP_URL}/settings?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${env.NEXT_PUBLIC_APP_URL}/settings`,
    metadata: { userId: session.user.id },
  });

  return NextResponse.json({ url: checkoutSession.url });
}

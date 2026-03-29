import { NextRequest, NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient, STRIPE_PRICES } from "@/lib/stripe";

export async function POST(req: NextRequest) {
  const user = await getAuthUser();
  if (!user) {
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

  const stripe = createStripeClient();
  const appUrl = process.env.NEXT_PUBLIC_APP_URL!;

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer_email: user.email ?? undefined,
    line_items: [{ price: STRIPE_PRICES[tier][interval], quantity: 1 }],
    allow_promotion_codes: true,
    success_url: `${appUrl}/settings?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/settings`,
    metadata: { userId: user.uid },
  });

  return NextResponse.json({ url: checkoutSession.url });
}

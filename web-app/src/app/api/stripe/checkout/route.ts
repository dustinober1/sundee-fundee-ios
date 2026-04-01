import { NextRequest, NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient, STRIPE_PRICES } from "@/lib/stripe";
import { requireOneOf } from "@/lib/write-validation";

export async function POST(req: NextRequest) {
  try {
    const user = await getAuthUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    let tier: "plus" | "premium";
    let interval: "monthly" | "annual";
    try {
      const body = await req.json() as Record<string, unknown>;
      tier = requireOneOf(String(body.tier ?? ""), ["plus", "premium"], "tier");
      interval = requireOneOf(String(body.interval ?? ""), ["monthly", "annual"], "interval");
    } catch (error) {
      return NextResponse.json({ error: (error as Error).message }, { status: 400 });
    }

    if (!process.env.STRIPE_SECRET_KEY) {
      return NextResponse.json({ error: "Stripe is not configured on the server." }, { status: 500 });
    }
    if (!process.env.NEXT_PUBLIC_APP_URL) {
      return NextResponse.json({ error: "NEXT_PUBLIC_APP_URL is not configured." }, { status: 500 });
    }

    const stripe = createStripeClient();
    const appUrl = process.env.NEXT_PUBLIC_APP_URL;

    const checkoutSession = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer_email: user.email ?? undefined,
      line_items: [{ price: STRIPE_PRICES[tier][interval], quantity: 1 }],
      allow_promotion_codes: true,
      success_url: `${appUrl}/settings?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${appUrl}/settings`,
      client_reference_id: user.uid,
      metadata: { userId: user.uid, tier, interval },
    });

    return NextResponse.json({ url: checkoutSession.url });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Unable to start Stripe checkout." },
      { status: 500 }
    );
  }
}

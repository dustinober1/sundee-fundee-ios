import { NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient } from "@/lib/stripe";
import { getSubscriptionRecord } from "@/lib/subscription-state";

async function createPortalResponse() {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const subscription = await getSubscriptionRecord(user.uid);
  const stripeCustomerId = subscription.stripeCustomerId;
  if (!stripeCustomerId) {
    return NextResponse.json({ error: "No subscription found" }, { status: 404 });
  }

  const stripe = createStripeClient();
  const portalSession = await stripe.billingPortal.sessions.create({
    customer: stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/settings`,
  });

  return NextResponse.json({ url: portalSession.url });
}

export async function POST() {
  return createPortalResponse();
}

export async function GET() {
  const response = await createPortalResponse();
  if ("status" in response && response.status !== 200) {
    return response;
  }
  const body = await response.json();
  if (!body?.url || typeof body.url !== "string") {
    return NextResponse.json({ error: "No subscription found" }, { status: 404 });
  }
  return NextResponse.redirect(body.url);
}

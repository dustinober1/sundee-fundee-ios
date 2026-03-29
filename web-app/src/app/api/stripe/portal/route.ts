import { NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient } from "@/lib/stripe";
import { db } from "@/lib/firebase-admin";

export async function POST() {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const subDoc = await db.collection("users").doc(user.uid)
    .collection("subscription").doc("current").get();

  const stripeCustomerId = subDoc.data()?.stripeCustomerId;
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

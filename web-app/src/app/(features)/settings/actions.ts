"use server";

import { getAuthUser, userDoc, db } from "@/lib/firestore";
import { resolveEntitlement, serializeSubscriptionRecord } from "@/lib/subscription-state";
import { createStripeClient, tierFromPriceId, subscriptionRecordFromStripe } from "@/lib/stripe";
import { optionalTrimmedString } from "@/lib/write-validation";

export async function getUserProfile() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userDoc(user.uid).get();
  if (!doc.exists) return null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return { id: doc.id, ...(doc.data() as any) };
}

export async function updateProfile(data: { name?: string; weightUnit?: string; experienceLevel?: string; primaryGoal?: string }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const updateData: Record<string, unknown> = { profileUpdatedAt: new Date() };
  const name = optionalTrimmedString(data.name);
  const weightUnit = optionalTrimmedString(data.weightUnit);
  const experienceLevel = optionalTrimmedString(data.experienceLevel);
  const primaryGoal = optionalTrimmedString(data.primaryGoal);

  if (name != null) updateData.name = name;
  if (weightUnit != null) updateData.weightUnit = weightUnit;
  if (experienceLevel != null) updateData.experienceLevel = experienceLevel;
  if (primaryGoal != null) updateData.primaryGoal = primaryGoal;

  await userDoc(user.uid).set(updateData, { merge: true });
}

/**
 * Verify a Stripe checkout session and write the subscription to Firestore.
 * Called when the user returns from Stripe before the webhook may have processed.
 */
export async function fulfillCheckoutSession(sessionId: string) {
  if (!sessionId || !process.env.STRIPE_SECRET_KEY) return;

  try {
    const stripe = createStripeClient();
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    const userId = session.metadata?.userId;
    if (!userId || !session.subscription || session.status !== "complete") return;

    // Only fulfill if the authenticated user matches the checkout metadata
    const user = await getAuthUser();
    if (!user || user.uid !== userId) return;

    // Check if subscription doc already exists with correct tier (webhook already processed)
    const existingDoc = await db
      .collection("users").doc(userId)
      .collection("subscription").doc("current")
      .get();

    if (existingDoc.exists) {
      const data = existingDoc.data();
      if (data?.tier === "plus" || data?.tier === "premium") return;
    }

    const sub = await stripe.subscriptions.retrieve(session.subscription as string);
    const item = sub.items.data[0];
    const priceId = item?.price.id;
    const tier = tierFromPriceId(priceId ?? "") ?? "free";

    const record = subscriptionRecordFromStripe(tier, {
      status: sub.status,
      stripeCustomerId: typeof session.customer === "string" ? session.customer : null,
      stripeSubscriptionId: typeof session.subscription === "string" ? session.subscription : null,
      currentPeriodEnd: item?.current_period_end ?? null,
      cancelAtPeriodEnd: sub.cancel_at_period_end,
    });

    await db
      .collection("users").doc(userId)
      .collection("subscription").doc("current")
      .set({ ...record, updatedAt: new Date() }, { merge: true });
  } catch (error) {
    console.error("[settings] Failed to fulfill checkout session", error);
  }
}

export async function getSubscription() {
  const user = await getAuthUser();
  if (!user) return null;

  const entitlement = await resolveEntitlement(user.uid);
  return {
    ...serializeSubscriptionRecord(entitlement.subscription),
    resolvedTier: entitlement.tier,
    hasActivePaidAccess: entitlement.hasActivePaidAccess,
    dailyCloudLimit: entitlement.dailyCloudLimit,
    generatedToday: entitlement.generatedToday,
    remainingCloudGenerations: entitlement.remainingCloudGenerations,
    canUseCloudAI: entitlement.canUseCloudAI,
  };
}

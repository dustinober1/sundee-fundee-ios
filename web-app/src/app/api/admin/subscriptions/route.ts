import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";
import { resolveEntitlement, serializeSubscriptionRecord } from "@/lib/subscription-state";

export async function GET() {
  try {
    await requireAdmin();
    const usersSnapshot = await db.collection("users").get();
    const subscriptions: Record<string, unknown>[] = [];
    for (const userDoc of usersSnapshot.docs) {
      const entitlement = await resolveEntitlement(userDoc.id);
      subscriptions.push({
        uid: userDoc.id,
        email: userDoc.data()?.email,
        name: userDoc.data()?.name,
        ...serializeSubscriptionRecord(entitlement.subscription),
        resolvedTier: entitlement.tier,
        hasActivePaidAccess: entitlement.hasActivePaidAccess,
        dailyCloudLimit: entitlement.dailyCloudLimit,
        generatedToday: entitlement.generatedToday,
        remainingCloudGenerations: entitlement.remainingCloudGenerations,
      });
    }

    return NextResponse.json(subscriptions);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

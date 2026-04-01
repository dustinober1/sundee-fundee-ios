import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";
import { getDailyAIUsage, resolveEntitlement } from "@/lib/subscription-state";

export async function GET() {
  try {
    await requireAdmin();

    const usersSnapshot = await db.collection("users").get();
    const totalUsers = usersSnapshot.size;

    const activeSubs = { free: 0, plus: 0, premium: 0 };
    let aiGenerationsToday = 0;

    await Promise.all(
      usersSnapshot.docs.map(async (userDoc) => {
        const [entitlement, usage] = await Promise.all([
          resolveEntitlement(userDoc.id),
          getDailyAIUsage(userDoc.id),
        ]);
        const tier = entitlement.tier;
        if (tier in activeSubs) activeSubs[tier as keyof typeof activeSubs]++;
        aiGenerationsToday += usage.count;
      })
    );

    return NextResponse.json({
      totalUsers,
      subscriptions: activeSubs,
      aiGenerationsToday,
    });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

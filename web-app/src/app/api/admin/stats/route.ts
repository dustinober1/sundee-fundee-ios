import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();

    const usersSnapshot = await db.collection("users").get();
    const totalUsers = usersSnapshot.size;

    const activeSubs = { free: 0, plus: 0, premium: 0 };
    let aiGenerationsToday = 0;
    const today = new Date().toISOString().split("T")[0];

    for (const userDoc of usersSnapshot.docs) {
      const subDoc = await userDoc.ref.collection("subscription").doc("current").get();
      const tier = subDoc.exists ? (subDoc.data()?.tier ?? "free") : "free";
      if (tier in activeSubs) activeSubs[tier as keyof typeof activeSubs]++;

      const aiDoc = await userDoc.ref.collection("aiUsage").doc(today).get();
      if (aiDoc.exists) {
        aiGenerationsToday += aiDoc.data()?.count ?? 0;
      }
    }

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

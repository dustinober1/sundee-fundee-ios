import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();
    const usersSnapshot = await db.collection("users").get();
    const generations: Record<string, unknown>[] = [];

    for (const userDoc of usersSnapshot.docs) {
      const recordsSnapshot = await userDoc.ref
        .collection("generatedWorkoutRecords")
        .orderBy("createdAt", "desc")
        .limit(20)
        .get();

      for (const recordDoc of recordsSnapshot.docs) {
        generations.push({
          id: recordDoc.id,
          uid: userDoc.id,
          email: userDoc.data()?.email,
          ...recordDoc.data(),
        });
      }
    }

    generations.sort((a, b) => {
      const aDate = String(a.createdAt ?? "");
      const bDate = String(b.createdAt ?? "");
      return bDate.localeCompare(aDate);
    });

    return NextResponse.json(generations);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

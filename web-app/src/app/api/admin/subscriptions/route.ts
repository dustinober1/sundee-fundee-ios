import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();
    const usersSnapshot = await db.collection("users").get();
    const subDocs = await Promise.all(
      usersSnapshot.docs.map((userDoc) =>
        userDoc.ref.collection("subscription").doc("current").get()
      )
    );
    const subscriptions: Record<string, unknown>[] = [];
    for (let i = 0; i < usersSnapshot.docs.length; i++) {
      const userDoc = usersSnapshot.docs[i];
      const subDoc = subDocs[i];
      if (subDoc.exists) {
        subscriptions.push({
          uid: userDoc.id,
          email: userDoc.data()?.email,
          name: userDoc.data()?.name,
          ...subDoc.data(),
        });
      }
    }

    return NextResponse.json(subscriptions);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

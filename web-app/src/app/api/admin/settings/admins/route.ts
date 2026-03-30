import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();
    const snapshot = await db.collection("admins").get();
    const admins = snapshot.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
    return NextResponse.json(admins);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireAdmin();
    const { uid, email, role } = await request.json();
    if (typeof uid !== "string" || !uid) return NextResponse.json({ error: "Missing uid" }, { status: 400 });
    await db.collection("admins").doc(uid).set({ email, role: role ?? "admin", addedAt: new Date().toISOString() });
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    await requireAdmin();
    const { uid } = await request.json();
    if (typeof uid !== "string" || !uid) return NextResponse.json({ error: "Missing uid" }, { status: 400 });
    await db.collection("admins").doc(uid).delete();
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

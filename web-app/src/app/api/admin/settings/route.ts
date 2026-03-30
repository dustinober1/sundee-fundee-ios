import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminDoc } from "@/lib/admin-firestore";

export async function GET() {
  try {
    await requireAdmin();
    const doc = await adminDoc("adminSettings", "config").get();
    if (!doc.exists) {
      return NextResponse.json({
        rateLimits: { free: 0, plus: 1, premium: 10 },
        featureFlags: {},
      });
    }
    return NextResponse.json(doc.data());
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    await requireAdmin();
    const body = await request.json();
    await adminDoc("adminSettings", "config").set(body, { merge: true });
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

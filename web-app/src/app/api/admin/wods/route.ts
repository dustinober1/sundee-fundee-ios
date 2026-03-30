import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";
import { exerciseToFirestore } from "@/lib/domain/admin-types";

export async function GET() {
  try {
    await requireAdmin();
    const snapshot = await adminCollection("wods").orderBy("date", "desc").get();
    const wods = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(wods);
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
    const body = await request.json();
    const { id, ...data } = body;
    if (data.exercises) {
      data.exercises = data.exercises.map((ex: Record<string, unknown>) =>
        exerciseToFirestore(ex as any)
      );
    }
    await adminCollection("wods").doc(id).set(data);
    return NextResponse.json({ ok: true, id });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

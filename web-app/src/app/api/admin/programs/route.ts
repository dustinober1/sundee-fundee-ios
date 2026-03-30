import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";
import { exerciseToFirestore } from "@/lib/domain/admin-types";

export async function GET() {
  try {
    await requireAdmin();
    const snapshot = await adminCollection("programs").orderBy("name", "asc").get();
    const programs = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(programs);
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
    if (typeof id !== "string" || !id) return NextResponse.json({ error: "Missing or invalid id" }, { status: 400 });
    if (data.weeks) {
      data.weeks = data.weeks.map((week: any) => ({
        ...week,
        sessions: week.sessions.map((session: any) => ({
          ...session,
          exercises: session.exercises.map((ex: any) => exerciseToFirestore(ex)),
        })),
      }));
    }
    await adminCollection("programs").doc(id).set(data);
    return NextResponse.json({ ok: true, id });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

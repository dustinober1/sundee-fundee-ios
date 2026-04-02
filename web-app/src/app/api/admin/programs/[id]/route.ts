import { NextRequest, NextResponse } from "next/server";
import { revalidatePath } from "next/cache";
import { requireAdmin } from "@/lib/admin-auth";
import { adminDoc } from "@/lib/admin-firestore";
import { exerciseToFirestore } from "@/lib/domain/admin-types";
import type { ProgramWeek, ProgramSession } from "@/lib/domain/admin-types";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    const doc = await adminDoc("programs", id).get();
    if (!doc.exists) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    const body = await request.json();
    
    // Remove id from body to avoid saving it as a field
    const { id: _, ...data } = body;

    if (data.weeks) {
      data.weeks = (data.weeks as ProgramWeek[]).map((week) => ({
        ...week,
        sessions: (week.sessions || []).map((session: ProgramSession) => ({
          ...session,
          exercises: (session.exercises || []).map((ex) => exerciseToFirestore(ex)),
        })),
      }));
    }
    
    await adminDoc("programs", id).set(data, { merge: true });
    revalidatePath("/programs");
    revalidatePath(`/programs/${id}`);
    
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("[Programs PATCH] Error:", e);
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: (e as Error).message || "Internal error" }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    await adminDoc("programs", id).delete();
    revalidatePath("/programs");
    revalidatePath(`/programs/${id}`);
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("[Programs DELETE] Error:", e);
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: (e as Error).message || "Internal error" }, { status: 500 });
  }
}

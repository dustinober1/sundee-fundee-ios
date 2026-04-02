import { NextRequest, NextResponse } from "next/server";
import { revalidatePath } from "next/cache";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";
import { exerciseToFirestore, exerciseFromFirestore } from "@/lib/domain/admin-types";
import type { ProgramWeek, ProgramSession } from "@/lib/domain/admin-types";

export async function GET() {
  try {
    await requireAdmin();
    const snapshot = await adminCollection("programs").orderBy("name", "asc").get();
    const programs = snapshot.docs.map((doc) => {
      const data = doc.data() as any;
      
      // Sanitize the data for the UI
      if (data.weeks) {
        data.weeks = data.weeks.map((week: any) => ({
          ...week,
          sessions: (week.sessions || []).map((session: any) => ({
            ...session,
            exercises: (session.exercises || []).map((ex: any) => exerciseFromFirestore(ex)),
          })),
        }));
      }
      
      return { id: doc.id, ...data };
    });
    return NextResponse.json(programs);
  } catch (e) {
    console.error("[Programs GET] Error:", e);
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
      data.weeks = (data.weeks as ProgramWeek[]).map((week) => ({
        ...week,
        sessions: (week.sessions || []).map((session: ProgramSession) => ({
          ...session,
          exercises: (session.exercises || []).map((ex) => exerciseToFirestore(ex)),
        })),
      }));
    }
    
    await adminCollection("programs").doc(id).set(data);
    revalidatePath("/programs");
    revalidatePath(`/programs/${id}`);
    
    return NextResponse.json({ ok: true, id });
  } catch (e) {
    console.error("[Programs POST] Error:", e);
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: (e as Error).message || "Internal error" }, { status: 500 });
  }
}

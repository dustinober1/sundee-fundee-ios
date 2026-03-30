import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";

const ALLOWED_COLLECTIONS = ["wods", "programs", "benchmarkDefinitions", "exerciseCatalog", "blogPosts", "supportArticles", "aiPrompts"];

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ collection: string }> }
) {
  try {
    await requireAdmin();
    const { collection } = await params;
    if (!ALLOWED_COLLECTIONS.includes(collection)) {
      return NextResponse.json({ error: "Collection not allowed" }, { status: 400 });
    }
    const items: Record<string, unknown>[] = await request.json();
    const col = adminCollection(collection);
    let count = 0;
    for (const item of items) {
      const { id, ...data } = item;
      if (typeof id !== "string") continue;
      await col.doc(id).set(data);
      count++;
    }
    return NextResponse.json({ ok: true, imported: count });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

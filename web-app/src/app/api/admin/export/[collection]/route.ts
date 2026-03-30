import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";

const ALLOWED_COLLECTIONS = ["wods", "programs", "benchmarkDefinitions", "exerciseCatalog", "blogPosts", "supportArticles", "aiPrompts"];

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ collection: string }> }
) {
  try {
    await requireAdmin();
    const { collection } = await params;
    if (!ALLOWED_COLLECTIONS.includes(collection)) {
      return NextResponse.json({ error: "Collection not allowed" }, { status: 400 });
    }
    const snapshot = await adminCollection(collection).get();
    const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(data);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

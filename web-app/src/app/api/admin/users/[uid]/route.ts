import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { userById, userSubcollection } from "@/lib/admin-firestore";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    await requireAdmin();
    const { uid } = await params;
    const user = await userById(uid);
    if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const [subscription, completedWorkouts, benchmarkResults, oneRepMaxes] =
      await Promise.all([
        userSubcollection(uid, "subscription"),
        userSubcollection(uid, "completedWorkouts"),
        userSubcollection(uid, "benchmarkResults"),
        userSubcollection(uid, "oneRepMaxes"),
      ]);

    return NextResponse.json({
      ...user,
      subscription: subscription[0] ?? null,
      completedWorkoutCount: completedWorkouts.length,
      benchmarkResultCount: benchmarkResults.length,
      oneRepMaxes,
    });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";

const WORKER_URL = "https://workout-proxy.sundeefundee.workers.dev/generate-workout";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json() as Record<string, unknown>;

  try {
    const res = await fetch(WORKER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ...body,
        userId: session.user.id,
      }),
    });

    if (!res.ok) {
      return NextResponse.json({ error: "Generation failed" }, { status: 502 });
    }

    const data = await res.json();
    return NextResponse.json(data);
  } catch {
    return NextResponse.json({ error: "Worker unavailable" }, { status: 503 });
  }
}

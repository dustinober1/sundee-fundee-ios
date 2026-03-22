import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const { ckMethod, path, body, ckWebAuthToken } = await req.json();

    const containerId = process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "";
    const apiToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN ?? "";
    const env = process.env.NEXT_PUBLIC_CLOUDKIT_ENV ?? "production";

    const url = `https://api.apple-cloudkit.com/database/1/${containerId}/${env}/public/${path}?ckAPIToken=${apiToken}&ckWebAuthToken=${encodeURIComponent(ckWebAuthToken)}`;

    const res = await fetch(url, {
      method: ckMethod || "POST",
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });

    const data = await res.json();
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

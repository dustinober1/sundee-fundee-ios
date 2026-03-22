import { NextResponse } from "next/server";

export async function GET() {
  const containerId = process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "";
  const apiToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN ?? "";
  const env = process.env.NEXT_PUBLIC_CLOUDKIT_ENV ?? "production";

  const url = `https://api.apple-cloudkit.com/database/1/${containerId}/${env}/public/users/caller?ckAPIToken=${apiToken}`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    return NextResponse.json(data);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 502 });
  }
}

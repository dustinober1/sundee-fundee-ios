import { NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { getUserProfile } from "@/app/(features)/settings/actions";

export async function GET() {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const profile = await getUserProfile();
  return NextResponse.json(profile ?? {});
}

import { NextRequest, NextResponse } from "next/server";
import { readJSONFile, writeJSONFile } from "@/lib/file-io";
import { WODS_JSON_PATH } from "@/lib/paths";

export async function GET() {
  try {
    const wods = await readJSONFile(WODS_JSON_PATH, []);
    return NextResponse.json(wods);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const wods = await req.json();
    await writeJSONFile(WODS_JSON_PATH, wods);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const wod = await req.json();
    const wods = await readJSONFile<any[]>(WODS_JSON_PATH, []);
    const index = wods.findIndex((w) => w.id === wod.id);
    if (index >= 0) { wods[index] = wod; } else { wods.push(wod); }
    await writeJSONFile(WODS_JSON_PATH, wods);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
    const wods = await readJSONFile<any[]>(WODS_JSON_PATH, []);
    const filtered = wods.filter((w) => w.id !== id);
    await writeJSONFile(WODS_JSON_PATH, filtered);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

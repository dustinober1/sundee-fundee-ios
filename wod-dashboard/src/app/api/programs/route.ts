import { NextRequest, NextResponse } from "next/server";
import { readJSONFile, writeJSONFile } from "@/lib/file-io";
import { PROGRAMS_JSON_PATH } from "@/lib/paths";

export async function GET() {
  try {
    const programs = await readJSONFile(PROGRAMS_JSON_PATH, []);
    return NextResponse.json(programs);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const programs = await req.json();
    await writeJSONFile(PROGRAMS_JSON_PATH, programs);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const program = await req.json();
    const programs = await readJSONFile<any[]>(PROGRAMS_JSON_PATH, []);
    const index = programs.findIndex((p) => p.id === program.id);
    if (index >= 0) { programs[index] = program; } else { programs.push(program); }
    await writeJSONFile(PROGRAMS_JSON_PATH, programs);
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
    const programs = await readJSONFile<any[]>(PROGRAMS_JSON_PATH, []);
    const filtered = programs.filter((p) => p.id !== id);
    await writeJSONFile(PROGRAMS_JSON_PATH, filtered);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

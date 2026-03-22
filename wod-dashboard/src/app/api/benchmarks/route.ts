import { NextRequest, NextResponse } from "next/server";
import { readJSONFile, writeJSONFile } from "@/lib/file-io";
import { BENCHMARKS_JSON_PATH } from "@/lib/paths";

export async function GET() {
  try {
    const benchmarks = await readJSONFile(BENCHMARKS_JSON_PATH, []);
    return NextResponse.json(benchmarks);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const benchmark = await req.json();
    const benchmarks = await readJSONFile<any[]>(BENCHMARKS_JSON_PATH, []);
    const index = benchmarks.findIndex((b) => b.id === benchmark.id);
    if (index >= 0) { benchmarks[index] = benchmark; } else { benchmarks.push(benchmark); }
    await writeJSONFile(BENCHMARKS_JSON_PATH, benchmarks);
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
    const benchmarks = await readJSONFile<any[]>(BENCHMARKS_JSON_PATH, []);
    const filtered = benchmarks.filter((b) => b.id !== id);
    await writeJSONFile(BENCHMARKS_JSON_PATH, filtered);
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

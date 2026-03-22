import { NextRequest, NextResponse } from "next/server";
import { readJSONFile, writeJSONFile } from "@/lib/file-io";
import { PUBLISH_STATUS_PATH } from "@/lib/paths";

interface PublishStatus {
  wods: Record<string, { publishedAt: string }>;
  programs: Record<string, { publishedAt: string }>;
  benchmarks: Record<string, { publishedAt: string }>;
}

const EMPTY_STATUS: PublishStatus = { wods: {}, programs: {}, benchmarks: {} };

async function readStatus(): Promise<PublishStatus> {
  return readJSONFile<PublishStatus>(PUBLISH_STATUS_PATH, EMPTY_STATUS);
}

export async function GET() {
  try {
    const status = await readStatus();
    return NextResponse.json(status);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const { type, id } = await req.json();
    if (!type || !id) {
      return NextResponse.json(
        { error: "type and id are required" },
        { status: 400 }
      );
    }
    if (type !== "wod" && type !== "program" && type !== "benchmark") {
      return NextResponse.json(
        { error: "type must be 'wod', 'program', or 'benchmark'" },
        { status: 400 }
      );
    }

    const status = await readStatus();
    const bucket = type === "wod" ? status.wods : type === "program" ? status.programs : status.benchmarks;
    bucket[id] = { publishedAt: new Date().toISOString() };
    await writeJSONFile(PUBLISH_STATUS_PATH, status);

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get("type");
    const id = searchParams.get("id");

    if (!type || !id) {
      return NextResponse.json(
        { error: "type and id query params are required" },
        { status: 400 }
      );
    }
    if (type !== "wod" && type !== "program" && type !== "benchmark") {
      return NextResponse.json(
        { error: "type must be 'wod', 'program', or 'benchmark'" },
        { status: 400 }
      );
    }

    const status = await readStatus();
    const bucket = type === "wod" ? status.wods : type === "program" ? status.programs : status.benchmarks;
    delete bucket[id];
    await writeJSONFile(PUBLISH_STATUS_PATH, status);

    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

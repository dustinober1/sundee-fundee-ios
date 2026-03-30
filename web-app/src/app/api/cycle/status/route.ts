import { NextResponse } from "next/server";
import { getCycleStatus } from "@/app/(features)/cycle/actions";

export async function GET() {
  const status = await getCycleStatus();
  if (!status) {
    return NextResponse.json(null);
  }
  return NextResponse.json({
    currentPhase: status.currentPhase,
    cycleDay: status.cycleDay,
    daysUntilNextPhase: status.daysUntilNextPhase,
  });
}

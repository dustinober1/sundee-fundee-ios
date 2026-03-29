"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { benchmarkResults, benchmarkDefinitions } from "@/db/schema";
import { eq, desc } from "drizzle-orm";
import { PREDEFINED_BENCHMARKS } from "@/lib/domain";

export async function getBenchmarkResults() {
  const session = await auth();
  if (!session?.user?.id) return [];
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.select().from(benchmarkResults)
    .where(eq(benchmarkResults.userId, session.user.id))
    .orderBy(desc(benchmarkResults.performedAt));
}

export async function logBenchmarkResult(data: { definitionId: string; scoreValue: number; notes?: string }) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  const env = await getBindings();
  const db = createDb(env.DB);

  // Ensure predefined benchmark definition exists in DB before inserting result
  const predefined = PREDEFINED_BENCHMARKS.find((b) => b.id === data.definitionId);
  if (predefined) {
    await db.insert(benchmarkDefinitions).values({
      id: predefined.id,
      userId: "",
      name: predefined.name,
      category: predefined.category,
      workoutDescription: predefined.workoutDescription,
      scoringType: predefined.scoringType,
      isPredefined: true,
      sortOrder: predefined.sortOrder,
    }).onConflictDoNothing();
  }

  await db.insert(benchmarkResults).values({
    id: crypto.randomUUID(),
    userId: session.user.id,
    definitionId: data.definitionId,
    scoreValue: data.scoreValue,
    notes: data.notes ?? "",
    performedAt: new Date(),
  });
}

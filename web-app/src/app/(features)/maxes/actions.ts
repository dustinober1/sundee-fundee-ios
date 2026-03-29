"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { oneRepMaxes } from "@/db/schema";
import { eq, desc } from "drizzle-orm";

export async function getMaxes() {
  const session = await auth();
  if (!session?.user?.id) return [];
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.select().from(oneRepMaxes)
    .where(eq(oneRepMaxes.userId, session.user.id))
    .orderBy(desc(oneRepMaxes.date));
}

export async function addMax(data: { exerciseId: string; weightKg: number; isEstimated: boolean }) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  const env = await getBindings();
  const db = createDb(env.DB);

  await db.insert(oneRepMaxes).values({
    id: crypto.randomUUID(),
    userId: session.user.id,
    exerciseId: data.exerciseId,
    weightKg: data.weightKg,
    date: new Date(),
    isEstimated: data.isEstimated,
  });
}

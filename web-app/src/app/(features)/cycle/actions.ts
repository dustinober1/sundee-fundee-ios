"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { periodLogs, cycleSettings } from "@/db/schema";
import { eq, desc } from "drizzle-orm";

export async function getPeriodLogs() {
  const session = await auth();
  if (!session?.user?.id) return [];
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.select().from(periodLogs)
    .where(eq(periodLogs.userId, session.user.id))
    .orderBy(desc(periodLogs.startDate));
}

export async function getCycleSettings() {
  const session = await auth();
  if (!session?.user?.id) return null;
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.query.cycleSettings.findFirst({
    where: eq(cycleSettings.userId, session.user.id),
  });
}

export async function logPeriod(startDate: string) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  const env = await getBindings();
  const db = createDb(env.DB);

  await db.insert(periodLogs).values({
    id: crypto.randomUUID(),
    userId: session.user.id,
    startDate: new Date(startDate),
    flowLevel: "medium",
  });
}

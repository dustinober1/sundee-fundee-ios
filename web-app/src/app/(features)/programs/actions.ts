"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { enrolledPrograms } from "@/db/schema";
import { eq } from "drizzle-orm";
import { generateProgram, type ProgramTemplate } from "@/lib/domain";

export async function getEnrolledPrograms() {
  const session = await auth();
  if (!session?.user?.id) return [];
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.select().from(enrolledPrograms)
    .where(eq(enrolledPrograms.userId, session.user.id));
}

export async function enrollInProgram(programId: string) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  const env = await getBindings();
  const db = createDb(env.DB);

  await db.insert(enrolledPrograms).values({
    id: crypto.randomUUID(),
    userId: session.user.id,
    programId,
    startDate: new Date(),
    currentWeek: 1,
    currentDay: 1,
    status: "active",
  });
}

export async function generateProgramAction(template: string, name: string) {
  return generateProgram(template as ProgramTemplate, name);
}

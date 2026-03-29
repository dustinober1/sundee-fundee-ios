"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { completedWorkouts, completedSets } from "@/db/schema";
import { eq, desc } from "drizzle-orm";

export async function getRecentWorkouts() {
  const session = await auth();
  if (!session?.user?.id) return [];

  const env = await getBindings();
  const db = createDb(env.DB);

  return db
    .select()
    .from(completedWorkouts)
    .where(eq(completedWorkouts.userId, session.user.id))
    .orderBy(desc(completedWorkouts.completedAt))
    .limit(20);
}

export async function saveWorkout(data: {
  programId?: string;
  sessionId?: string;
  durationSeconds: number;
  notes?: string;
  perceivedEffort?: number;
  sets: Array<{
    exerciseName: string;
    setIndex: number;
    prescribedReps: string;
    actualReps?: number;
    prescribedWeightKg?: number;
    actualWeightKg?: number;
    isCompleted: boolean;
  }>;
}) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");

  const userId = session.user.id;

  const env = await getBindings();
  const db = createDb(env.DB);

  const workoutId = crypto.randomUUID();

  await db.insert(completedWorkouts).values({
    id: workoutId,
    userId,
    programId: data.programId ?? "",
    sessionId: data.sessionId ?? "",
    completedAt: new Date(),
    durationSeconds: data.durationSeconds,
    notes: data.notes ?? null,
    perceivedEffort: data.perceivedEffort ?? null,
  });

  if (data.sets.length > 0) {
    await db.insert(completedSets).values(
      data.sets.map((s) => ({
        id: crypto.randomUUID(),
        userId,
        workoutId,
        exerciseName: s.exerciseName,
        setIndex: s.setIndex,
        prescribedReps: s.prescribedReps,
        actualReps: s.actualReps ?? null,
        prescribedWeightKg: s.prescribedWeightKg ?? null,
        actualWeightKg: s.actualWeightKg ?? null,
        isCompleted: s.isCompleted,
        completedAt: new Date(),
      }))
    );
  }

  return { id: workoutId };
}

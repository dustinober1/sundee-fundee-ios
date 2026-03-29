"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";

export async function getRecentWorkouts() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "completedWorkouts")
    .orderBy("completedAt", "desc")
    .limit(20)
    .get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
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
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const workoutRef = userCollection(user.uid, "completedWorkouts").doc();

  await workoutRef.set({
    programId: data.programId ?? "",
    sessionId: data.sessionId ?? "",
    completedAt: new Date(),
    durationSeconds: data.durationSeconds,
    notes: data.notes ?? null,
    perceivedEffort: data.perceivedEffort ?? null,
    sets: data.sets.map((s) => ({
      exerciseName: s.exerciseName,
      setIndex: s.setIndex,
      prescribedReps: s.prescribedReps,
      actualReps: s.actualReps ?? null,
      prescribedWeightKg: s.prescribedWeightKg ?? null,
      actualWeightKg: s.actualWeightKg ?? null,
      isCompleted: s.isCompleted,
      completedAt: new Date(),
    })),
  });

  return { id: workoutRef.id };
}

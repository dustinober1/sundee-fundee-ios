"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import {
  optionalFiniteNumber,
  optionalTrimmedString,
  requireFiniteNumber,
  requireTrimmedString,
} from "@/lib/write-validation";

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

  const durationSeconds = requireFiniteNumber(data.durationSeconds, "Duration", {
    integer: true,
    min: 0,
  });
  const perceivedEffort = optionalFiniteNumber(data.perceivedEffort, "Perceived effort", {
    integer: true,
    min: 1,
    max: 10,
  });
  const notes = optionalTrimmedString(data.notes);
  const sets = data.sets.map((s, index) => ({
    exerciseName: requireTrimmedString(s.exerciseName, `Set ${index + 1} exercise name`),
    setIndex: requireFiniteNumber(s.setIndex, `Set ${index + 1} index`, {
      integer: true,
      min: 0,
    }),
    prescribedReps: requireTrimmedString(s.prescribedReps, `Set ${index + 1} reps`),
    actualReps: optionalFiniteNumber(s.actualReps, `Set ${index + 1} actual reps`, {
      integer: true,
      min: 0,
    }),
    prescribedWeightKg: optionalFiniteNumber(
      s.prescribedWeightKg,
      `Set ${index + 1} prescribed weight`,
      { min: 0 }
    ),
    actualWeightKg: optionalFiniteNumber(s.actualWeightKg, `Set ${index + 1} actual weight`, {
      min: 0,
    }),
    isCompleted: s.isCompleted,
  }));

  if (sets.length === 0) {
    throw new Error("At least one set is required.");
  }

  const workoutRef = userCollection(user.uid, "completedWorkouts").doc();

  await workoutRef.set({
    programId: data.programId ?? "",
    sessionId: data.sessionId ?? "",
    completedAt: new Date(),
    durationSeconds,
    notes: notes ?? null,
    perceivedEffort: perceivedEffort ?? null,
    sets: sets.map((s) => ({
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

"use server";

import { getAuthUser, userCollection, db } from "@/lib/firestore";
import { generateProgram, type ProgramTemplate } from "@/lib/domain";
import { requireTrimmedString } from "@/lib/write-validation";
import type { Program } from "@/lib/domain/types";
import { exerciseFromFirestore } from "@/lib/domain/admin-types";

export async function getPublishedPrograms(): Promise<Program[]> {
  const snapshot = await db
    .collection("programs")
    .where("status", "==", "published")
    .get();
  console.log(`[getPublishedPrograms] Found ${snapshot.size} published programs`);
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export async function getProgramById(id: string): Promise<Program | null> {
  const doc = await db.collection("programs").doc(id).get();
  if (!doc.exists) return null;
  const data = doc.data() as any;
  if (!data) return null;

  if (data.weeks) {
    data.weeks = data.weeks.map((week: any) => ({
      ...week,
      sessions: week.sessions.map((session: any) => ({
        ...session,
        exercises: session.exercises.map((ex: any) => exerciseFromFirestore(ex)),
      })),
    }));
  }

  return { id: doc.id, ...data } as Program;
}

export async function getEnrolledPrograms() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "enrolledPrograms").get();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export async function enrollInProgram(programId: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const normalizedProgramId = requireTrimmedString(programId, "Program");

  await userCollection(user.uid, "enrolledPrograms").add({
    programId: normalizedProgramId,
    startDate: new Date(),
    currentWeek: 1,
    currentDay: 1,
    status: "active",
  });
}

export async function unenrollProgram(enrollmentId: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const id = requireTrimmedString(enrollmentId, "Enrollment");
  await userCollection(user.uid, "enrolledPrograms").doc(id).delete();
}

export async function generateProgramAction(template: string, name: string) {
  return generateProgram(template as ProgramTemplate, name);
}

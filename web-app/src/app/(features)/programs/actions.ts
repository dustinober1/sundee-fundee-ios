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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export async function getProgramById(id: string): Promise<Program | null> {
  const doc = await db.collection("programs").doc(id).get();
  if (!doc.exists) return null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const data = doc.data() as any;
  if (!data) return null;

  if (data.weeks) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    data.weeks = data.weeks.map((week: any) => ({
      ...week,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      sessions: (week.sessions ?? []).map((session: any) => ({
        ...session,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        exercises: (Array.isArray(session.exercises) ? session.exercises : []).map((ex: any) => {
          try {
            return exerciseFromFirestore(ex);
          } catch (error) {
            console.error("Error processing exercise:", error);
            return null;
          }
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        }).filter((ex: any) => ex !== null),
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

  // Look up the program template to store the name
  const program = await getProgramById(normalizedProgramId);

  await userCollection(user.uid, "enrolledPrograms").add({
    programId: normalizedProgramId,
    programName: program?.name ?? normalizedProgramId,
    startDate: new Date(),
    currentWeek: 1,
    currentDay: 1,
    status: "active",
  });
}

/** Resolve the current session's exercises for an enrolled program. */
export async function getSessionForEnrollment(enrollmentId: string) {
  const user = await getAuthUser();
  if (!user) return null;

  const id = requireTrimmedString(enrollmentId, "Enrollment");
  const enrollDoc = await userCollection(user.uid, "enrolledPrograms").doc(id).get();
  if (!enrollDoc.exists) return null;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const enrollment = enrollDoc.data() as any;
  const program = await getProgramById(enrollment.programId);
  if (!program?.weeks?.length) return null;

  const weekIndex = (enrollment.currentWeek ?? 1) - 1;
  const dayIndex = (enrollment.currentDay ?? 1) - 1;

  const week = program.weeks[weekIndex];
  if (!week) return null;

  const session = week.sessions?.[dayIndex];
  if (!session) return null;

  const exercises = Array.isArray(session.exercises) ? session.exercises : [];

  return {
    programId: enrollment.programId,
    programName: program.name,
    enrollmentId: enrollDoc.id,
    sessionId: session.sessionId,
    sessionName: session.sessionName,
    exercises,
  };
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

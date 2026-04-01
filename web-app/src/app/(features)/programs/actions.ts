"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { generateProgram, type ProgramTemplate } from "@/lib/domain";
import { requireTrimmedString } from "@/lib/write-validation";

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

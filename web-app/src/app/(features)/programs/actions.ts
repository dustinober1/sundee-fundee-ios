"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { generateProgram, type ProgramTemplate } from "@/lib/domain";

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

  await userCollection(user.uid, "enrolledPrograms").add({
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

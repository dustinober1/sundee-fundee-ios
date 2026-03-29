"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";

export async function getPeriodLogs() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "periodLogs")
    .orderBy("startDate", "desc")
    .get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export async function getCycleSettings() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "cycleSettings").doc("default").get();
  return doc.exists ? doc.data() : null;
}

export async function logPeriod(startDate: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "periodLogs").add({
    startDate: new Date(startDate),
    flowLevel: "medium",
  });
}

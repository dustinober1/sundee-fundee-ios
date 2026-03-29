"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";

export async function getMaxes() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "oneRepMaxes")
    .orderBy("date", "desc")
    .get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
}

export async function addMax(data: { exerciseId: string; weightKg: number; isEstimated: boolean }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "oneRepMaxes").add({
    exerciseId: data.exerciseId,
    weightKg: data.weightKg,
    date: new Date(),
    isEstimated: data.isEstimated,
  });
}

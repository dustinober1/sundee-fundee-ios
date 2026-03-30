"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { requireFiniteNumber, requireTrimmedString } from "@/lib/write-validation";

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

  const exerciseId = requireTrimmedString(data.exerciseId, "Exercise");
  const weightKg = requireFiniteNumber(data.weightKg, "Weight", { min: 0.1 });

  await userCollection(user.uid, "oneRepMaxes").add({
    exerciseId,
    weightKg,
    date: new Date(),
    isEstimated: data.isEstimated,
  });
}

export async function deleteMax(maxId: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const id = requireTrimmedString(maxId, "Max");
  await userCollection(user.uid, "oneRepMaxes").doc(id).delete();
}

"use server";

import { getAuthUser, userDoc, userCollection } from "@/lib/firestore";
import { optionalTrimmedString } from "@/lib/write-validation";

export async function getUserProfile() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userDoc(user.uid).get();
  if (!doc.exists) return null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return { id: doc.id, ...(doc.data() as any) };
}

export async function updateProfile(data: { name?: string; weightUnit?: string; experienceLevel?: string; primaryGoal?: string }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const updateData: Record<string, unknown> = { profileUpdatedAt: new Date() };
  const name = optionalTrimmedString(data.name);
  const weightUnit = optionalTrimmedString(data.weightUnit);
  const experienceLevel = optionalTrimmedString(data.experienceLevel);
  const primaryGoal = optionalTrimmedString(data.primaryGoal);

  if (name != null) updateData.name = name;
  if (weightUnit != null) updateData.weightUnit = weightUnit;
  if (experienceLevel != null) updateData.experienceLevel = experienceLevel;
  if (primaryGoal != null) updateData.primaryGoal = primaryGoal;

  await userDoc(user.uid).set(updateData, { merge: true });
}

export async function getSubscription() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "subscription").doc("current").get();
  return doc.exists ? doc.data() : null;
}

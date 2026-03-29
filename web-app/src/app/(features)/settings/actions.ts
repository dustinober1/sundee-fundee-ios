"use server";

import { auth } from "@/lib/auth";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { users, subscriptions } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function getUserProfile() {
  const session = await auth();
  if (!session?.user?.id) return null;
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.query.users.findFirst({ where: eq(users.id, session.user.id) });
}

export async function updateProfile(data: { name?: string; weightUnit?: string; experienceLevel?: string; primaryGoal?: string }) {
  const session = await auth();
  if (!session?.user?.id) throw new Error("Unauthorized");
  const env = await getBindings();
  const db = createDb(env.DB);
  await db.update(users).set({
    ...(data.name != null && { name: data.name }),
    ...(data.weightUnit != null && { weightUnit: data.weightUnit }),
    ...(data.experienceLevel != null && { experienceLevel: data.experienceLevel }),
    ...(data.primaryGoal != null && { primaryGoal: data.primaryGoal }),
    profileUpdatedAt: new Date(),
  }).where(eq(users.id, session.user.id));
}

export async function getSubscription() {
  const session = await auth();
  if (!session?.user?.id) return null;
  const env = await getBindings();
  const db = createDb(env.DB);
  return db.query.subscriptions.findFirst({ where: eq(subscriptions.userId, session.user.id) });
}

// web-app/src/lib/admin-auth.ts
import { getAuthUser, type AuthUser } from "./firestore";
import { db } from "./firebase-admin";

export async function requireAdmin(): Promise<AuthUser> {
  const user = await getAuthUser();
  if (!user) {
    throw new Error("UNAUTHORIZED");
  }
  const adminDoc = await db.collection("admins").doc(user.uid).get();
  if (!adminDoc.exists) {
    throw new Error("FORBIDDEN");
  }
  return user;
}

export async function isAdmin(uid: string): Promise<boolean> {
  const adminDoc = await db.collection("admins").doc(uid).get();
  return adminDoc.exists;
}

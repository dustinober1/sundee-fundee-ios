import { cookies } from "next/headers";
import { adminAuth, db } from "./firebase-admin";

export interface AuthUser {
  uid: string;
  email: string | undefined;
  name: string | undefined;
}

export async function getAuthUser(): Promise<AuthUser | null> {
  const cookieStore = await cookies();
  const sessionCookie = cookieStore.get("__session")?.value;
  if (!sessionCookie) return null;

  try {
    const decoded = await adminAuth.verifySessionCookie(sessionCookie, true);
    return {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name,
    };
  } catch {
    return null;
  }
}

export function userCollection(uid: string, collection: string) {
  return db.collection("users").doc(uid).collection(collection);
}

export function userDoc(uid: string) {
  return db.collection("users").doc(uid);
}

export { db };

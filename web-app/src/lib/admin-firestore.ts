// web-app/src/lib/admin-firestore.ts
import { db } from "./firebase-admin";

export function adminCollection(name: string) {
  return db.collection(name);
}

export function adminDoc(name: string, id: string) {
  return db.collection(name).doc(id);
}

export async function allUsers(options?: {
  limit?: number;
  orderBy?: string;
  direction?: "asc" | "desc";
  startAfter?: string;
}) {
  let query = db.collection("users").orderBy(
    options?.orderBy ?? "email",
    options?.direction ?? "asc"
  );
  if (options?.startAfter) {
    const cursor = await db.collection("users").doc(options.startAfter).get();
    if (cursor.exists) {
      query = query.startAfter(cursor);
    }
  }
  if (options?.limit) {
    query = query.limit(options.limit);
  }
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
}

export async function userById(uid: string) {
  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists) return null;
  return { uid: doc.id, ...doc.data() };
}

export async function userSubcollection(uid: string, name: string) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection(name)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

import { doc, getDoc, getDocs, collection, query, orderBy, limit as firestoreLimit } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { WODRepository, WODRecord } from './WODRepo';

export class FirestoreWODRepo implements WODRepository {
  async getWODForDate(date: string): Promise<WODRecord | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'wods', date));
    return snap.exists() ? (snap.data() as WODRecord) : null;
  }

  async getRecentWODs(limit = 30): Promise<WODRecord[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'wods'),
      orderBy('date', 'desc'),
      firestoreLimit(limit),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as WODRecord);
  }
}

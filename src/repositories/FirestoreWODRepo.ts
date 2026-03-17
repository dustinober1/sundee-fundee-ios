/**
 * FirestoreWODRepo — Firestore implementation of WODRepository.
 *
 * Reads WOD records from /wods/{yyyy-MM-dd}.
 * WODs are admin-seeded public data — read-only for app clients.
 * Uses date string as document ID for O(1) point lookups.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { WODRepository, WODRecord } from './WODRepo';

export class FirestoreWODRepo implements WODRepository {
  /**
   * Retrieves the WOD for a specific date.
   * @param date - ISO date string 'yyyy-MM-dd'
   * Returns null if no WOD exists for that date.
   */
  async getWODForDate(date: string): Promise<WODRecord | null> {
    const db = getFirestoreInstance();
    const doc = await db
      .collection('wods')
      .doc(date)
      .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as WODRecord;
  }

  /**
   * Retrieves recent WODs ordered by date descending.
   * @param limit - Maximum number of records to return (default 30)
   */
  async getRecentWODs(limit = 30): Promise<WODRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('wods')
      .orderBy('date', 'desc')
      .limit(limit)
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => WODRecord }) => doc.data() as WODRecord
    );
  }
}

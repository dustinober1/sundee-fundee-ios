/**
 * FirestoreReadinessRepo — Firestore implementation of ReadinessRepository.
 *
 * Writes readiness survey records to /users/{uid}/readiness/{date} subcollection.
 * Uses the date string as the document ID for O(1) point lookups.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { ReadinessSurveyRecord, ReadinessRepository } from './ReadinessRepo';

export class FirestoreReadinessRepo implements ReadinessRepository {
  /**
   * Saves a readiness survey to /users/{uid}/readiness/{date}.
   * Date string is used as the document ID for efficient date-based lookups.
   */
  async saveSurvey(uid: string, record: ReadinessSurveyRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('readiness')
      .doc(record.date)
      .set(record);
  }

  /**
   * Retrieves a single survey by date.
   * Returns null if no survey exists for that date.
   */
  async getSurveyForDate(uid: string, date: string): Promise<ReadinessSurveyRecord | null> {
    const db = getFirestoreInstance();
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('readiness')
      .doc(date)
      .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as ReadinessSurveyRecord;
  }

  /**
   * Retrieves recent readiness surveys ordered by date descending.
   * @param limit - Maximum number of records to return (default 30)
   */
  async getRecentSurveys(uid: string, limit = 30): Promise<ReadinessSurveyRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('readiness')
      .orderBy('date', 'desc')
      .limit(limit)
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => ReadinessSurveyRecord }) => doc.data() as ReadinessSurveyRecord
    );
  }
}

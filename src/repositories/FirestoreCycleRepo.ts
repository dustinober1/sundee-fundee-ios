/**
 * FirestoreCycleRepo — Firestore implementation of CycleRepository.
 *
 * Writes period logs to /users/{uid}/periodLogs/{logId}.
 * Writes cycle settings to /users/{uid}/cycleSettings/settings (single doc per user).
 * Dates stored as ISO strings for consistency with ReadinessRepo pattern.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { CycleSettings } from '../domain/types/index';
import type { CycleRepository, PeriodLogRecord } from './CycleRepo';

export class FirestoreCycleRepo implements CycleRepository {
  /**
   * Saves a period log to /users/{uid}/periodLogs/{logId}.
   * Uses the log's id as the document ID for upsert behavior.
   */
  async savePeriodLog(uid: string, record: PeriodLogRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('periodLogs')
      .doc(record.id)
      .set(record);
  }

  /**
   * Retrieves all period logs for a user, ordered by startDate descending.
   */
  async getPeriodLogs(uid: string): Promise<PeriodLogRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('periodLogs')
      .orderBy('startDate', 'desc')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => PeriodLogRecord }) => doc.data() as PeriodLogRecord
    );
  }

  /**
   * Deletes a period log by its document ID.
   */
  async deletePeriodLog(uid: string, logId: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('periodLogs')
      .doc(logId)
      .delete();
  }

  /**
   * Saves cycle settings to /users/{uid}/cycleSettings/settings.
   * Single document per user — always overwrites.
   */
  async saveCycleSettings(uid: string, settings: CycleSettings): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('cycleSettings')
      .doc('settings')
      .set(settings);
  }

  /**
   * Retrieves cycle settings for a user.
   * Returns null if no settings exist.
   */
  async getCycleSettings(uid: string): Promise<CycleSettings | null> {
    const db = getFirestoreInstance();
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('cycleSettings')
      .doc('settings')
      .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as CycleSettings;
  }
}

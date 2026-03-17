/**
 * FirestoreInjuryRepo — Firestore implementation of InjuryRepository.
 *
 * Writes injury profiles to /users/{uid}/injuries/{injuryId}.
 * Writes pain logs to /users/{uid}/injuries/{injuryId}/painLogs/{logId}.
 * Dates stored as ISO strings for consistency with ReadinessRepo pattern.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { InjuryRepository, InjuryProfileRecord, PainLogRecord } from './InjuryRepo';

export class FirestoreInjuryRepo implements InjuryRepository {
  /**
   * Saves (upserts) an injury profile to /users/{uid}/injuries/{injuryId}.
   */
  async saveInjury(uid: string, injury: InjuryProfileRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('injuries')
      .doc(injury.id)
      .set(injury);
  }

  /**
   * Retrieves all injury profiles for a user.
   */
  async getInjuries(uid: string): Promise<InjuryProfileRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('injuries')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => InjuryProfileRecord }) => doc.data() as InjuryProfileRecord
    );
  }

  /**
   * Deletes an injury profile by its document ID.
   */
  async deleteInjury(uid: string, injuryId: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('injuries')
      .doc(injuryId)
      .delete();
  }

  /**
   * Saves a pain log to /users/{uid}/injuries/{injuryId}/painLogs/{logId}.
   */
  async savePainLog(uid: string, log: PainLogRecord): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('injuries')
      .doc(log.injuryId)
      .collection('painLogs')
      .doc(log.id)
      .set(log);
  }

  /**
   * Retrieves all pain logs for a given injury, ordered by date descending.
   */
  async getPainLogs(uid: string, injuryId: string): Promise<PainLogRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('injuries')
      .doc(injuryId)
      .collection('painLogs')
      .orderBy('date', 'desc')
      .get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map(
      (doc: { data: () => PainLogRecord }) => doc.data() as PainLogRecord
    );
  }
}

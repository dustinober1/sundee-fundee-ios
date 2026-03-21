import { doc, setDoc, getDoc, getDocs, deleteDoc, collection } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { CycleSettings } from '../domain/types/index';
import type { PeriodLogRecord, CycleRepository } from './CycleRepo';

export class FirestoreCycleRepo implements CycleRepository {
  async savePeriodLog(uid: string, record: PeriodLogRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'periodLogs', record.id), record);
  }

  async getPeriodLogs(uid: string): Promise<PeriodLogRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'periodLogs'));
    return snapshot.docs.map((d) => d.data() as PeriodLogRecord);
  }

  async deletePeriodLog(uid: string, logId: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'periodLogs', logId));
  }

  async saveCycleSettings(uid: string, settings: CycleSettings): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'cycleSettings', 'settings'), settings);
  }

  async getCycleSettings(uid: string): Promise<CycleSettings | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid, 'cycleSettings', 'settings'));
    return snap.exists() ? (snap.data() as CycleSettings) : null;
  }
}

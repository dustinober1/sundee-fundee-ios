import { doc, setDoc, getDocs, deleteDoc, collection, query, orderBy } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { InjuryRepository, InjuryProfileRecord, PainLogRecord } from './InjuryRepo';

export class FirestoreInjuryRepo implements InjuryRepository {
  async saveInjury(uid: string, injury: InjuryProfileRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'injuries', injury.id), injury);
  }

  async getInjuries(uid: string): Promise<InjuryProfileRecord[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'users', uid, 'injuries'));
    return snapshot.docs.map((d) => d.data() as InjuryProfileRecord);
  }

  async deleteInjury(uid: string, injuryId: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'injuries', injuryId));
  }

  async savePainLog(uid: string, log: PainLogRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'injuries', log.injuryId, 'painLogs', log.id), log);
  }

  async getPainLogs(uid: string, injuryId: string): Promise<PainLogRecord[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'injuries', injuryId, 'painLogs'),
      orderBy('date', 'desc'),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as PainLogRecord);
  }
}

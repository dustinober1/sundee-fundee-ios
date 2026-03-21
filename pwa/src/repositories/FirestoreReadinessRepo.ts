import { doc, setDoc, getDoc, getDocs, collection, query, orderBy, limit as firestoreLimit } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { ReadinessSurveyRecord, ReadinessRepository } from './ReadinessRepo';

export class FirestoreReadinessRepo implements ReadinessRepository {
  async saveSurvey(uid: string, record: ReadinessSurveyRecord): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'readiness', record.id), record);
  }

  async getSurveyForDate(uid: string, date: string): Promise<ReadinessSurveyRecord | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid, 'readiness', date));
    return snap.exists() ? (snap.data() as ReadinessSurveyRecord) : null;
  }

  async getRecentSurveys(uid: string, limit = 7): Promise<ReadinessSurveyRecord[]> {
    const db = getFirestoreInstance();
    const q = query(
      collection(db, 'users', uid, 'readiness'),
      orderBy('date', 'desc'),
      firestoreLimit(limit),
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => d.data() as ReadinessSurveyRecord);
  }
}

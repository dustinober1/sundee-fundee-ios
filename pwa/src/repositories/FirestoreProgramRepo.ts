import { doc, setDoc, getDoc, getDocs, deleteDoc, collection } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { Program } from '../domain/types/index';
import type { ProgramRepository, ProgramEnrollment, FirestoreProgramDocument } from './ProgramRepo';
import { firestoreProgramToProgram } from './ProgramRepo';

export class FirestoreProgramRepo implements ProgramRepository {
  async getPrograms(): Promise<Program[]> {
    const db = getFirestoreInstance();
    const snapshot = await getDocs(collection(db, 'programs'));
    return snapshot.docs.map((d) => firestoreProgramToProgram(d.data() as FirestoreProgramDocument));
  }

  async getProgram(programId: string): Promise<Program | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'programs', programId));
    return snap.exists() ? firestoreProgramToProgram(snap.data() as FirestoreProgramDocument) : null;
  }

  async enrollUser(uid: string, programId: string): Promise<void> {
    const db = getFirestoreInstance();
    const enrollment: ProgramEnrollment = {
      programId,
      startDate: new Date().toISOString().split('T')[0],
      currentWeek: 0,
      currentSession: 0,
    };
    await setDoc(doc(db, 'users', uid, 'enrollment', 'active'), enrollment);
  }

  async getEnrollment(uid: string): Promise<ProgramEnrollment | null> {
    const db = getFirestoreInstance();
    const snap = await getDoc(doc(db, 'users', uid, 'enrollment', 'active'));
    return snap.exists() ? (snap.data() as ProgramEnrollment) : null;
  }

  async updateEnrollmentProgress(uid: string, weekIndex: number, sessionIndex: number): Promise<void> {
    const db = getFirestoreInstance();
    await setDoc(doc(db, 'users', uid, 'enrollment', 'active'), { currentWeek: weekIndex, currentSession: sessionIndex }, { merge: true });
  }

  async unenroll(uid: string): Promise<void> {
    const db = getFirestoreInstance();
    await deleteDoc(doc(db, 'users', uid, 'enrollment', 'active'));
  }
}

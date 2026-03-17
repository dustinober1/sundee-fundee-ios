/**
 * FirestoreProgramRepo — Firestore implementation of ProgramRepository.
 *
 * Programs are stored at /programs/{programId} as admin-seeded public data.
 * Enrollment is stored at /users/{uid}/enrollment/active (single doc per user).
 * Program documents use a denormalized weeks[] schema; this repo maps to domain Program.
 */
import { getFirestoreInstance } from '../firebase/firestore';
import type { Program } from '../domain/types/index';
import type {
  ProgramRepository,
  ProgramEnrollment,
  FirestoreProgramDocument,
} from './ProgramRepo';
import { firestoreProgramToProgram } from './ProgramRepo';

export class FirestoreProgramRepo implements ProgramRepository {
  /**
   * Retrieves all programs from the /programs collection.
   * Programs are public admin-seeded data — no uid needed.
   */
  async getPrograms(): Promise<Program[]> {
    const db = getFirestoreInstance();
    const snapshot = await db.collection('programs').get();
    if (snapshot.empty) {
      return [];
    }
    return snapshot.docs.map((doc: { data: () => FirestoreProgramDocument }) =>
      firestoreProgramToProgram(doc.data())
    );
  }

  /**
   * Retrieves a single program by ID.
   * Returns null if the program does not exist.
   */
  async getProgram(programId: string): Promise<Program | null> {
    const db = getFirestoreInstance();
    const doc = await db.collection('programs').doc(programId).get();
    if (!doc.exists) {
      return null;
    }
    return firestoreProgramToProgram(doc.data() as FirestoreProgramDocument);
  }

  /**
   * Enrolls a user in a program by creating an enrollment document.
   * Stored at /users/{uid}/enrollment/active — overwrites any existing enrollment.
   */
  async enrollUser(uid: string, programId: string): Promise<void> {
    const db = getFirestoreInstance();
    const enrollment: ProgramEnrollment = {
      programId,
      startDate: new Date().toISOString().split('T')[0],
      currentWeek: 0,
      currentSession: 0,
    };
    await db
      .collection('users')
      .doc(uid)
      .collection('enrollment')
      .doc('active')
      .set(enrollment);
  }

  /**
   * Retrieves the active program enrollment for a user.
   * Returns null if the user is not enrolled in any program.
   */
  async getEnrollment(uid: string): Promise<ProgramEnrollment | null> {
    const db = getFirestoreInstance();
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('enrollment')
      .doc('active')
      .get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() as ProgramEnrollment;
  }

  /**
   * Updates the user's current week and session progress within an enrollment.
   */
  async updateEnrollmentProgress(
    uid: string,
    weekIndex: number,
    sessionIndex: number
  ): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('enrollment')
      .doc('active')
      .set({ currentWeek: weekIndex, currentSession: sessionIndex }, { merge: true });
  }

  /**
   * Removes the user's active enrollment.
   */
  async unenroll(uid: string): Promise<void> {
    const db = getFirestoreInstance();
    await db
      .collection('users')
      .doc(uid)
      .collection('enrollment')
      .doc('active')
      .delete();
  }
}

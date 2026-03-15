/**
 * ProgramRepository interface and factory function.
 *
 * Defines the contract for strength training program access and enrollment.
 * Programs are admin-seeded public data; enrollment is per-user.
 *
 * Implementations:
 *   - FirestoreProgramRepo: authenticated users (/programs, /users/{uid}/enrollment)
 *   - LocalProgramRepo: guest users (bundled JSON + AsyncStorage enrollment)
 */
import type { Program, ProgramSession, ProgramExercise, WorkoutFocus } from '../domain/types/index';
import { FirestoreProgramRepo } from './FirestoreProgramRepo';
import { LocalProgramRepo } from './LocalProgramRepo';

export type { Program, ProgramSession, ProgramExercise };

/**
 * A week grouping of sessions within a program.
 * Used in the Firestore schema to denormalize program structure.
 * The repo maps this to domain Program.sessions for callers.
 */
export interface ProgramWeek {
  id: string;
  name: string;
  sessions: ProgramSession[];
}

/**
 * Firestore schema for a program document.
 * Extends domain Program with a weeks array.
 */
export interface FirestoreProgramDocument {
  id: string;
  name: string;
  weeks: ProgramWeek[];
  startDate?: string;
  endDate?: string;
}

/**
 * Active program enrollment record for a user.
 * Stored at /users/{uid}/enrollment/active or in AsyncStorage.
 */
export interface ProgramEnrollment {
  programId: string;
  /** ISO date string 'yyyy-MM-dd' for when enrollment started */
  startDate: string;
  currentWeek: number;
  currentSession: number;
}

export interface ProgramRepository {
  getPrograms(): Promise<Program[]>;
  getProgram(programId: string): Promise<Program | null>;
  enrollUser(uid: string, programId: string): Promise<void>;
  getEnrollment(uid: string): Promise<ProgramEnrollment | null>;
  updateEnrollmentProgress(uid: string, weekIndex: number, sessionIndex: number): Promise<void>;
  unenroll(uid: string): Promise<void>;
}

/**
 * Returns the appropriate ProgramRepository based on auth state.
 * Guest users use local bundled JSON + AsyncStorage; authenticated users use Firestore.
 */
export function getProgramRepo(isGuest: boolean): ProgramRepository {
  return isGuest
    ? new LocalProgramRepo()
    : new FirestoreProgramRepo();
}

/**
 * Map a FirestoreProgramDocument to a flat domain Program.
 * Flattens weeks.sessions into program.sessions for domain layer compatibility.
 */
export function firestoreProgramToProgram(doc: FirestoreProgramDocument): Program {
  const sessions: ProgramSession[] = doc.weeks.flatMap((week) => week.sessions);
  return {
    id: doc.id,
    name: doc.name,
    sessions,
    startDate: doc.startDate,
    endDate: doc.endDate,
  };
}

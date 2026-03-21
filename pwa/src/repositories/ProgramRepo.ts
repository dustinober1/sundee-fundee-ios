import type { Program, ProgramSession, ProgramExercise } from '../domain/types/index';
import { FirestoreProgramRepo } from './FirestoreProgramRepo';
import { LocalProgramRepo } from './LocalProgramRepo';

export type { Program, ProgramSession, ProgramExercise };

export interface ProgramWeek {
  id: string;
  name: string;
  sessions: ProgramSession[];
}

export interface FirestoreProgramDocument {
  id: string;
  name: string;
  weeks: ProgramWeek[];
  startDate?: string;
  endDate?: string;
}

export interface ProgramEnrollment {
  programId: string;
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

export function getProgramRepo(isGuest: boolean): ProgramRepository {
  return isGuest ? new LocalProgramRepo() : new FirestoreProgramRepo();
}

export function firestoreProgramToProgram(d: FirestoreProgramDocument): Program {
  const sessions: ProgramSession[] = d.weeks.flatMap((week) => week.sessions);
  return { id: d.id, name: d.name, sessions, startDate: d.startDate, endDate: d.endDate };
}

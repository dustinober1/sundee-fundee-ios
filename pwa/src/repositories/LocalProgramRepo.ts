import type { Program } from '../domain/types/index';
import type { ProgramRepository, ProgramEnrollment } from './ProgramRepo';
import { firestoreProgramToProgram } from './ProgramRepo';
import programsJson from '../resources/programs.json';

const ENROLLMENT_KEY = '@sundee/program_enrollment';

export class LocalProgramRepo implements ProgramRepository {
  async getPrograms(): Promise<Program[]> {
    return (programsJson as { id: string; name: string; weeks: { id: string; name: string; sessions: unknown[] }[] }[])
      .map((p) => firestoreProgramToProgram(p as Parameters<typeof firestoreProgramToProgram>[0]));
  }

  async getProgram(programId: string): Promise<Program | null> {
    const programs = await this.getPrograms();
    return programs.find((p) => p.id === programId) ?? null;
  }

  async enrollUser(_uid: string, programId: string): Promise<void> {
    const enrollment: ProgramEnrollment = {
      programId,
      startDate: new Date().toISOString().split('T')[0],
      currentWeek: 0,
      currentSession: 0,
    };
    localStorage.setItem(ENROLLMENT_KEY, JSON.stringify(enrollment));
  }

  async getEnrollment(_uid: string): Promise<ProgramEnrollment | null> {
    const raw = localStorage.getItem(ENROLLMENT_KEY);
    return raw ? (JSON.parse(raw) as ProgramEnrollment) : null;
  }

  async updateEnrollmentProgress(_uid: string, weekIndex: number, sessionIndex: number): Promise<void> {
    const raw = localStorage.getItem(ENROLLMENT_KEY);
    if (!raw) return;
    const enrollment = JSON.parse(raw) as ProgramEnrollment;
    enrollment.currentWeek = weekIndex;
    enrollment.currentSession = sessionIndex;
    localStorage.setItem(ENROLLMENT_KEY, JSON.stringify(enrollment));
  }

  async unenroll(_uid: string): Promise<void> {
    localStorage.removeItem(ENROLLMENT_KEY);
  }
}

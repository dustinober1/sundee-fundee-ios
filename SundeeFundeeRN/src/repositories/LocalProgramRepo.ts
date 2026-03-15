/**
 * LocalProgramRepo — AsyncStorage + bundled JSON implementation of ProgramRepository.
 *
 * Programs are served from the bundled programs.json file (no network dependency).
 * Enrollment state is stored in AsyncStorage under '@sundee/program_enrollment'.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Program } from '../domain/types/index';
import type { ProgramRepository, ProgramEnrollment, FirestoreProgramDocument } from './ProgramRepo';
import { firestoreProgramToProgram } from './ProgramRepo';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const bundledPrograms: FirestoreProgramDocument[] = require('../resources/programs.json') as FirestoreProgramDocument[];

const ENROLLMENT_KEY = '@sundee/program_enrollment';

export class LocalProgramRepo implements ProgramRepository {
  /**
   * Retrieves all programs from the bundled programs.json file.
   */
  async getPrograms(): Promise<Program[]> {
    return bundledPrograms.map(firestoreProgramToProgram);
  }

  /**
   * Retrieves a single program by ID from the bundled programs.
   * Returns null if the program is not found.
   */
  async getProgram(programId: string): Promise<Program | null> {
    const doc = bundledPrograms.find((p) => p.id === programId);
    if (!doc) {
      return null;
    }
    return firestoreProgramToProgram(doc);
  }

  /**
   * Enrolls the user in a program by saving an enrollment record to AsyncStorage.
   */
  async enrollUser(_uid: string, programId: string): Promise<void> {
    const enrollment: ProgramEnrollment = {
      programId,
      startDate: new Date().toISOString().split('T')[0],
      currentWeek: 0,
      currentSession: 0,
    };
    await AsyncStorage.setItem(ENROLLMENT_KEY, JSON.stringify(enrollment));
  }

  /**
   * Retrieves the active program enrollment from AsyncStorage.
   * Returns null if no enrollment exists.
   */
  async getEnrollment(_uid: string): Promise<ProgramEnrollment | null> {
    const raw = await AsyncStorage.getItem(ENROLLMENT_KEY);
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as ProgramEnrollment;
  }

  /**
   * Updates the current week and session progress for the active enrollment.
   */
  async updateEnrollmentProgress(
    _uid: string,
    weekIndex: number,
    sessionIndex: number
  ): Promise<void> {
    const existing = await this.getEnrollment(_uid);
    if (!existing) {
      return;
    }
    const updated: ProgramEnrollment = {
      ...existing,
      currentWeek: weekIndex,
      currentSession: sessionIndex,
    };
    await AsyncStorage.setItem(ENROLLMENT_KEY, JSON.stringify(updated));
  }

  /**
   * Removes the active enrollment from AsyncStorage.
   */
  async unenroll(_uid: string): Promise<void> {
    await AsyncStorage.removeItem(ENROLLMENT_KEY);
  }
}

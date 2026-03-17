/**
 * WODRepository interface and factory function.
 *
 * Defines the contract for Workout of the Day (WOD) data access.
 * WODs are public read-only data — no guest/auth distinction needed.
 * Implementation:
 *   - FirestoreWODRepo: always used; Firestore offline persistence handles offline guests.
 */
import type { BenchmarkScoringType } from '../domain/types/index';
import { FirestoreWODRepo } from './FirestoreWODRepo';

/**
 * A single Workout of the Day record.
 * Document ID in Firestore is the date string 'yyyy-MM-dd'.
 */
export interface WODRecord {
  /** Document ID — date string 'yyyy-MM-dd' */
  id: string;
  /** ISO date string 'yyyy-MM-dd' */
  date: string;
  name: string;
  description: string;
  exercises: string[];
  scoringType?: BenchmarkScoringType;
}

export interface WODRepository {
  getWODForDate(date: string): Promise<WODRecord | null>;
  getRecentWODs(limit?: number): Promise<WODRecord[]>;
}

/**
 * Returns the WOD repository.
 * WODs are public read-only data, so the same implementation is used
 * for both authenticated and guest users.
 */
export function getWODRepo(): WODRepository {
  return new FirestoreWODRepo();
}

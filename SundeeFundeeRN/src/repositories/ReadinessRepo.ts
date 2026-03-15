/**
 * ReadinessRepository interface and factory function.
 *
 * Defines the contract for readiness survey record persistence.
 * Implementations:
 *   - FirestoreReadinessRepo: authenticated users (subcollection /users/{uid}/readiness)
 *   - LocalReadinessRepo: guest users (@sundee/readiness_surveys key)
 */
import type { ReadinessResult } from '../domain/readiness/readiness-survey';
import { FirestoreReadinessRepo } from './FirestoreReadinessRepo';
import { LocalReadinessRepo } from './LocalReadinessRepo';

export interface ReadinessSurveyRecord {
  /** Document ID — uses date string 'yyyy-MM-dd' as ID for easy lookup */
  id: string;
  uid: string;
  /** ISO date string 'yyyy-MM-dd' */
  date: string;
  sleepQuality: number;
  /** Energy level (1–10, higher = more energised). Added per locked decision: 4-slider survey. */
  energyLevel: number;
  stressLevel: number;
  sorenessLevel: number;
  result: ReadinessResult;
}

export interface ReadinessRepository {
  saveSurvey(uid: string, record: ReadinessSurveyRecord): Promise<void>;
  getSurveyForDate(uid: string, date: string): Promise<ReadinessSurveyRecord | null>;
  getRecentSurveys(uid: string, limit?: number): Promise<ReadinessSurveyRecord[]>;
}

/**
 * Returns the appropriate ReadinessRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getReadinessRepo(isGuest: boolean): ReadinessRepository {
  return isGuest
    ? new LocalReadinessRepo()
    : new FirestoreReadinessRepo();
}

import type { ReadinessResult } from '../domain/readiness/readiness-survey';
import { FirestoreReadinessRepo } from './FirestoreReadinessRepo';
import { LocalReadinessRepo } from './LocalReadinessRepo';

export interface ReadinessSurveyRecord {
  id: string;
  uid: string;
  date: string;
  sleepQuality: number;
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

export function getReadinessRepo(isGuest: boolean): ReadinessRepository {
  return isGuest ? new LocalReadinessRepo() : new FirestoreReadinessRepo();
}

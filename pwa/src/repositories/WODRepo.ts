import type { BenchmarkScoringType } from '../domain/types/index';
import { FirestoreWODRepo } from './FirestoreWODRepo';

export interface WODRecord {
  id: string;
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

export function getWODRepo(): WODRepository {
  return new FirestoreWODRepo();
}

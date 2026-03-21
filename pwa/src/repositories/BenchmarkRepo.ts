import type { BenchmarkDefinition, BenchmarkScoringType } from '../domain/types/index';
import { FirestoreBenchmarkRepo } from './FirestoreBenchmarkRepo';
import { LocalBenchmarkRepo } from './LocalBenchmarkRepo';

export type { BenchmarkDefinition };

export interface BenchmarkResultRecord {
  id: string;
  uid: string;
  benchmarkId: string;
  benchmarkName: string;
  scoringType: BenchmarkScoringType;
  score: number;
  date: string;
  notes?: string;
}

export interface BenchmarkRepository {
  saveResult(uid: string, result: BenchmarkResultRecord): Promise<void>;
  getResults(uid: string, benchmarkId: string): Promise<BenchmarkResultRecord[]>;
  getAllResults(uid: string): Promise<BenchmarkResultRecord[]>;
  saveCustomBenchmark(uid: string, definition: BenchmarkDefinition): Promise<void>;
  getCustomBenchmarks(uid: string): Promise<BenchmarkDefinition[]>;
  deleteCustomBenchmark(uid: string, benchmarkId: string): Promise<void>;
}

export function getBenchmarkRepo(isGuest: boolean): BenchmarkRepository {
  return isGuest ? new LocalBenchmarkRepo() : new FirestoreBenchmarkRepo();
}

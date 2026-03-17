/**
 * BenchmarkRepository interface and factory function.
 *
 * Defines the contract for benchmark result and custom benchmark definition persistence.
 * Implementations:
 *   - FirestoreBenchmarkRepo: authenticated users (/users/{uid}/benchmarkResults, customBenchmarks)
 *   - LocalBenchmarkRepo: guest users (@sundee/benchmark_results, @sundee/custom_benchmarks keys)
 */
import type { BenchmarkDefinition, BenchmarkScoringType } from '../domain/types/index';
import { FirestoreBenchmarkRepo } from './FirestoreBenchmarkRepo';
import { LocalBenchmarkRepo } from './LocalBenchmarkRepo';

export type { BenchmarkDefinition };

/**
 * A single benchmark result record.
 * The `score` field stores the already-encoded value:
 * - time: seconds (lower is better)
 * - reps: count (higher is better)
 * - weight: kg (higher is better)
 * - distance: seconds for fixed distance (lower is better)
 * - roundsAndReps: rounds * 10000 + reps (higher is better)
 */
export interface BenchmarkResultRecord {
  /** UUID document ID */
  id: string;
  uid: string;
  benchmarkId: string;
  benchmarkName: string;
  scoringType: BenchmarkScoringType;
  score: number;
  /** ISO date string 'yyyy-MM-dd' */
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

/**
 * Returns the appropriate BenchmarkRepository based on auth state.
 * Guest users use local AsyncStorage; authenticated users use Firestore.
 */
export function getBenchmarkRepo(isGuest: boolean): BenchmarkRepository {
  return isGuest
    ? new LocalBenchmarkRepo()
    : new FirestoreBenchmarkRepo();
}

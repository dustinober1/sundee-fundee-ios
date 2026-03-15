/**
 * LocalBenchmarkRepo — AsyncStorage implementation of BenchmarkRepository.
 *
 * Persists benchmark results and custom benchmark definitions locally for guest users.
 * Results stored under '@sundee/benchmark_results' as a JSON array.
 * Custom benchmarks stored under '@sundee/custom_benchmarks' as a JSON array.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { BenchmarkDefinition } from '../domain/types/index';
import type { BenchmarkRepository, BenchmarkResultRecord } from './BenchmarkRepo';

const BENCHMARK_RESULTS_KEY = '@sundee/benchmark_results';
const CUSTOM_BENCHMARKS_KEY = '@sundee/custom_benchmarks';

export class LocalBenchmarkRepo implements BenchmarkRepository {
  /**
   * Saves (upserts) a benchmark result to AsyncStorage.
   * If a record with the same id exists, it is replaced.
   */
  async saveResult(_uid: string, result: BenchmarkResultRecord): Promise<void> {
    const existing = await this.loadAllResults();
    const filtered = existing.filter((r) => r.id !== result.id);
    filtered.push(result);
    await AsyncStorage.setItem(BENCHMARK_RESULTS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves all results for a specific benchmark, ordered by date descending.
   */
  async getResults(_uid: string, benchmarkId: string): Promise<BenchmarkResultRecord[]> {
    const all = await this.loadAllResults();
    return all
      .filter((r) => r.benchmarkId === benchmarkId)
      .sort((a, b) => b.date.localeCompare(a.date));
  }

  /**
   * Retrieves all benchmark results for a user, ordered by date descending.
   */
  async getAllResults(_uid: string): Promise<BenchmarkResultRecord[]> {
    const all = await this.loadAllResults();
    return all.sort((a, b) => b.date.localeCompare(a.date));
  }

  /**
   * Saves (upserts) a custom benchmark definition to AsyncStorage.
   * If a definition with the same id exists, it is replaced.
   */
  async saveCustomBenchmark(_uid: string, definition: BenchmarkDefinition): Promise<void> {
    const existing = await this.loadAllCustomBenchmarks();
    const filtered = existing.filter((b) => b.id !== definition.id);
    filtered.push(definition);
    await AsyncStorage.setItem(CUSTOM_BENCHMARKS_KEY, JSON.stringify(filtered));
  }

  /**
   * Retrieves all custom benchmark definitions.
   */
  async getCustomBenchmarks(_uid: string): Promise<BenchmarkDefinition[]> {
    return this.loadAllCustomBenchmarks();
  }

  /**
   * Deletes a custom benchmark definition by its id.
   */
  async deleteCustomBenchmark(_uid: string, benchmarkId: string): Promise<void> {
    const existing = await this.loadAllCustomBenchmarks();
    const filtered = existing.filter((b) => b.id !== benchmarkId);
    await AsyncStorage.setItem(CUSTOM_BENCHMARKS_KEY, JSON.stringify(filtered));
  }

  private async loadAllResults(): Promise<BenchmarkResultRecord[]> {
    const raw = await AsyncStorage.getItem(BENCHMARK_RESULTS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as BenchmarkResultRecord[];
  }

  private async loadAllCustomBenchmarks(): Promise<BenchmarkDefinition[]> {
    const raw = await AsyncStorage.getItem(CUSTOM_BENCHMARKS_KEY);
    if (!raw) {
      return [];
    }
    return JSON.parse(raw) as BenchmarkDefinition[];
  }
}

import type { BenchmarkDefinition } from '../domain/types/index';
import type { BenchmarkResultRecord, BenchmarkRepository } from './BenchmarkRepo';

const RESULTS_KEY = '@sundee/benchmark_results';
const CUSTOM_KEY = '@sundee/custom_benchmarks';

export class LocalBenchmarkRepo implements BenchmarkRepository {
  async saveResult(_uid: string, result: BenchmarkResultRecord): Promise<void> {
    const all = this.loadResults();
    const filtered = all.filter((r) => r.id !== result.id);
    filtered.push(result);
    localStorage.setItem(RESULTS_KEY, JSON.stringify(filtered));
  }

  async getResults(_uid: string, benchmarkId: string): Promise<BenchmarkResultRecord[]> {
    return this.loadResults().filter((r) => r.benchmarkId === benchmarkId);
  }

  async getAllResults(_uid: string): Promise<BenchmarkResultRecord[]> {
    return this.loadResults();
  }

  async saveCustomBenchmark(_uid: string, definition: BenchmarkDefinition): Promise<void> {
    const all = this.loadCustom();
    const filtered = all.filter((d) => d.id !== definition.id);
    filtered.push(definition);
    localStorage.setItem(CUSTOM_KEY, JSON.stringify(filtered));
  }

  async getCustomBenchmarks(_uid: string): Promise<BenchmarkDefinition[]> {
    return this.loadCustom();
  }

  async deleteCustomBenchmark(_uid: string, benchmarkId: string): Promise<void> {
    localStorage.setItem(CUSTOM_KEY, JSON.stringify(this.loadCustom().filter((d) => d.id !== benchmarkId)));
  }

  private loadResults(): BenchmarkResultRecord[] {
    const raw = localStorage.getItem(RESULTS_KEY);
    return raw ? (JSON.parse(raw) as BenchmarkResultRecord[]) : [];
  }

  private loadCustom(): BenchmarkDefinition[] {
    const raw = localStorage.getItem(CUSTOM_KEY);
    return raw ? (JSON.parse(raw) as BenchmarkDefinition[]) : [];
  }
}

/**
 * Domain layer — top-level barrel export.
 * Re-exports all public API from every subdomain.
 *
 * Usage: import { estimated1RM, generateOfflineWorkout, BENCHMARK_CATALOG } from 'src/domain'
 */

export * from './types';
export * from './calculations';
export * from './ai-workout';
export * from './history';
export * from './readiness';
export * from './benchmarks';
export * from './shared';

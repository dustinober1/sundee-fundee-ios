/**
 * Domain layer — top-level barrel export.
 * Re-exports all public API from every subdomain.
 *
 * Usage: import { estimated1RM, generateOfflineWorkout, BENCHMARK_CATALOG } from 'src/domain'
 *
 * Note: cycle and injury both export `adaptProgram`. To avoid a re-export collision,
 * the top-level barrel re-exports each as a domain-scoped alias:
 *   adaptCycleProgram  — from cycle/cycle-program-generator (cycle-phase adaptation)
 *   adaptInjuryProgram — from injury/injury-adaptation-engine (injury adaptation)
 * Direct sub-barrel imports are recommended for internal use:
 *   import { adaptProgram } from 'src/domain/cycle'
 *   import { adaptProgram } from 'src/domain/injury'
 */

export * from './types';
export * from './calculations';

// ---------------------------------------------------------------------------
// Cycle subdomain — explicit named re-exports to avoid adaptProgram collision
// ---------------------------------------------------------------------------
export {
  getPhaseBoundaries,
  inferCurrentPhase,
  calculateCycleStatus,
  getPhaseRecommendation,
} from './cycle/cycle-calculations';
export type {
  PhaseBoundary,
  PhaseBoundaries,
  CycleStatusResult,
  PhaseRecommendation,
} from './cycle/cycle-calculations';
export {
  blendMultiplier,
  resolveReadinessTier,
  resolveConfidenceScale,
  applyPhaseAdjustment,
} from './cycle/cycle-adaptation-policy';
export type { AdaptationConfidence } from './cycle/cycle-adaptation-policy';
export {
  adaptProgram as adaptCycleProgram,
  resolveConfidence,
} from './cycle/cycle-program-generator';

// ---------------------------------------------------------------------------
// Injury subdomain — explicit named re-exports to avoid adaptProgram collision
// ---------------------------------------------------------------------------
export { phaseIndex, isMoreRestrictive, nextPhase, phaseDisplayName } from './injury/recovery-phase';
export {
  BODY_LOCATIONS,
  bodyLocationDisplayName,
  bodyLocationEngineKeyFromRegion,
  parseRegions,
  encodeRegions,
} from './injury/body-location';
export {
  getLoadMultipliers,
  adjustExerciseValue,
  adjustLoad,
} from './injury/load-adjustment-policy';
export type { LoadMultipliers } from './injury/load-adjustment-policy';
export { analyzeTrend, hasRecentLog, sparklineData } from './injury/pain-trend-analyzer';
export type { TrendResult } from './injury/pain-trend-analyzer';
export { meetsThreshold, evaluateTransition } from './injury/phase-transition-advisor';
export type { TransitionSuggestion } from './injury/phase-transition-advisor';
export {
  adaptProgram as adaptInjuryProgram,
  adaptProgramWithMetadata,
  mostRestrictive,
  normalizedBodyRegions,
  buildRecoveryPrepBlock,
} from './injury/injury-adaptation-engine';
export type { AdaptationResult } from './injury/injury-adaptation-engine';
export { generateSession } from './injury/rehab-session-generator';

export * from './ai-workout';
export * from './history';
export * from './readiness';
export * from './benchmarks';
export * from './shared';

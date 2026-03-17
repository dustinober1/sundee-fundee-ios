/* istanbul ignore file — barrel re-exports only, no executable logic */
/**
 * src/domain/injury/index.ts
 * Barrel re-export for all public injury domain functions.
 */

export { phaseIndex, isMoreRestrictive, nextPhase, phaseDisplayName } from './recovery-phase';

export {
  BODY_LOCATIONS,
  bodyLocationDisplayName,
  bodyLocationEngineKeyFromRegion,
  parseRegions,
  encodeRegions,
} from './body-location';

export {
  getLoadMultipliers,
  adjustExerciseValue,
  adjustLoad,
} from './load-adjustment-policy';
export type { LoadMultipliers } from './load-adjustment-policy';

export { analyzeTrend, hasRecentLog, sparklineData } from './pain-trend-analyzer';
export type { TrendResult } from './pain-trend-analyzer';

export { meetsThreshold, evaluateTransition } from './phase-transition-advisor';
export type { TransitionSuggestion } from './phase-transition-advisor';

export {
  adaptProgram,
  adaptProgramWithMetadata,
  mostRestrictive,
  normalizedBodyRegions,
  buildRecoveryPrepBlock,
} from './injury-adaptation-engine';
export type { AdaptationResult } from './injury-adaptation-engine';

export { generateSession } from './rehab-session-generator';

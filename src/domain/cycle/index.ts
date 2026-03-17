// =============================================================================
// Cycle domain — barrel re-export
// =============================================================================

export {
  getPhaseBoundaries,
  inferCurrentPhase,
  calculateCycleStatus,
  getPhaseRecommendation,
} from './cycle-calculations';

export type {
  PhaseBoundary,
  PhaseBoundaries,
  CycleStatusResult,
  PhaseRecommendation,
} from './cycle-calculations';

export {
  blendMultiplier,
  resolveReadinessTier,
  resolveConfidenceScale,
  applyPhaseAdjustment,
} from './cycle-adaptation-policy';

export type { AdaptationConfidence } from './cycle-adaptation-policy';

export { adaptProgram, resolveConfidence } from './cycle-program-generator';

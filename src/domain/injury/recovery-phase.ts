/**
 * recovery-phase.ts
 * Helper functions for the RecoveryPhase type.
 * The type itself and RECOVERY_PHASE_ORDER are defined in src/domain/types/index.ts.
 */

import { RecoveryPhase, RECOVERY_PHASE_ORDER } from '../types';

/**
 * Returns the 0-based index of the phase in the ordered sequence.
 * acute=0, rehab=1, lightLoad=2, returnToPlay=3, resolved=4.
 */
export function phaseIndex(phase: RecoveryPhase): number {
  return RECOVERY_PHASE_ORDER.indexOf(phase);
}

/**
 * Returns true when `a` is more restrictive (earlier) than `b`.
 */
export function isMoreRestrictive(a: RecoveryPhase, b: RecoveryPhase): boolean {
  return phaseIndex(a) < phaseIndex(b);
}

/**
 * Returns the next phase in the recovery arc, or null if already resolved.
 */
export function nextPhase(phase: RecoveryPhase): RecoveryPhase | null {
  const idx = phaseIndex(phase);
  if (idx < 0 || idx >= RECOVERY_PHASE_ORDER.length - 1) return null;
  return RECOVERY_PHASE_ORDER[idx + 1];
}

/**
 * Human-readable display name matching Swift RecoveryPhase.displayName.
 */
export function phaseDisplayName(phase: RecoveryPhase): string {
  const names: Record<RecoveryPhase, string> = {
    acute: 'Acute',
    rehab: 'Rehab',
    lightLoad: 'Light Load',
    returnToPlay: 'Return to Play',
    resolved: 'Resolved',
  };
  return names[phase];
}

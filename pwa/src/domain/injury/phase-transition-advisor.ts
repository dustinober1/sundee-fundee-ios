/**
 * phase-transition-advisor.ts
 * Pure logic rules for suggesting recovery phase transitions based on pain trends.
 * User always manually confirms — no auto-transitions.
 * Ported from Swift PhaseTransitionAdvisor.swift.
 */

import { RecoveryPhase, PainLog } from '../types';

export interface TransitionSuggestion {
  injuryId: string;
  currentPhase: RecoveryPhase;
  suggestedPhase: RecoveryPhase;
}

/**
 * Checks whether the N most recent logs all have pain at or below the threshold.
 * Logs must be sorted newest-first.
 * Matches Swift PhaseTransitionAdvisor.meetsThreshold(_:count:maxPain:).
 */
export function meetsThreshold(logs: PainLog[], count: number, maxPain: number): boolean {
  if (logs.length < count) return false;
  return logs.slice(0, count).every(l => l.painLevel <= maxPain);
}

/**
 * Evaluates whether an injury is ready to advance to the next recovery phase.
 * Returns null if no transition is suggested.
 *
 * Thresholds (matching Swift source):
 *   acute      → rehab:         3 logs at pain <= 5
 *   rehab      → lightLoad:     3 logs at pain <= 3
 *   lightLoad  → returnToPlay:  3 logs at pain <= 2
 *   returnToPlay → resolved:    5 logs at pain <= 1
 *
 * Matches Swift PhaseTransitionAdvisor.evaluateTransition(injuryID:currentPhase:painLogs:).
 */
export function evaluateTransition(
  injuryId: string,
  currentPhase: RecoveryPhase,
  painLogs: PainLog[],
): TransitionSuggestion | null {
  // Only consider the 5 most recent logs (matches Swift prefix(5))
  const recentLogs = painLogs.slice(0, 5);

  switch (currentPhase) {
    case 'acute':
      if (meetsThreshold(recentLogs, 3, 5)) {
        return { injuryId, currentPhase: 'acute', suggestedPhase: 'rehab' };
      }
      break;
    case 'rehab':
      if (meetsThreshold(recentLogs, 3, 3)) {
        return { injuryId, currentPhase: 'rehab', suggestedPhase: 'lightLoad' };
      }
      break;
    case 'lightLoad':
      if (meetsThreshold(recentLogs, 3, 2)) {
        return { injuryId, currentPhase: 'lightLoad', suggestedPhase: 'returnToPlay' };
      }
      break;
    case 'returnToPlay':
      if (meetsThreshold(recentLogs, 5, 1)) {
        return { injuryId, currentPhase: 'returnToPlay', suggestedPhase: 'resolved' };
      }
      break;
    case 'resolved':
      break;
  }

  return null;
}

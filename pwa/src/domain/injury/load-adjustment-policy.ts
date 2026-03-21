/**
 * load-adjustment-policy.ts
 * Phase-specific multipliers for exercise load, sets, and reps.
 * Ported from Swift LoadAdjustmentPolicy.swift.
 */

import { RecoveryPhase, ExerciseValue } from '../types';
import { swiftRound } from '../types';

export interface LoadMultipliers {
  load: number;
  sets: number;
  reps: number;
}

/**
 * Returns load/sets/reps multipliers for the given recovery phase.
 * Matches Swift LoadAdjustmentPolicy.multipliers(for:).
 */
export function getLoadMultipliers(phase: RecoveryPhase): LoadMultipliers {
  switch (phase) {
    case 'acute':
      return { load: 0.0, sets: 0.0, reps: 0.0 };
    case 'rehab':
      return { load: 0.30, sets: 0.50, reps: 0.70 };
    case 'lightLoad':
      return { load: 0.50, sets: 0.75, reps: 0.85 };
    case 'returnToPlay':
      return { load: 0.80, sets: 0.90, reps: 1.0 };
    case 'resolved':
      return { load: 1.0, sets: 1.0, reps: 1.0 };
  }
}

/**
 * Applies a multiplier to an ExerciseValue.
 * - fixed: rounds result, clamps to min 1
 * - range: rounds both ends, clamps to min 1
 * - amrap/text: pass through unchanged
 * Matches Swift LoadAdjustmentPolicy.adjustValue(_:multiplier:).
 */
export function adjustExerciseValue(ev: ExerciseValue, multiplier: number): ExerciseValue {
  switch (ev.kind) {
    case 'fixed':
      return { kind: 'fixed', value: Math.max(1, swiftRound(ev.value * multiplier)) };
    case 'range':
      return {
        kind: 'range',
        lo: Math.max(1, swiftRound(ev.lo * multiplier)),
        hi: Math.max(1, swiftRound(ev.hi * multiplier)),
      };
    case 'amrap':
      return ev;
    case 'text':
      return ev;
  }
}

/**
 * Applies the load multiplier to a percent1RM value.
 * Returns null when load is undefined (matching Swift Optional.none).
 * Matches Swift LoadAdjustmentPolicy.adjustLoad(_:multiplier:).
 */
export function adjustLoad(load: number | undefined, multiplier: number): number | null {
  if (load === undefined || load === null) return null;
  return load * multiplier;
}

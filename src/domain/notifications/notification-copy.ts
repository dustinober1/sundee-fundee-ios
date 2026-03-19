/**
 * notification-copy — pure domain module for cycle-aware notification copy.
 *
 * Zero dependencies outside the domain types.
 * Used by notificationService to build notification body text.
 */

import type { CyclePhase } from '../types';

// ─── Cycle-phase copy ─────────────────────────────────────────────────────────

/** One-line encouraging copy keyed by CyclePhase. */
export const CYCLE_COPY: Record<CyclePhase, string> = {
  menstrual: 'Menstrual phase — gentle movement counts. You\'ve got this.',
  follicular: 'Follicular phase — great day for strength PRs.',
  ovulation: 'Peak energy today — make it count.',
  luteal: 'Luteal phase — listen to your body. Consistent beats heroic.',
};

// ─── Generic copy ─────────────────────────────────────────────────────────────

/** Motivational copy variations used when cycle data is unavailable. */
export const GENERIC_COPY: string[] = [
  'Time to train.',
  'Your workout is waiting.',
  'Show up today.',
  'Strength is built one session at a time.',
];

// ─── Functions ────────────────────────────────────────────────────────────────

/**
 * Returns cycle-phase-specific notification body copy.
 */
export function getCycleAwareCopy(phase: CyclePhase): string {
  return CYCLE_COPY[phase];
}

/**
 * Returns a random motivational copy string from GENERIC_COPY.
 */
export function getGenericCopy(): string {
  return GENERIC_COPY[Math.floor(Math.random() * GENERIC_COPY.length)];
}

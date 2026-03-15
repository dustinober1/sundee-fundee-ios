/**
 * scoring-input.ts — Benchmark scoring helper utilities.
 *
 * Provides formatting and parsing functions for the five BenchmarkScoringTypes:
 * - time: displayed as MM:SS (lower is better)
 * - reps: displayed as plain rep count or "N rounds + M reps" when encoded
 * - roundsAndReps: displayed as "N rounds + M reps" (encodeRoundsAndReps encoding)
 * - weight: displayed with "lbs" label (higher is better)
 * - distance: displayed as MM:SS time for fixed-distance events (lower is better)
 */

import type { BenchmarkScoringType } from '@/src/domain/types';
import { decodeRoundsAndReps } from '@/src/domain/benchmarks/benchmark-catalog';

// ---------------------------------------------------------------------------
// formatScore
// ---------------------------------------------------------------------------

/**
 * Format a numeric score for display based on scoring type.
 *
 * - time: seconds -> "M:SS" (e.g. 300 -> "5:00")
 * - reps: if value >= 10000, decodes as roundsAndReps; otherwise plain reps count
 * - roundsAndReps: decodes to "N rounds + M reps"
 * - weight: "N lbs"
 * - distance: seconds -> "M:SS" (same as time — fixed-distance events are timed)
 */
export function formatScore(scoringType: BenchmarkScoringType, score: number): string {
  switch (scoringType) {
    case 'time':
    case 'distance':
      return formatSeconds(score);

    case 'roundsAndReps':
      return formatRoundsAndReps(score);

    case 'reps':
      // If score >= 10000 treat as encoded rounds+reps (AMRAP-style)
      if (score >= 10000) {
        return formatRoundsAndReps(score);
      }
      return `${score} reps`;

    case 'weight':
      return `${score} lbs`;
  }
}

// ---------------------------------------------------------------------------
// parseTimeInput
// ---------------------------------------------------------------------------

/**
 * Parse a "M:SS" or "MM:SS" string into total seconds.
 * Returns NaN for invalid input.
 *
 * Examples:
 *   "5:30" -> 330
 *   "1:05" -> 65
 *   "0:00" -> 0
 */
export function parseTimeInput(mmss: string): number {
  if (!mmss || !mmss.includes(':')) {
    return NaN;
  }

  const parts = mmss.split(':');
  if (parts.length !== 2) {
    return NaN;
  }

  const minutes = parseInt(parts[0] ?? '', 10);
  const seconds = parseInt(parts[1] ?? '', 10);

  if (isNaN(minutes) || isNaN(seconds)) {
    return NaN;
  }

  return minutes * 60 + seconds;
}

// ---------------------------------------------------------------------------
// isScoreImproved
// ---------------------------------------------------------------------------

/**
 * Determine whether newScore represents an improvement over oldScore.
 *
 * Improvement direction by type:
 * - time: lower is better
 * - distance: lower is better (faster time for fixed distance)
 * - reps, roundsAndReps, weight: higher is better
 */
export function isScoreImproved(
  scoringType: BenchmarkScoringType,
  newScore: number,
  oldScore: number,
): boolean {
  switch (scoringType) {
    case 'time':
    case 'distance':
      // Lower is better — strictly less than
      return newScore < oldScore;

    case 'reps':
    case 'roundsAndReps':
    case 'weight':
      // Higher is better — strictly greater than
      return newScore > oldScore;
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/** Format total seconds as "M:SS" string. */
function formatSeconds(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

/** Format an encoded roundsAndReps value as "N rounds + M reps". */
function formatRoundsAndReps(encoded: number): string {
  const { rounds, reps } = decodeRoundsAndReps(encoded);
  return `${rounds} rounds + ${reps} reps`;
}

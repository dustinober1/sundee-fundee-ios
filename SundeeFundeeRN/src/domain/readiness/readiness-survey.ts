/**
 * ReadinessSurvey — pure scoring functions only.
 * Ported from SundeeFundee/Domain/ReadinessSurvey.swift
 *
 * IMPORTANT: saveTodayResult and loadTodayResult (UserDefaults/AsyncStorage)
 * are intentionally OMITTED here. Storage belongs in the repository layer
 * (Phase 3 per research pitfall 6).
 *
 * All functions are pure — no side effects, no storage access.
 */

import type { ReadinessTier } from '../types';
import { clamp } from '../types';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ReadinessResult {
  score: number;
  tier: ReadinessTier;
}

// ---------------------------------------------------------------------------
// Scoring weights (4-slider model: sleep, stress, soreness, energy)
// ---------------------------------------------------------------------------

const SLEEP_WEIGHT = 0.3;
const STRESS_WEIGHT = 0.25;
const SORENESS_WEIGHT = 0.25;
const ENERGY_WEIGHT = 0.2;

// ---------------------------------------------------------------------------
// Pure functions
// ---------------------------------------------------------------------------

/**
 * Calculate a readiness score from survey inputs.
 *
 * Extended to 4 parameters per locked decision (READ-01):
 * sleep/energy/stress/motivation sliders capture daily readiness.
 *
 * @param sleepQuality  - 1–10 (higher = better sleep)
 * @param stressLevel   - 1–10 (higher = more stressed; inverted in formula)
 * @param sorenessLevel - 1–10 (higher = more soreness; inverted in formula)
 * @param energyLevel   - 1–10 (higher = more energy; not inverted)
 *                        Defaults to 5 for backward compatibility with 3-param callers.
 */
export function calculateReadinessScore(
  sleepQuality: number,
  stressLevel: number,
  sorenessLevel: number,
  energyLevel = 5,
): ReadinessResult {
  const invertedStress = 10.0 - stressLevel;
  const invertedSoreness = 10.0 - sorenessLevel;
  const raw =
    sleepQuality * SLEEP_WEIGHT +
    invertedStress * STRESS_WEIGHT +
    invertedSoreness * SORENESS_WEIGHT +
    energyLevel * ENERGY_WEIGHT;
  const score = clamp(raw, 0, 10);
  return { score, tier: tierFromScore(score) };
}

/**
 * Blend a survey score with an optional HealthKit readiness score.
 * Matches Swift ReadinessSurvey.blendWithHealthKit(surveyScore:healthKitScore:).
 *
 * Survey is weighted 70%, HealthKit 30%.
 */
export function blendWithHealthKit(
  surveyScore: number,
  healthKitScore: number | null,
): ReadinessResult {
  if (healthKitScore == null) {
    return { score: surveyScore, tier: tierFromScore(surveyScore) };
  }
  const blended = clamp(surveyScore * 0.7 + healthKitScore * 0.3, 0, 10);
  return { score: blended, tier: tierFromScore(blended) };
}

/**
 * Map a readiness score to a ReadinessTier.
 * Matches Swift ReadinessSurvey.tierFromScore(_:).
 *
 * score <= 3 → 'low'
 * score >= 8 → 'high'
 * otherwise  → 'neutral'
 */
export function tierFromScore(score: number): ReadinessTier {
  if (score <= 3) return 'low';
  if (score >= 8) return 'high';
  return 'neutral';
}

/**
 * Human-readable display name for a tier.
 * Matches Swift ReadinessSurvey.tierDisplayName(_:).
 */
export function tierDisplayName(tier: ReadinessTier): string {
  switch (tier) {
    case 'low': return 'Fatigued';
    case 'neutral': return 'Normal';
    case 'high': return 'Prime';
  }
}

/**
 * AI-prompt-friendly tier string.
 * Matches Swift ReadinessSurvey.tierStringForAI(_:).
 */
export function tierStringForAI(tier: ReadinessTier): string {
  switch (tier) {
    case 'low': return 'fatigued';
    case 'neutral': return 'normal';
    case 'high': return 'prime';
  }
}

/**
 * Returns a banner message to display when readiness affects the workout.
 * Returns null for neutral tier (no banner shown).
 * Matches Swift ReadinessSurvey.adjustmentBannerText(for:).
 */
export function adjustmentBannerText(tier: ReadinessTier): string | null {
  switch (tier) {
    case 'low': return 'Volume reduced 40% — low readiness';
    case 'high': return 'Intensity boosted 20% — high readiness';
    case 'neutral': return null;
  }
}

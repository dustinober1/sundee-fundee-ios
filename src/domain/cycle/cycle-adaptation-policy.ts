// =============================================================================
// CycleAdaptationPolicy — TypeScript port of CycleAdaptationPolicy.swift
// Provides phase-aware load/set/rep multiplier blending with readiness integration.
// Pure functions — no side effects, no mutation.
// =============================================================================

import { clamp, scaleExerciseValue, swiftRound } from '../types';
import type { CyclePhase, ReadinessTier, ProgramExercise, ExerciseValue } from '../types';

// ---------------------------------------------------------------------------
// Confidence tier (internal — not exported from types to keep types pure)
// ---------------------------------------------------------------------------

export type AdaptationConfidence = 'low' | 'medium' | 'high';

// ---------------------------------------------------------------------------
// Phase multiplier tables (mirrors Swift baselinePhaseSettings)
// ---------------------------------------------------------------------------

interface PhaseSettings {
  load: number;
  sets: number;
  reps: number;
}

const BASELINE_PHASE_SETTINGS: Record<CyclePhase, PhaseSettings> = {
  menstrual:  { load: 0.90, sets: 0.90, reps: 0.90 },
  follicular: { load: 1.00, sets: 1.00, reps: 1.00 },
  ovulation:  { load: 1.12, sets: 1.05, reps: 0.95 },
  luteal:     { load: 0.97, sets: 0.95, reps: 0.92 },
};

// ---------------------------------------------------------------------------
// Readiness scale table (mirrors Swift readinessScales)
// ---------------------------------------------------------------------------

const READINESS_SCALES: Record<ReadinessTier, number> = {
  low:     0.6,
  neutral: 1.0,
  high:    1.2,
};

// ---------------------------------------------------------------------------
// Confidence scale table (mirrors Swift confidenceScales)
// ---------------------------------------------------------------------------

const CONFIDENCE_SCALES: Record<AdaptationConfidence, number> = {
  low:    0.55,
  medium: 0.80,
  high:   1.00,
};

// ---------------------------------------------------------------------------
// Core blend function
// ---------------------------------------------------------------------------

/**
 * Blend a phase multiplier target with readiness and confidence scaling.
 *
 * Formula (mirrors Swift):
 *   result = clamp(1.0 + (target - 1.0) * readinessScale * confidenceScale, 0.75, 1.25)
 *
 * - target: phase-specific multiplier (e.g. 0.90 for menstrual reps)
 * - readinessScale: derived from ReadinessTier (low=0.6, neutral=1.0, high=1.2)
 * - confidenceScale: derived from AdaptationConfidence (low=0.55, medium=0.8, high=1.0)
 */
export function blendMultiplier(
  target: number,
  readinessScale: number,
  confidenceScale: number
): number {
  return clamp(1.0 + (target - 1.0) * readinessScale * confidenceScale, 0.75, 1.25);
}

// ---------------------------------------------------------------------------
// Readiness tier resolution
// ---------------------------------------------------------------------------

/**
 * Map a readiness score (1–10 survey) to a ReadinessTier.
 * Mirrors CycleAdaptationPolicy.resolveReadinessTier(readinessScore:).
 *
 * - undefined/null → neutral
 * - score ≤ 3     → low
 * - score ≥ 8     → high
 * - otherwise     → neutral
 */
export function resolveReadinessTier(readinessScore?: number): ReadinessTier {
  if (readinessScore === undefined || readinessScore === null) return 'neutral';
  if (readinessScore <= 3) return 'low';
  if (readinessScore >= 8) return 'high';
  return 'neutral';
}

// ---------------------------------------------------------------------------
// Confidence scale resolution
// ---------------------------------------------------------------------------

/**
 * Resolve the numeric confidence scale from an AdaptationConfidence tier.
 * Mirrors resolveConfidenceScale(confidence:lowConfidenceScale:).
 */
export function resolveConfidenceScale(
  confidence: AdaptationConfidence,
  lowConfidenceScale: number = 0.7
): number {
  const base = CONFIDENCE_SCALES[confidence];
  if (confidence !== 'low') return base;
  return clamp(base * lowConfidenceScale, 0.1, 1.0);
}

// ---------------------------------------------------------------------------
// Phase settings helper
// ---------------------------------------------------------------------------

function resolvePhaseSettings(phase: CyclePhase): PhaseSettings {
  return BASELINE_PHASE_SETTINGS[phase];
}

// ---------------------------------------------------------------------------
// Scale a numeric sets count by multiplier (mirrors Swift scaleValue for sets)
// ---------------------------------------------------------------------------

function scaleSets(sets: number, multiplier: number): number {
  return Math.max(1, swiftRound(sets * multiplier));
}

// ---------------------------------------------------------------------------
// Main adaptation function
// ---------------------------------------------------------------------------

/**
 * Apply cycle phase adjustment to a single exercise.
 * Scales sets (number), reps (ExerciseValue), and weight (ExerciseValue) independently
 * using phase-specific multipliers blended with readiness and confidence.
 *
 * Mirrors CycleAdaptationPolicy.applyPhaseAdjustment(exercise:phase:readinessTier:confidence:profile:).
 */
export function applyPhaseAdjustment(
  exercise: ProgramExercise,
  phase: CyclePhase,
  readinessTier: ReadinessTier,
  confidence: AdaptationConfidence,
  lowConfidenceScale: number = 0.7
): ProgramExercise {
  const settings = resolvePhaseSettings(phase);
  const rs = READINESS_SCALES[readinessTier];
  const cs = resolveConfidenceScale(confidence, lowConfidenceScale);

  const setsMultiplier = blendMultiplier(settings.sets, rs, cs);
  const repsMultiplier = blendMultiplier(settings.reps, rs, cs);
  const loadMultiplier = blendMultiplier(settings.load, rs, cs);

  return {
    ...exercise,
    sets: scaleSets(exercise.sets, setsMultiplier),
    reps: scaleExerciseValue(exercise.reps, repsMultiplier),
    weight: exercise.weight !== undefined
      ? scaleExerciseValue(exercise.weight, loadMultiplier)
      : undefined,
  };
}

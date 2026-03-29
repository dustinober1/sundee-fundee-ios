import type { CyclePhase, ExerciseValue } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type AdaptationReadinessTier = "low" | "neutral" | "high";
export type AdaptationConfidence = "low" | "medium" | "high";

export interface PhaseMultipliers {
  load: number;
  sets: number;
  reps: number;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

export const PHASE_MULTIPLIERS: Record<CyclePhase, PhaseMultipliers> = {
  menstrual:  { load: 0.90, sets: 0.90, reps: 0.90 },
  follicular: { load: 1.00, sets: 1.00, reps: 1.00 },
  ovulation:  { load: 1.12, sets: 1.05, reps: 0.95 },
  luteal:     { load: 0.97, sets: 0.95, reps: 0.92 },
};

const READINESS_SCALES: Record<AdaptationReadinessTier, number> = {
  low:     0.6,
  neutral: 1.0,
  high:    1.2,
};

const CONFIDENCE_SCALES: Record<AdaptationConfidence, number> = {
  low:    0.55,
  medium: 0.8,
  high:   1.0,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function adjustExerciseValue(value: ExerciseValue, multiplier: number): ExerciseValue {
  switch (value.type) {
    case "fixed":
      return { type: "fixed", value: Math.max(1, Math.round(value.value * multiplier)) };
    case "range": {
      const newLo = Math.max(1, Math.round(value.low * multiplier));
      const newHi = Math.max(newLo, Math.round(value.high * multiplier));
      return { type: "range", low: newLo, high: newHi };
    }
    case "amrap":
    case "text":
      return value;
  }
}

// ---------------------------------------------------------------------------
// resolveReadinessTier
// ---------------------------------------------------------------------------

export function resolveReadinessTier(score: number | undefined | null): AdaptationReadinessTier {
  if (score == null) return "neutral";
  if (score <= 3) return "low";
  if (score >= 8) return "high";
  return "neutral";
}

// ---------------------------------------------------------------------------
// resolveConfidence
// ---------------------------------------------------------------------------

export function resolveConfidence(
  currentPhase: CyclePhase | null | undefined,
  _lastKnownPhase: CyclePhase | null | undefined,
  periodLogCount: number,
  lastPeriodStart: Date | null | undefined,
  referenceDate: Date = new Date()
): AdaptationConfidence {
  if (periodLogCount === 0) return "low";

  if (lastPeriodStart) {
    const daysSince = (referenceDate.getTime() - lastPeriodStart.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSince > 60) return "medium";
  }

  if (currentPhase != null && periodLogCount >= 3) return "high";
  if (currentPhase != null) return "medium";
  return "low";
}

// ---------------------------------------------------------------------------
// applyPhaseAdjustment
// ---------------------------------------------------------------------------

import type { ProgramExercise } from "./types";

export function applyPhaseAdjustment(
  exercise: ProgramExercise,
  phase: CyclePhase,
  readinessTier: AdaptationReadinessTier,
  confidence: AdaptationConfidence
): ProgramExercise {
  const settings = PHASE_MULTIPLIERS[phase];
  const rs = READINESS_SCALES[readinessTier];
  const cs = CONFIDENCE_SCALES[confidence];

  function blendMultiplier(target: number): number {
    return clamp(1.0 + (target - 1.0) * rs * cs, 0.75, 1.25);
  }

  return {
    ...exercise,
    sets: adjustExerciseValue(exercise.sets, blendMultiplier(settings.sets)),
    reps: adjustExerciseValue(exercise.reps, blendMultiplier(settings.reps)),
    percent1RM: exercise.percent1RM != null
      ? clamp(exercise.percent1RM * blendMultiplier(settings.load), 0.4, 1.1)
      : undefined,
  };
}

import type { RecoveryPhase, ExerciseValue, ProgramExercise } from "./types";

// ---------------------------------------------------------------------------
// Load Multipliers
// ---------------------------------------------------------------------------

export interface LoadMultipliers {
  load: number;
  sets: number;
  reps: number;
}

export const LOAD_MULTIPLIERS: Record<RecoveryPhase, LoadMultipliers> = {
  acute:         { load: 0,    sets: 0,    reps: 0    },
  rehab:         { load: 0.30, sets: 0.50, reps: 0.70 },
  lightLoad:     { load: 0.50, sets: 0.75, reps: 0.85 },
  returnToPlay:  { load: 0.80, sets: 0.90, reps: 1.0  },
  resolved:      { load: 1.0,  sets: 1.0,  reps: 1.0  },
};

// ---------------------------------------------------------------------------
// adjustExerciseValueByMultiplier
// ---------------------------------------------------------------------------

export function adjustExerciseValueByMultiplier(
  value: ExerciseValue,
  multiplier: number
): ExerciseValue {
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
// adjustLoad
// ---------------------------------------------------------------------------

export function adjustLoad(
  percent1RM: number | undefined | null,
  multiplier: number
): number | undefined {
  if (percent1RM == null) return undefined;
  return percent1RM * multiplier;
}

// ---------------------------------------------------------------------------
// applyLoadMultipliers
// ---------------------------------------------------------------------------

export function applyLoadMultipliers(
  exercise: ProgramExercise,
  phase: RecoveryPhase
): ProgramExercise {
  const m = LOAD_MULTIPLIERS[phase];
  if (m.load >= 1.0 && m.sets >= 1.0 && m.reps >= 1.0) return exercise;
  return {
    ...exercise,
    sets: adjustExerciseValueByMultiplier(exercise.sets, m.sets),
    reps: adjustExerciseValueByMultiplier(exercise.reps, m.reps),
    percent1RM: adjustLoad(exercise.percent1RM, m.load),
  };
}

// ---------------------------------------------------------------------------
// Pain Log type (local — mirrors Swift PainLog)
// ---------------------------------------------------------------------------

export interface PainLog {
  injuryId: string;
  painLevel: number;   // 0-10
  recordedAt: Date;
}

// ---------------------------------------------------------------------------
// Pain Trend Analyzer
// ---------------------------------------------------------------------------

export interface TrendResult {
  trailingAverage: number;
  isImproving: boolean;
  latestPainLevel: number | null;
  readingCount: number;
}

/**
 * Analyzes pain trend from logs sorted newest-first.
 * windowSize: number of recent readings to consider.
 */
export function analyzePainTrend(
  logs: PainLog[],
  windowSize: number = 7
): TrendResult {
  if (logs.length === 0) {
    return { trailingAverage: 0, isImproving: false, latestPainLevel: null, readingCount: 0 };
  }

  // Sort newest first
  const sorted = [...logs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  const recent = sorted.slice(0, windowSize);
  const average = recent.reduce((sum, l) => sum + l.painLevel, 0) / recent.length;
  const latest = recent[0]?.painLevel ?? null;

  let improving = false;
  if (recent.length >= 2) {
    const midpoint = Math.floor(recent.length / 2);
    const newerHalf = recent.slice(0, midpoint);
    const olderHalf = recent.slice(midpoint);
    const newerAvg = newerHalf.reduce((s, l) => s + l.painLevel, 0) / newerHalf.length;
    const olderAvg = olderHalf.reduce((s, l) => s + l.painLevel, 0) / olderHalf.length;
    improving = newerAvg < olderAvg;
  }

  return {
    trailingAverage: average,
    isImproving: improving,
    latestPainLevel: latest,
    readingCount: logs.length,
  };
}

/**
 * Checks if a pain log has been recorded within the given hours window.
 * referenceDate defaults to now.
 */
export function hasRecentLog(
  logs: PainLog[],
  referenceDate: Date = new Date(),
  withinHours: number = 24
): boolean {
  if (logs.length === 0) return false;
  const cutoff = new Date(referenceDate.getTime() - withinHours * 3600 * 1000);
  return logs.some((l) => l.recordedAt >= cutoff);
}

/**
 * Returns the last N pain levels in chronological order (oldest first) for sparkline display.
 */
export function sparklineData(logs: PainLog[], count: number = 7): number[] {
  const sorted = [...logs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  return sorted.slice(0, count).map((l) => l.painLevel).reverse();
}

// ---------------------------------------------------------------------------
// Phase Transition Advisor
// ---------------------------------------------------------------------------

export interface TransitionSuggestion {
  injuryId: string;
  currentPhase: RecoveryPhase;
  suggestedPhase: RecoveryPhase;
}

const PHASE_TRANSITION_RULES: Array<{
  from: RecoveryPhase;
  to: RecoveryPhase;
  count: number;
  maxPain: number;
}> = [
  { from: "acute",        to: "rehab",         count: 3, maxPain: 5 },
  { from: "rehab",        to: "lightLoad",      count: 3, maxPain: 3 },
  { from: "lightLoad",    to: "returnToPlay",   count: 3, maxPain: 2 },
  { from: "returnToPlay", to: "resolved",       count: 5, maxPain: 1 },
];

function meetsThreshold(logs: PainLog[], count: number, maxPain: number): boolean {
  if (logs.length < count) return false;
  return logs.slice(0, count).every((l) => l.painLevel <= maxPain);
}

/**
 * Evaluates whether an injury is ready to advance to the next recovery phase.
 * Logs should be sorted newest-first.
 * Returns null if no transition is suggested.
 */
export function evaluateTransition(
  injuryId: string,
  currentPhase: RecoveryPhase,
  painLogs: PainLog[]
): TransitionSuggestion | null {
  // Sort newest first
  const sorted = [...painLogs].sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime());
  const recent = sorted.slice(0, 5);

  const rule = PHASE_TRANSITION_RULES.find((r) => r.from === currentPhase);
  if (!rule) return null;

  if (meetsThreshold(recent, rule.count, rule.maxPain)) {
    return { injuryId, currentPhase, suggestedPhase: rule.to };
  }
  return null;
}

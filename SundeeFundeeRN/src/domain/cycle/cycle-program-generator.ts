// =============================================================================
// CycleProgramGenerator — TypeScript port of CycleProgramGenerator.swift
// Adapts a Program's exercises for the user's current cycle phase.
// Pure function — returns a new Program object, never mutates input.
// =============================================================================

import { calculateCycleStatus } from './cycle-calculations';
import { applyPhaseAdjustment, resolveReadinessTier } from './cycle-adaptation-policy';
import type { CyclePhase, CycleSettings, PeriodLog, Program } from '../types';
import type { AdaptationConfidence } from './cycle-adaptation-policy';

// ---------------------------------------------------------------------------
// Confidence resolution (mirrors Swift CycleAdaptationPolicy.resolveConfidence)
// ---------------------------------------------------------------------------

/** @internal Exported for testing only */
export function resolveConfidence(
  currentPhase: CyclePhase | undefined,
  periodLogCount: number,
  lastPeriodStart: Date | undefined,
  referenceDate: Date
): AdaptationConfidence {
  if (periodLogCount === 0) return 'low';
  if (lastPeriodStart !== undefined) {
    const daysSince = (referenceDate.getTime() - lastPeriodStart.getTime()) / 86400000;
    if (daysSince > 45) return 'low';
  }
  if (currentPhase !== undefined && periodLogCount >= 3) return 'high';
  if (currentPhase !== undefined) return 'medium';
  return 'low';
}

// ---------------------------------------------------------------------------
// Main adapt function
// ---------------------------------------------------------------------------

/**
 * Adapt all sessions in a program for the user's current cycle phase.
 *
 * Mirrors CycleProgramGenerator.adaptProgram(_:phase:settings:preferences:periodLogs:referenceDate:readinessScore:).
 *
 * If periodLogs is empty, calculateCycleStatus returns undefined and the
 * function falls back to 'follicular' with low confidence. The program is
 * still adapted (unlike Swift which has an adaptationEnabled guard — the RN
 * adaptation is always applied since the caller controls whether to invoke it).
 *
 * @param program - The program to adapt
 * @param periodLogs - User's period log history
 * @param settings - User's cycle settings
 * @param referenceDate - Reference date (defaults to today)
 * @param readinessScore - Optional readiness survey score (1–10)
 */
export function adaptProgram(
  program: Program,
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  referenceDate: Date = new Date(),
  readinessScore?: number
): Program {
  const status = calculateCycleStatus(periodLogs, settings, referenceDate);
  const currentPhase = status?.currentPhase;

  // Fallback to follicular when no cycle data is available
  const effectivePhase: CyclePhase = currentPhase ?? 'follicular';

  const lastPeriodStart = periodLogs.length > 0
    ? periodLogs.reduce((latest, log) =>
        log.startDate > latest ? log.startDate : latest,
        periodLogs[0].startDate
      )
    : undefined;

  const confidence = resolveConfidence(
    currentPhase,
    periodLogs.length,
    lastPeriodStart,
    referenceDate
  );

  const readinessTier = resolveReadinessTier(readinessScore);

  const adaptedSessions = program.sessions.map(session => ({
    ...session,
    exercises: session.exercises.map(exercise =>
      applyPhaseAdjustment(exercise, effectivePhase, readinessTier, confidence)
    ),
  }));

  return {
    ...program,
    sessions: adaptedSessions,
  };
}

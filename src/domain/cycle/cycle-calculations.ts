// =============================================================================
// CycleCalculations — TypeScript port of CycleCalculations.swift
// Uses date-fns for all calendar arithmetic (exact Swift Calendar.current parity).
// Pure functions — no side effects.
// =============================================================================

import { startOfDay, differenceInCalendarDays, addDays } from 'date-fns';
import type { CyclePhase, CycleSettings, PeriodLog } from '../types';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

export interface PhaseBoundary {
  start: number;
  end: number;
}

export interface PhaseBoundaries {
  menstrual: PhaseBoundary;
  follicular: PhaseBoundary;
  ovulation: PhaseBoundary;
  luteal: PhaseBoundary;
}

export interface CycleStatusResult {
  currentPhase: CyclePhase;
  cycleDay: number;
  daysUntilNextPhase: number;
  predictedNextPeriod: Date;
  phaseStartDate: Date;
  phaseEndDate: Date;
}

// ---------------------------------------------------------------------------
// Phase boundaries
// ---------------------------------------------------------------------------

/**
 * Compute start/end cycle-day boundaries for each phase given cycle settings.
 * Mirrors CycleCalculations.getPhaseBoundaries(_:) exactly.
 */
export function getPhaseBoundaries(settings: CycleSettings): PhaseBoundaries {
  const cycleLen = settings.averageCycleLengthDays;
  const periodLen = settings.averagePeriodLengthDays;
  const lutealLen = settings.lutealPhaseLengthDays;

  const ovDay = cycleLen - lutealLen;
  const ovStart = Math.max(periodLen + 2, ovDay - 2);
  const ovEnd = Math.max(ovStart, Math.min(ovDay + 2, cycleLen - lutealLen + 2));
  const follicularEnd = Math.max(periodLen + 1, ovStart - 1);

  return {
    menstrual:  { start: 1,            end: periodLen     },
    follicular: { start: periodLen + 1, end: follicularEnd },
    ovulation:  { start: ovStart,       end: ovEnd         },
    luteal:     { start: ovEnd + 1,     end: cycleLen      },
  };
}

// ---------------------------------------------------------------------------
// Phase inference
// ---------------------------------------------------------------------------

/** Ordered cycle phases matching Swift CyclePhase.allCases */
const PHASE_ORDER: CyclePhase[] = ['menstrual', 'follicular', 'ovulation', 'luteal'];

/**
 * Infer the current cycle phase from a cycle-day number and settings.
 * Mirrors Swift's phase lookup loop in calculateCycleStatus.
 * Falls back to 'follicular' if no boundary matches (parity with Swift default).
 */
export function inferCurrentPhase(cycleDay: number, settings: CycleSettings): CyclePhase {
  const boundaries = getPhaseBoundaries(settings);
  for (const phase of PHASE_ORDER) {
    const b = boundaries[phase];
    if (cycleDay >= b.start && cycleDay <= b.end) {
      return phase;
    }
  }
  return 'follicular';
}

// ---------------------------------------------------------------------------
// Date helpers (private)
// ---------------------------------------------------------------------------

function daysBetween(from: Date, to: Date): number {
  return differenceInCalendarDays(startOfDay(to), startOfDay(from));
}

function isWithin(target: Date, start: Date, end: Date): boolean {
  const t = startOfDay(target).getTime();
  return t >= startOfDay(start).getTime() && t <= startOfDay(end).getTime();
}

// ---------------------------------------------------------------------------
// Main status calculation
// ---------------------------------------------------------------------------

/**
 * Calculate the full cycle status from period logs.
 * Returns undefined if no logs are provided.
 * Mirrors CycleCalculations.calculateCycleStatus(_:settings:referenceDate:) exactly.
 */
export function calculateCycleStatus(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  referenceDate: Date = new Date()
): CycleStatusResult | undefined {
  if (periodLogs.length === 0) return undefined;

  const ref = startOfDay(referenceDate);

  // Sort most-recent first (mirrors Swift: sorted { $0.startDate > $1.startDate })
  const sorted = [...periodLogs].sort(
    (a, b) => b.startDate.getTime() - a.startDate.getTime()
  );

  let cycleStartDate: Date | undefined;

  for (const period of sorted) {
    const pStart = startOfDay(period.startDate);
    const pEnd = period.endDate
      ? startOfDay(period.endDate)
      : addDays(pStart, settings.averagePeriodLengthDays - 1);

    if (isWithin(ref, pStart, pEnd)) {
      cycleStartDate = pStart;
      break;
    }
    const nextExpected = addDays(pStart, settings.averageCycleLengthDays);
    if (ref.getTime() > pEnd.getTime() && ref.getTime() < startOfDay(nextExpected).getTime()) {
      cycleStartDate = pStart;
      break;
    }
  }

  let cycleStart: Date;
  if (cycleStartDate !== undefined) {
    cycleStart = cycleStartDate;
  } else {
    // Fast-forward from most recent period by complete cycle lengths
    const most = sorted[0];
    let start = startOfDay(most.startDate);
    const daysSince = daysBetween(start, ref);
    const safeCycleLength = Math.max(1, settings.averageCycleLengthDays);
    const completed = Math.floor(daysSince / safeCycleLength);
    start = addDays(start, completed * safeCycleLength);
    cycleStart = start;
  }

  const cycleDay = daysBetween(cycleStart, ref) + 1;
  const boundaries = getPhaseBoundaries(settings);

  let currentPhase: CyclePhase = 'follicular';
  let phaseStartDay = 1;
  let phaseEndDay = settings.averageCycleLengthDays;

  for (const phase of PHASE_ORDER) {
    const b = boundaries[phase];
    if (cycleDay >= b.start && cycleDay <= b.end) {
      currentPhase = phase;
      phaseStartDay = b.start;
      phaseEndDay = b.end;
      break;
    }
  }

  let daysUntilNext: number;
  switch (currentPhase) {
    case 'menstrual':
      daysUntilNext = (boundaries.follicular.start) - cycleDay;
      break;
    case 'follicular':
      daysUntilNext = (boundaries.ovulation.start) - cycleDay;
      break;
    case 'ovulation':
      daysUntilNext = (boundaries.luteal.start) - cycleDay;
      break;
    case 'luteal':
      daysUntilNext = settings.averageCycleLengthDays - cycleDay + 1;
      break;
  }

  return {
    currentPhase,
    cycleDay,
    daysUntilNextPhase: Math.max(0, daysUntilNext),
    predictedNextPeriod: addDays(cycleStart, settings.averageCycleLengthDays),
    phaseStartDate: addDays(cycleStart, phaseStartDay - 1),
    phaseEndDate: addDays(cycleStart, phaseEndDay - 1),
  };
}

// ---------------------------------------------------------------------------
// Phase recommendation (informational — not used in adaptation pipeline)
// ---------------------------------------------------------------------------

export interface PhaseRecommendation {
  phase: CyclePhase;
  title: string;
  description: string;
  trainingFocus: string;
  intensityRecommendation: string;
  exercisesToEmphasize: string[];
  exercisesToAvoid: string[];
}

export function getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation {
  switch (phase) {
    case 'menstrual':
      return {
        phase,
        title: 'Menstrual Phase',
        description: 'Your period phase. Energy may be lower — you might feel more fatigued.',
        trainingFocus: 'Recovery and light movement',
        intensityRecommendation: 'low',
        exercisesToEmphasize: ['yoga', 'walking', 'light stretching'],
        exercisesToAvoid: ['heavy compound lifts', 'max effort attempts'],
      };
    case 'follicular':
      return {
        phase,
        title: 'Follicular Phase',
        description: 'Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.',
        trainingFocus: 'Building strength and endurance',
        intensityRecommendation: 'moderate',
        exercisesToEmphasize: ['compound movements', 'strength training', 'cardio'],
        exercisesToAvoid: [],
      };
    case 'ovulation':
      return {
        phase,
        title: 'Ovulation Phase',
        description: 'Peak estrogen and testosterone. Often the strongest phase for performance.',
        trainingFocus: 'High-intensity training and PR attempts',
        intensityRecommendation: 'peak',
        exercisesToEmphasize: ['max effort attempts', 'heavy compound lifts', 'power-focused workouts'],
        exercisesToAvoid: [],
      };
    case 'luteal':
      return {
        phase,
        title: 'Luteal Phase',
        description: 'Progesterone rises, which may affect recovery and energy. Focus on maintenance.',
        trainingFocus: 'Maintenance and technique refinement',
        intensityRecommendation: 'moderate',
        exercisesToEmphasize: ['technique work', 'volume training', 'recovery-focused sessions'],
        exercisesToAvoid: ['max effort attempts', 'extremely heavy loads'],
      };
  }
}

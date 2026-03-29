import type { CyclePhase } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CycleSettings {
  averageCycleLengthDays: number;
  averagePeriodLengthDays: number;
  lutealPhaseLengthDays: number;
}

export interface PeriodLog {
  startDate: Date;
  endDate?: Date;
}

export interface PhaseBoundary {
  start: number;
  end: number;
}

export interface CycleStatusResult {
  currentPhase: CyclePhase;
  cycleDay: number;
  daysUntilNextPhase: number;
  predictedNextPeriod: Date;
  phaseStartDate: Date;
  phaseEndDate: Date;
}

export interface PhaseRecommendation {
  phase: CyclePhase;
  title: string;
  description: string;
  trainingFocus: string;
  intensityRecommendation: string;
  exercisesToEmphasize: string[];
  exercisesToAvoid: string[];
}

// ---------------------------------------------------------------------------
// Date helpers
// ---------------------------------------------------------------------------

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function addDays(date: Date, days: number): Date {
  const d = startOfDay(date);
  d.setDate(d.getDate() + days);
  return d;
}

function daysBetween(from: Date, to: Date): number {
  const f = startOfDay(from).getTime();
  const t = startOfDay(to).getTime();
  return Math.round((t - f) / (1000 * 60 * 60 * 24));
}

function isWithin(target: Date, start: Date, end: Date): boolean {
  const t = startOfDay(target).getTime();
  return t >= startOfDay(start).getTime() && t <= startOfDay(end).getTime();
}

// ---------------------------------------------------------------------------
// Phase Boundaries
// ---------------------------------------------------------------------------

export function getPhaseBoundaries(
  settings: CycleSettings
): Record<CyclePhase, PhaseBoundary> {
  const { averageCycleLengthDays: cycleLen, averagePeriodLengthDays: periodLen, lutealPhaseLengthDays: lutealLen } = settings;

  const ovDay = cycleLen - lutealLen;
  const ovStart = Math.max(periodLen + 2, ovDay - 2);
  const ovEnd = Math.min(ovDay + 2, cycleLen - lutealLen + 2);

  return {
    menstrual:  { start: 1,             end: periodLen },
    follicular: { start: periodLen + 1, end: ovStart - 1 },
    ovulation:  { start: ovStart,       end: ovEnd },
    luteal:     { start: ovEnd + 1,     end: cycleLen },
  };
}

// ---------------------------------------------------------------------------
// calculateCycleStatus
// ---------------------------------------------------------------------------

export function calculateCycleStatus(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  referenceDate: Date = new Date()
): CycleStatusResult | null {
  if (periodLogs.length === 0) return null;

  const ref = startOfDay(referenceDate);
  const sorted = [...periodLogs].sort(
    (a, b) => startOfDay(b.startDate).getTime() - startOfDay(a.startDate).getTime()
  );

  let cycleStartDate: Date | null = null;

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
    if (ref > pEnd && ref < nextExpected) {
      cycleStartDate = pStart;
      break;
    }
  }

  let cycleStart: Date;
  if (cycleStartDate) {
    cycleStart = cycleStartDate;
  } else {
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

  const phases: CyclePhase[] = ["menstrual", "follicular", "ovulation", "luteal"];
  let currentPhase: CyclePhase = "follicular";
  let phaseStartDay = 1;
  let phaseEndDay = settings.averageCycleLengthDays;

  for (const phase of phases) {
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
    case "menstrual":
      daysUntilNext = (boundaries.follicular?.start ?? cycleDay) - cycleDay;
      break;
    case "follicular":
      daysUntilNext = (boundaries.ovulation?.start ?? cycleDay) - cycleDay;
      break;
    case "ovulation":
      daysUntilNext = (boundaries.luteal?.start ?? cycleDay) - cycleDay;
      break;
    case "luteal":
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
// getPhaseRecommendation
// ---------------------------------------------------------------------------

export function getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation {
  switch (phase) {
    case "menstrual":
      return {
        phase: "menstrual",
        title: "Menstrual Phase",
        description: "Your period phase. Energy may be lower — you might feel more fatigued.",
        trainingFocus: "Recovery and light movement",
        intensityRecommendation: "low",
        exercisesToEmphasize: ["yoga", "walking", "light stretching"],
        exercisesToAvoid: ["heavy compound lifts", "max effort attempts"],
      };
    case "follicular":
      return {
        phase: "follicular",
        title: "Follicular Phase",
        description: "Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.",
        trainingFocus: "Building strength and endurance",
        intensityRecommendation: "moderate",
        exercisesToEmphasize: ["compound movements", "strength training", "cardio"],
        exercisesToAvoid: [],
      };
    case "ovulation":
      return {
        phase: "ovulation",
        title: "Ovulation Phase",
        description: "Peak estrogen and testosterone. Often the strongest phase for performance.",
        trainingFocus: "High-intensity training and PR attempts",
        intensityRecommendation: "peak",
        exercisesToEmphasize: ["max effort attempts", "heavy compound lifts", "power-focused workouts"],
        exercisesToAvoid: [],
      };
    case "luteal":
      return {
        phase: "luteal",
        title: "Luteal Phase",
        description: "Progesterone rises, which may affect recovery and energy. Focus on maintenance.",
        trainingFocus: "Maintenance and technique refinement",
        intensityRecommendation: "moderate",
        exercisesToEmphasize: ["technique work", "volume training", "recovery-focused sessions"],
        exercisesToAvoid: ["max effort attempts", "extremely heavy loads"],
      };
  }
}

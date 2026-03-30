import type { CyclePhase } from "./types";
import { getPhaseBoundaries, calculateCycleStatus, type CycleSettings, type PeriodLog } from "./cycle-calculations";

// ---------------------------------------------------------------------------
// getPhaseForDay
// ---------------------------------------------------------------------------

export function getPhaseForDay(cycleDay: number, settings: CycleSettings): CyclePhase {
  const len = Math.max(1, settings.averageCycleLengthDays);
  let normalized: number;

  if (cycleDay <= 0) {
    normalized = len + cycleDay;
    if (normalized <= 0) normalized = ((normalized - 1) % len + len) % len + 1;
  } else {
    normalized = ((cycleDay - 1) % len + len) % len + 1;
  }

  const boundaries = getPhaseBoundaries(settings);
  const phases: CyclePhase[] = ["menstrual", "follicular", "ovulation", "luteal"];

  for (const phase of phases) {
    const b = boundaries[phase];
    if (normalized >= b.start && normalized <= b.end) {
      return phase;
    }
  }

  return "luteal";
}

// ---------------------------------------------------------------------------
// getPhaseAdjustmentSummary
// ---------------------------------------------------------------------------

export function getPhaseAdjustmentSummary(phase: CyclePhase): string {
  switch (phase) {
    case "menstrual":
      return "Recovery focus — load -10%, volume -10%";
    case "follicular":
      return "baseline — no adjustments, building phase";
    case "ovulation":
      return "Peak performance — load +12%, sets +5%";
    case "luteal":
      return "Maintenance — load -3%, volume -8%";
  }
}

// ---------------------------------------------------------------------------
// getPhaseExplanation
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CalendarDayData {
  date: Date;
  cycleDay: number | null;
  phase: CyclePhase | null;
  isToday: boolean;
  isPeriodLogged: boolean;
}

// ---------------------------------------------------------------------------
// getCycleCalendarData
// ---------------------------------------------------------------------------

export function getCycleCalendarData(
  periodLogs: PeriodLog[],
  settings: CycleSettings,
  month: number,
  year: number
): CalendarDayData[] {
  const today = new Date();
  const todayStr = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`;
  const daysInMonth = new Date(year, month, 0).getDate();
  const result: CalendarDayData[] = [];

  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day);
    const dateStr = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
    const isToday = dateStr === todayStr;

    const status = calculateCycleStatus(periodLogs, settings, date);

    const isPeriodLogged = periodLogs.some((log) => {
      const start = new Date(log.startDate);
      start.setHours(0, 0, 0, 0);
      const end = log.endDate
        ? new Date(log.endDate)
        : new Date(start.getFullYear(), start.getMonth(), start.getDate() + settings.averagePeriodLengthDays - 1);
      end.setHours(23, 59, 59, 999);
      return date >= start && date <= end;
    });

    result.push({
      date,
      cycleDay: status?.cycleDay ?? null,
      phase: status?.currentPhase ?? null,
      isToday,
      isPeriodLogged,
    });
  }

  return result;
}

export function getPhaseExplanation(phase: CyclePhase): string {
  switch (phase) {
    case "menstrual":
      return "During menstruation, your body is actively recovering. Energy and iron levels may be lower, so we reduce load and volume to support recovery while keeping you active.";
    case "follicular":
      return "Rising estrogen supports muscle growth and endurance. This is your building phase — no adjustments needed, train at your normal capacity.";
    case "ovulation":
      return "Peak estrogen and testosterone create an optimal window for strength. Your body can handle higher loads and intensity — this is your time to push for PRs.";
    case "luteal":
      return "Progesterone rises, which may affect recovery and thermoregulation. We slightly reduce load and volume to match your body's shifting priorities. Toggle off if you're feeling strong.";
  }
}

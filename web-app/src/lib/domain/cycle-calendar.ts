import type { CyclePhase } from "./types";
import { getPhaseBoundaries, type CycleSettings } from "./cycle-calculations";

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

import type { WeightUnit, BenchmarkScoringType } from "./types";
import { fromKilograms, formatWeight } from "./weight-unit-conversion";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type CelebrationEvent =
  | { type: "workoutCompleted"; durationSeconds: number }
  | { type: "newPersonalRecord"; exerciseName: string; weightKg: number }
  | { type: "programCompleted"; programName: string }
  | { type: "weightMilestone"; exerciseName: string; thresholdKg: number }
  | { type: "newConditioningPR"; exerciseName: string; value: number; scoringType: BenchmarkScoringType };

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

function formatConditioningValue(value: number, scoringType: BenchmarkScoringType): string {
  if (scoringType === "time") {
    const totalSeconds = Math.floor(value);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${String(seconds).padStart(2, "0")}`;
  }
  if (scoringType === "reps") {
    const count = Math.floor(value);
    return count === 1 ? "1 rep" : `${count} reps`;
  }
  if (scoringType === "roundsAndReps") {
    const rounds = Math.floor(value / 10000);
    const reps = Math.floor(value) % 10000;
    return `${rounds} rounds + ${reps} reps`;
  }
  if (scoringType === "distance") {
    return `${value} m`;
  }
  // weight
  return `${value} kg`;
}

// ---------------------------------------------------------------------------
// celebrationTitle
// ---------------------------------------------------------------------------

export function celebrationTitle(event: CelebrationEvent): string {
  switch (event.type) {
    case "workoutCompleted":
      return "Workout Complete!";
    case "newPersonalRecord":
      return "New Personal Record!";
    case "programCompleted":
      return "Program Complete!";
    case "weightMilestone":
      return "Weight Milestone!";
    case "newConditioningPR":
      return "New Conditioning PR!";
  }
}

// ---------------------------------------------------------------------------
// celebrationSubtitle
// ---------------------------------------------------------------------------

export function celebrationSubtitle(
  event: CelebrationEvent,
  unit: (typeof WeightUnit)[keyof typeof WeightUnit] = "kg"
): string {
  switch (event.type) {
    case "workoutCompleted": {
      const minutes = Math.floor(event.durationSeconds / 60);
      return minutes > 0 ? `Completed in ${minutes} min` : "Workout saved!";
    }
    case "newPersonalRecord": {
      const converted = fromKilograms(event.weightKg, unit);
      const formatted = `${formatWeight(converted)} ${unit}`;
      return `${event.exerciseName} — ${formatted} estimated 1RM`;
    }
    case "programCompleted":
      return `You finished ${event.programName}. Time to level up!`;
    case "weightMilestone": {
      const converted = fromKilograms(event.thresholdKg, unit);
      const formatted = `${Math.round(converted)} ${unit}`;
      return `${event.exerciseName} hit ${formatted}!`;
    }
    case "newConditioningPR": {
      const formatted = formatConditioningValue(event.value, event.scoringType);
      return `${event.exerciseName} — ${formatted}`;
    }
  }
}

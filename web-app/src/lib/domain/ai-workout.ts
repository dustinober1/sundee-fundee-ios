import type { CyclePhase } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type WorkoutFocus =
  | "upper_body"
  | "lower_body"
  | "full_body"
  | "push"
  | "pull"
  | "core"
  | "conditioning";

export type EnergyLevel = "low" | "medium" | "high";

export type EquipmentAccess =
  | "full_gym"
  | "home_dumbbells"
  | "bodyweight_only"
  | "outdoor";

export interface QuestionnaireAnswers {
  timeMinutes: number;
  focus: WorkoutFocus;
  energyLevel: EnergyLevel;
  equipment: EquipmentAccess;
}

export interface GeneratedExercise {
  id: string;
  name: string;
  sets: number;
  reps: string;   // "8-10", "5", "AMRAP"
  weightKg?: number;
  restMinutes?: number;
  notes?: string;
  reasoning?: string;
  bodyweightOnly: boolean;
}

export interface GeneratedWorkout {
  id: string;
  createdAt: Date;
  isFavorite: boolean;
  coachingSummary: string;
  exercises: GeneratedExercise[];
  questionnaire: QuestionnaireAnswers;
}

export interface ExerciseMax {
  name: string;
  weightKg: number;
}

// ---------------------------------------------------------------------------
// extractMuscleGroups
// ---------------------------------------------------------------------------

export function extractMuscleGroups(exercises: GeneratedExercise[]): string[] {
  const groups = new Set<string>();
  for (const ex of exercises) {
    const name = ex.name.toLowerCase();
    if (name.includes("squat") || name.includes("lunge") || name.includes("leg press")) {
      groups.add("Quads");
    }
    if (name.includes("deadlift") || name.includes("hip thrust") || name.includes("glute")) {
      groups.add("Glutes");
    }
    if (name.includes("bench") || name.includes("push") || name.includes("chest") || name.includes("fly")) {
      groups.add("Chest");
    }
    if (name.includes("row") || name.includes("pull") || name.includes("lat")) {
      groups.add("Back");
    }
    if (name.includes("press") && (name.includes("overhead") || name.includes("shoulder") || name.includes("military"))) {
      groups.add("Shoulders");
    }
    if (name.includes("curl") || name.includes("bicep")) {
      groups.add("Biceps");
    }
    if (name.includes("tricep") || name.includes("extension") || name.includes("dip")) {
      groups.add("Triceps");
    }
    if (name.includes("core") || name.includes("plank") || name.includes("crunch") || name.includes("ab")) {
      groups.add("Core");
    }
    if (name.includes("calf")) {
      groups.add("Calves");
    }
    if (name.includes("hamstring") || name.includes("romanian") || name.includes("nordic")) {
      groups.add("Hamstrings");
    }
  }
  return [...groups].sort();
}

// ---------------------------------------------------------------------------
// defaultPercentage
// ---------------------------------------------------------------------------

export function defaultPercentage(reps: string): number {
  const repCount = parseInt(reps.split("-")[0] ?? "", 10);
  const count = isNaN(repCount) ? 10 : repCount;
  if (count >= 1 && count <= 3) return 0.85;
  if (count >= 4 && count <= 5) return 0.80;
  if (count >= 6 && count <= 8) return 0.70;
  if (count >= 9 && count <= 12) return 0.65;
  return 0.60;
}

// ---------------------------------------------------------------------------
// assignRestMinutes
// ---------------------------------------------------------------------------

export function assignRestMinutes(bodyweight: boolean, reps: string): number {
  if (bodyweight) return 1.0;
  const repCount = parseInt(reps.split("-")[0] ?? "", 10);
  const count = isNaN(repCount) ? 10 : repCount;
  if (count >= 1 && count <= 5) return 2.5;
  if (count >= 6 && count <= 8) return 2.0;
  if (count >= 9 && count <= 12) return 1.5;
  return 1.0;
}

// ---------------------------------------------------------------------------
// totalEstimatedMinutes
// ---------------------------------------------------------------------------

export function totalEstimatedMinutes(exercises: GeneratedExercise[]): number {
  const total = exercises.reduce((sum, ex) => {
    const rest = ex.restMinutes ?? 1.5;
    return sum + ex.sets * (rest + 0.5);
  }, 0);
  return Math.max(1, Math.round(total));
}

// ---------------------------------------------------------------------------
// energyMultiplier
// ---------------------------------------------------------------------------

export function energyMultiplier(level: EnergyLevel): number {
  switch (level) {
    case "low":    return 0.85;
    case "medium": return 1.0;
    case "high":   return 1.05;
  }
}

// ---------------------------------------------------------------------------
// cyclePhaseMultiplier
// ---------------------------------------------------------------------------

export function cyclePhaseMultiplier(phase: CyclePhase | string | undefined | null): number {
  if (phase == null) return 1.0;
  switch ((phase as string).toLowerCase()) {
    case "menstrual":  return 0.90;
    case "follicular": return 1.00;
    case "ovulation":  return 1.12;
    case "luteal":     return 0.97;
    default:           return 1.0;
  }
}

// ---------------------------------------------------------------------------
// applyWeights
// ---------------------------------------------------------------------------

export function applyWeights(
  exercises: GeneratedExercise[],
  maxes: ExerciseMax[],
  energyMult: number,
  cycleMult: number
): GeneratedExercise[] {
  return exercises.map((ex) => {
    if (ex.bodyweightOnly) return ex;

    const matched = findMatchingMax(ex.name, maxes);
    if (!matched) return ex;

    const pct = defaultPercentage(ex.reps);
    const raw = matched.weightKg * pct * energyMult * cycleMult;
    const rounded = Math.round(raw / 5) * 5; // round to nearest 5

    return { ...ex, weightKg: rounded };
  });
}

// ---------------------------------------------------------------------------
// findMatchingMax (fuzzy)
// ---------------------------------------------------------------------------

export function findMatchingMax(exerciseName: string, maxes: ExerciseMax[]): ExerciseMax | null {
  const lower = exerciseName.toLowerCase();
  const exact = maxes.find((m) => m.name.toLowerCase() === lower);
  if (exact) return exact;
  return maxes.find((m) =>
    m.name.toLowerCase().includes(lower) || lower.includes(m.name.toLowerCase())
  ) ?? null;
}

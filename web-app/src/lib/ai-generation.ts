import {
  requireFiniteNumber,
  requireOneOf,
} from "./write-validation";
import type {
  CyclePhase,
  EnergyLevel,
  EquipmentAccess,
  GeneratedExercise,
  WorkoutFocus,
} from "./domain";
import { type SubscriptionTier } from "./domain";

const WORKOUT_FOCUS_VALUES = [
  "upper_body",
  "lower_body",
  "full_body",
  "push",
  "pull",
  "core",
  "conditioning",
] as const;

const ENERGY_VALUES = ["low", "medium", "high"] as const;
const EQUIPMENT_VALUES = [
  "full_gym",
  "home_dumbbells",
  "bodyweight_only",
  "outdoor",
] as const;

const CYCLE_PHASE_VALUES = ["menstrual", "follicular", "ovulation", "luteal"] as const;

export interface AIModelConfig {
  model: string | null;
  temperature: number;
  maxOutputTokens: number;
}

export interface AIWorkoutRequest {
  time: number;
  focus: WorkoutFocus;
  energy: EnergyLevel;
  equipment: EquipmentAccess;
  cyclePhase?: CyclePhase;
}

export interface AIWorkoutResponse {
  coachingSummary: string;
  exercises: GeneratedExercise[];
  usage: {
    tier: SubscriptionTier;
    model: string | null;
    generatedToday: number;
    remainingCloudGenerations: number;
    dailyCloudLimit: number;
  };
}

export const AI_MODEL_CONFIG: Record<SubscriptionTier, AIModelConfig> = {
  free: {
    model: null,
    temperature: 0.7,
    maxOutputTokens: 2048,
  },
  plus: {
    model: process.env.GEMINI_MODEL ?? "models/gemini-flash-lite-latest",
    temperature: 0.7,
    maxOutputTokens: 2048,
  },
  premium: {
    model: process.env.GEMINI_PREMIUM_MODEL ?? "models/gemini-flash-latest",
    temperature: 0.8,
    maxOutputTokens: 3072,
  },
};

export function validateAIWorkoutRequest(raw: unknown): AIWorkoutRequest {
  const data = (raw ?? {}) as Record<string, unknown>;
  const time = requireFiniteNumber(Number(data.time), "time", {
    integer: true,
    min: 15,
    max: 90,
  });

  const focus = requireOneOf(String(data.focus ?? ""), WORKOUT_FOCUS_VALUES, "focus");
  const energy = requireOneOf(String(data.energy ?? ""), ENERGY_VALUES, "energy");
  const equipment = requireOneOf(String(data.equipment ?? ""), EQUIPMENT_VALUES, "equipment");

  let cyclePhase: CyclePhase | undefined;
  if (data.cyclePhase != null) {
    cyclePhase = requireOneOf(
      String(data.cyclePhase),
      CYCLE_PHASE_VALUES,
      "cyclePhase"
    );
  }

  return { time, focus, energy, equipment, cyclePhase };
}

export function getAIModelConfig(tier: SubscriptionTier): AIModelConfig {
  return AI_MODEL_CONFIG[tier];
}

export function buildWorkoutSystemInstruction(): string {
  return "You are a certified strength and conditioning coach designing personalized workouts. Return ONLY valid JSON. No markdown fences, no commentary outside the JSON.";
}

export function buildWorkoutPrompt(request: AIWorkoutRequest): string {
  return [
    "Create one workout for the athlete using the following inputs.",
    `Time available: ${request.time} minutes`,
    `Workout focus: ${request.focus.replaceAll("_", " ")}`,
    `Energy level: ${request.energy}`,
    `Equipment access: ${request.equipment.replaceAll("_", " ")}`,
    request.cyclePhase ? `Cycle phase: ${request.cyclePhase}` : "Cycle phase: not provided",
    "Return a JSON object with:",
    '- "coachingSummary": 2-3 short sentences',
    '- "exercises": an array of 4-8 exercises',
    'Each exercise must include "name", "sets", "reps", and "bodyweightOnly".',
    'Optional fields: "weightKg", "restMinutes", "notes", "reasoning".',
    'Use reps as a string like "5", "8-10", or "AMRAP".',
    "Keep the workout realistic for the requested time and equipment.",
  ].join("\n");
}

function stripCodeFences(text: string): string {
  const trimmed = text.trim();
  if (!trimmed.startsWith("```")) return trimmed;
  return trimmed.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
}

function isGeneratedExercise(value: unknown, index: number): value is GeneratedExercise {
  const ex = value as Record<string, unknown>;
  return typeof ex === "object" &&
    ex !== null &&
    typeof ex.name === "string" &&
    typeof ex.sets === "number" &&
    typeof ex.reps === "string" &&
    typeof ex.bodyweightOnly === "boolean" &&
    (ex.id == null || typeof ex.id === "string" || ex.id === `ex-${index + 1}`);
}

export function parseAIWorkoutResponse(rawText: string): { coachingSummary: string; exercises: GeneratedExercise[] } {
  const cleaned = stripCodeFences(rawText);
  const parsed = JSON.parse(cleaned) as Record<string, unknown>;
  if (typeof parsed.coachingSummary !== "string" || !Array.isArray(parsed.exercises)) {
    throw new Error("AI response did not match expected workout schema.");
  }

  const exercises = parsed.exercises.map((item, index) => {
    const value = item as Record<string, unknown>;
    const exercise: GeneratedExercise = {
      id: typeof value.id === "string" ? value.id : `ex-${index + 1}`,
      name: String(value.name ?? ""),
      sets: Number(value.sets ?? 0),
      reps: String(value.reps ?? ""),
      bodyweightOnly: Boolean(value.bodyweightOnly),
      weightKg: typeof value.weightKg === "number" ? value.weightKg : undefined,
      restMinutes: typeof value.restMinutes === "number" ? value.restMinutes : undefined,
      notes: typeof value.notes === "string" ? value.notes : undefined,
      reasoning: typeof value.reasoning === "string" ? value.reasoning : undefined,
    };

    if (!isGeneratedExercise(exercise, index) || !exercise.name.trim() || exercise.sets <= 0 || !exercise.reps.trim()) {
      throw new Error("AI response contained an invalid exercise.");
    }

    return exercise;
  });

  return {
    coachingSummary: parsed.coachingSummary,
    exercises,
  };
}

// ExerciseValue — discriminated union matching Swift ExerciseValue
export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; value: string };

export function exerciseValueToString(ev: ExerciseValue): string {
  switch (ev.type) {
    case "fixed": return String(ev.value);
    case "amrap": return "AMRAP";
    case "range": return `${ev.low}\u2013${ev.high}`;
    case "text": return ev.value;
  }
}

export function decodeExerciseValue(raw: unknown): ExerciseValue {
  if (typeof raw === "number") return { type: "fixed", value: Math.floor(raw) };
  if (Array.isArray(raw) && raw.length === 2 && typeof raw[0] === "number" && typeof raw[1] === "number") {
    return { type: "range", low: raw[0], high: raw[1] };
  }
  if (typeof raw === "string") {
    const trimmed = raw.trim();
    if (trimmed.toUpperCase() === "AMRAP") return { type: "amrap" };
    if (trimmed.includes("-")) {
      const parts = trimmed.split("-");
      if (parts.length === 2) {
        const lo = parseInt(parts[0].trim(), 10);
        const hi = parseInt(parts[1].trim(), 10);
        if (!isNaN(lo) && !isNaN(hi)) return { type: "range", low: lo, high: hi };
      }
    }
    const n = parseInt(trimmed, 10);
    if (!isNaN(n) && String(n) === trimmed) return { type: "fixed", value: n };
    return { type: "text", value: raw };
  }
  return { type: "fixed", value: 0 };
}

export function encodeExerciseValue(ev: ExerciseValue): unknown {
  switch (ev.type) {
    case "fixed": return ev.value;
    case "amrap": return "AMRAP";
    case "range": return [ev.low, ev.high];
    case "text": return ev.value;
    default: return null;
  }
}

// Program types
export interface ProgramExercise {
  exercise: string;
  variant?: string;
  sets: ExerciseValue;
  reps: ExerciseValue;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export interface ProgramSession {
  sessionId: string;
  sessionName: string;
  sessionType: string;
  focus: string;
  exercises: ProgramExercise[];
}

export interface ProgramWeek {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: ProgramSession[];
}

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
}

export interface ProgramPhaseAdjustmentSettings {
  loadMultiplier: number;
  setsMultiplier: number;
  repsMultiplier: number;
}

export interface ProgramCycleAdjustmentProfile {
  fallbackPhase: string;
  lowConfidenceScale: number;
  phaseSettings: Record<string, ProgramPhaseAdjustmentSettings>;
}

export interface Program {
  id: string;
  name: string;
  category: string;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: string;
  phases: ProgramPhase[];
  weeks: ProgramWeek[];
  cycleAdjustmentProfile?: ProgramCycleAdjustmentProfile;
  status?: "draft" | "published";
}

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

// Enums
export const ExperienceLevel = { beginner: "beginner", intermediate: "intermediate", advanced: "advanced" } as const;
export type ExperienceLevel = (typeof ExperienceLevel)[keyof typeof ExperienceLevel];

export const PrimaryGoal = { strength: "strength", hypertrophy: "hypertrophy", endurance: "endurance", weightLoss: "weight_loss" } as const;
export type PrimaryGoal = (typeof PrimaryGoal)[keyof typeof PrimaryGoal];

export const Gender = { male: "male", female: "female", preferNotToSay: "prefer_not_to_say" } as const;
export type Gender = (typeof Gender)[keyof typeof Gender];

export const WeightUnit = { kilograms: "kg", pounds: "lb" } as const;
export type WeightUnit = (typeof WeightUnit)[keyof typeof WeightUnit];

export const RecoveryPhase = { acute: "acute", rehab: "rehab", lightLoad: "lightLoad", returnToPlay: "returnToPlay", resolved: "resolved" } as const;
export type RecoveryPhase = (typeof RecoveryPhase)[keyof typeof RecoveryPhase];

export const CyclePhase = { menstrual: "menstrual", follicular: "follicular", ovulation: "ovulation", luteal: "luteal" } as const;
export type CyclePhase = (typeof CyclePhase)[keyof typeof CyclePhase];

export const BenchmarkScoringType = { time: "time", reps: "reps", weight: "weight", distance: "distance", roundsAndReps: "roundsAndReps", height: "height" } as const;
export type BenchmarkScoringType = (typeof BenchmarkScoringType)[keyof typeof BenchmarkScoringType];

export const ConditioningScoringType = { time: "time", reps: "reps" } as const;
export type ConditioningScoringType = (typeof ConditioningScoringType)[keyof typeof ConditioningScoringType];

export const SessionResult = { first: "first", success: "success", failure: "failure" } as const;
export type SessionResult = (typeof SessionResult)[keyof typeof SessionResult];

export const SubscriptionTier = { free: "free", plus: "plus", premium: "premium" } as const;
export type SubscriptionTier = (typeof SubscriptionTier)[keyof typeof SubscriptionTier];

import { encodeExerciseValue, decodeExerciseValue, BenchmarkScoringType, ProgramExercise } from "./types";

// Re-export shared types from domain/types so consumers can import from admin-types
export type {
  ExerciseValue,
  ProgramExercise,
  ProgramPhase,
  ProgramSession,
  ProgramWeek,
  ProgramCycleAdjustmentProfile,
  ProgramPhaseAdjustmentSettings,
  Program,
  WOD,
  BenchmarkScoringType,
} from "./types";

export { encodeExerciseValue, decodeExerciseValue } from "./types";

// Re-export BenchmarkDefinition from benchmark-catalog (canonical definition)
export type { BenchmarkDefinition } from "./benchmark-catalog";

// ExerciseValueJSON — typed representation of the wire/Firestore format
// (admin-specific; types.ts uses `unknown` for the decode input)
export type ExerciseValueJSON = number | string | [number, number];

export interface ProgramExerciseFirestore {
  exercise: string;
  variant?: string;
  sets: ExerciseValueJSON;
  reps: ExerciseValueJSON;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export function exerciseToFirestore(ex: ProgramExercise): ProgramExerciseFirestore {
  const result: ProgramExerciseFirestore = {
    exercise: ex.exercise,
    sets: encodeExerciseValue(ex.sets) as ExerciseValueJSON,
    reps: encodeExerciseValue(ex.reps) as ExerciseValueJSON,
  };
  if (ex.variant !== undefined) result.variant = ex.variant;
  if (ex.percent1RM !== undefined) result.percent1RM = ex.percent1RM;
  if (ex.restMinutes !== undefined) result.restMinutes = ex.restMinutes;
  if (ex.notes !== undefined) result.notes = ex.notes;
  if (ex.bodyweightOnly !== undefined) result.bodyweightOnly = ex.bodyweightOnly;
  return result;
}

export function exerciseFromFirestore(json: ProgramExerciseFirestore): ProgramExercise {
  const result: ProgramExercise = {
    exercise: json.exercise,
    sets: decodeExerciseValue(json.sets),
    reps: decodeExerciseValue(json.reps),
  };
  if (json.variant !== undefined) result.variant = json.variant;
  if (json.percent1RM !== undefined) {
    result.percent1RM = json.percent1RM > 1.5 ? json.percent1RM / 100 : json.percent1RM;
  }
  if (json.restMinutes !== undefined) result.restMinutes = json.restMinutes;
  if (json.notes !== undefined) result.notes = json.notes;
  if (json.bodyweightOnly !== undefined) result.bodyweightOnly = json.bodyweightOnly;
  return result;
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/[\s-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  author: string;
  date: string;
  tags: string[];
  image?: string;
  content: string;
  status: "draft" | "published";
  publishedAt?: string;
  updatedAt: string;
}

export interface SupportArticle {
  slug: string;
  title: string;
  content: string;
  sortOrder: number;
  status: "draft" | "published";
  updatedAt: string;
}

export type CatalogEquipment =
  | "barbell"
  | "dumbbell"
  | "kettlebell"
  | "machine"
  | "cable"
  | "bodyweight"
  | "band"
  | "cardio"
  | "other";

export interface CatalogExercise {
  id: string;
  name: string;
  category: string;
  subcategory?: string;
  equipment?: CatalogEquipment;
  scoring?: BenchmarkScoringType;
}

export interface AdminUser {
  email: string;
  role: string;
  addedAt: string;
}

export interface AiModelConfig {
  temperature: number;
  maxTokens: number;
}

export interface AiPrompt {
  id: string;
  name: string;
  description: string;
  promptText: string;
  modelConfig: AiModelConfig;
  updatedAt: string;
}

export interface AdminSettings {
  rateLimits: {
    free: number;
    plus: number;
    premium: number;
  };
  featureFlags: Record<string, boolean>;
}


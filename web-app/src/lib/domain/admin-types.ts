export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; text: string };

export type ExerciseValueJSON = number | string | [number, number];

export function encodeExerciseValue(val: ExerciseValue): ExerciseValueJSON {
  switch (val.type) {
    case "fixed": return val.value;
    case "amrap": return "AMRAP";
    case "range": return [val.low, val.high];
    case "text": return val.text;
  }
}

export function decodeExerciseValue(raw: ExerciseValueJSON): ExerciseValue {
  if (Array.isArray(raw) && raw.length === 2) {
    return { type: "range", low: raw[0], high: raw[1] };
  }
  if (typeof raw === "number") {
    return { type: "fixed", value: Math.trunc(raw) };
  }
  if (typeof raw === "string") {
    if (raw.toLowerCase() === "amrap") return { type: "amrap" };
    const hyphen = raw.match(/^(\d+)-(\d+)$/);
    if (hyphen) return { type: "range", low: Number(hyphen[1]), high: Number(hyphen[2]) };
    if (/^\d+$/.test(raw)) return { type: "fixed", value: Number(raw) };
    return { type: "text", text: raw };
  }
  return { type: "text", text: String(raw) };
}

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
    sets: encodeExerciseValue(ex.sets),
    reps: encodeExerciseValue(ex.reps),
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

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
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
}

export interface BenchmarkDefinition {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringTypeRaw: string;
  sortOrder: number;
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

export interface CatalogExercise {
  id: string;
  name: string;
  category: string;
  subcategory?: string;
  scoring?: string;
}

export interface AdminUser {
  email: string;
  role: string;
  addedAt: string;
}

export interface AiPrompt {
  id: string;
  name: string;
  description: string;
  promptText: string;
  modelConfig: {
    temperature: number;
    maxTokens: number;
  };
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

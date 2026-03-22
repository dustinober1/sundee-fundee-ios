// ─── ExerciseValue ────────────────────────────────────────────────────────────

export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; text: string };

/** The raw JSON representation of an ExerciseValue (mirrors Swift Codable encoding). */
export type ExerciseValueJSON = number | string | [number, number];

export function encodeExerciseValue(val: ExerciseValue): ExerciseValueJSON {
  switch (val.type) {
    case "fixed":
      return val.value;
    case "amrap":
      return "AMRAP";
    case "range":
      return [val.low, val.high];
    case "text":
      return val.text;
  }
}

export function decodeExerciseValue(raw: ExerciseValueJSON): ExerciseValue {
  // Array → range
  if (Array.isArray(raw) && raw.length === 2) {
    return { type: "range", low: raw[0], high: raw[1] };
  }

  // Number → fixed (truncate doubles)
  if (typeof raw === "number") {
    return { type: "fixed", value: Math.trunc(raw) };
  }

  // String cases
  if (typeof raw === "string") {
    const trimmed = raw.trim();

    // AMRAP (case-insensitive)
    if (trimmed.toUpperCase() === "AMRAP") {
      return { type: "amrap" };
    }

    // Hyphenated range e.g. "8-12"
    const dashParts = trimmed.split("-");
    if (dashParts.length === 2) {
      const lo = parseInt(dashParts[0].trim(), 10);
      const hi = parseInt(dashParts[1].trim(), 10);
      if (!isNaN(lo) && !isNaN(hi)) {
        return { type: "range", low: lo, high: hi };
      }
    }

    // String integer e.g. "4"
    const asInt = parseInt(trimmed, 10);
    if (!isNaN(asInt) && String(asInt) === trimmed) {
      return { type: "fixed", value: asInt };
    }

    // Fallback: text
    return { type: "text", text: raw };
  }

  // Fallback
  return { type: "fixed", value: 0 };
}

// ─── ProgramExercise ─────────────────────────────────────────────────────────

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

/** JSON shape that matches the Swift Codable encoding (percent1RM exact casing). */
export interface ProgramExerciseJSON {
  exercise: string;
  variant?: string;
  sets: ExerciseValueJSON;
  reps: ExerciseValueJSON;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export function exerciseToJSON(ex: ProgramExercise): ProgramExerciseJSON {
  const json: ProgramExerciseJSON = {
    exercise: ex.exercise,
    sets: encodeExerciseValue(ex.sets),
    reps: encodeExerciseValue(ex.reps),
  };
  if (ex.variant !== undefined) json.variant = ex.variant;
  if (ex.percent1RM !== undefined) json.percent1RM = ex.percent1RM;
  if (ex.restMinutes !== undefined) json.restMinutes = ex.restMinutes;
  if (ex.notes !== undefined) json.notes = ex.notes;
  if (ex.bodyweightOnly !== undefined) json.bodyweightOnly = ex.bodyweightOnly;
  return json;
}

export function exerciseFromJSON(json: ProgramExerciseJSON): ProgramExercise {
  const ex: ProgramExercise = {
    exercise: json.exercise,
    sets: decodeExerciseValue(json.sets),
    reps: decodeExerciseValue(json.reps),
  };
  if (json.variant !== undefined) ex.variant = json.variant;
  if (json.percent1RM !== undefined) ex.percent1RM = json.percent1RM;
  if (json.restMinutes !== undefined) ex.restMinutes = json.restMinutes;
  if (json.notes !== undefined) ex.notes = json.notes;
  if (json.bodyweightOnly !== undefined) ex.bodyweightOnly = json.bodyweightOnly;
  return ex;
}

// ─── WOD ──────────────────────────────────────────────────────────────────────

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

// ─── Program ──────────────────────────────────────────────────────────────────

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
}

export interface ProgramSession {
  /** Stored as "sessionId" in JSON (mirrors Swift CodingKeys). */
  sessionId: string;
  sessionName: string;
  sessionType: string;
  focus: string;
  exercises: ProgramExercise[];
}

export interface ProgramWeek {
  week: number;
  /** Stored as "phaseId" in JSON (mirrors Swift CodingKeys). */
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

// ─── Benchmark ───────────────────────────────────────────────────────────────

export interface BenchmarkDefinition {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringTypeRaw: string;
  sortOrder: number;
}

// ─── Program ──────────────────────────────────────────────────────────────────

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

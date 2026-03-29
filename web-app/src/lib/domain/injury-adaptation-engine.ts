import type { RecoveryPhase, ProgramExercise, ProgramSession, ProgramWeek, Program } from "./types";
import { BODY_REGIONS } from "./body-location";
import { applyLoadMultipliers } from "./injury-support";

// ---------------------------------------------------------------------------
// Injury Profile (minimal interface for adaptation)
// ---------------------------------------------------------------------------

export interface InjuryProfile {
  id: string;
  location: string;  // comma-separated region IDs or free-text
  recoveryPhase: RecoveryPhase;
}

// ---------------------------------------------------------------------------
// Contraindication rules
// ---------------------------------------------------------------------------

interface ContraindicationRule {
  categories: string[];
  keywords: string[];
}

const CONTRAINDICATION_RULES: Record<string, ContraindicationRule> = {
  knee: {
    categories: ["Squat"],
    keywords: ["squat", "lunge", "leg press", "leg extension", "box jump", "jump"],
  },
  shoulder: {
    categories: ["Press", "Olympic Weightlifting"],
    keywords: ["press", "overhead", "bench", "push-up", "dip", "fly", "raise"],
  },
  back: {
    categories: ["Hip Hinge"],
    keywords: ["deadlift", "good morning", "row", "back extension", "hyperextension"],
  },
  hip: {
    categories: [],
    keywords: ["hip thrust", "glute", "hamstring", "lunge", "step-up"],
  },
  wrist: {
    categories: ["Olympic Weightlifting"],
    keywords: ["clean", "snatch", "jerk", "front squat", "wrist"],
  },
  elbow: {
    categories: [],
    keywords: ["curl", "tricep", "extension", "press"],
  },
  ankle: {
    categories: [],
    keywords: ["calf", "jump", "run", "sprint", "box jump"],
  },
};

// ---------------------------------------------------------------------------
// Clinical synonyms
// ---------------------------------------------------------------------------

const CLINICAL_SYNONYMS: Record<string, string> = {
  "acl": "knee",
  "mcl": "knee",
  "meniscus": "knee",
  "patella": "knee",
  "rotator cuff": "shoulder",
  "labrum": "shoulder",
  "frozen shoulder": "shoulder",
  "lumbar": "back",
  "herniated disc": "back",
  "sciatica": "back",
  "si joint": "hip",
  "piriformis": "hip",
  "carpal tunnel": "wrist",
  "tennis elbow": "elbow",
  "golfers elbow": "elbow",
  "achilles": "ankle",
  "plantar fascia": "ankle",
};

// ---------------------------------------------------------------------------
// Regression table
// ---------------------------------------------------------------------------

const REGRESSION_TABLE: Record<string, string[]> = {
  "Back Squat":                 ["Goblet Squat", "Box Squat", "Air Squats"],
  "Front Squat":                ["Goblet Squat", "Box Squat", "Air Squats"],
  "Flat Barbell Bench Press":   ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
  "Incline Barbell Bench Press":["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
  "Strict Press":               ["Lateral Raises", "Z-Press", "Seated Dumbbell Press"],
  "Push Press":                 ["Dumbbell Overhead Press", "Lateral Raises", "Arnold Press"],
  "Conventional Deadlift (No Straps)":   ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
  "Conventional Deadlift (With Straps)": ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
  "Romanian Deadlift (No Straps)":  ["Nordic Curl", "Glute Bridge", "Hip Thrust"],
  "Romanian Deadlift (With Straps)": ["Nordic Curl", "Glute Bridge", "Hip Thrust"],
  "Squat Snatch":   ["Power Snatch", "Hang Snatch", "Overhead Squat"],
  "Squat Clean":    ["Power Clean", "Hang Clean", "Front Squat"],
  "Power Clean":    ["Hang Clean", "Kettlebell Deadlift", "Hip Thrust"],
  "Power Snatch":   ["Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"],
  "Clean and Jerk": ["Power Clean", "Push Press", "Front Squat"],
  "Split Jerk":     ["Push Press", "Push Jerk", "Strict Press"],
  "Pull-Up":        ["Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"],
  "Barbell Row":    ["Dumbbell Row", "Cable Row", "TRX Row"],
  "Pendlay Row":    ["Dumbbell Row", "Cable Row", "TRX Row"],
};

// ---------------------------------------------------------------------------
// Recovery prep map
// ---------------------------------------------------------------------------

const RECOVERY_PREP_MAP: Record<string, string[]> = {
  knee:     ["Bird-Dogs", "Reverse Lunges", "Terminal Knee Extension"],
  shoulder: ["Band Pull-Aparts", "Face Pulls", "Wall Slides"],
  back:     ["Cat-Cow", "Bird-Dogs", "Dead Bugs"],
  hip:      ["Glute Bridges", "Clamshells", "Side-Lying Hip Abduction"],
  wrist:    ["Wrist Circles", "Finger Extensions", "Prayer Stretches"],
  elbow:    ["Wrist Curls", "Reverse Wrist Curls", "Forearm Pronation"],
  ankle:    ["Calf Raises", "Ankle Circles", "Banded Dorsiflexion"],
};

// ---------------------------------------------------------------------------
// Safe bodyweight fallbacks
// ---------------------------------------------------------------------------

const SAFE_BODYWEIGHT = ["Air Squats", "Bird-Dogs", "Bodyweight Lunges"];

// ---------------------------------------------------------------------------
// normalizeBodyRegions
// ---------------------------------------------------------------------------

export function normalizeBodyRegions(
  regions: string[],
  freeText?: string
): string[] {
  const result = new Set<string>();
  const knownKeys = new Set(Object.keys(CONTRAINDICATION_RULES));

  // From structured regions (BODY_REGIONS ids)
  for (const regionId of regions) {
    const bodyRegion = BODY_REGIONS.find((r) => r.id === regionId);
    if (bodyRegion && knownKeys.has(bodyRegion.engineKey)) {
      result.add(bodyRegion.engineKey);
    }
  }

  // From free text — direct key match
  if (freeText) {
    const lower = freeText.toLowerCase();
    for (const key of knownKeys) {
      if (lower.includes(key)) result.add(key);
    }
    // Clinical synonym matching
    for (const [synonym, key] of Object.entries(CLINICAL_SYNONYMS)) {
      if (lower.includes(synonym)) result.add(key);
    }
  }

  return Array.from(result);
}

// ---------------------------------------------------------------------------
// mostRestrictivePhase
// ---------------------------------------------------------------------------

const PHASE_ORDER: RecoveryPhase[] = ["acute", "rehab", "lightLoad", "returnToPlay", "resolved"];

export function mostRestrictivePhase(phases: RecoveryPhase[]): RecoveryPhase | null {
  if (phases.length === 0) return null;
  return phases.reduce((most, phase) => {
    const mostIdx = PHASE_ORDER.indexOf(most);
    const phaseIdx = PHASE_ORDER.indexOf(phase);
    return phaseIdx < mostIdx ? phase : most;
  });
}

// ---------------------------------------------------------------------------
// Contraindication check
// ---------------------------------------------------------------------------

function isContraindicated(exerciseName: string, engineKeys: string[]): boolean {
  const lower = exerciseName.toLowerCase();
  for (const key of engineKeys) {
    const rule = CONTRAINDICATION_RULES[key];
    if (!rule) continue;
    for (const keyword of rule.keywords) {
      if (lower.includes(keyword)) return true;
    }
    // Category check: if exercise name includes the category name
    for (const cat of rule.categories) {
      if (lower.includes(cat.toLowerCase())) return true;
    }
  }
  return false;
}

function findReplacement(
  exerciseName: string,
  engineKeys: string[]
): string {
  const regressions = REGRESSION_TABLE[exerciseName];
  if (regressions) {
    for (const candidate of regressions) {
      if (!isContraindicated(candidate, engineKeys)) {
        return candidate;
      }
    }
  }
  for (const safe of SAFE_BODYWEIGHT) {
    if (!isContraindicated(safe, engineKeys)) {
      return safe;
    }
  }
  return exerciseName;
}

// ---------------------------------------------------------------------------
// buildRecoveryPrepBlock
// ---------------------------------------------------------------------------

export function buildRecoveryPrepBlock(
  injuries: InjuryProfile[],
  phase?: RecoveryPhase
): ProgramExercise[] {
  const seen = new Set<string>();
  const block: ProgramExercise[] = [];

  const engineKeys: string[] = [];
  for (const injury of injuries) {
    const regions = injury.location.split(",").map((s) => s.trim());
    const keys = normalizeBodyRegions(regions, injury.location);
    engineKeys.push(...keys);
  }

  const uniqueKeys = [...new Set(engineKeys)];

  for (const key of uniqueKeys) {
    const exercises = RECOVERY_PREP_MAP[key] ?? [];
    for (const ex of exercises) {
      if (seen.has(ex)) continue;
      seen.add(ex);

      let sets: ProgramExercise["sets"] = { type: "fixed", value: 2 };
      let reps: ProgramExercise["reps"] = { type: "fixed", value: 10 };
      let notes = "Recovery prep — gentle movement only";

      if (phase === "rehab") {
        sets = { type: "fixed", value: 3 };
        reps = { type: "fixed", value: 12 };
        notes = "Recovery prep — controlled movement";
      } else if (phase === "lightLoad") {
        sets = { type: "fixed", value: 2 };
        reps = { type: "fixed", value: 15 };
        notes = "Recovery prep — slow and controlled";
      }

      block.push({
        exercise: ex,
        sets,
        reps,
        restMinutes: 1,
        notes,
      });
    }
  }

  return block;
}

// ---------------------------------------------------------------------------
// adaptProgram
// ---------------------------------------------------------------------------

function getEngineKeys(injuries: InjuryProfile[]): string[] {
  const keys: string[] = [];
  for (const injury of injuries) {
    const regions = injury.location.split(",").map((s) => s.trim());
    keys.push(...normalizeBodyRegions(regions, injury.location));
  }
  return [...new Set(keys)];
}

function adaptSession(
  session: ProgramSession,
  injuries: InjuryProfile[]
): ProgramSession {
  const acuteInjuries        = injuries.filter((i) => i.recoveryPhase === "acute");
  const rehabInjuries        = injuries.filter((i) => i.recoveryPhase === "rehab");
  const lightLoadInjuries    = injuries.filter((i) => i.recoveryPhase === "lightLoad");
  const returnToPlayInjuries = injuries.filter((i) => i.recoveryPhase === "returnToPlay");

  const replacementInjuries = [...acuteInjuries, ...rehabInjuries, ...lightLoadInjuries];
  const replacementKeys = getEngineKeys(replacementInjuries);

  // Replace contraindicated exercises
  let adaptedExercises: ProgramExercise[] = session.exercises.map((ex) => {
    if (replacementInjuries.length > 0 && isContraindicated(ex.exercise, replacementKeys)) {
      const replacement = findReplacement(ex.exercise, replacementKeys);
      return { ...ex, exercise: replacement };
    }
    return ex;
  });

  // Apply load multipliers for most restrictive phase
  const overallPhase = mostRestrictivePhase(injuries.map((i) => i.recoveryPhase));
  if (overallPhase && overallPhase !== "resolved") {
    adaptedExercises = adaptedExercises.map((ex) =>
      applyLoadMultipliers(ex, overallPhase)
    );
  }

  // Prepend recovery prep block for rehab phase
  let finalExercises = adaptedExercises;
  if (rehabInjuries.length > 0) {
    const prepBlock = buildRecoveryPrepBlock(rehabInjuries, "rehab");
    finalExercises = [...prepBlock, ...finalExercises];
  }

  // Prepend recovery warmup for returnToPlay (no replacement)
  if (returnToPlayInjuries.length > 0) {
    const warmupBlock = buildRecoveryPrepBlock(returnToPlayInjuries);
    finalExercises = [...warmupBlock, ...finalExercises];
  }

  return {
    ...session,
    exercises: finalExercises,
  };
}

export function adaptProgram(
  program: Program,
  injuries: InjuryProfile[]
): Program {
  const nonResolved = injuries.filter((i) => i.recoveryPhase !== "resolved");
  if (nonResolved.length === 0) return program;

  const adaptedWeeks: ProgramWeek[] = program.weeks.map((week) => ({
    ...week,
    sessions: week.sessions.map((session) => adaptSession(session, nonResolved)),
  }));

  return { ...program, weeks: adaptedWeeks };
}

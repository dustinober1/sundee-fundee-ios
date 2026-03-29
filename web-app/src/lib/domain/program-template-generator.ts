import type { Program, ProgramWeek, ProgramSession, ProgramExercise, ProgramPhase } from "./types";

// ---------------------------------------------------------------------------
// Template types
// ---------------------------------------------------------------------------

export type ProgramTemplate = "strength" | "hypertrophy" | "fullBody" | "linear" | "dup" | "block";

export const TEMPLATE_DEFAULTS: Record<ProgramTemplate, { durationWeeks: number; sessionsPerWeek: number }> = {
  strength:    { durationWeeks: 4, sessionsPerWeek: 3 },
  hypertrophy: { durationWeeks: 6, sessionsPerWeek: 4 },
  fullBody:    { durationWeeks: 4, sessionsPerWeek: 3 },
  linear:      { durationWeeks: 6, sessionsPerWeek: 3 },
  dup:         { durationWeeks: 4, sessionsPerWeek: 3 },
  block:       { durationWeeks: 9, sessionsPerWeek: 3 },
};

// ---------------------------------------------------------------------------
// generateProgram
// ---------------------------------------------------------------------------

export function generateProgram(
  template: ProgramTemplate,
  name: string,
  durationWeeks?: number,
  sessionsPerWeek?: number
): Program {
  const defaults = TEMPLATE_DEFAULTS[template];
  const totalWeeks = durationWeeks ?? defaults.durationWeeks;
  const totalSessions = sessionsPerWeek ?? defaults.sessionsPerWeek;

  const phases: ProgramPhase[] = template === "block" ? blockPhases(totalWeeks) : [];

  const weeks: ProgramWeek[] = [];
  for (let weekNum = 1; weekNum <= totalWeeks; weekNum++) {
    const sessions: ProgramSession[] = [];
    for (let dayNum = 1; dayNum <= totalSessions; dayNum++) {
      sessions.push(buildSession(template, weekNum, dayNum, totalSessions, totalWeeks));
    }
    const phaseId = template === "block" ? blockPhaseId(weekNum, totalWeeks) : undefined;
    weeks.push({ week: weekNum, phaseId, sessions });
  }

  const displayName = templateDisplayName(template);

  return {
    id: `template-${template}-${Date.now()}`,
    name,
    category: "custom",
    description: `${displayName} program — ${totalWeeks} weeks, ${totalSessions}x/week`,
    durationWeeks: totalWeeks,
    sessionsPerWeek: totalSessions,
    difficulty: "intermediate",
    phases,
    weeks,
  };
}

// ---------------------------------------------------------------------------
// Display names
// ---------------------------------------------------------------------------

function templateDisplayName(template: ProgramTemplate): string {
  switch (template) {
    case "strength":    return "Strength";
    case "hypertrophy": return "Hypertrophy";
    case "fullBody":    return "Full Body";
    case "linear":      return "Linear";
    case "dup":         return "Daily Undulating";
    case "block":       return "Block";
  }
}

// ---------------------------------------------------------------------------
// Session building
// ---------------------------------------------------------------------------

function buildSession(
  template: ProgramTemplate,
  week: number,
  day: number,
  sessionsPerWeek: number,
  totalWeeks: number
): ProgramSession {
  const focus = sessionFocus(template, day, sessionsPerWeek);
  const sessionName = buildSessionName(template, day, focus);
  const exercises = sessionExercises(template, focus, week, day, totalWeeks);

  return {
    sessionId: `w${week}d${day}`,
    sessionName,
    sessionType: "strength",
    focus,
    exercises,
  };
}

function buildSessionName(template: ProgramTemplate, day: number, focus: string): string {
  if (template === "dup") {
    const labels = ["Heavy", "Moderate", "Volume", "Heavy", "Moderate"];
    const label = labels[(day - 1) % labels.length];
    return `Day ${day} — ${label}`;
  }
  return `Day ${day} — ${focus.charAt(0).toUpperCase() + focus.slice(1)} Focus`;
}

function sessionFocus(template: ProgramTemplate, day: number, _sessionsPerWeek: number): string {
  const idx = (day - 1);
  switch (template) {
    case "strength":
    case "linear":
    case "block": {
      const focuses = ["squat", "bench", "deadlift", "overhead press", "squat"];
      return focuses[idx % focuses.length];
    }
    case "hypertrophy": {
      const focuses = ["upper", "lower", "push", "pull", "upper"];
      return focuses[idx % focuses.length];
    }
    case "fullBody": {
      const focuses = ["full body a", "full body b", "full body c", "full body a", "full body b"];
      return focuses[idx % focuses.length];
    }
    case "dup":
      return "full body";
  }
}

// ---------------------------------------------------------------------------
// Exercise generation
// ---------------------------------------------------------------------------

type ExerciseTuple = [string, number, number, number, number, boolean];
// [name, sets, reps, basePct1RM, restMinutes, bodyweightOnly]

function sessionExercises(
  template: ProgramTemplate,
  focus: string,
  week: number,
  day: number,
  totalWeeks: number
): ProgramExercise[] {
  switch (template) {
    case "strength":
    case "hypertrophy":
    case "fullBody": {
      const pool = exercisePool(template, focus);
      const progressionOffset = (week - 1) * 0.02;
      return pool.map(([name, sets, reps, basePct, rest, bw]) => ({
        exercise: name,
        sets: { type: "fixed", value: sets },
        reps: reps === 0 ? { type: "text", value: "hold" } : { type: "fixed", value: reps },
        percent1RM: bw ? undefined : basePct + progressionOffset,
        restMinutes: rest,
        bodyweightOnly: bw,
      }));
    }
    case "linear":
      return linearExercises(focus, week, totalWeeks);
    case "dup":
      return dupExercises(day, week);
    case "block":
      return blockExercises(focus, week, totalWeeks);
  }
}

// ---------------------------------------------------------------------------
// Basic template exercise pools
// ---------------------------------------------------------------------------

function exercisePool(
  template: "strength" | "hypertrophy" | "fullBody",
  focus: string
): ExerciseTuple[] {
  switch (template) {
    case "strength":
      return strengthExercises(focus);
    case "hypertrophy":
      return hypertrophyExercises(focus);
    case "fullBody":
      return fullBodyExercises(focus);
  }
}

function strengthExercises(focus: string): ExerciseTuple[] {
  switch (focus) {
    case "squat":
      return [
        ["Back Squat", 4, 5, 0.78, 3.0, false],
        ["Front Squat", 3, 5, 0.68, 2.5, false],
        ["Leg Press", 3, 8, 0.0, 2.0, false],
        ["Walking Lunge", 3, 10, 0.0, 1.5, false],
        ["Calf Raise", 3, 12, 0.0, 1.0, false],
      ];
    case "bench":
      return [
        ["Bench Press", 4, 5, 0.78, 3.0, false],
        ["Incline Dumbbell Press", 3, 8, 0.0, 2.0, false],
        ["Barbell Row", 4, 5, 0.72, 2.5, false],
        ["Dumbbell Lateral Raise", 3, 12, 0.0, 1.0, false],
        ["Tricep Pushdown", 3, 10, 0.0, 1.0, false],
      ];
    case "deadlift":
      return [
        ["Deadlift", 4, 5, 0.78, 3.0, false],
        ["Romanian Deadlift", 3, 8, 0.65, 2.0, false],
        ["Pull-Up", 3, 8, 0.0, 2.0, true],
        ["Hip Thrust", 3, 10, 0.0, 1.5, false],
        ["Plank", 3, 0, 0.0, 1.0, true],
      ];
    default:
      return [
        ["Overhead Press", 4, 5, 0.72, 3.0, false],
        ["Push Press", 3, 5, 0.68, 2.5, false],
        ["Lateral Raise", 3, 12, 0.0, 1.0, false],
        ["Face Pull", 3, 15, 0.0, 1.0, false],
        ["Dip", 3, 8, 0.0, 1.5, true],
      ];
  }
}

function hypertrophyExercises(focus: string): ExerciseTuple[] {
  switch (focus) {
    case "upper":
      return [
        ["Bench Press", 4, 10, 0.65, 2.0, false],
        ["Dumbbell Row", 4, 10, 0.0, 1.5, false],
        ["Overhead Press", 3, 10, 0.62, 1.5, false],
        ["Lat Pulldown", 3, 12, 0.0, 1.5, false],
        ["Bicep Curl", 3, 12, 0.0, 1.0, false],
        ["Tricep Extension", 3, 12, 0.0, 1.0, false],
      ];
    case "lower":
      return [
        ["Back Squat", 4, 10, 0.65, 2.0, false],
        ["Romanian Deadlift", 3, 10, 0.62, 2.0, false],
        ["Leg Press", 3, 12, 0.0, 1.5, false],
        ["Leg Curl", 3, 12, 0.0, 1.0, false],
        ["Calf Raise", 4, 15, 0.0, 1.0, false],
        ["Plank", 3, 0, 0.0, 1.0, true],
      ];
    case "push":
      return [
        ["Incline Bench Press", 4, 10, 0.62, 2.0, false],
        ["Dumbbell Fly", 3, 12, 0.0, 1.0, false],
        ["Overhead Press", 3, 10, 0.60, 1.5, false],
        ["Lateral Raise", 3, 15, 0.0, 1.0, false],
        ["Tricep Pushdown", 3, 12, 0.0, 1.0, false],
      ];
    default: // pull
      return [
        ["Barbell Row", 4, 10, 0.65, 2.0, false],
        ["Pull-Up", 3, 8, 0.0, 2.0, true],
        ["Face Pull", 3, 15, 0.0, 1.0, false],
        ["Hammer Curl", 3, 12, 0.0, 1.0, false],
        ["Shrug", 3, 12, 0.0, 1.0, false],
      ];
  }
}

function fullBodyExercises(focus: string): ExerciseTuple[] {
  switch (focus) {
    case "full body a":
      return [
        ["Back Squat", 3, 8, 0.70, 2.5, false],
        ["Bench Press", 3, 8, 0.70, 2.0, false],
        ["Barbell Row", 3, 8, 0.68, 2.0, false],
        ["Overhead Press", 3, 10, 0.62, 1.5, false],
        ["Plank", 3, 0, 0.0, 1.0, true],
      ];
    case "full body b":
      return [
        ["Deadlift", 3, 6, 0.75, 3.0, false],
        ["Incline Dumbbell Press", 3, 10, 0.0, 1.5, false],
        ["Pull-Up", 3, 8, 0.0, 2.0, true],
        ["Walking Lunge", 3, 10, 0.0, 1.5, false],
        ["Bicep Curl", 3, 12, 0.0, 1.0, false],
      ];
    default: // full body c
      return [
        ["Front Squat", 3, 8, 0.65, 2.5, false],
        ["Dumbbell Bench Press", 3, 10, 0.0, 1.5, false],
        ["Seated Row", 3, 10, 0.0, 1.5, false],
        ["Hip Thrust", 3, 10, 0.0, 1.5, false],
        ["Lateral Raise", 3, 12, 0.0, 1.0, false],
      ];
  }
}

// ---------------------------------------------------------------------------
// Linear Periodization
// ---------------------------------------------------------------------------

function linearExercises(focus: string, week: number, totalWeeks: number): ProgramExercise[] {
  const progress = (week - 1) / Math.max(totalWeeks - 1, 1);
  const reps = Math.round(10 - progress * 7); // 10 → 3
  const pct  = 0.60 + progress * 0.28;         // 60% → 88%
  const sets = reps <= 3 ? 5 : 4;
  const rest = reps <= 5 ? 3.0 : 2.0;

  const pool = linearPool(focus);
  return pool.map(([name, bw]) => ({
    exercise: name,
    sets: { type: "fixed", value: sets },
    reps: { type: "fixed", value: reps },
    percent1RM: bw ? undefined : pct,
    restMinutes: rest,
    bodyweightOnly: bw,
  }));
}

function linearPool(focus: string): [string, boolean][] {
  switch (focus) {
    case "squat":
      return [["Back Squat", false], ["Front Squat", false], ["Leg Press", false], ["Walking Lunge", false], ["Calf Raise", false]];
    case "bench":
      return [["Bench Press", false], ["Incline Dumbbell Press", false], ["Barbell Row", false], ["Lateral Raise", false], ["Tricep Pushdown", false]];
    case "deadlift":
      return [["Deadlift", false], ["Romanian Deadlift", false], ["Pull-Up", true], ["Hip Thrust", false], ["Plank", true]];
    default:
      return [["Overhead Press", false], ["Push Press", false], ["Lateral Raise", false], ["Face Pull", false], ["Dip", true]];
  }
}

// ---------------------------------------------------------------------------
// Daily Undulating Periodization
// ---------------------------------------------------------------------------

function dupExercises(day: number, week: number): ProgramExercise[] {
  const weekOffset = (week - 1) * 0.02;
  const dayIndex = (day - 1) % 3;

  let reps: number, basePct: number, sets: number, rest: number;
  switch (dayIndex) {
    case 0: reps = 3; basePct = 0.85; sets = 5; rest = 3.0; break; // Heavy
    case 1: reps = 6; basePct = 0.72; sets = 4; rest = 2.0; break; // Moderate
    default: reps = 12; basePct = 0.60; sets = 3; rest = 1.5; break; // Volume
  }

  const exercises: [string, boolean][] = [
    ["Back Squat", false],
    ["Bench Press", false],
    ["Deadlift", false],
    ["Overhead Press", false],
    ["Pull-Up", true],
  ];

  return exercises.map(([name, bw]) => ({
    exercise: name,
    sets: { type: "fixed", value: sets },
    reps: { type: "fixed", value: reps },
    percent1RM: bw ? undefined : basePct + weekOffset,
    restMinutes: rest,
    bodyweightOnly: bw,
  }));
}

// ---------------------------------------------------------------------------
// Block Periodization
// ---------------------------------------------------------------------------

function blockPhaseId(week: number, totalWeeks: number): string {
  const phaseLength = Math.floor(totalWeeks / 3);
  if (week <= phaseLength) return "accumulation";
  if (week <= phaseLength * 2) return "intensification";
  return "peaking";
}

function blockPhases(totalWeeks: number): ProgramPhase[] {
  const phaseLength = Math.floor(totalWeeks / 3);
  return [
    {
      id: "accumulation",
      name: "Accumulation",
      goal: "Build work capacity with high volume, moderate intensity",
      weekRange: [1, phaseLength],
    },
    {
      id: "intensification",
      name: "Intensification",
      goal: "Increase intensity, reduce volume",
      weekRange: [phaseLength + 1, phaseLength * 2],
    },
    {
      id: "peaking",
      name: "Peaking",
      goal: "Peak strength with low volume, max intensity",
      weekRange: [phaseLength * 2 + 1, totalWeeks],
    },
  ];
}

function blockExercises(focus: string, week: number, totalWeeks: number): ProgramExercise[] {
  const phaseLength = Math.floor(totalWeeks / 3);

  let reps: number, basePct: number, sets: number, rest: number;
  if (week <= phaseLength) {
    // Accumulation: 10 reps @ 60–66%
    const weekInPhase = week - 1;
    reps = 10;
    basePct = 0.60 + weekInPhase * 0.02;
    sets = 4;
    rest = 1.5;
  } else if (week <= phaseLength * 2) {
    // Intensification: 5 reps @ 75–81%
    const weekInPhase = week - phaseLength - 1;
    reps = 5;
    basePct = 0.75 + weekInPhase * 0.02;
    sets = 4;
    rest = 2.5;
  } else {
    // Peaking: 2 reps @ 85–91%
    const weekInPhase = week - phaseLength * 2 - 1;
    reps = 2;
    basePct = 0.85 + weekInPhase * 0.02;
    sets = 5;
    rest = 3.0;
  }

  const pool = blockPool(focus);
  return pool.map(([name, bw]) => ({
    exercise: name,
    sets: { type: "fixed", value: sets },
    reps: { type: "fixed", value: reps },
    percent1RM: bw ? undefined : basePct,
    restMinutes: rest,
    bodyweightOnly: bw,
  }));
}

function blockPool(focus: string): [string, boolean][] {
  switch (focus) {
    case "squat":
      return [["Back Squat", false], ["Front Squat", false], ["Leg Press", false], ["Walking Lunge", false], ["Calf Raise", false]];
    case "bench":
      return [["Bench Press", false], ["Incline Dumbbell Press", false], ["Barbell Row", false], ["Lateral Raise", false], ["Tricep Pushdown", false]];
    case "deadlift":
      return [["Deadlift", false], ["Romanian Deadlift", false], ["Pull-Up", true], ["Hip Thrust", false], ["Plank", true]];
    default:
      return [["Overhead Press", false], ["Push Press", false], ["Lateral Raise", false], ["Face Pull", false], ["Dip", true]];
  }
}

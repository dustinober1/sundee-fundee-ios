import { describe, it, expect } from "vitest";
import {
  generateProgram,
  TEMPLATE_DEFAULTS,
  type ProgramTemplate,
} from "../program-template-generator";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function exercisesForWeek(program: ReturnType<typeof generateProgram>, weekNum: number) {
  const week = program.weeks.find((w) => w.week === weekNum);
  return week?.sessions.flatMap((s) => s.exercises) ?? [];
}

// ---------------------------------------------------------------------------
// Default durations and sessions
// ---------------------------------------------------------------------------

describe("generateProgram defaults", () => {
  const templates: ProgramTemplate[] = ["strength", "hypertrophy", "fullBody", "linear", "dup", "block"];

  for (const template of templates) {
    it(`${template} generates correct default weeks and sessions`, () => {
      const defaults = TEMPLATE_DEFAULTS[template];
      const program = generateProgram(template, `Test ${template}`);
      expect(program.durationWeeks).toBe(defaults.durationWeeks);
      expect(program.sessionsPerWeek).toBe(defaults.sessionsPerWeek);
      expect(program.weeks).toHaveLength(defaults.durationWeeks);
      for (const week of program.weeks) {
        expect(week.sessions).toHaveLength(defaults.sessionsPerWeek);
      }
    });
  }

  it("accepts custom duration and sessions", () => {
    const program = generateProgram("strength", "Custom", 8, 4);
    expect(program.durationWeeks).toBe(8);
    expect(program.sessionsPerWeek).toBe(4);
    expect(program.weeks).toHaveLength(8);
    for (const week of program.weeks) {
      expect(week.sessions).toHaveLength(4);
    }
  });
});

// ---------------------------------------------------------------------------
// Linear: progressive load
// ---------------------------------------------------------------------------

describe("linear template", () => {
  it("has decreasing reps over weeks (10 → 3)", () => {
    const program = generateProgram("linear", "Linear Test");
    const week1Exercises = exercisesForWeek(program, 1);
    const lastWeekExercises = exercisesForWeek(program, program.durationWeeks);

    const week1Reps = week1Exercises[0]?.reps;
    const lastWeekReps = lastWeekExercises[0]?.reps;

    expect(week1Reps?.type).toBe("fixed");
    expect(lastWeekReps?.type).toBe("fixed");
    if (week1Reps?.type === "fixed" && lastWeekReps?.type === "fixed") {
      expect(week1Reps.value).toBeGreaterThan(lastWeekReps.value);
    }
  });

  it("has increasing load over weeks", () => {
    const program = generateProgram("linear", "Linear Test");
    const week1Ex = exercisesForWeek(program, 1);
    const lastEx = exercisesForWeek(program, program.durationWeeks);

    const week1Pct = week1Ex.find((e) => !e.bodyweightOnly)?.percent1RM;
    const lastPct  = lastEx.find((e) => !e.bodyweightOnly)?.percent1RM;

    expect(week1Pct).toBeDefined();
    expect(lastPct).toBeDefined();
    expect(lastPct!).toBeGreaterThan(week1Pct!);
  });

  it("week 1 reps are approximately 10", () => {
    const program = generateProgram("linear", "Linear Test");
    const week1Ex = exercisesForWeek(program, 1);
    const firstEx = week1Ex[0];
    expect(firstEx.reps.type).toBe("fixed");
    if (firstEx.reps.type === "fixed") {
      expect(firstEx.reps.value).toBe(10);
    }
  });

  it("last week reps are approximately 3", () => {
    const program = generateProgram("linear", "Linear Test");
    const lastEx = exercisesForWeek(program, program.durationWeeks);
    const firstEx = lastEx[0];
    expect(firstEx.reps.type).toBe("fixed");
    if (firstEx.reps.type === "fixed") {
      expect(firstEx.reps.value).toBe(3);
    }
  });
});

// ---------------------------------------------------------------------------
// DUP: 3 session types
// ---------------------------------------------------------------------------

describe("dup template", () => {
  it("has 3 session types: Heavy, Moderate, Volume", () => {
    const program = generateProgram("dup", "DUP Test");
    const week1 = program.weeks[0];
    expect(week1.sessions).toHaveLength(3);

    const names = week1.sessions.map((s) => s.sessionName);
    expect(names.some((n) => n.includes("Heavy"))).toBe(true);
    expect(names.some((n) => n.includes("Moderate"))).toBe(true);
    expect(names.some((n) => n.includes("Volume"))).toBe(true);
  });

  it("Heavy day has lower reps than Volume day", () => {
    const program = generateProgram("dup", "DUP Test");
    const week1 = program.weeks[0];

    const heavySession = week1.sessions[0]; // Day 1
    const volumeSession = week1.sessions[2]; // Day 3

    const heavyReps = heavySession.exercises[0]?.reps;
    const volumeReps = volumeSession.exercises[0]?.reps;

    expect(heavyReps?.type).toBe("fixed");
    expect(volumeReps?.type).toBe("fixed");
    if (heavyReps?.type === "fixed" && volumeReps?.type === "fixed") {
      expect(heavyReps.value).toBeLessThan(volumeReps.value);
    }
  });

  it("Heavy day has higher % than Volume day", () => {
    const program = generateProgram("dup", "DUP Test");
    const week1 = program.weeks[0];
    const heavyEx = week1.sessions[0].exercises.find((e) => !e.bodyweightOnly);
    const volumeEx = week1.sessions[2].exercises.find((e) => !e.bodyweightOnly);
    expect(heavyEx!.percent1RM!).toBeGreaterThan(volumeEx!.percent1RM!);
  });
});

// ---------------------------------------------------------------------------
// Block: 3 phases
// ---------------------------------------------------------------------------

describe("block template", () => {
  it("generates 3 phases", () => {
    const program = generateProgram("block", "Block Test");
    expect(program.phases).toHaveLength(3);
    const phaseIds = program.phases.map((p) => p.id);
    expect(phaseIds).toContain("accumulation");
    expect(phaseIds).toContain("intensification");
    expect(phaseIds).toContain("peaking");
  });

  it("accumulation phase has higher reps than peaking phase", () => {
    const program = generateProgram("block", "Block Test");
    // Accumulation is first 3 weeks (9 total / 3 = 3 per phase)
    const accumEx = exercisesForWeek(program, 1);
    const peakingEx = exercisesForWeek(program, 9);

    const accumReps = accumEx[0]?.reps;
    const peakingReps = peakingEx[0]?.reps;

    expect(accumReps?.type).toBe("fixed");
    expect(peakingReps?.type).toBe("fixed");
    if (accumReps?.type === "fixed" && peakingReps?.type === "fixed") {
      expect(accumReps.value).toBeGreaterThan(peakingReps.value);
    }
  });

  it("peaking phase has higher % than accumulation", () => {
    const program = generateProgram("block", "Block Test");
    const accumEx = exercisesForWeek(program, 1).find((e) => !e.bodyweightOnly);
    const peakEx = exercisesForWeek(program, 9).find((e) => !e.bodyweightOnly);
    expect(accumEx!.percent1RM!).toBeLessThan(peakEx!.percent1RM!);
  });

  it("weeks have phaseId assigned", () => {
    const program = generateProgram("block", "Block Test");
    for (const week of program.weeks) {
      expect(week.phaseId).toBeDefined();
    }
  });
});

// ---------------------------------------------------------------------------
// General structure
// ---------------------------------------------------------------------------

describe("generateProgram structure", () => {
  it("all exercises have sets and reps", () => {
    const templates: ProgramTemplate[] = ["strength", "hypertrophy", "fullBody", "linear", "dup", "block"];
    for (const template of templates) {
      const program = generateProgram(template, `Test ${template}`);
      for (const week of program.weeks) {
        for (const session of week.sessions) {
          for (const exercise of session.exercises) {
            expect(exercise.sets).toBeDefined();
            expect(exercise.reps).toBeDefined();
          }
        }
      }
    }
  });

  it("each session has a unique sessionId within a program", () => {
    const program = generateProgram("strength", "Test");
    const ids = program.weeks.flatMap((w) => w.sessions.map((s) => s.sessionId));
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(ids.length);
  });
});

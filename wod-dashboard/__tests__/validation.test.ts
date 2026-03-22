import { validateWOD, validateProgram, ValidationError } from "../src/lib/validation";
import { WOD, Program, ProgramWeek, ProgramSession, ProgramPhase } from "../src/lib/types";

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeWOD(overrides: Partial<WOD> = {}): WOD {
  return {
    id: "wod-2024-01-15",
    date: "2024-01-15",
    title: "Monday Strength",
    description: "Heavy lower body day",
    exercises: [
      {
        exercise: "Back Squat",
        sets: { type: "fixed", value: 4 },
        reps: { type: "fixed", value: 5 },
      },
    ],
    ...overrides,
  };
}

function makeProgram(overrides: Partial<Program> = {}): Program {
  const phase: ProgramPhase = { id: "phase-1", name: "Base", goal: "Build base", weekRange: [1, 4] };
  const session: ProgramSession = {
    sessionId: "s1",
    sessionName: "Day 1",
    sessionType: "strength",
    focus: "lower",
    exercises: [
      {
        exercise: "Deadlift",
        sets: { type: "fixed", value: 3 },
        reps: { type: "fixed", value: 5 },
        percent1RM: 0.75,
      },
    ],
  };
  const week: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [session] };
  return {
    id: "beginner-strength",
    name: "Beginner Strength",
    category: "Strength",
    description: "A beginner program",
    durationWeeks: 1,
    sessionsPerWeek: 1,
    difficulty: "beginner",
    phases: [phase],
    weeks: [week],
    ...overrides,
  };
}

// ─── validateWOD ──────────────────────────────────────────────────────────────

describe("validateWOD", () => {
  it("returns no errors for a valid WOD", () => {
    expect(validateWOD(makeWOD())).toEqual([]);
  });

  it("errors when id is empty", () => {
    const errors = validateWOD(makeWOD({ id: "" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("errors when id is whitespace only", () => {
    const errors = validateWOD(makeWOD({ id: "   " }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("errors when title is empty", () => {
    const errors = validateWOD(makeWOD({ title: "" }));
    expect(errors.some((e: ValidationError) => e.field === "title")).toBe(true);
  });

  it("errors when title is whitespace only", () => {
    const errors = validateWOD(makeWOD({ title: "   " }));
    expect(errors.some((e: ValidationError) => e.field === "title")).toBe(true);
  });

  it("errors when date is empty", () => {
    const errors = validateWOD(makeWOD({ date: "" }));
    expect(errors.some((e: ValidationError) => e.field === "date")).toBe(true);
  });

  it("errors when date is wrong format (MM/DD/YYYY)", () => {
    const errors = validateWOD(makeWOD({ date: "01/15/2024" }));
    expect(errors.some((e: ValidationError) => e.field === "date")).toBe(true);
  });

  it("errors when date is wrong format (missing leading zeros)", () => {
    const errors = validateWOD(makeWOD({ date: "2024-1-5" }));
    expect(errors.some((e: ValidationError) => e.field === "date")).toBe(true);
  });

  it("errors when exercises array is empty", () => {
    const errors = validateWOD(makeWOD({ exercises: [] }));
    expect(errors.some((e: ValidationError) => e.field === "exercises")).toBe(true);
  });

  it("errors when an exercise name is empty", () => {
    const wod = makeWOD({
      exercises: [
        {
          exercise: "",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
      ],
    });
    const errors = validateWOD(wod);
    expect(errors.some((e: ValidationError) => e.field === "exercises[0]")).toBe(true);
  });

  it("errors when an exercise name is whitespace only", () => {
    const wod = makeWOD({
      exercises: [
        {
          exercise: "  ",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
      ],
    });
    const errors = validateWOD(wod);
    expect(errors.some((e: ValidationError) => e.field === "exercises[0]")).toBe(true);
  });

  it("reports the correct index for the bad exercise", () => {
    const wod = makeWOD({
      exercises: [
        {
          exercise: "Back Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
        {
          exercise: "",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
      ],
    });
    const errors = validateWOD(wod);
    expect(errors.some((e: ValidationError) => e.field === "exercises[1]")).toBe(true);
  });
});

// ─── validateProgram ──────────────────────────────────────────────────────────

describe("validateProgram", () => {
  it("returns no errors for a valid program", () => {
    expect(validateProgram(makeProgram())).toEqual([]);
  });

  it("errors when name is empty", () => {
    const errors = validateProgram(makeProgram({ name: "" }));
    expect(errors.some((e: ValidationError) => e.field === "name")).toBe(true);
  });

  it("errors when id is empty", () => {
    const errors = validateProgram(makeProgram({ id: "" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("errors for a bad slug (uppercase letters)", () => {
    const errors = validateProgram(makeProgram({ id: "BeginnerStrength" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("errors for a bad slug (trailing hyphen)", () => {
    const errors = validateProgram(makeProgram({ id: "beginner-" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("errors for a bad slug (spaces)", () => {
    const errors = validateProgram(makeProgram({ id: "beginner strength" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(true);
  });

  it("accepts valid slug with hyphens", () => {
    const errors = validateProgram(makeProgram({ id: "beginner-strength-12" }));
    expect(errors.some((e: ValidationError) => e.field === "id")).toBe(false);
  });

  it("errors when durationWeeks doesn't match weeks.length", () => {
    const errors = validateProgram(makeProgram({ durationWeeks: 4 })); // weeks has 1 entry
    expect(errors.some((e: ValidationError) => e.field === "durationWeeks")).toBe(true);
  });

  it("includes counts in the durationWeeks error message", () => {
    const errors = validateProgram(makeProgram({ durationWeeks: 4 }));
    const err = errors.find((e: ValidationError) => e.field === "durationWeeks");
    expect(err?.message).toContain("4");
    expect(err?.message).toContain("1");
  });

  it("errors when a week references an unknown phaseId", () => {
    const phase: ProgramPhase = { id: "phase-1", name: "Base", goal: "Build", weekRange: [1, 4] };
    const session: ProgramSession = {
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
      ],
    };
    const week: ProgramWeek = { week: 1, phaseId: "unknown-phase", sessions: [session] };
    const program = makeProgram({ phases: [phase], weeks: [week], durationWeeks: 1 });
    const errors = validateProgram(program);
    expect(errors.some((e: ValidationError) => e.field === "weeks[0].phaseId")).toBe(true);
  });

  it("does not error when a week has no phaseId", () => {
    const session: ProgramSession = {
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
        },
      ],
    };
    const week: ProgramWeek = { week: 1, sessions: [session] }; // no phaseId
    const program = makeProgram({ weeks: [week], durationWeeks: 1 });
    const errors = validateProgram(program);
    expect(errors.some((e: ValidationError) => e.field.includes("phaseId"))).toBe(false);
  });

  it("errors when percent1RM is below 0.0", () => {
    const session: ProgramSession = {
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
          percent1RM: -0.1,
        },
      ],
    };
    const week: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [session] };
    const program = makeProgram({ weeks: [week], durationWeeks: 1 });
    const errors = validateProgram(program);
    expect(errors.some((e: ValidationError) => e.field.includes("percent1RM"))).toBe(true);
  });

  it("errors when percent1RM is above 1.5", () => {
    const session: ProgramSession = {
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
          percent1RM: 1.6,
        },
      ],
    };
    const week: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [session] };
    const program = makeProgram({ weeks: [week], durationWeeks: 1 });
    const errors = validateProgram(program);
    expect(errors.some((e: ValidationError) => e.field.includes("percent1RM"))).toBe(true);
  });

  it("accepts percent1RM at boundary values 0.0 and 1.5", () => {
    const makeSession = (pct: number): ProgramSession => ({
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
          percent1RM: pct,
        },
      ],
    });
    const week0: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [makeSession(0.0)] };
    const week15: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [makeSession(1.5)] };
    expect(validateProgram(makeProgram({ weeks: [week0], durationWeeks: 1 })).some((e: ValidationError) => e.field.includes("percent1RM"))).toBe(false);
    expect(validateProgram(makeProgram({ weeks: [week15], durationWeeks: 1 })).some((e: ValidationError) => e.field.includes("percent1RM"))).toBe(false);
  });

  it("does not error when percent1RM is undefined", () => {
    const session: ProgramSession = {
      sessionId: "s1",
      sessionName: "Day 1",
      sessionType: "strength",
      focus: "lower",
      exercises: [
        {
          exercise: "Squat",
          sets: { type: "fixed", value: 3 },
          reps: { type: "fixed", value: 5 },
          // no percent1RM
        },
      ],
    };
    const week: ProgramWeek = { week: 1, phaseId: "phase-1", sessions: [session] };
    expect(validateProgram(makeProgram({ weeks: [week], durationWeeks: 1 }))).toEqual([]);
  });
});

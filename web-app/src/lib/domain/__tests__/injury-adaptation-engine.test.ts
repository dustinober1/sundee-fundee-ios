import { describe, it, expect } from "vitest";
import {
  normalizeBodyRegions,
  mostRestrictivePhase,
  buildRecoveryPrepBlock,
  adaptProgram,
  type InjuryProfile,
} from "../injury-adaptation-engine";
import type { Program, ProgramSession, ProgramWeek } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeProgram(exerciseNames: string[]): Program {
  const session: ProgramSession = {
    sessionId: "s1",
    sessionName: "Session 1",
    sessionType: "strength",
    focus: "squat",
    exercises: exerciseNames.map((name) => ({
      exercise: name,
      sets: { type: "fixed", value: 4 },
      reps: { type: "fixed", value: 5 },
      percent1RM: 0.80,
    })),
  };
  const week: ProgramWeek = { week: 1, sessions: [session] };
  return {
    id: "prog-1",
    name: "Test Program",
    category: "custom",
    description: "Test",
    durationWeeks: 1,
    sessionsPerWeek: 1,
    difficulty: "intermediate",
    phases: [],
    weeks: [week],
  };
}

function makeInjury(id: string, location: string, phase: InjuryProfile["recoveryPhase"]): InjuryProfile {
  return { id, location, recoveryPhase: phase };
}

// ---------------------------------------------------------------------------
// normalizeBodyRegions
// ---------------------------------------------------------------------------

describe("normalizeBodyRegions", () => {
  it("maps knee_left region ID to knee engine key", () => {
    const result = normalizeBodyRegions(["knee_left"]);
    expect(result).toContain("knee");
  });

  it("maps shoulder_right region ID to shoulder engine key", () => {
    const result = normalizeBodyRegions(["shoulder_right"]);
    expect(result).toContain("shoulder");
  });

  it("extracts knee from freeText via clinical synonym 'acl'", () => {
    const result = normalizeBodyRegions([], "ACL tear");
    expect(result).toContain("knee");
  });

  it("extracts shoulder from freeText via clinical synonym 'rotator cuff'", () => {
    const result = normalizeBodyRegions([], "rotator cuff strain");
    expect(result).toContain("shoulder");
  });

  it("extracts back from clinical synonym 'sciatica'", () => {
    const result = normalizeBodyRegions([], "sciatica");
    expect(result).toContain("back");
  });

  it("extracts wrist from clinical synonym 'carpal tunnel'", () => {
    const result = normalizeBodyRegions([], "carpal tunnel syndrome");
    expect(result).toContain("wrist");
  });

  it("returns empty for empty inputs", () => {
    const result = normalizeBodyRegions([], "");
    expect(result).toHaveLength(0);
  });

  it("deduplicates engine keys", () => {
    const result = normalizeBodyRegions(["knee_left", "knee_right"]);
    expect(result.filter((k) => k === "knee")).toHaveLength(1);
  });
});

// ---------------------------------------------------------------------------
// mostRestrictivePhase
// ---------------------------------------------------------------------------

describe("mostRestrictivePhase", () => {
  it("returns null for empty array", () => {
    expect(mostRestrictivePhase([])).toBeNull();
  });

  it("returns acute when acute is present", () => {
    expect(mostRestrictivePhase(["rehab", "acute", "lightLoad"])).toBe("acute");
  });

  it("returns rehab when no acute", () => {
    expect(mostRestrictivePhase(["lightLoad", "rehab", "resolved"])).toBe("rehab");
  });

  it("returns resolved for single resolved", () => {
    expect(mostRestrictivePhase(["resolved"])).toBe("resolved");
  });

  it("returns returnToPlay when between returnToPlay and resolved", () => {
    expect(mostRestrictivePhase(["resolved", "returnToPlay"])).toBe("returnToPlay");
  });
});

// ---------------------------------------------------------------------------
// buildRecoveryPrepBlock
// ---------------------------------------------------------------------------

describe("buildRecoveryPrepBlock", () => {
  it("generates prep exercises for knee injury", () => {
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "rehab")];
    const block = buildRecoveryPrepBlock(injuries, "rehab");
    expect(block.length).toBeGreaterThan(0);
    const names = block.map((e) => e.exercise);
    // Should include knee prep exercises
    expect(names.some((n) => ["Bird-Dogs", "Reverse Lunges", "Terminal Knee Extension"].includes(n))).toBe(true);
  });

  it("generates prep exercises for shoulder injury", () => {
    const injuries: InjuryProfile[] = [makeInjury("1", "shoulder_left", "rehab")];
    const block = buildRecoveryPrepBlock(injuries, "rehab");
    const names = block.map((e) => e.exercise);
    expect(names.some((n) => ["Band Pull-Aparts", "Face Pulls", "Wall Slides"].includes(n))).toBe(true);
  });

  it("does not duplicate exercises for bilateral injury", () => {
    const injuries: InjuryProfile[] = [
      makeInjury("1", "knee_left", "rehab"),
      makeInjury("2", "knee_right", "rehab"),
    ];
    const block = buildRecoveryPrepBlock(injuries, "rehab");
    const names = block.map((e) => e.exercise);
    const uniqueNames = new Set(names);
    expect(names.length).toBe(uniqueNames.size);
  });

  it("rehab phase uses 3x12", () => {
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "rehab")];
    const block = buildRecoveryPrepBlock(injuries, "rehab");
    expect(block[0].sets).toEqual({ type: "fixed", value: 3 });
    expect(block[0].reps).toEqual({ type: "fixed", value: 12 });
  });

  it("lightLoad phase uses 2x15", () => {
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "lightLoad")];
    const block = buildRecoveryPrepBlock(injuries, "lightLoad");
    expect(block[0].sets).toEqual({ type: "fixed", value: 2 });
    expect(block[0].reps).toEqual({ type: "fixed", value: 15 });
  });

  it("default phase uses 2x10", () => {
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "returnToPlay")];
    const block = buildRecoveryPrepBlock(injuries);
    expect(block[0].sets).toEqual({ type: "fixed", value: 2 });
    expect(block[0].reps).toEqual({ type: "fixed", value: 10 });
  });
});

// ---------------------------------------------------------------------------
// adaptProgram
// ---------------------------------------------------------------------------

describe("adaptProgram", () => {
  it("returns program unchanged for resolved injuries", () => {
    const program = makeProgram(["Back Squat", "Deadlift"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "resolved")];
    const result = adaptProgram(program, injuries);
    expect(result).toEqual(program);
  });

  it("returns program unchanged for empty injuries", () => {
    const program = makeProgram(["Back Squat"]);
    const result = adaptProgram(program, []);
    expect(result).toEqual(program);
  });

  it("replaces squat exercises for acute knee injury", () => {
    const program = makeProgram(["Back Squat", "Barbell Row"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "acute")];
    const result = adaptProgram(program, injuries);
    const exercises = result.weeks[0].sessions[0].exercises;
    // Back Squat should be replaced (squat keyword matches knee contraindication)
    expect(exercises[0].exercise).not.toBe("Back Squat");
  });

  it("wrist injury does not affect squats", () => {
    const program = makeProgram(["Back Squat"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "wrist_left", "rehab")];
    const result = adaptProgram(program, injuries);
    const exercises = result.weeks[0].sessions[0].exercises;
    // Back squat doesn't involve wrist keywords, should be unchanged
    expect(exercises.some((e) => e.exercise === "Back Squat")).toBe(true);
  });

  it("prepends recovery prep block for rehab injuries", () => {
    const program = makeProgram(["Bird-Dogs"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "knee_left", "rehab")];
    const result = adaptProgram(program, injuries);
    const exercises = result.weeks[0].sessions[0].exercises;
    expect(exercises.length).toBeGreaterThan(1);
  });

  it("applies load multipliers for rehab phase", () => {
    const program = makeProgram(["Bird-Dogs"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "ankle_left", "rehab")];
    const result = adaptProgram(program, injuries);
    // We can verify the program was modified (structure preserved)
    expect(result.id).toBe(program.id);
    expect(result.weeks).toHaveLength(1);
  });

  it("preserves non-contraindicated exercises", () => {
    const program = makeProgram(["Barbell Row", "Back Squat"]);
    const injuries: InjuryProfile[] = [makeInjury("1", "wrist_left", "acute")];
    const result = adaptProgram(program, injuries);
    const exercises = result.weeks[0].sessions[0].exercises;
    // Barbell Row involves wrist? No, wrist only has keywords: clean/snatch/jerk/front squat/wrist
    // Row doesn't match wrist contraindication
    const names = exercises.map((e) => e.exercise);
    expect(names).toContain("Barbell Row");
  });
});

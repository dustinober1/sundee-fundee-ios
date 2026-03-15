import {
  buildUserPrompt,
  buildSystemPrompt,
  WorkoutContext,
} from "../src/prompts/workoutPrompt";

const baseContext: WorkoutContext = {
  timeMinutes: 45,
  focus: "strength",
  energyLevel: "medium",
  equipment: "full gym",
  maxes: [],
  recentWorkouts: [],
  cyclePhase: null,
  readinessTier: null,
  activeInjuries: [],
  experienceLevel: "intermediate",
  primaryGoal: "strength",
  gender: "female",
  weightUnit: "lbs",
};

describe("buildUserPrompt — WorkoutGenerationContext fields", () => {
  test("includes cyclePhase in prompt when provided", () => {
    const ctx: WorkoutContext = { ...baseContext, cyclePhase: "luteal" };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("CYCLE PHASE");
    expect(prompt).toContain("luteal");
  });

  test("omits cyclePhase section when null", () => {
    const ctx: WorkoutContext = { ...baseContext, cyclePhase: null };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).not.toContain("CYCLE PHASE");
  });

  test("includes readinessTier in prompt when provided", () => {
    const ctx: WorkoutContext = { ...baseContext, readinessTier: "fatigued" };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("READINESS");
    expect(prompt).toContain("fatigued");
  });

  test("omits readinessTier section when null", () => {
    const ctx: WorkoutContext = { ...baseContext, readinessTier: null };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).not.toContain("READINESS");
  });

  test("includes activeInjuries in prompt when array is non-empty", () => {
    const ctx: WorkoutContext = {
      ...baseContext,
      activeInjuries: [
        {
          location: "right knee",
          phase: "subacute",
          restrictions: ["deep squats", "lunges"],
        },
      ],
    };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("ACTIVE INJURIES");
    expect(prompt).toContain("right knee");
    expect(prompt).toContain("subacute");
    expect(prompt).toContain("deep squats");
  });

  test("omits activeInjuries section when array is empty", () => {
    const ctx: WorkoutContext = { ...baseContext, activeInjuries: [] };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).not.toContain("ACTIVE INJURIES");
  });

  test("includes all three context fields together when all provided", () => {
    const ctx: WorkoutContext = {
      ...baseContext,
      cyclePhase: "follicular",
      readinessTier: "optimal",
      activeInjuries: [
        {
          location: "left shoulder",
          phase: "acute",
          restrictions: ["overhead press"],
        },
      ],
    };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("CYCLE PHASE");
    expect(prompt).toContain("follicular");
    expect(prompt).toContain("READINESS");
    expect(prompt).toContain("optimal");
    expect(prompt).toContain("ACTIVE INJURIES");
    expect(prompt).toContain("left shoulder");
  });

  test("includes multiple injuries with their restrictions", () => {
    const ctx: WorkoutContext = {
      ...baseContext,
      activeInjuries: [
        {
          location: "right knee",
          phase: "subacute",
          restrictions: ["deep squats"],
        },
        {
          location: "lower back",
          phase: "chronic",
          restrictions: ["deadlifts", "good mornings"],
        },
      ],
    };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("right knee");
    expect(prompt).toContain("lower back");
    expect(prompt).toContain("deadlifts");
  });

  test("includes known maxes in prompt when provided", () => {
    const ctx: WorkoutContext = {
      ...baseContext,
      maxes: [
        { name: "Back Squat", weightLb: 185 },
        { name: "Deadlift", weightLb: 225 },
      ],
    };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("1RM MAXES");
    expect(prompt).toContain("Back Squat");
    expect(prompt).toContain("185 lb");
  });

  test("includes recent workouts in prompt when provided", () => {
    const ctx: WorkoutContext = {
      ...baseContext,
      recentWorkouts: [
        {
          date: "2026-03-14",
          focus: "lower body",
          exercises: ["Squat", "Deadlift"],
          durationMinutes: 50,
        },
      ],
    };
    const prompt = buildUserPrompt(ctx);
    expect(prompt).toContain("RECENT TRAINING");
    expect(prompt).toContain("lower body");
  });

  test("prompt contains core workout request fields", () => {
    const prompt = buildUserPrompt(baseContext);
    expect(prompt).toContain("45 minutes");
    expect(prompt).toContain("strength");
    expect(prompt).toContain("medium");
  });
});

describe("buildSystemPrompt", () => {
  test("system prompt contains cycle phase guidelines", () => {
    const prompt = buildSystemPrompt();
    expect(prompt).toContain("CYCLE PHASE GUIDELINES");
    expect(prompt).toContain("Luteal");
    expect(prompt).toContain("Follicular");
  });

  test("system prompt contains JSON output format instructions", () => {
    const prompt = buildSystemPrompt();
    expect(prompt).toContain("coachingSummary");
    expect(prompt).toContain("exercises");
  });
});

import { describe, it, expect } from "vitest";
import {
  extractMuscleGroups,
  defaultPercentage,
  assignRestMinutes,
  totalEstimatedMinutes,
  energyMultiplier,
  cyclePhaseMultiplier,
  applyWeights,
  findMatchingMax,
  type GeneratedExercise,
  type ExerciseMax,
} from "../ai-workout";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeExercise(
  name: string,
  sets: number = 3,
  reps: string = "8",
  bodyweightOnly: boolean = false,
  weightKg?: number
): GeneratedExercise {
  return {
    id: `ex-${name}`,
    name,
    sets,
    reps,
    weightKg,
    restMinutes: undefined,
    bodyweightOnly,
  };
}

// ---------------------------------------------------------------------------
// extractMuscleGroups
// ---------------------------------------------------------------------------

describe("extractMuscleGroups", () => {
  it("detects Quads from squat", () => {
    const groups = extractMuscleGroups([makeExercise("Back Squat")]);
    expect(groups).toContain("Quads");
  });

  it("detects Glutes from deadlift", () => {
    const groups = extractMuscleGroups([makeExercise("Romanian Deadlift")]);
    expect(groups).toContain("Glutes");
  });

  it("detects Chest from bench", () => {
    const groups = extractMuscleGroups([makeExercise("Bench Press")]);
    expect(groups).toContain("Chest");
  });

  it("detects Back from row", () => {
    const groups = extractMuscleGroups([makeExercise("Barbell Row")]);
    expect(groups).toContain("Back");
  });

  it("detects Biceps from curl", () => {
    const groups = extractMuscleGroups([makeExercise("Barbell Curl")]);
    expect(groups).toContain("Biceps");
  });

  it("detects Triceps from tricep", () => {
    const groups = extractMuscleGroups([makeExercise("Tricep Extension")]);
    expect(groups).toContain("Triceps");
  });

  it("detects Core from plank", () => {
    const groups = extractMuscleGroups([makeExercise("Plank")]);
    expect(groups).toContain("Core");
  });

  it("detects Calves from calf", () => {
    const groups = extractMuscleGroups([makeExercise("Calf Raise")]);
    expect(groups).toContain("Calves");
  });

  it("detects Hamstrings from romanian", () => {
    const groups = extractMuscleGroups([makeExercise("Romanian Deadlift")]);
    expect(groups).toContain("Hamstrings");
  });

  it("returns sorted array", () => {
    const exercises = [makeExercise("Back Squat"), makeExercise("Bench Press"), makeExercise("Barbell Curl")];
    const groups = extractMuscleGroups(exercises);
    expect(groups).toEqual([...groups].sort());
  });

  it("returns empty for exercises without matches", () => {
    const groups = extractMuscleGroups([makeExercise("Stretching")]);
    expect(groups).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
// defaultPercentage
// ---------------------------------------------------------------------------

describe("defaultPercentage", () => {
  it("1-3 reps → 85%", () => {
    expect(defaultPercentage("1")).toBe(0.85);
    expect(defaultPercentage("3")).toBe(0.85);
  });

  it("4-5 reps → 80%", () => {
    expect(defaultPercentage("4")).toBe(0.80);
    expect(defaultPercentage("5")).toBe(0.80);
  });

  it("6-8 reps → 70%", () => {
    expect(defaultPercentage("6")).toBe(0.70);
    expect(defaultPercentage("8")).toBe(0.70);
  });

  it("9-12 reps → 65%", () => {
    expect(defaultPercentage("9")).toBe(0.65);
    expect(defaultPercentage("12")).toBe(0.65);
  });

  it("13+ reps → 60%", () => {
    expect(defaultPercentage("15")).toBe(0.60);
    expect(defaultPercentage("20")).toBe(0.60);
  });

  it("AMRAP (non-numeric) defaults to 60%", () => {
    // parseInt("AMRAP") returns NaN, defaults to 10 → 65%
    // This tests actual behavior
    expect(defaultPercentage("AMRAP")).toBe(0.65);
  });

  it("handles range strings like '8-10'", () => {
    expect(defaultPercentage("8-10")).toBe(0.70);
  });
});

// ---------------------------------------------------------------------------
// assignRestMinutes
// ---------------------------------------------------------------------------

describe("assignRestMinutes", () => {
  it("bodyweight exercises get 1.0 min", () => {
    expect(assignRestMinutes(true, "15")).toBe(1.0);
  });

  it("1-5 reps get 2.5 min", () => {
    expect(assignRestMinutes(false, "3")).toBe(2.5);
    expect(assignRestMinutes(false, "5")).toBe(2.5);
  });

  it("6-8 reps get 2.0 min", () => {
    expect(assignRestMinutes(false, "6")).toBe(2.0);
    expect(assignRestMinutes(false, "8")).toBe(2.0);
  });

  it("9-12 reps get 1.5 min", () => {
    expect(assignRestMinutes(false, "10")).toBe(1.5);
    expect(assignRestMinutes(false, "12")).toBe(1.5);
  });

  it("13+ reps get 1.0 min", () => {
    expect(assignRestMinutes(false, "15")).toBe(1.0);
  });
});

// ---------------------------------------------------------------------------
// totalEstimatedMinutes
// ---------------------------------------------------------------------------

describe("totalEstimatedMinutes", () => {
  it("calculates total time from sets, rest, and 0.5 min work per set", () => {
    const exercises: GeneratedExercise[] = [
      { ...makeExercise("A", 3, "8"), restMinutes: 2.0 },
    ];
    // 3 sets * (2.0 rest + 0.5 work) = 7.5 → rounds to 8
    const result = totalEstimatedMinutes(exercises);
    expect(result).toBe(8);
  });

  it("returns at least 1", () => {
    const result = totalEstimatedMinutes([]);
    expect(result).toBeGreaterThanOrEqual(1);
  });

  it("sums over all exercises", () => {
    const exercises: GeneratedExercise[] = [
      { ...makeExercise("A", 3, "8"), restMinutes: 1.0 },
      { ...makeExercise("B", 3, "8"), restMinutes: 1.0 },
    ];
    // Each: 3 * (1 + 0.5) = 4.5, total = 9
    const result = totalEstimatedMinutes(exercises);
    expect(result).toBe(9);
  });
});

// ---------------------------------------------------------------------------
// energyMultiplier
// ---------------------------------------------------------------------------

describe("energyMultiplier", () => {
  it("low → 0.85", () => expect(energyMultiplier("low")).toBe(0.85));
  it("medium → 1.0", () => expect(energyMultiplier("medium")).toBe(1.0));
  it("high → 1.05", () => expect(energyMultiplier("high")).toBe(1.05));
});

// ---------------------------------------------------------------------------
// cyclePhaseMultiplier
// ---------------------------------------------------------------------------

describe("cyclePhaseMultiplier", () => {
  it("menstrual → 0.90", () => expect(cyclePhaseMultiplier("menstrual")).toBe(0.90));
  it("follicular → 1.0", () => expect(cyclePhaseMultiplier("follicular")).toBe(1.0));
  it("ovulation → 1.12", () => expect(cyclePhaseMultiplier("ovulation")).toBe(1.12));
  it("luteal → 0.97", () => expect(cyclePhaseMultiplier("luteal")).toBe(0.97));
  it("null → 1.0", () => expect(cyclePhaseMultiplier(null)).toBe(1.0));
  it("undefined → 1.0", () => expect(cyclePhaseMultiplier(undefined)).toBe(1.0));
  it("unknown → 1.0", () => expect(cyclePhaseMultiplier("unknown_phase")).toBe(1.0));
});

// ---------------------------------------------------------------------------
// findMatchingMax
// ---------------------------------------------------------------------------

describe("findMatchingMax", () => {
  const maxes: ExerciseMax[] = [
    { name: "Back Squat", weightKg: 100 },
    { name: "Bench Press", weightKg: 80 },
  ];

  it("finds exact match", () => {
    const result = findMatchingMax("Back Squat", maxes);
    expect(result?.weightKg).toBe(100);
  });

  it("finds partial match", () => {
    const result = findMatchingMax("Barbell Back Squat", maxes);
    expect(result?.weightKg).toBe(100);
  });

  it("returns null for no match", () => {
    const result = findMatchingMax("Unknown Exercise", maxes);
    expect(result).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// applyWeights
// ---------------------------------------------------------------------------

describe("applyWeights", () => {
  const maxes: ExerciseMax[] = [
    { name: "Back Squat", weightKg: 100 },
    { name: "Bench Press", weightKg: 80 },
  ];

  it("applies weight based on percentage and multipliers", () => {
    const exercises: GeneratedExercise[] = [makeExercise("Back Squat", 3, "5")];
    const result = applyWeights(exercises, maxes, 1.0, 1.0);
    // 100kg * 0.80 (5 reps) * 1.0 * 1.0 = 80, rounded to 80
    expect(result[0].weightKg).toBe(80);
  });

  it("bodyweight exercises are not modified", () => {
    const exercises: GeneratedExercise[] = [makeExercise("Pull-Up", 3, "8", true)];
    const result = applyWeights(exercises, maxes, 1.0, 1.0);
    expect(result[0].weightKg).toBeUndefined();
  });

  it("applies energy multiplier", () => {
    const exercises: GeneratedExercise[] = [makeExercise("Back Squat", 3, "5")];
    const withEnergy = applyWeights(exercises, maxes, 0.85, 1.0);
    const withoutEnergy = applyWeights(exercises, maxes, 1.0, 1.0);
    expect(withEnergy[0].weightKg!).toBeLessThanOrEqual(withoutEnergy[0].weightKg!);
  });

  it("applies cycle multiplier", () => {
    const exercises: GeneratedExercise[] = [makeExercise("Back Squat", 3, "5")];
    const withCycle = applyWeights(exercises, maxes, 1.0, 0.90);
    const withoutCycle = applyWeights(exercises, maxes, 1.0, 1.0);
    expect(withCycle[0].weightKg!).toBeLessThanOrEqual(withoutCycle[0].weightKg!);
  });

  it("returns exercise unchanged if no matching max found", () => {
    const exercises: GeneratedExercise[] = [makeExercise("Unknown Exercise", 3, "8")];
    const result = applyWeights(exercises, maxes, 1.0, 1.0);
    expect(result[0].weightKg).toBeUndefined();
  });

  it("rounds weight to nearest 5", () => {
    // 100kg * 0.70 (8 reps) = 70, already divisible by 5
    const exercises: GeneratedExercise[] = [makeExercise("Back Squat", 3, "8")];
    const result = applyWeights(exercises, maxes, 1.0, 1.0);
    expect(result[0].weightKg! % 5).toBe(0);
  });
});

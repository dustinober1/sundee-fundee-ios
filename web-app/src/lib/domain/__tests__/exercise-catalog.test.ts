import { describe, it, expect } from "vitest";
import {
  WEIGHTLIFTING_EXERCISES,
  isWeightliftingExercise,
  CONDITIONING_EXERCISES,
  isConditioningExercise,
  conditioningScoringType,
  formatConditioningValue,
  isBetterConditioningScore,
} from "../exercise-catalog";

// ---------------------------------------------------------------------------
// Weightlifting Exercise Catalog
// ---------------------------------------------------------------------------

describe("WEIGHTLIFTING_EXERCISES", () => {
  it("contains exactly 59 exercises", () => {
    expect(WEIGHTLIFTING_EXERCISES).toHaveLength(59);
  });

  it("contains 9 squats", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter((e) => e.category === "Squat")
    ).toHaveLength(9);
  });

  it("contains 13 hip hinge exercises", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter((e) => e.category === "Hip Hinge")
    ).toHaveLength(13);
  });

  it("contains 10 press exercises", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter((e) => e.category === "Press")
    ).toHaveLength(10);
  });

  it("contains 12 pull exercises", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter((e) => e.category === "Pull")
    ).toHaveLength(12);
  });

  it("contains 4 carry exercises", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter((e) => e.category === "Carry")
    ).toHaveLength(4);
  });

  it("contains 11 olympic weightlifting exercises", () => {
    expect(
      WEIGHTLIFTING_EXERCISES.filter(
        (e) => e.category === "Olympic Weightlifting"
      )
    ).toHaveLength(11);
  });
});

describe("isWeightliftingExercise", () => {
  it("returns true for a known exercise", () => {
    expect(isWeightliftingExercise("Back Squat")).toBe(true);
  });

  it("returns true for a hip hinge exercise with straps", () => {
    expect(
      isWeightliftingExercise("Conventional Deadlift (With Straps)")
    ).toBe(true);
  });

  it("returns true for an olympic lift", () => {
    expect(isWeightliftingExercise("Clean and Jerk")).toBe(true);
  });

  it("returns false for an unknown exercise", () => {
    expect(isWeightliftingExercise("Bicep Curl")).toBe(false);
  });

  it("returns false for empty string", () => {
    expect(isWeightliftingExercise("")).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Conditioning Exercise Catalog
// ---------------------------------------------------------------------------

describe("CONDITIONING_EXERCISES", () => {
  it("contains exactly 31 exercises", () => {
    expect(CONDITIONING_EXERCISES).toHaveLength(31);
  });

  it("contains 21 reps-based exercises", () => {
    expect(
      CONDITIONING_EXERCISES.filter((e) => e.defaultScoringType === "reps")
    ).toHaveLength(21);
  });

  it("contains 10 time-based exercises", () => {
    expect(
      CONDITIONING_EXERCISES.filter((e) => e.defaultScoringType === "time")
    ).toHaveLength(10);
  });
});

describe("isConditioningExercise", () => {
  it("returns true for a known conditioning exercise", () => {
    expect(isConditioningExercise("Wall Ball")).toBe(true);
  });

  it("returns true for a time-based exercise", () => {
    expect(isConditioningExercise("400m Run")).toBe(true);
  });

  it("returns false for a weightlifting exercise", () => {
    expect(isConditioningExercise("Back Squat")).toBe(false);
  });

  it("returns false for an unknown exercise", () => {
    expect(isConditioningExercise("Zumba")).toBe(false);
  });
});

describe("conditioningScoringType", () => {
  it("returns reps for Wall Ball", () => {
    expect(conditioningScoringType("Wall Ball")).toBe("reps");
  });

  it("returns time for 400m Run", () => {
    expect(conditioningScoringType("400m Run")).toBe("time");
  });

  it("returns time for 2K Row", () => {
    expect(conditioningScoringType("2K Row")).toBe("time");
  });

  it("returns undefined for unknown exercise", () => {
    expect(conditioningScoringType("Zumba")).toBeUndefined();
  });
});

describe("formatConditioningValue", () => {
  it("formats time: 0 seconds → 0:00", () => {
    expect(formatConditioningValue(0, "time")).toBe("0:00");
  });

  it("formats time: 90 seconds → 1:30", () => {
    expect(formatConditioningValue(90, "time")).toBe("1:30");
  });

  it("formats time: 605 seconds → 10:05", () => {
    expect(formatConditioningValue(605, "time")).toBe("10:05");
  });

  it("formats time: 3600 seconds → 60:00", () => {
    expect(formatConditioningValue(3600, "time")).toBe("60:00");
  });

  it("formats time: truncates fractional seconds", () => {
    expect(formatConditioningValue(90.9, "time")).toBe("1:30");
  });

  it("formats reps: 1 rep (singular)", () => {
    expect(formatConditioningValue(1, "reps")).toBe("1 rep");
  });

  it("formats reps: 0 reps (plural)", () => {
    expect(formatConditioningValue(0, "reps")).toBe("0 reps");
  });

  it("formats reps: 50 reps", () => {
    expect(formatConditioningValue(50, "reps")).toBe("50 reps");
  });

  it("formats reps: truncates fractional", () => {
    expect(formatConditioningValue(9.9, "reps")).toBe("9 reps");
  });
});

describe("isBetterConditioningScore", () => {
  it("time: lower is better", () => {
    expect(isBetterConditioningScore(80, 90, "time")).toBe(true);
  });

  it("time: higher is not better", () => {
    expect(isBetterConditioningScore(100, 90, "time")).toBe(false);
  });

  it("time: equal is not better", () => {
    expect(isBetterConditioningScore(90, 90, "time")).toBe(false);
  });

  it("reps: higher is better", () => {
    expect(isBetterConditioningScore(100, 90, "reps")).toBe(true);
  });

  it("reps: lower is not better", () => {
    expect(isBetterConditioningScore(80, 90, "reps")).toBe(false);
  });

  it("reps: equal is not better", () => {
    expect(isBetterConditioningScore(90, 90, "reps")).toBe(false);
  });

  it("always better than undefined (time)", () => {
    expect(isBetterConditioningScore(300, undefined, "time")).toBe(true);
  });

  it("always better than undefined (reps)", () => {
    expect(isBetterConditioningScore(0, undefined, "reps")).toBe(true);
  });
});

import { describe, it, expect } from "vitest";
import {
  roundToNearestFive,
  calculateTargetWeight,
  getNextRecommendedWeight,
  wasSetSuccessful,
  isPersonalRecord,
  calculateVolumeLoad,
  detectPlateau,
  estimate1RM,
  isPR,
} from "../weight-calculations";
import { SessionResult } from "../types";

describe("roundToNearestFive", () => {
  it("rounds to nearest 5 — exact", () => {
    expect(roundToNearestFive(100)).toBe(100);
  });
  it("rounds up when >= 2.5", () => {
    expect(roundToNearestFive(102.5)).toBe(105);
  });
  it("rounds down when < 2.5", () => {
    expect(roundToNearestFive(101)).toBe(100);
  });
  it("rounds 0", () => {
    expect(roundToNearestFive(0)).toBe(0);
  });
  it("works with decimals", () => {
    expect(roundToNearestFive(67.5)).toBe(70);
  });
});

describe("calculateTargetWeight", () => {
  it("calculates 80% of 100kg", () => {
    expect(calculateTargetWeight(100, 0.8)).toBe(80);
  });
  it("rounds result to nearest 5", () => {
    // 100 * 0.75 = 75
    expect(calculateTargetWeight(100, 0.75)).toBe(75);
    // 100 * 0.77 = 77 → rounds to 75
    expect(calculateTargetWeight(100, 0.77)).toBe(75);
    // 100 * 0.78 = 78 → rounds to 80
    expect(calculateTargetWeight(100, 0.78)).toBe(80);
  });
  it("handles 0 1RM", () => {
    expect(calculateTargetWeight(0, 0.8)).toBe(0);
  });
});

describe("getNextRecommendedWeight", () => {
  it("first: returns 70% of 1RM rounded to 5", () => {
    expect(getNextRecommendedWeight(0, SessionResult.first, 100)).toBe(70);
  });
  it("success: adds 5 and rounds", () => {
    expect(getNextRecommendedWeight(70, SessionResult.success, 100)).toBe(75);
  });
  it("success: already on a multiple of 5", () => {
    expect(getNextRecommendedWeight(80, SessionResult.success, 100)).toBe(85);
  });
  it("failure: subtracts 5 and rounds", () => {
    expect(getNextRecommendedWeight(70, SessionResult.failure, 100)).toBe(65);
  });
  it("failure: floors at 50% of 1RM", () => {
    // current = 52, 1RM = 100 → floor = 50, decreased = 50 → max(50, 50) = 50
    expect(getNextRecommendedWeight(52, SessionResult.failure, 100)).toBe(50);
  });
  it("failure: does not go below 50% floor", () => {
    expect(getNextRecommendedWeight(50, SessionResult.failure, 100)).toBe(50);
  });
});

describe("wasSetSuccessful", () => {
  it("succeeds when reps and weight both met", () => {
    expect(wasSetSuccessful(5, 5, 100, 100)).toBe(true);
  });
  it("fails when reps below prescribed", () => {
    expect(wasSetSuccessful(4, 5, 100, 100)).toBe(false);
  });
  it("fails when weight below prescribed", () => {
    expect(wasSetSuccessful(5, 5, 90, 100)).toBe(false);
  });
  it("succeeds when reps exceeded", () => {
    expect(wasSetSuccessful(7, 5, 100, 100)).toBe(true);
  });
  it("succeeds with no prescribed weight", () => {
    expect(wasSetSuccessful(5, 5, 0)).toBe(true);
  });
  it("fails with no prescribed weight but insufficient reps", () => {
    expect(wasSetSuccessful(3, 5, 0)).toBe(false);
  });
});

describe("isPersonalRecord", () => {
  it("returns true when weight exceeds previous max", () => {
    expect(isPersonalRecord(105, 100)).toBe(true);
  });
  it("returns false when weight equals previous max", () => {
    expect(isPersonalRecord(100, 100)).toBe(false);
  });
  it("returns false when weight is below previous max", () => {
    expect(isPersonalRecord(95, 100)).toBe(false);
  });
});

describe("calculateVolumeLoad", () => {
  it("calculates weight × reps × sets", () => {
    expect(calculateVolumeLoad(100, 5, 3)).toBe(1500);
  });
  it("returns 0 when weight is 0", () => {
    expect(calculateVolumeLoad(0, 5, 3)).toBe(0);
  });
  it("returns 0 when reps is 0", () => {
    expect(calculateVolumeLoad(100, 0, 3)).toBe(0);
  });
});

describe("detectPlateau", () => {
  it("returns false for fewer than 3 data points", () => {
    expect(detectPlateau([])).toBe(false);
    expect(detectPlateau([100])).toBe(false);
    expect(detectPlateau([100, 100])).toBe(false);
  });
  it("detects plateau when last 3 within 5kg", () => {
    expect(detectPlateau([80, 100, 102, 103])).toBe(true);
  });
  it("detects plateau when all exactly same", () => {
    expect(detectPlateau([100, 100, 100])).toBe(true);
  });
  it("returns false when range > 5kg", () => {
    expect(detectPlateau([100, 105, 111])).toBe(false);
  });
  it("uses only last 3 values", () => {
    // first 3 would be a plateau but last 3 are not
    expect(detectPlateau([100, 100, 100, 100, 120])).toBe(false);
  });
  it("detects plateau on exactly 5kg spread", () => {
    expect(detectPlateau([100, 103, 105])).toBe(true);
  });
});

describe("estimate1RM", () => {
  it("returns weight unchanged for 1 rep", () => {
    expect(estimate1RM(100, 1)).toBe(100);
  });
  it("returns weight unchanged for 0 reps", () => {
    expect(estimate1RM(100, 0)).toBe(100);
  });
  it("applies Epley formula for multiple reps", () => {
    // 100 * (1 + 5/30) = 100 * 1.1667 = 116.67
    expect(estimate1RM(100, 5)).toBeCloseTo(116.67, 1);
  });
  it("10 reps", () => {
    // 100 * (1 + 10/30) = 100 * 1.333 = 133.33
    expect(estimate1RM(100, 10)).toBeCloseTo(133.33, 1);
  });
});

describe("isPR", () => {
  it("returns true when new estimate exceeds current max", () => {
    expect(isPR(110, 100)).toBe(true);
  });
  it("returns false when equal to current max", () => {
    expect(isPR(100, 100)).toBe(false);
  });
  it("returns false when below current max", () => {
    expect(isPR(90, 100)).toBe(false);
  });
});

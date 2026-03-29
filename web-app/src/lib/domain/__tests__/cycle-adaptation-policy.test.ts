import { describe, it, expect } from "vitest";
import {
  PHASE_MULTIPLIERS,
  resolveReadinessTier,
  resolveConfidence,
  applyPhaseAdjustment,
} from "../cycle-adaptation-policy";

describe("PHASE_MULTIPLIERS", () => {
  it("menstrual multipliers are 0.90", () => {
    expect(PHASE_MULTIPLIERS.menstrual.load).toBe(0.90);
    expect(PHASE_MULTIPLIERS.menstrual.sets).toBe(0.90);
    expect(PHASE_MULTIPLIERS.menstrual.reps).toBe(0.90);
  });

  it("follicular multipliers are 1.00", () => {
    expect(PHASE_MULTIPLIERS.follicular.load).toBe(1.00);
    expect(PHASE_MULTIPLIERS.follicular.sets).toBe(1.00);
    expect(PHASE_MULTIPLIERS.follicular.reps).toBe(1.00);
  });

  it("ovulation multipliers are correct", () => {
    expect(PHASE_MULTIPLIERS.ovulation.load).toBe(1.12);
    expect(PHASE_MULTIPLIERS.ovulation.sets).toBe(1.05);
    expect(PHASE_MULTIPLIERS.ovulation.reps).toBe(0.95);
  });

  it("luteal multipliers are correct", () => {
    expect(PHASE_MULTIPLIERS.luteal.load).toBe(0.97);
    expect(PHASE_MULTIPLIERS.luteal.sets).toBe(0.95);
    expect(PHASE_MULTIPLIERS.luteal.reps).toBe(0.92);
  });
});

describe("resolveReadinessTier", () => {
  it("returns low for score <= 3", () => {
    expect(resolveReadinessTier(1)).toBe("low");
    expect(resolveReadinessTier(3)).toBe("low");
    expect(resolveReadinessTier(0)).toBe("low");
  });

  it("returns high for score >= 8", () => {
    expect(resolveReadinessTier(8)).toBe("high");
    expect(resolveReadinessTier(10)).toBe("high");
  });

  it("returns neutral for score 4-7", () => {
    expect(resolveReadinessTier(4)).toBe("neutral");
    expect(resolveReadinessTier(5)).toBe("neutral");
    expect(resolveReadinessTier(7)).toBe("neutral");
  });

  it("returns neutral for undefined/null", () => {
    expect(resolveReadinessTier(undefined)).toBe("neutral");
    expect(resolveReadinessTier(null)).toBe("neutral");
  });
});

describe("resolveConfidence", () => {
  it("returns low for 0 logs", () => {
    expect(resolveConfidence(null, null, 0, null)).toBe("low");
  });

  it("returns high for 3+ logs with current phase", () => {
    expect(resolveConfidence("follicular", null, 3, new Date(), new Date())).toBe("high");
  });

  it("returns medium for current phase with fewer than 3 logs", () => {
    expect(resolveConfidence("follicular", null, 2, new Date(), new Date())).toBe("medium");
  });

  it("returns medium for stale data > 60 days", () => {
    const old = new Date();
    old.setDate(old.getDate() - 61);
    expect(resolveConfidence("follicular", null, 5, old, new Date())).toBe("medium");
  });

  it("returns low when no current phase and < 3 logs", () => {
    expect(resolveConfidence(null, null, 2, new Date(), new Date())).toBe("low");
  });
});

describe("applyPhaseAdjustment", () => {
  const baseExercise = {
    exercise: "Back Squat",
    sets: { type: "fixed" as const, value: 4 },
    reps: { type: "fixed" as const, value: 8 },
    percent1RM: 0.75,
  };

  it("follicular phase with neutral readiness and high confidence returns unchanged sets/reps", () => {
    const result = applyPhaseAdjustment(baseExercise, "follicular", "neutral", "high");
    // follicular multiplier is 1.0, so blendMultiplier = 1.0 + (1.0 - 1.0) * 1.0 * 1.0 = 1.0
    expect(result.sets).toEqual({ type: "fixed", value: 4 });
    expect(result.reps).toEqual({ type: "fixed", value: 8 });
  });

  it("menstrual phase reduces load percent1RM", () => {
    const result = applyPhaseAdjustment(baseExercise, "menstrual", "neutral", "high");
    // load target = 0.90, rs=1.0, cs=1.0 -> blend = 1 + (0.9-1)*1*1 = 0.9
    expect(result.percent1RM).toBeLessThan(0.75);
  });

  it("ovulation phase increases percent1RM", () => {
    const result = applyPhaseAdjustment(baseExercise, "ovulation", "neutral", "high");
    expect(result.percent1RM).toBeGreaterThan(0.75);
  });

  it("clamps percent1RM within 0.4 to 1.1", () => {
    const ex = { ...baseExercise, percent1RM: 1.05 };
    const result = applyPhaseAdjustment(ex, "ovulation", "high", "high");
    expect(result.percent1RM).toBeLessThanOrEqual(1.1);
  });

  it("AMRAP reps are unchanged", () => {
    const ex = { ...baseExercise, reps: { type: "amrap" as const } };
    const result = applyPhaseAdjustment(ex, "menstrual", "low", "high");
    expect(result.reps).toEqual({ type: "amrap" });
  });

  it("text reps are unchanged", () => {
    const ex = { ...baseExercise, reps: { type: "text" as const, value: "10 sec" } };
    const result = applyPhaseAdjustment(ex, "menstrual", "low", "high");
    expect(result.reps).toEqual({ type: "text", value: "10 sec" });
  });

  it("range reps are scaled", () => {
    const ex = { ...baseExercise, reps: { type: "range" as const, low: 8, high: 12 } };
    const result = applyPhaseAdjustment(ex, "menstrual", "neutral", "high");
    if (result.reps.type === "range") {
      expect(result.reps.low).toBeLessThanOrEqual(8);
      expect(result.reps.high).toBeLessThanOrEqual(12);
    }
  });

  it("low confidence dampens adjustment", () => {
    const highConfResult = applyPhaseAdjustment(baseExercise, "menstrual", "neutral", "high");
    const lowConfResult = applyPhaseAdjustment(baseExercise, "menstrual", "neutral", "low");
    // Low confidence should result in less deviation from baseline
    const highDelta = Math.abs((highConfResult.percent1RM ?? 0) - 0.75);
    const lowDelta = Math.abs((lowConfResult.percent1RM ?? 0) - 0.75);
    expect(lowDelta).toBeLessThanOrEqual(highDelta);
  });
});

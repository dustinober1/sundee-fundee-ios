import { describe, it, expect } from "vitest";
import {
  LOAD_MULTIPLIERS,
  adjustExerciseValueByMultiplier,
  adjustLoad,
  applyLoadMultipliers,
  analyzePainTrend,
  hasRecentLog,
  sparklineData,
  evaluateTransition,
  type PainLog,
} from "../injury-support";

// ---------------------------------------------------------------------------
// LOAD_MULTIPLIERS
// ---------------------------------------------------------------------------

describe("LOAD_MULTIPLIERS", () => {
  it("acute phase has all zeros", () => {
    expect(LOAD_MULTIPLIERS.acute.load).toBe(0);
    expect(LOAD_MULTIPLIERS.acute.sets).toBe(0);
    expect(LOAD_MULTIPLIERS.acute.reps).toBe(0);
  });

  it("rehab phase multipliers are correct", () => {
    expect(LOAD_MULTIPLIERS.rehab.load).toBe(0.30);
    expect(LOAD_MULTIPLIERS.rehab.sets).toBe(0.50);
    expect(LOAD_MULTIPLIERS.rehab.reps).toBe(0.70);
  });

  it("lightLoad phase multipliers are correct", () => {
    expect(LOAD_MULTIPLIERS.lightLoad.load).toBe(0.50);
    expect(LOAD_MULTIPLIERS.lightLoad.sets).toBe(0.75);
    expect(LOAD_MULTIPLIERS.lightLoad.reps).toBe(0.85);
  });

  it("returnToPlay phase multipliers are correct", () => {
    expect(LOAD_MULTIPLIERS.returnToPlay.load).toBe(0.80);
    expect(LOAD_MULTIPLIERS.returnToPlay.sets).toBe(0.90);
    expect(LOAD_MULTIPLIERS.returnToPlay.reps).toBe(1.0);
  });

  it("resolved phase multipliers are all 1", () => {
    expect(LOAD_MULTIPLIERS.resolved.load).toBe(1.0);
    expect(LOAD_MULTIPLIERS.resolved.sets).toBe(1.0);
    expect(LOAD_MULTIPLIERS.resolved.reps).toBe(1.0);
  });
});

// ---------------------------------------------------------------------------
// adjustExerciseValueByMultiplier
// ---------------------------------------------------------------------------

describe("adjustExerciseValueByMultiplier", () => {
  it("scales fixed value", () => {
    const result = adjustExerciseValueByMultiplier({ type: "fixed", value: 10 }, 0.5);
    expect(result).toEqual({ type: "fixed", value: 5 });
  });

  it("floors fixed value to minimum of 1", () => {
    const result = adjustExerciseValueByMultiplier({ type: "fixed", value: 1 }, 0.0);
    expect(result.type === "fixed" && result.value).toBeGreaterThanOrEqual(1);
  });

  it("scales range value", () => {
    const result = adjustExerciseValueByMultiplier({ type: "range", low: 8, high: 12 }, 0.5);
    expect(result).toEqual({ type: "range", low: 4, high: 6 });
  });

  it("AMRAP passes through unchanged", () => {
    const result = adjustExerciseValueByMultiplier({ type: "amrap" }, 0.5);
    expect(result).toEqual({ type: "amrap" });
  });

  it("text passes through unchanged", () => {
    const result = adjustExerciseValueByMultiplier({ type: "text", value: "hold" }, 0.5);
    expect(result).toEqual({ type: "text", value: "hold" });
  });
});

// ---------------------------------------------------------------------------
// adjustLoad
// ---------------------------------------------------------------------------

describe("adjustLoad", () => {
  it("multiplies percent1RM", () => {
    expect(adjustLoad(0.75, 0.8)).toBeCloseTo(0.6);
  });

  it("returns undefined for null input", () => {
    expect(adjustLoad(null, 0.8)).toBeUndefined();
  });

  it("returns undefined for undefined input", () => {
    expect(adjustLoad(undefined, 0.8)).toBeUndefined();
  });
});

// ---------------------------------------------------------------------------
// applyLoadMultipliers
// ---------------------------------------------------------------------------

describe("applyLoadMultipliers", () => {
  const baseExercise = {
    exercise: "Back Squat",
    sets: { type: "fixed" as const, value: 4 },
    reps: { type: "fixed" as const, value: 8 },
    percent1RM: 0.75,
  };

  it("resolved phase returns exercise unchanged", () => {
    const result = applyLoadMultipliers(baseExercise, "resolved");
    expect(result).toEqual(baseExercise);
  });

  it("rehab phase reduces sets by 50%", () => {
    const result = applyLoadMultipliers(baseExercise, "rehab");
    expect(result.sets).toEqual({ type: "fixed", value: 2 });
  });

  it("rehab phase reduces reps by 30%", () => {
    const result = applyLoadMultipliers(baseExercise, "rehab");
    expect(result.reps.type).toBe("fixed");
    if (result.reps.type === "fixed") {
      expect(result.reps.value).toBeCloseTo(6, 0);
    }
  });

  it("rehab phase reduces percent1RM by 70%", () => {
    const result = applyLoadMultipliers(baseExercise, "rehab");
    expect(result.percent1RM).toBeCloseTo(0.225, 3);
  });
});

// ---------------------------------------------------------------------------
// analyzePainTrend
// ---------------------------------------------------------------------------

function makeLogs(levels: number[]): PainLog[] {
  const now = new Date();
  return levels.map((painLevel, i) => ({
    injuryId: "test",
    painLevel,
    recordedAt: new Date(now.getTime() - (levels.length - 1 - i) * 86400 * 1000),
  }));
}

describe("analyzePainTrend", () => {
  it("returns zeroed result for empty logs", () => {
    const result = analyzePainTrend([]);
    expect(result.trailingAverage).toBe(0);
    expect(result.isImproving).toBe(false);
    expect(result.latestPainLevel).toBeNull();
    expect(result.readingCount).toBe(0);
  });

  it("detects improving trend (newer lower than older)", () => {
    // Older: high pain, newer: low pain
    const logs = makeLogs([8, 7, 6, 3, 2]);
    const result = analyzePainTrend(logs);
    expect(result.isImproving).toBe(true);
  });

  it("detects worsening trend (newer higher than older)", () => {
    const logs = makeLogs([2, 3, 5, 7, 8]);
    const result = analyzePainTrend(logs);
    expect(result.isImproving).toBe(false);
  });

  it("computes trailing average correctly", () => {
    const logs = makeLogs([4, 6]);
    const result = analyzePainTrend(logs);
    expect(result.trailingAverage).toBe(5);
  });

  it("returns latest pain level", () => {
    const logs = makeLogs([5, 3, 1]);
    const result = analyzePainTrend(logs);
    expect(result.latestPainLevel).toBe(1);
  });

  it("respects windowSize", () => {
    const logs = makeLogs([9, 9, 9, 1, 1]);
    const result = analyzePainTrend(logs, 2);
    expect(result.trailingAverage).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// hasRecentLog
// ---------------------------------------------------------------------------

describe("hasRecentLog", () => {
  it("returns false for empty logs", () => {
    expect(hasRecentLog([], new Date())).toBe(false);
  });

  it("returns true when log is within 24 hours", () => {
    const now = new Date();
    const logs: PainLog[] = [{
      injuryId: "test",
      painLevel: 5,
      recordedAt: new Date(now.getTime() - 60 * 60 * 1000), // 1 hour ago
    }];
    expect(hasRecentLog(logs, now, 24)).toBe(true);
  });

  it("returns false when log is older than cutoff", () => {
    const now = new Date();
    const logs: PainLog[] = [{
      injuryId: "test",
      painLevel: 5,
      recordedAt: new Date(now.getTime() - 48 * 60 * 60 * 1000), // 48 hours ago
    }];
    expect(hasRecentLog(logs, now, 24)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// sparklineData
// ---------------------------------------------------------------------------

describe("sparklineData", () => {
  it("returns pain levels in chronological order", () => {
    const logs = makeLogs([3, 5, 7]);
    const result = sparklineData(logs, 3);
    expect(result).toEqual([3, 5, 7]);
  });

  it("limits to count", () => {
    const logs = makeLogs([1, 2, 3, 4, 5, 6, 7, 8]);
    const result = sparklineData(logs, 3);
    expect(result).toHaveLength(3);
  });

  it("returns last N in chronological order", () => {
    const logs = makeLogs([1, 2, 3, 4, 5]);
    const result = sparklineData(logs, 3);
    expect(result).toEqual([3, 4, 5]);
  });
});

// ---------------------------------------------------------------------------
// evaluateTransition
// ---------------------------------------------------------------------------

describe("evaluateTransition", () => {
  it("suggests acute → rehab when 3+ consecutive days pain <= 5", () => {
    const logs = makeLogs([5, 4, 3]);
    const result = evaluateTransition("injury-1", "acute", logs);
    expect(result).not.toBeNull();
    expect(result!.suggestedPhase).toBe("rehab");
  });

  it("does not suggest transition if threshold not met", () => {
    const logs = makeLogs([6, 4, 3]);
    const result = evaluateTransition("injury-1", "acute", logs);
    expect(result).toBeNull();
  });

  it("suggests rehab → lightLoad when 3+ consecutive days pain <= 3", () => {
    const logs = makeLogs([3, 2, 1]);
    const result = evaluateTransition("injury-1", "rehab", logs);
    expect(result).not.toBeNull();
    expect(result!.suggestedPhase).toBe("lightLoad");
  });

  it("suggests lightLoad → returnToPlay when 3+ days pain <= 2", () => {
    const logs = makeLogs([2, 1, 0]);
    const result = evaluateTransition("injury-1", "lightLoad", logs);
    expect(result).not.toBeNull();
    expect(result!.suggestedPhase).toBe("returnToPlay");
  });

  it("suggests returnToPlay → resolved when 5+ days pain <= 1", () => {
    const logs = makeLogs([1, 0, 1, 0, 1]);
    const result = evaluateTransition("injury-1", "returnToPlay", logs);
    expect(result).not.toBeNull();
    expect(result!.suggestedPhase).toBe("resolved");
  });

  it("returns null for resolved phase", () => {
    const logs = makeLogs([0, 0, 0, 0, 0]);
    const result = evaluateTransition("injury-1", "resolved", logs);
    expect(result).toBeNull();
  });

  it("returns null when not enough logs", () => {
    const logs = makeLogs([3]);
    const result = evaluateTransition("injury-1", "acute", logs);
    expect(result).toBeNull();
  });
});

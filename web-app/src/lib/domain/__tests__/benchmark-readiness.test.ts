import { describe, it, expect } from "vitest";
import {
  calculateBenchmarkReadiness,
  getBestAttemptWindow,
  type ReadinessTier,
} from "../benchmark-readiness";
import type { CyclePhase } from "../types";

describe("calculateBenchmarkReadiness", () => {
  describe("when phase is null", () => {
    it("returns moderate tier with neutral values", () => {
      const result = calculateBenchmarkReadiness(null, 3, []);

      expect(result.tier).toBe("moderate");
      expect(result.reason).toBe("No cycle data available");
      expect(result.phaseMultiplier).toBe(1.0);
      expect(result.emoji).toBe("⚪");
      expect(result.color).toBe("text-text-secondary");
    });
  });

  describe("menstrual phase", () => {
    it("returns recovery for high intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("menstrual" as CyclePhase, 5, ["Heavy Pull"]);

      expect(result.tier).toBe("recovery");
      expect(result.emoji).toBe("🔴");
      expect(result.color).toBe("text-warm-rose");
    });

    it("returns recovery for benchmarks with heavy tags", () => {
      const result = calculateBenchmarkReadiness("menstrual" as CyclePhase, 3, ["Heavy Lifts", "Max Effort"]);

      expect(result.tier).toBe("recovery");
    });

    it("returns recovery for high cardio benchmarks", () => {
      const result = calculateBenchmarkReadiness("menstrual" as CyclePhase, 4, ["High Cardio"]);

      expect(result.tier).toBe("recovery");
    });

    it("returns moderate for light intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("menstrual" as CyclePhase, 2, []);

      expect(result.tier).toBe("moderate");
      expect(result.emoji).toBe("🟡");
    });
  });

  describe("follicular phase", () => {
    it("returns peak for low intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, 2, []);

      expect(result.tier).toBe("peak");
      expect(result.emoji).toBe("🟢");
      expect(result.color).toBe("text-green-600");
    });

    it("returns peak for high intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, 5, ["Heavy Pull"]);

      expect(result.tier).toBe("peak");
      expect(result.reason).toContain("strength window");
    });

    it("returns peak for moderate intensity", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, 3, []);

      expect(result.tier).toBe("peak");
    });
  });

  describe("ovulation phase", () => {
    it("always returns peak regardless of intensity", () => {
      const lowIntensity = calculateBenchmarkReadiness("ovulation" as CyclePhase, 1, []);
      const highIntensity = calculateBenchmarkReadiness("ovulation" as CyclePhase, 5, ["Heavy Pull", "Max Effort"]);

      expect(lowIntensity.tier).toBe("peak");
      expect(highIntensity.tier).toBe("peak");
      expect(highIntensity.reason).toContain("peak performance");
    });

    it("has highest phase multiplier", () => {
      const result = calculateBenchmarkReadiness("ovulation" as CyclePhase, 5, []);

      expect(result.phaseMultiplier).toBe(1.12);
    });
  });

  describe("luteal phase", () => {
    it("returns recovery for max intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("luteal" as CyclePhase, 5, ["Heavy Pull"]);

      expect(result.tier).toBe("recovery");
      expect(result.emoji).toBe("🔴");
    });

    it("returns moderate for high intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("luteal" as CyclePhase, 4, []);

      expect(result.tier).toBe("moderate");
      expect(result.emoji).toBe("🟡");
    });

    it("returns moderate for low intensity benchmarks", () => {
      const result = calculateBenchmarkReadiness("luteal" as CyclePhase, 2, []);

      expect(result.tier).toBe("moderate");
      expect(result.reason).toContain("maintenance");
    });
  });

  describe("with undefined intensity and tags", () => {
    it("handles undefined intensity gracefully", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, undefined, []);

      expect(result.tier).toBe("peak");
    });

    it("handles undefined tags gracefully", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, 3, undefined);

      expect(result.tier).toBe("peak");
    });

    it("handles both undefined gracefully", () => {
      const result = calculateBenchmarkReadiness("follicular" as CyclePhase, undefined, undefined);

      expect(result.tier).toBe("peak");
    });
  });
});

describe("getBestAttemptWindow", () => {
  it("calculates window based on 28-day cycle", () => {
    const lastPeriod = new Date("2026-03-01");
    const result = getBestAttemptWindow(28, lastPeriod);

    // Ovulation window for 28-day cycle starting March 1 should be around days 12-16
    // March 1 + 10 days = March 11 (start of window)
    // March 1 + 14 days = March 15 (end of window)
    expect(result.startDate.getMonth()).toBe(2); // March
    expect(result.endDate.getMonth()).toBe(2); // March
    expect(result.reason).toContain("ovulation");
  });

  it("adjusts window for longer cycles", () => {
    const lastPeriod = new Date("2026-03-01");
    const result = getBestAttemptWindow(35, lastPeriod);

    // For a 35-day cycle, ovulation is around day 16 (35 * 0.45 ≈ 16)
    // Window should be days 14-18
    expect(result.startDate.getDate()).toBeGreaterThan(10);
    expect(result.endDate.getDate()).toBeGreaterThan(15);
  });

  it("adjusts window for shorter cycles", () => {
    const lastPeriod = new Date("2026-03-01");
    const result = getBestAttemptWindow(25, lastPeriod);

    // For a 25-day cycle, ovulation is around day 11 (25 * 0.45 ≈ 11)
    // Window should be days 9-13
    expect(result.startDate.getDate()).toBeLessThan(15);
    expect(result.endDate.getDate()).toBeLessThan(20);
  });

  it("returns a reason explaining the window", () => {
    const result = getBestAttemptWindow(28, new Date("2026-03-01"));

    expect(result.reason).toContain("estrogen");
    expect(result.reason).toContain("testosterone");
  });
});

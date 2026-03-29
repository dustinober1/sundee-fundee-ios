import { describe, it, expect } from "vitest";
import {
  getPhaseBoundaries,
  calculateCycleStatus,
  getPhaseRecommendation,
  type CycleSettings,
  type PeriodLog,
} from "../cycle-calculations";

const defaultSettings: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

describe("getPhaseBoundaries", () => {
  it("returns correct boundaries for a 28-day cycle", () => {
    const b = getPhaseBoundaries(defaultSettings);
    expect(b.menstrual.start).toBe(1);
    expect(b.menstrual.end).toBe(5);
    expect(b.follicular.start).toBe(6);
    expect(b.luteal.end).toBe(28);
  });

  it("ovulation phase ends before luteal starts", () => {
    const b = getPhaseBoundaries(defaultSettings);
    expect(b.ovulation.end).toBeLessThan(b.luteal.start);
  });

  it("all phases together cover the cycle with no gaps (contiguous boundaries)", () => {
    const b = getPhaseBoundaries(defaultSettings);
    // menstrual ends 1 before follicular starts
    expect(b.follicular.start).toBe(b.menstrual.end + 1);
    // luteal ends at cycleLengthDays
    expect(b.luteal.end).toBe(defaultSettings.averageCycleLengthDays);
  });
});

describe("calculateCycleStatus", () => {
  it("returns null for empty logs", () => {
    const result = calculateCycleStatus([], defaultSettings);
    expect(result).toBeNull();
  });

  it("detects menstrual phase on day 2", () => {
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-02");
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result).not.toBeNull();
    expect(result!.currentPhase).toBe("menstrual");
    expect(result!.cycleDay).toBe(2);
  });

  it("detects follicular phase on day 10", () => {
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-10");
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result).not.toBeNull();
    expect(result!.currentPhase).toBe("follicular");
  });

  it("detects luteal phase on day 20", () => {
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-20");
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result).not.toBeNull();
    expect(result!.currentPhase).toBe("luteal");
  });

  it("detects ovulation phase near ovulation day", () => {
    // ovulationDay = 28 - 14 = 14; ovStart = max(7, 12) = 12
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-13"); // day 13 should be ovulation
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result).not.toBeNull();
    expect(result!.currentPhase).toBe("ovulation");
  });

  it("daysUntilNextPhase is non-negative", () => {
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-15");
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result!.daysUntilNextPhase).toBeGreaterThanOrEqual(0);
  });

  it("returns predictedNextPeriod 28 days after cycle start", () => {
    const start = new Date("2024-01-01");
    const ref = new Date("2024-01-05");
    const logs: PeriodLog[] = [{ startDate: start }];
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    const expectedDate = new Date("2024-01-29");
    expect(result!.predictedNextPeriod.getTime()).toBe(expectedDate.getTime());
  });

  it("handles multiple period logs and picks the most recent relevant one", () => {
    const logs: PeriodLog[] = [
      { startDate: new Date("2024-02-01") },
      { startDate: new Date("2024-01-04") },
    ];
    const ref = new Date("2024-02-03");
    const result = calculateCycleStatus(logs, defaultSettings, ref);
    expect(result).not.toBeNull();
    expect(result!.cycleDay).toBe(3);
  });
});

describe("getPhaseRecommendation", () => {
  it("returns menstrual recommendation with low intensity", () => {
    const rec = getPhaseRecommendation("menstrual");
    expect(rec.phase).toBe("menstrual");
    expect(rec.title).toBe("Menstrual Phase");
    expect(rec.intensityRecommendation).toBe("low");
    expect(rec.exercisesToEmphasize.length).toBeGreaterThan(0);
    expect(rec.exercisesToAvoid.length).toBeGreaterThan(0);
  });

  it("returns follicular recommendation with moderate intensity", () => {
    const rec = getPhaseRecommendation("follicular");
    expect(rec.intensityRecommendation).toBe("moderate");
    expect(rec.exercisesToAvoid).toEqual([]);
  });

  it("returns ovulation recommendation with peak intensity", () => {
    const rec = getPhaseRecommendation("ovulation");
    expect(rec.intensityRecommendation).toBe("peak");
    expect(rec.trainingFocus).toContain("PR");
  });

  it("returns luteal recommendation with moderate intensity", () => {
    const rec = getPhaseRecommendation("luteal");
    expect(rec.intensityRecommendation).toBe("moderate");
    expect(rec.exercisesToAvoid.length).toBeGreaterThan(0);
  });

  it("all phases return a non-empty title", () => {
    const phases = ["menstrual", "follicular", "ovulation", "luteal"] as const;
    for (const phase of phases) {
      const rec = getPhaseRecommendation(phase);
      expect(rec.title.length).toBeGreaterThan(0);
    }
  });
});

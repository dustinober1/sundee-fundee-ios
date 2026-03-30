import { describe, it, expect } from "vitest";
import {
  getPhaseForDay,
  getPhaseAdjustmentSummary,
  getPhaseExplanation,
} from "../cycle-calendar";
import type { CycleSettings } from "../cycle-calculations";

const defaultSettings: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

describe("getPhaseForDay", () => {
  it("returns menstrual for day 1", () => {
    expect(getPhaseForDay(1, defaultSettings)).toBe("menstrual");
  });

  it("returns menstrual for day 5", () => {
    expect(getPhaseForDay(5, defaultSettings)).toBe("menstrual");
  });

  it("returns follicular for day 6", () => {
    expect(getPhaseForDay(6, defaultSettings)).toBe("follicular");
  });

  it("returns ovulation for day 13", () => {
    expect(getPhaseForDay(13, defaultSettings)).toBe("ovulation");
  });

  it("returns luteal for day 20", () => {
    expect(getPhaseForDay(20, defaultSettings)).toBe("luteal");
  });

  it("returns luteal for day 28", () => {
    expect(getPhaseForDay(28, defaultSettings)).toBe("luteal");
  });

  it("wraps days beyond cycle length", () => {
    expect(getPhaseForDay(29, defaultSettings)).toBe("menstrual");
  });

  it("handles day 0 by wrapping to last day", () => {
    expect(getPhaseForDay(0, defaultSettings)).toBe("luteal");
  });
});

describe("getPhaseAdjustmentSummary", () => {
  it("returns load +12% for ovulation", () => {
    const summary = getPhaseAdjustmentSummary("ovulation");
    expect(summary).toContain("+12%");
  });

  it("returns load -10% for menstrual", () => {
    const summary = getPhaseAdjustmentSummary("menstrual");
    expect(summary).toContain("-10%");
  });

  it("returns no change for follicular", () => {
    const summary = getPhaseAdjustmentSummary("follicular");
    expect(summary).toContain("baseline");
  });

  it("returns load -3% for luteal", () => {
    const summary = getPhaseAdjustmentSummary("luteal");
    expect(summary).toContain("-3%");
  });
});

describe("getPhaseExplanation", () => {
  it("returns non-empty string for each phase", () => {
    const phases = ["menstrual", "follicular", "ovulation", "luteal"] as const;
    for (const phase of phases) {
      const explanation = getPhaseExplanation(phase);
      expect(explanation.length).toBeGreaterThan(20);
    }
  });

  it("mentions recovery for menstrual", () => {
    expect(getPhaseExplanation("menstrual").toLowerCase()).toContain("recover");
  });

  it("mentions peak for ovulation", () => {
    expect(getPhaseExplanation("ovulation").toLowerCase()).toContain("peak");
  });
});

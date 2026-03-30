import { describe, it, expect } from "vitest";
import {
  getPhaseForDay,
  getPhaseAdjustmentSummary,
  getPhaseExplanation,
  getCycleCalendarData,
} from "../cycle-calendar";
import type { PeriodLog } from "../cycle-calculations";
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

function localDate(year: number, month: number, day: number): Date {
  return new Date(year, month - 1, day);
}

describe("getCycleCalendarData", () => {
  it("returns entries for every day in the month", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 3, 3) }];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    expect(data).toHaveLength(31); // March has 31 days
  });

  it("marks today correctly", () => {
    const today = new Date();
    const logs: PeriodLog[] = [{ startDate: localDate(today.getFullYear(), today.getMonth() + 1, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, today.getMonth() + 1, today.getFullYear());
    const todayEntry = data.find((d) => d.isToday);
    expect(todayEntry).toBeDefined();
    expect(todayEntry!.date.getDate()).toBe(today.getDate());
  });

  it("assigns a phase to each day", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 3, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    for (const entry of data) {
      expect(["menstrual", "follicular", "ovulation", "luteal"]).toContain(entry.phase);
    }
  });

  it("returns null phases when no period logs exist", () => {
    const data = getCycleCalendarData([], defaultSettings, 3, 2026);
    expect(data).toHaveLength(31);
    for (const entry of data) {
      expect(entry.phase).toBeNull();
    }
  });

  it("marks logged period days", () => {
    const logs: PeriodLog[] = [
      { startDate: localDate(2026, 3, 3), endDate: localDate(2026, 3, 7) },
    ];
    const data = getCycleCalendarData(logs, defaultSettings, 3, 2026);
    const loggedDays = data.filter((d) => d.isPeriodLogged);
    expect(loggedDays.length).toBe(5); // Mar 3-7
  });

  it("handles February correctly", () => {
    const logs: PeriodLog[] = [{ startDate: localDate(2026, 2, 1) }];
    const data = getCycleCalendarData(logs, defaultSettings, 2, 2026);
    expect(data).toHaveLength(28); // 2026 is not a leap year
  });
});

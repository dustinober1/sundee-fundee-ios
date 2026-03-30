import { describe, it, expect } from "vitest";
import {
  PREDEFINED_BENCHMARKS,
  BENCHMARK_CATEGORY_CLASSIC_WODS,
  BENCHMARK_CATEGORY_SUNDEE_FUNDEE,
  groupedByCategory,
} from "../benchmark-catalog";

describe("PREDEFINED_BENCHMARKS", () => {
  it("has at least 28 entries", () => {
    expect(PREDEFINED_BENCHMARKS.length).toBeGreaterThanOrEqual(28);
  });

  it("all benchmarks have isPredefined = true", () => {
    for (const b of PREDEFINED_BENCHMARKS) {
      expect(b.isPredefined).toBe(true);
    }
  });

  it("Fran is time-scored", () => {
    const fran = PREDEFINED_BENCHMARKS.find((b) => b.name === "Fran");
    expect(fran).toBeDefined();
    expect(fran!.scoringType).toBe("time");
  });

  it("Cindy is roundsAndReps-scored", () => {
    const cindy = PREDEFINED_BENCHMARKS.find((b) => b.name === "Cindy");
    expect(cindy).toBeDefined();
    expect(cindy!.scoringType).toBe("roundsAndReps");
  });

  it("Murph is time-scored", () => {
    const murph = PREDEFINED_BENCHMARKS.find((b) => b.name === "Murph");
    expect(murph).toBeDefined();
    expect(murph!.scoringType).toBe("time");
  });

  it("1RM Back Squat is weight-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "1RM Back Squat");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("weight");
  });

  it("Max Pull-ups is reps-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Max Pull-ups");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("reps");
  });

  it("1-Mile Run is distance-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "1-Mile Run");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("distance");
  });

  it("5K Run is distance-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "5K Run");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("distance");
  });

  it("all benchmarks have non-empty ids", () => {
    for (const b of PREDEFINED_BENCHMARKS) {
      expect(b.id.length).toBeGreaterThan(0);
    }
  });

  it("all benchmarks have non-empty names", () => {
    for (const b of PREDEFINED_BENCHMARKS) {
      expect(b.name.length).toBeGreaterThan(0);
    }
  });

  it("all benchmarks have non-empty workoutDescriptions", () => {
    for (const b of PREDEFINED_BENCHMARKS) {
      expect(b.workoutDescription.length).toBeGreaterThan(0);
    }
  });

  it("sortOrder is ascending with no gaps relative to index", () => {
    for (let i = 0; i < PREDEFINED_BENCHMARKS.length; i++) {
      expect(PREDEFINED_BENCHMARKS[i].sortOrder).toBe(i);
    }
  });

  // Sundee Fundee Exclusive Benchmarks
  it("Vanessa is time-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Vanessa");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("time");
    expect(entry!.category).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
  });

  it("Eliz is time-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Eliz");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("time");
    expect(entry!.category).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
  });

  it("Adria is time-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Adria");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("time");
    expect(entry!.category).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
  });

  it("Kelsey is time-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Kelsey");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("time");
    expect(entry!.category).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
  });

  it("Margarita is time-scored", () => {
    const entry = PREDEFINED_BENCHMARKS.find((b) => b.name === "Margarita");
    expect(entry).toBeDefined();
    expect(entry!.scoringType).toBe("time");
    expect(entry!.category).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
  });
});

describe("groupedByCategory", () => {
  it("contains Sundee Fundee category as first", () => {
    const grouped = groupedByCategory();
    const categories = Array.from(grouped.keys());
    expect(categories[0]).toBe(BENCHMARK_CATEGORY_SUNDEE_FUNDEE);
    expect(grouped.has(BENCHMARK_CATEGORY_SUNDEE_FUNDEE)).toBe(true);
  });

  it("Sundee Fundee contains all exclusive benchmarks", () => {
    const grouped = groupedByCategory();
    const sundeeFundee = grouped.get(BENCHMARK_CATEGORY_SUNDEE_FUNDEE) ?? [];
    expect(sundeeFundee.some((b) => b.name === "Vanessa")).toBe(true);
    expect(sundeeFundee.some((b) => b.name === "Eliz")).toBe(true);
    expect(sundeeFundee.some((b) => b.name === "Adria")).toBe(true);
    expect(sundeeFundee.some((b) => b.name === "Kelsey")).toBe(true);
    expect(sundeeFundee.some((b) => b.name === "Margarita")).toBe(true);
  });

  it("contains Classic WODs category", () => {
    const grouped = groupedByCategory();
    expect(grouped.has(BENCHMARK_CATEGORY_CLASSIC_WODS)).toBe(true);
  });

  it("Classic WODs contains Fran", () => {
    const grouped = groupedByCategory();
    const classicWODs = grouped.get(BENCHMARK_CATEGORY_CLASSIC_WODS) ?? [];
    expect(classicWODs.some((b) => b.name === "Fran")).toBe(true);
  });

  it("returns a Map", () => {
    const grouped = groupedByCategory();
    expect(grouped instanceof Map).toBe(true);
  });

  it("each category group has at least one entry", () => {
    const grouped = groupedByCategory();
    for (const [, entries] of grouped) {
      expect(entries.length).toBeGreaterThan(0);
    }
  });

  it("total entries match PREDEFINED_BENCHMARKS count", () => {
    const grouped = groupedByCategory();
    let total = 0;
    for (const [, entries] of grouped) {
      total += entries.length;
    }
    expect(total).toBe(PREDEFINED_BENCHMARKS.length);
  });
});

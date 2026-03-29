import { describe, it, expect } from "vitest";
import {
  LB_PER_KG,
  fromKilograms,
  toKilograms,
  parseInputToKilograms,
  formatWeight,
  formatWeightWithUnit,
} from "../weight-unit-conversion";
import { WeightUnit } from "../types";

describe("LB_PER_KG", () => {
  it("has the correct constant", () => {
    expect(LB_PER_KG).toBeCloseTo(2.2046226218, 10);
  });
});

describe("fromKilograms", () => {
  it("returns kg unchanged for kilograms unit", () => {
    expect(fromKilograms(100, WeightUnit.kilograms)).toBe(100);
  });
  it("converts kg to lb", () => {
    expect(fromKilograms(100, WeightUnit.pounds)).toBeCloseTo(220.46226218, 4);
  });
  it("converts 0 kg to 0 lb", () => {
    expect(fromKilograms(0, WeightUnit.pounds)).toBe(0);
  });
  it("converts 1 kg to ~2.205 lb", () => {
    expect(fromKilograms(1, WeightUnit.pounds)).toBeCloseTo(2.2046, 3);
  });
});

describe("toKilograms", () => {
  it("returns value unchanged for kilograms unit", () => {
    expect(toKilograms(100, WeightUnit.kilograms)).toBe(100);
  });
  it("converts lb to kg", () => {
    expect(toKilograms(220.46226218, WeightUnit.pounds)).toBeCloseTo(100, 4);
  });
  it("converts 0 lb to 0 kg", () => {
    expect(toKilograms(0, WeightUnit.pounds)).toBe(0);
  });
});

describe("parseInputToKilograms", () => {
  it("parses a valid kg string", () => {
    expect(parseInputToKilograms("100", WeightUnit.kilograms)).toBeCloseTo(100);
  });
  it("parses a valid lb string and converts to kg", () => {
    expect(parseInputToKilograms("220.46226218", WeightUnit.pounds)).toBeCloseTo(100, 4);
  });
  it("returns null for non-numeric input", () => {
    expect(parseInputToKilograms("abc", WeightUnit.kilograms)).toBeNull();
  });
  it("returns null for empty string", () => {
    expect(parseInputToKilograms("", WeightUnit.kilograms)).toBeNull();
  });
  it("handles whitespace-padded input", () => {
    expect(parseInputToKilograms("  80  ", WeightUnit.kilograms)).toBeCloseTo(80);
  });
  it("parses decimal kg input", () => {
    expect(parseInputToKilograms("82.5", WeightUnit.kilograms)).toBeCloseTo(82.5);
  });
});

describe("formatWeight", () => {
  it("formats whole number without decimal", () => {
    expect(formatWeight(100)).toBe("100");
  });
  it("formats one decimal place", () => {
    expect(formatWeight(100.5)).toBe("100.5");
  });
  it("rounds to 1 decimal", () => {
    expect(formatWeight(100.47)).toBe("100.5");
  });
  it("formats 0", () => {
    expect(formatWeight(0)).toBe("0");
  });
  it("rounds .05 up", () => {
    expect(formatWeight(1.05)).toBe("1.1");
  });
  it("trims .0 from whole numbers after rounding", () => {
    // 99.95 rounds to 100.0 which should display as "100"
    expect(formatWeight(99.95)).toBe("100");
  });
});

describe("formatWeightWithUnit", () => {
  it("formats kg value with kg symbol", () => {
    expect(formatWeightWithUnit(80, WeightUnit.kilograms)).toBe("80 kg");
  });
  it("formats kg value converted to lb with lb symbol", () => {
    // 1 kg ≈ 2.2 lb
    const result = formatWeightWithUnit(1, WeightUnit.pounds);
    expect(result).toBe("2.2 lb");
  });
  it("formats 100 kg in lb", () => {
    // 100 kg = 220.46... lb → formatWeight → "220.5"
    const result = formatWeightWithUnit(100, WeightUnit.pounds);
    expect(result).toBe("220.5 lb");
  });
  it("formats 0 kg in kg", () => {
    expect(formatWeightWithUnit(0, WeightUnit.kilograms)).toBe("0 kg");
  });
});

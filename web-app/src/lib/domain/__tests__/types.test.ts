import { describe, it, expect } from "vitest";
import {
  decodeExerciseValue,
  encodeExerciseValue,
  exerciseValueToString,
  type ExerciseValue,
} from "../types";

describe("decodeExerciseValue", () => {
  it("decodes an integer number as fixed", () => {
    expect(decodeExerciseValue(8)).toEqual({ type: "fixed", value: 8 });
  });

  it("decodes a float number as fixed (floors it)", () => {
    expect(decodeExerciseValue(8.9)).toEqual({ type: "fixed", value: 8 });
  });

  it("decodes 'AMRAP' string as amrap", () => {
    expect(decodeExerciseValue("AMRAP")).toEqual({ type: "amrap" });
  });

  it("decodes 'amrap' (lowercase) as amrap", () => {
    expect(decodeExerciseValue("amrap")).toEqual({ type: "amrap" });
  });

  it("decodes '8-10' string as range", () => {
    expect(decodeExerciseValue("8-10")).toEqual({ type: "range", low: 8, high: 10 });
  });

  it("decodes [8, 10] array as range", () => {
    expect(decodeExerciseValue([8, 10])).toEqual({ type: "range", low: 8, high: 10 });
  });

  it("decodes numeric string as fixed", () => {
    expect(decodeExerciseValue("5")).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes non-numeric string as text", () => {
    expect(decodeExerciseValue("max effort")).toEqual({ type: "text", value: "max effort" });
  });

  it("decodes unknown/null as fixed 0", () => {
    expect(decodeExerciseValue(null)).toEqual({ type: "fixed", value: 0 });
  });

  it("decodes undefined as fixed 0", () => {
    expect(decodeExerciseValue(undefined)).toEqual({ type: "fixed", value: 0 });
  });

  it("ignores arrays longer than 2", () => {
    // A 3-element array is not a valid range — falls through to fixed 0
    expect(decodeExerciseValue([1, 2, 3])).toEqual({ type: "fixed", value: 0 });
  });
});

describe("encodeExerciseValue", () => {
  it("encodes fixed as number", () => {
    expect(encodeExerciseValue({ type: "fixed", value: 5 })).toBe(5);
  });

  it("encodes amrap as 'AMRAP'", () => {
    expect(encodeExerciseValue({ type: "amrap" })).toBe("AMRAP");
  });

  it("encodes range as [low, high]", () => {
    expect(encodeExerciseValue({ type: "range", low: 8, high: 12 })).toEqual([8, 12]);
  });

  it("encodes text as string", () => {
    expect(encodeExerciseValue({ type: "text", value: "heavy" })).toBe("heavy");
  });
});

describe("exerciseValueToString", () => {
  it("formats fixed", () => {
    expect(exerciseValueToString({ type: "fixed", value: 3 })).toBe("3");
  });

  it("formats amrap", () => {
    expect(exerciseValueToString({ type: "amrap" })).toBe("AMRAP");
  });

  it("formats range with en-dash", () => {
    expect(exerciseValueToString({ type: "range", low: 8, high: 10 })).toBe("8\u201310");
  });

  it("formats text", () => {
    expect(exerciseValueToString({ type: "text", value: "hold 2s" })).toBe("hold 2s");
  });
});

describe("encode/decode round-trip", () => {
  const cases: ExerciseValue[] = [
    { type: "fixed", value: 5 },
    { type: "amrap" },
    { type: "range", low: 8, high: 12 },
    { type: "text", value: "heavy" },
  ];

  for (const ev of cases) {
    it(`round-trips ${ev.type}`, () => {
      expect(decodeExerciseValue(encodeExerciseValue(ev))).toEqual(ev);
    });
  }
});

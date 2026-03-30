import { describe, it, expect } from "vitest";
import {
  type ProgramExercise,
  encodeExerciseValue,
  decodeExerciseValue,
  exerciseToFirestore,
  exerciseFromFirestore,
  slugify,
} from "../admin-types";

describe("ExerciseValue encode/decode", () => {
  it("encodes fixed value as number", () => {
    expect(encodeExerciseValue({ type: "fixed", value: 5 })).toBe(5);
  });
  it("encodes amrap as string", () => {
    expect(encodeExerciseValue({ type: "amrap" })).toBe("AMRAP");
  });
  it("encodes range as array", () => {
    expect(encodeExerciseValue({ type: "range", low: 8, high: 12 })).toEqual([8, 12]);
  });
  it("encodes text as string", () => {
    expect(encodeExerciseValue({ type: "text", value: "Max effort" })).toBe("Max effort");
  });
  it("decodes number as fixed", () => {
    expect(decodeExerciseValue(5)).toEqual({ type: "fixed", value: 5 });
  });
  it("decodes AMRAP string as amrap", () => {
    expect(decodeExerciseValue("AMRAP")).toEqual({ type: "amrap" });
  });
  it("decodes amrap case-insensitive", () => {
    expect(decodeExerciseValue("amrap")).toEqual({ type: "amrap" });
  });
  it("decodes 2-element array as range", () => {
    expect(decodeExerciseValue([8, 12])).toEqual({ type: "range", low: 8, high: 12 });
  });
  it("decodes hyphenated string as range", () => {
    expect(decodeExerciseValue("8-12")).toEqual({ type: "range", low: 8, high: 12 });
  });
  it("decodes numeric string as fixed", () => {
    expect(decodeExerciseValue("5")).toEqual({ type: "fixed", value: 5 });
  });
  it("decodes arbitrary string as text", () => {
    expect(decodeExerciseValue("Max effort")).toEqual({ type: "text", value: "Max effort" });
  });
});

describe("exerciseToFirestore / exerciseFromFirestore", () => {
  it("round-trips a full exercise", () => {
    const exercise: ProgramExercise = {
      exercise: "Back Squat",
      variant: "Low Bar",
      sets: { type: "fixed", value: 5 },
      reps: { type: "range", low: 3, high: 5 },
      percent1RM: 0.8,
      restMinutes: 3,
      notes: "Pause at bottom",
      bodyweightOnly: false,
    };
    const encoded = exerciseToFirestore(exercise);
    const decoded = exerciseFromFirestore(encoded);
    expect(decoded).toEqual(exercise);
  });
  it("normalizes percent1RM > 1.5 as divided by 100", () => {
    const encoded = { exercise: "Bench", sets: 3, reps: 5, percent1RM: 80 };
    const decoded = exerciseFromFirestore(encoded);
    expect(decoded.percent1RM).toBe(0.8);
  });
  it("omits undefined optional fields", () => {
    const exercise: ProgramExercise = {
      exercise: "Push-up",
      sets: { type: "fixed", value: 3 },
      reps: { type: "fixed", value: 10 },
    };
    const encoded = exerciseToFirestore(exercise);
    expect(encoded).not.toHaveProperty("variant");
    expect(encoded).not.toHaveProperty("percent1RM");
    expect(encoded).not.toHaveProperty("restMinutes");
    expect(encoded).not.toHaveProperty("notes");
    expect(encoded).not.toHaveProperty("bodyweightOnly");
  });
});

describe("slugify", () => {
  it("lowercases and replaces spaces with hyphens", () => {
    expect(slugify("My Cool Program")).toBe("my-cool-program");
  });
  it("removes non-alphanumeric characters", () => {
    expect(slugify("Hello, World!")).toBe("hello-world");
  });
  it("collapses multiple hyphens", () => {
    expect(slugify("foo---bar")).toBe("foo-bar");
  });
  it("trims leading and trailing hyphens", () => {
    expect(slugify("--hello--")).toBe("hello");
  });
});

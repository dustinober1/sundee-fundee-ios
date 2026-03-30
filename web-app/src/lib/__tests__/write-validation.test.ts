import { describe, expect, it } from "vitest";
import {
  optionalFiniteNumber,
  optionalTrimmedString,
  requireDateInput,
  requireFiniteNumber,
  requireOneOf,
  requireTrimmedString,
} from "../write-validation";

describe("write validation", () => {
  it("rejects blank required strings", () => {
    expect(() => requireTrimmedString("   ", "Exercise")).toThrow("Exercise is required.");
  });

  it("trims optional strings and drops blanks", () => {
    expect(optionalTrimmedString("  Notes  ")).toBe("Notes");
    expect(optionalTrimmedString("   ")).toBeUndefined();
  });

  it("rejects NaN and infinity", () => {
    expect(() => requireFiniteNumber(Number.NaN, "Score")).toThrow("Score must be a valid number.");
    expect(() => requireFiniteNumber(Number.POSITIVE_INFINITY, "Score")).toThrow(
      "Score must be a valid number."
    );
  });

  it("enforces integer and range constraints", () => {
    expect(() => requireFiniteNumber(1.5, "Reps", { integer: true })).toThrow(
      "Reps must be a whole number."
    );
    expect(() => requireFiniteNumber(0, "Effort", { min: 1 })).toThrow(
      "Effort must be at least 1."
    );
    expect(optionalFiniteNumber(undefined, "Effort", { min: 1 })).toBeUndefined();
  });

  it("parses valid date inputs and rejects invalid ones", () => {
    expect(requireDateInput("2026-03-29", "Start date").toISOString()).toBe(
      "2026-03-29T00:00:00.000Z"
    );
    expect(() => requireDateInput("2026-02-30", "Start date")).toThrow(
      "Start date must be a valid date."
    );
  });

  it("validates allowed enum values", () => {
    expect(requireOneOf("medium", ["light", "medium", "heavy"], "Flow level")).toBe("medium");
    expect(() => requireOneOf("wild", ["light", "medium", "heavy"], "Flow level")).toThrow(
      "Flow level is invalid."
    );
  });
});

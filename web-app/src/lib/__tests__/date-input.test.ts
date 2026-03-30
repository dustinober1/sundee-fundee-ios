import { describe, expect, it } from "vitest";
import {
  coerceStoredDateToLocalDate,
  formatDateInputValue,
  parseDateInputValue,
} from "../date-input";

describe("date-input", () => {
  it("parses a date input string into a local calendar date", () => {
    const date = parseDateInputValue("2026-03-08");

    expect(date.getFullYear()).toBe(2026);
    expect(date.getMonth()).toBe(2);
    expect(date.getDate()).toBe(8);
  });

  it("formats a local calendar date as yyyy-mm-dd", () => {
    expect(formatDateInputValue(new Date(2026, 2, 8))).toBe("2026-03-08");
  });

  it("normalizes a persisted UTC date without shifting the calendar day", () => {
    const normalized = coerceStoredDateToLocalDate(new Date(Date.UTC(2026, 2, 8)));

    expect(normalized).not.toBeNull();
    expect(formatDateInputValue(normalized!)).toBe("2026-03-08");
  });

  it("accepts timestamp-like values from Firestore", () => {
    const normalized = coerceStoredDateToLocalDate({
      toDate: () => new Date(Date.UTC(2026, 2, 8)),
    });

    expect(normalized).not.toBeNull();
    expect(formatDateInputValue(normalized!)).toBe("2026-03-08");
  });

  it("parses ISO timestamps without shifting the calendar day", () => {
    const date = parseDateInputValue("2026-03-08T00:00:00.000Z");

    expect(formatDateInputValue(date)).toBe("2026-03-08");
  });
});

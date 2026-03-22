import { encodeExerciseValue, decodeExerciseValue, ExerciseValue } from "../src/lib/types";

describe("ExerciseValue", () => {
  test("fixed int round-trips", () => {
    const val: ExerciseValue = { type: "fixed", value: 4 };
    expect(encodeExerciseValue(val)).toBe(4);
    expect(decodeExerciseValue(4)).toEqual(val);
  });

  test("AMRAP round-trips", () => {
    const val: ExerciseValue = { type: "amrap" };
    expect(encodeExerciseValue(val)).toBe("AMRAP");
    expect(decodeExerciseValue("AMRAP")).toEqual(val);
  });

  test("range round-trips", () => {
    const val: ExerciseValue = { type: "range", low: 8, high: 12 };
    expect(encodeExerciseValue(val)).toEqual([8, 12]);
    expect(decodeExerciseValue([8, 12])).toEqual(val);
  });

  test("text round-trips", () => {
    const val: ExerciseValue = { type: "text", text: "60s" };
    expect(encodeExerciseValue(val)).toBe("60s");
    expect(decodeExerciseValue("60s")).toEqual(val);
  });

  test("decodes double as fixed int", () => {
    expect(decodeExerciseValue(4.7)).toEqual({ type: "fixed", value: 4 });
  });

  test("decodes string integer as fixed", () => {
    expect(decodeExerciseValue("4")).toEqual({ type: "fixed", value: 4 });
  });

  test("decodes hyphenated range string", () => {
    expect(decodeExerciseValue("8-12")).toEqual({ type: "range", low: 8, high: 12 });
  });
});

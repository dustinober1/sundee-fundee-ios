import { weightliftingExercises, conditioningExercises, allExerciseNames } from "../src/lib/exercise-catalog";

describe("ExerciseCatalog", () => {
  test("has 39 weightlifting exercises", () => {
    expect(weightliftingExercises.length).toBe(39);
  });
  test("has 21 conditioning exercises", () => {
    expect(conditioningExercises.length).toBe(21);
  });
  test("allExerciseNames contains Back Squat", () => {
    expect(allExerciseNames).toContain("Back Squat");
  });
  test("categories are correct", () => {
    const categories = [...new Set(weightliftingExercises.map((e) => e.category))];
    expect(categories).toEqual(expect.arrayContaining(["Squat", "Hip Hinge", "Press", "Pull", "Carry", "Olympic Weightlifting"]));
  });
});

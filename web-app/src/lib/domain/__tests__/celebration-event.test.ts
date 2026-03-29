import { describe, it, expect } from "vitest";
import { celebrationTitle, celebrationSubtitle, type CelebrationEvent } from "../celebration-event";

describe("celebrationTitle", () => {
  it("workoutCompleted returns 'Workout Complete!'", () => {
    const event: CelebrationEvent = { type: "workoutCompleted", durationSeconds: 3600 };
    expect(celebrationTitle(event)).toBe("Workout Complete!");
  });

  it("newPersonalRecord returns 'New Personal Record!'", () => {
    const event: CelebrationEvent = { type: "newPersonalRecord", exerciseName: "Back Squat", weightKg: 100 };
    expect(celebrationTitle(event)).toBe("New Personal Record!");
  });

  it("programCompleted returns 'Program Complete!'", () => {
    const event: CelebrationEvent = { type: "programCompleted", programName: "Strength Block" };
    expect(celebrationTitle(event)).toBe("Program Complete!");
  });

  it("weightMilestone returns 'Weight Milestone!'", () => {
    const event: CelebrationEvent = { type: "weightMilestone", exerciseName: "Deadlift", thresholdKg: 200 };
    expect(celebrationTitle(event)).toBe("Weight Milestone!");
  });

  it("newConditioningPR returns 'New Conditioning PR!'", () => {
    const event: CelebrationEvent = { type: "newConditioningPR", exerciseName: "Fran", value: 300, scoringType: "time" };
    expect(celebrationTitle(event)).toBe("New Conditioning PR!");
  });
});

describe("celebrationSubtitle", () => {
  it("workoutCompleted with duration > 60s shows minutes", () => {
    const event: CelebrationEvent = { type: "workoutCompleted", durationSeconds: 3600 };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("60 min");
  });

  it("workoutCompleted with duration < 60s shows 'Workout saved!'", () => {
    const event: CelebrationEvent = { type: "workoutCompleted", durationSeconds: 30 };
    const sub = celebrationSubtitle(event);
    expect(sub).toBe("Workout saved!");
  });

  it("workoutCompleted exactly 60s shows 1 min", () => {
    const event: CelebrationEvent = { type: "workoutCompleted", durationSeconds: 60 };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("1 min");
  });

  it("newPersonalRecord formats weight in kg", () => {
    const event: CelebrationEvent = { type: "newPersonalRecord", exerciseName: "Back Squat", weightKg: 100 };
    const sub = celebrationSubtitle(event, "kg");
    expect(sub).toContain("Back Squat");
    expect(sub).toContain("100 kg");
    expect(sub).toContain("estimated 1RM");
  });

  it("newPersonalRecord formats weight in lb", () => {
    const event: CelebrationEvent = { type: "newPersonalRecord", exerciseName: "Deadlift", weightKg: 100 };
    const sub = celebrationSubtitle(event, "lb");
    expect(sub).toContain("lb");
    expect(sub).not.toContain("100 kg");
  });

  it("programCompleted includes program name", () => {
    const event: CelebrationEvent = { type: "programCompleted", programName: "Stronglift 5x5" };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("Stronglift 5x5");
    expect(sub).toContain("level up");
  });

  it("weightMilestone includes exercise name and threshold", () => {
    const event: CelebrationEvent = { type: "weightMilestone", exerciseName: "Bench Press", thresholdKg: 100 };
    const sub = celebrationSubtitle(event, "kg");
    expect(sub).toContain("Bench Press");
    expect(sub).toContain("100");
  });

  it("weightMilestone converts to lb", () => {
    const event: CelebrationEvent = { type: "weightMilestone", exerciseName: "Bench Press", thresholdKg: 100 };
    const sub = celebrationSubtitle(event, "lb");
    expect(sub).toContain("lb");
  });

  it("newConditioningPR time shows formatted time", () => {
    const event: CelebrationEvent = { type: "newConditioningPR", exerciseName: "Fran", value: 185, scoringType: "time" };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("Fran");
    expect(sub).toContain("3:05");
  });

  it("newConditioningPR reps shows rep count", () => {
    const event: CelebrationEvent = { type: "newConditioningPR", exerciseName: "Cindy", value: 15, scoringType: "reps" };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("15 reps");
  });

  it("newConditioningPR roundsAndReps shows rounds format", () => {
    const event: CelebrationEvent = { type: "newConditioningPR", exerciseName: "Cindy", value: 150003, scoringType: "roundsAndReps" };
    const sub = celebrationSubtitle(event);
    expect(sub).toContain("15 rounds");
    expect(sub).toContain("3 reps");
  });
});

import { describe, expect, it } from "vitest";
import {
  buildWorkoutPrompt,
  getAIModelConfig,
  parseAIWorkoutResponse,
  validateAIWorkoutRequest,
} from "../ai-generation";

describe("getAIModelConfig", () => {
  it("maps plus to the default flash-lite model", () => {
    expect(getAIModelConfig("plus").model).toBe("models/gemini-flash-lite-latest");
  });

  it("maps premium to flash-lite by default", () => {
    expect(getAIModelConfig("premium").model).toBe("models/gemini-flash-lite-latest");
  });
});

describe("validateAIWorkoutRequest", () => {
  it("accepts the questionnaire payload used by the client", () => {
    expect(
      validateAIWorkoutRequest({
        time: 30,
        focus: "full_body",
        energy: "medium",
        equipment: "full_gym",
        cyclePhase: "follicular",
      })
    ).toEqual({
      time: 30,
      focus: "full_body",
      energy: "medium",
      equipment: "full_gym",
      cyclePhase: "follicular",
    });
  });

  it("rejects invalid focus values", () => {
    expect(() =>
      validateAIWorkoutRequest({
        time: 30,
        focus: "bad",
        energy: "medium",
        equipment: "full_gym",
      })
    ).toThrow("focus is invalid.");
  });
});

describe("buildWorkoutPrompt", () => {
  it("includes the questionnaire details in the prompt", () => {
    const prompt = buildWorkoutPrompt({
      time: 45,
      focus: "lower_body",
      energy: "high",
      equipment: "home_dumbbells",
      cyclePhase: "ovulation",
    });

    expect(prompt).toContain("45 minutes");
    expect(prompt).toContain("lower body");
    expect(prompt).toContain("high");
    expect(prompt).toContain("home dumbbells");
    expect(prompt).toContain("ovulation");
  });

  it("includes user context when provided", () => {
    const prompt = buildWorkoutPrompt({
      time: 30,
      focus: "full_body",
      energy: "medium",
      equipment: "full_gym",
      userContext: {
        experienceLevel: "intermediate",
        primaryGoal: "strength",
        maxes: [{ exerciseId: "back-squat", weightKg: 100 }],
        recentWorkouts: [
          { completedAt: "2026-03-30", durationSeconds: 2400, exercises: ["Bench Press", "Rows"] },
        ],
      },
    });

    expect(prompt).toContain("intermediate");
    expect(prompt).toContain("strength");
    expect(prompt).toContain("back-squat: 100 kg");
    expect(prompt).toContain("Bench Press, Rows");
    expect(prompt).toContain("2026-03-30");
  });
});

describe("parseAIWorkoutResponse", () => {
  it("parses a valid JSON payload", () => {
    const result = parseAIWorkoutResponse(JSON.stringify({
      coachingSummary: "Strong session today.",
      exercises: [
        {
          name: "Back Squat",
          sets: 4,
          reps: "5",
          bodyweightOnly: false,
          restMinutes: 3,
        },
      ],
    }));

    expect(result.coachingSummary).toBe("Strong session today.");
    expect(result.exercises[0]?.id).toBe("ex-1");
    expect(result.exercises[0]?.name).toBe("Back Squat");
  });

  it("strips markdown code fences before parsing", () => {
    const result = parseAIWorkoutResponse("```json\n{\"coachingSummary\":\"Test\",\"exercises\":[]}\n```");
    expect(result.coachingSummary).toBe("Test");
  });

  it("throws on invalid exercise content", () => {
    expect(() =>
      parseAIWorkoutResponse(JSON.stringify({
        coachingSummary: "Bad",
        exercises: [{ name: "", sets: 0, reps: "", bodyweightOnly: false }],
      }))
    ).toThrow("AI response contained an invalid exercise.");
  });
});

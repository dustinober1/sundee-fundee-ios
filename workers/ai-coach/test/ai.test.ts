import { describe, it, expect, vi } from "vitest";
import { generateWorkout } from "../src/ai";
import type { Tier } from "../src/types";

function createMockAI(responseText: string) {
  return {
    run: vi.fn(async () => ({ response: responseText })),
  } as unknown as Ai;
}

const VALID_RESPONSE = JSON.stringify({
  coachingSummary: "Great upper body session.",
  exercises: [
    {
      name: "Bench Press",
      sets: 4,
      reps: "8",
      weightKg: null,
      restMinutes: 2,
      notes: "Control the eccentric",
      bodyweightOnly: false,
    },
  ],
});

describe("generateWorkout", () => {
  it("routes plus tier to qwen model", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    await generateWorkout(ai, "plus", "Build a workout", "You are a coach");
    expect(ai.run).toHaveBeenCalledWith(
      "@cf/qwen/qwen3-30b-a3b-fp8",
      expect.objectContaining({
        messages: [
          { role: "system", content: "You are a coach" },
          { role: "user", content: "Build a workout" },
        ],
      }),
    );
  });

  it("routes premium tier to nemotron model", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    await generateWorkout(ai, "premium", "Build a workout", "You are a coach");
    expect(ai.run).toHaveBeenCalledWith(
      "@cf/nvidia/nemotron-3-120b-a12b",
      expect.any(Object),
    );
  });

  it("parses valid JSON response", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    const result = await generateWorkout(ai, "plus", "prompt", "system");
    expect(result.coachingSummary).toBe("Great upper body session.");
    expect(result.exercises).toHaveLength(1);
    expect(result.exercises[0].name).toBe("Bench Press");
  });

  it("strips markdown code fences from response", async () => {
    const wrapped = "```json\n" + VALID_RESPONSE + "\n```";
    const ai = createMockAI(wrapped);
    const result = await generateWorkout(ai, "plus", "prompt", "system");
    expect(result.coachingSummary).toBe("Great upper body session.");
  });

  it("throws on unparseable response", async () => {
    const ai = createMockAI("This is not JSON at all");
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Failed to parse");
  });

  it("throws on missing coachingSummary", async () => {
    const bad = JSON.stringify({ exercises: [] });
    const ai = createMockAI(bad);
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Invalid response");
  });

  it("throws on missing exercises array", async () => {
    const bad = JSON.stringify({ coachingSummary: "Hi" });
    const ai = createMockAI(bad);
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Invalid response");
  });
});

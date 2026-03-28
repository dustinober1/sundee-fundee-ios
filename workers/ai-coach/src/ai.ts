import { TIER_MODELS, type Tier, type WorkoutResponse } from "./types";

export async function generateWorkout(
  ai: Ai,
  tier: Tier,
  prompt: string,
  systemInstruction: string,
): Promise<WorkoutResponse> {
  const model = TIER_MODELS[tier];

  const result = await ai.run(model, {
    messages: [
      { role: "system", content: systemInstruction },
      { role: "user", content: prompt },
    ],
  });

  const raw = (result as { response: string }).response;
  const cleaned = stripMarkdownFences(raw);

  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    throw new Error("Failed to parse AI response as JSON");
  }

  if (!isValidWorkoutResponse(parsed)) {
    throw new Error("Invalid response structure from AI");
  }

  return parsed;
}

function stripMarkdownFences(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("```")) {
    const lines = trimmed.split("\n");
    lines.shift(); // remove opening fence
    if (lines[lines.length - 1]?.trim() === "```") {
      lines.pop(); // remove closing fence
    }
    return lines.join("\n");
  }
  return trimmed;
}

function isValidWorkoutResponse(data: unknown): data is WorkoutResponse {
  if (typeof data !== "object" || data === null) return false;
  const obj = data as Record<string, unknown>;
  return typeof obj.coachingSummary === "string" && Array.isArray(obj.exercises);
}

import { NextRequest, NextResponse } from "next/server";

const VALID_SCORING_TYPES = ["time", "reps", "weight", "distance", "roundsAndReps"];

const SYSTEM_PROMPT = `You are a strength training benchmark designer. Given a list of exercises, create a benchmark workout with a rep scheme and scoring method. Return valid JSON only, no markdown.

Scoring types: "time" (for-time workouts), "reps" (max reps in time), "weight" (max load), "distance" (max distance), "roundsAndReps" (AMRAP-style).

Return format: { "workoutDescription": "...", "scoringTypeRaw": "..." }

The workoutDescription should be a complete, readable workout description including movements, rep scheme, time caps, and any standards.`;

export async function POST(req: NextRequest) {
  try {
    const { messages } = await req.json();

    if (!Array.isArray(messages) || messages.length === 0) {
      return NextResponse.json(
        { error: "messages array is required and must not be empty" },
        { status: 400 }
      );
    }

    const valid = messages.every(
      (m: unknown) =>
        typeof m === "object" && m !== null &&
        typeof (m as Record<string, unknown>).role === "string" &&
        typeof (m as Record<string, unknown>).content === "string"
    );
    if (!valid) {
      return NextResponse.json(
        { error: "Each message must have role and content strings" },
        { status: 400 }
      );
    }

    const workerUrl = process.env.CLOUDFLARE_WORKER_URL;
    if (!workerUrl) {
      return NextResponse.json(
        { error: "CLOUDFLARE_WORKER_URL is not configured" },
        { status: 500 }
      );
    }

    // Map messages to Gemini contents format (assistant -> model)
    const contents = messages.map(
      (m: { role: string; content: string }) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      })
    );

    const workerRes = await fetch(workerUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents,
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
      }),
    });

    if (!workerRes.ok) {
      const errText = await workerRes.text().catch(() => "");
      return NextResponse.json(
        { error: `Worker request failed: ${workerRes.status}`, detail: errText },
        { status: 502 }
      );
    }

    const data = await workerRes.json();
    const rawText: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!rawText) {
      return NextResponse.json(
        { error: "No content returned from worker", raw: data },
        { status: 502 }
      );
    }

    // Strip markdown code fences if present
    const stripped = rawText
      .trim()
      .replace(/^```(?:json)?\s*/i, "")
      .replace(/\s*```$/, "")
      .trim();

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(stripped);
    } catch {
      return NextResponse.json(
        { error: "Failed to parse JSON from worker response", raw: rawText },
        { status: 502 }
      );
    }

    // Validate required fields
    if (
      typeof parsed.workoutDescription !== "string" ||
      typeof parsed.scoringTypeRaw !== "string"
    ) {
      return NextResponse.json(
        { error: "Response missing required fields", raw: parsed },
        { status: 502 }
      );
    }

    if (!VALID_SCORING_TYPES.includes(parsed.scoringTypeRaw)) {
      return NextResponse.json(
        {
          error: `Invalid scoringTypeRaw: "${parsed.scoringTypeRaw}". Must be one of: ${VALID_SCORING_TYPES.join(", ")}`,
          raw: parsed,
        },
        { status: 502 }
      );
    }

    return NextResponse.json({
      workoutDescription: parsed.workoutDescription,
      scoringTypeRaw: parsed.scoringTypeRaw,
    });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

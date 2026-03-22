import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const {
      prompt: userPrompt,
      category,
      duration,
      sessionsPerWeek,
      difficulty,
      goal,
    } = await req.json();

    const workerUrl = process.env.CLOUDFLARE_WORKER_URL;
    if (!workerUrl) {
      return NextResponse.json(
        { error: "CLOUDFLARE_WORKER_URL is not configured" },
        { status: 500 }
      );
    }

    const prompt = `Generate a complete strength training program as valid JSON matching this schema exactly:

{
  "id": string,              // unique identifier, e.g. "program-slug"
  "name": string,            // program name
  "category": string,        // e.g. "Strength", "Hypertrophy", "Conditioning"
  "description": string,     // 2-3 sentence program overview
  "durationWeeks": number,   // total program length in weeks
  "sessionsPerWeek": number, // training days per week
  "difficulty": string,      // "beginner" | "intermediate" | "advanced"
  "phases": [
    {
      "id": string,          // unique phase identifier
      "name": string,        // phase name, e.g. "Accumulation"
      "goal": string,        // phase goal description
      "weekRange": [number, number]  // [startWeek, endWeek], 1-indexed
    }
  ],
  "weeks": [
    {
      "week": number,        // week number, 1-indexed
      "phaseId": string,     // references a phase id
      "isTestWeek": boolean, // optional, true for deload/test weeks
      "sessions": [
        {
          "sessionId": string,    // unique session identifier
          "sessionName": string,  // e.g. "Day 1 - Lower Body"
          "sessionType": string,  // e.g. "strength", "hypertrophy", "conditioning"
          "focus": string,        // primary muscle group or movement pattern
          "exercises": [
            {
              "exercise": string,       // exercise name
              "variant": string,        // optional variation
              "sets": number | string | [number, number],
              "reps": number | string | [number, number],
              "percent1RM": number,     // optional, 0-100
              "restMinutes": number,    // optional
              "notes": string,          // optional coaching cues
              "bodyweightOnly": boolean // optional
            }
          ]
        }
      ]
    }
  ],
  "cycleAdjustmentProfile": {
    "fallbackPhase": string,   // default phase name for unknown cycle phase
    "lowConfidenceScale": number, // 0-1, load scale when cycle data confidence is low
    "phaseSettings": {
      "<phaseName>": {
        "loadMultiplier": number,  // e.g. 1.0 for normal, 0.85 for reduced
        "setsMultiplier": number,
        "repsMultiplier": number
      }
    }
  }
}

Program parameters:
${userPrompt ? `- User description: ${userPrompt}` : ""}
- Category: ${category ?? "Strength"}
- Duration: ${duration ?? 8} weeks
- Sessions per week: ${sessionsPerWeek ?? 3}
- Difficulty: ${difficulty ?? "intermediate"}
- Goal: ${goal ?? "general strength improvement"}

The cycleAdjustmentProfile.phaseSettings keys should cover hormonal cycle phases: "follicular", "ovulatory", "luteal", "menstrual".

Return only valid JSON. No markdown, no explanation.`;

    const workerRes = await fetch(workerUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        systemInstruction: {
          parts: [
            {
              text: "You are a strength training program designer. Return valid JSON only, no markdown.",
            },
          ],
        },
        generationConfig: { temperature: 0.7, maxOutputTokens: 16384 },
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

    let parsed: unknown;
    try {
      parsed = JSON.parse(stripped);
    } catch {
      return NextResponse.json(
        { error: "Failed to parse JSON from worker response", raw: rawText },
        { status: 502 }
      );
    }

    return NextResponse.json(parsed);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

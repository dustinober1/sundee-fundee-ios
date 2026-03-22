import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  try {
    const {
      date,
      focusArea,
      difficulty,
      exerciseCount,
      equipment,
      notes,
      batchDates,
    } = await req.json();

    const workerUrl = process.env.CLOUDFLARE_WORKER_URL;
    if (!workerUrl) {
      return NextResponse.json(
        { error: "CLOUDFLARE_WORKER_URL is not configured" },
        { status: 500 }
      );
    }

    const prompt = `Generate a Workout of the Day (WOD) as valid JSON matching this schema exactly:

{
  "id": string,           // unique identifier, e.g. "wod-YYYY-MM-DD"
  "date": string,         // ISO date string "YYYY-MM-DD"
  "title": string,        // short workout title
  "description": string,  // 1-2 sentence workout overview
  "exercises": [
    {
      "exercise": string,       // exercise name
      "variant": string,        // optional variation (e.g. "sumo", "close-grip")
      "sets": number | string | [number, number],  // fixed count, "AMRAP", or [low, high] range
      "reps": number | string | [number, number],  // fixed count, "AMRAP", or [low, high] range
      "percent1RM": number,     // optional, 0-100
      "restMinutes": number,    // optional rest between sets
      "notes": string,          // optional coaching cues
      "bodyweightOnly": boolean // optional, true if no equipment needed
    }
  ]
}

Parameters:
- Date: ${date ?? "today"}
- Focus area: ${focusArea ?? "full body"}
- Difficulty: ${difficulty ?? "intermediate"}
- Number of exercises: ${exerciseCount ?? 5}
- Available equipment: ${equipment ?? "barbell, dumbbells, pull-up bar"}
${notes ? `- Additional notes: ${notes}` : ""}
${batchDates ? `- Generate WODs for these dates: ${JSON.stringify(batchDates)} — return a JSON array of WOD objects` : ""}

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
        generationConfig: { temperature: 0.7, maxOutputTokens: 4096 },
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

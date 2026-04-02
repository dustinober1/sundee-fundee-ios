import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";

interface GenerateRequest {
  topic: string;
  tone?: string;
  length?: "short" | "medium" | "long";
}

const LENGTH_TOKENS: Record<string, number> = {
  short: 4096,
  medium: 8192,
  long: 16384,
};

function buildBlogSystemInstruction(): string {
  return [
    "You are a fitness and wellness content writer for Sundee Fundee, a cycle-aware strength training app.",
    "Sundee Fundee helps women train smarter by adapting workouts to their menstrual cycle phases (menstrual, follicular, ovulation, luteal).",
    "The brand voice is empowering, knowledgeable, and approachable — never condescending.",
    "Write in a warm, authoritative tone that blends sports science with practical advice.",
    "Return ONLY valid JSON. No markdown fences, no commentary outside the JSON.",
  ].join(" ");
}

function buildBlogPrompt(req: GenerateRequest): string {
  const lines = [
    `Write a blog post about: ${req.topic}`,
    "",
    "--- CONTENT GUIDELINES ---",
    "- Focus on cycle-aware strength training, women's fitness, or related wellness topics",
    "- Include actionable advice backed by exercise science",
    "- Use subheadings (H2/H3) to break up the content",
    "- Keep paragraphs short and scannable",
    req.tone ? `- Tone: ${req.tone}` : "- Tone: empowering and informative",
    req.length === "long"
      ? "- Write a comprehensive, in-depth article (1500-2500 words)"
      : req.length === "short"
        ? "- Write a concise article (400-700 words)"
        : "- Write a standard-length article (800-1200 words)",
    "",
    "--- OUTPUT FORMAT ---",
    "Return a JSON object with these fields:",
    '- "title": a compelling blog post title (no quotes around it)',
    '- "description": a 1-2 sentence meta description for SEO (under 160 characters)',
    '- "tags": an array of 2-5 relevant tags (lowercase, e.g. ["training", "cycle", "recovery"])',
    '- "content": the full blog post body as valid HTML using <h2>, <h3>, <p>, <ul>, <li>, <strong>, <em> tags',
    "Do not include the title in the content HTML — it will be rendered separately.",
    "Do not wrap the content in <html>, <body>, or <article> tags.",
  ];

  return lines.join("\n");
}

function extractJSON(text: string): string {
  const trimmed = text.trim();
  const stripped = trimmed.startsWith("```")
    ? trimmed.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim()
    : trimmed;
  const start = stripped.indexOf("{");
  if (start === -1) return stripped;
  let depth = 0;
  let inString = false;
  let escape = false;
  for (let i = start; i < stripped.length; i++) {
    const ch = stripped[i];
    if (escape) { escape = false; continue; }
    if (ch === "\\") { escape = true; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (inString) continue;
    if (ch === "{") depth++;
    else if (ch === "}") { depth--; if (depth === 0) return stripped.slice(start, i + 1); }
  }
  return stripped;
}

export async function POST(request: NextRequest) {
  try {
    await requireAdmin();
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Auth error" }, { status: 401 });
  }

  const body = await request.json() as GenerateRequest;
  if (!body.topic || typeof body.topic !== "string" || body.topic.trim().length < 3) {
    return NextResponse.json({ error: "Topic is required (at least 3 characters)" }, { status: 400 });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "GEMINI_API_KEY is not configured" }, { status: 500 });
  }

  try {
    const { GoogleGenAI } = await import("@google/genai");
    const client = new GoogleGenAI({ apiKey: apiKey.trim() });

    const model = process.env.GEMINI_PREMIUM_MODEL ?? "models/gemini-flash-lite-latest";
    const maxOutputTokens = LENGTH_TOKENS[body.length ?? "medium"] ?? 8192;

    const result = await client.models.generateContent({
      model,
      contents: buildBlogPrompt(body),
      config: {
        systemInstruction: buildBlogSystemInstruction(),
        responseMimeType: "application/json",
        temperature: 0.85,
        maxOutputTokens,
      },
    });

    const raw = typeof result.text === "string" ? result.text : "";
    if (!raw) {
      return NextResponse.json({ error: "No response from AI" }, { status: 502 });
    }

    const cleaned = extractJSON(raw);
    const parsed = JSON.parse(cleaned) as Record<string, unknown>;

    if (typeof parsed.title !== "string" || typeof parsed.content !== "string") {
      return NextResponse.json({ error: "AI response did not match expected blog schema" }, { status: 502 });
    }

    return NextResponse.json({
      title: parsed.title,
      description: typeof parsed.description === "string" ? parsed.description : "",
      tags: Array.isArray(parsed.tags) ? parsed.tags.filter((t): t is string => typeof t === "string") : [],
      content: parsed.content,
    });
  } catch (error) {
    const msg = error instanceof Error ? error.message : "AI generation failed";
    console.error("[admin/blog/generate] Error:", msg);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

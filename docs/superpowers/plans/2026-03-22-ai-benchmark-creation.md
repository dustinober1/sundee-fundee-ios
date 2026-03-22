# AI-Assisted Benchmark Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a conversational AI chat panel inside the WOD Dashboard's Benchmark Editor that generates workout descriptions and scoring types from free-form exercise input.

**Architecture:** New API route `/api/generate/benchmark` sends conversation history to the existing Cloudflare Worker (Gemini). A new `BenchmarkAIChat` component embeds in the existing `BenchmarkEditor` with an `onApply` callback to populate form fields.

**Tech Stack:** Next.js (App Router), TypeScript, Tailwind CSS, Cloudflare Worker + Gemini API

**Spec:** `docs/superpowers/specs/2026-03-22-ai-benchmark-creation-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `wod-dashboard/src/app/api/generate/benchmark/route.ts` | API route: receives messages, calls Cloudflare Worker, validates response |
| Create | `wod-dashboard/src/components/benchmark-ai-chat.tsx` | Chat UI: message history, input, send, apply to form |
| Modify | `wod-dashboard/src/components/benchmark-editor.tsx` | Import chat component, wire `onApply` to set form state |

---

### Task 1: Create the API route

**Files:**
- Create: `wod-dashboard/src/app/api/generate/benchmark/route.ts`
- Reference: `wod-dashboard/src/app/api/generate/wod/route.ts` (pattern to follow)

- [ ] **Step 1: Create the API route file**

```typescript
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
```

- [ ] **Step 2: Verify the route compiles**

Run: `cd wod-dashboard && npx next lint src/app/api/generate/benchmark/route.ts`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add wod-dashboard/src/app/api/generate/benchmark/route.ts
git commit -m "feat(wod-dashboard): add /api/generate/benchmark route for AI benchmark generation"
```

---

### Task 2: Create the BenchmarkAIChat component

**Files:**
- Create: `wod-dashboard/src/components/benchmark-ai-chat.tsx`
- Reference: `wod-dashboard/src/components/benchmark-editor.tsx` (styling patterns)

- [ ] **Step 1: Create the chat component**

```tsx
"use client";

import { useEffect, useRef, useState } from "react";

interface Message {
  role: "user" | "assistant";
  content: string;
  workoutDescription?: string;
  scoringTypeRaw?: string;
}

interface BenchmarkAIChatProps {
  benchmarkId: string;
  onApply: (workoutDescription: string, scoringTypeRaw: string) => void;
}

export function BenchmarkAIChat({ benchmarkId, onApply }: BenchmarkAIChatProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Reset conversation when benchmark changes
  useEffect(() => {
    setMessages([]);
    setInput("");
    setIsLoading(false);
  }, [benchmarkId]);

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function handleSend() {
    const text = input.trim();
    if (!text || isLoading) return;

    const userMessage: Message = { role: "user", content: text };
    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setInput("");
    setIsLoading(true);

    try {
      const res = await fetch("/api/generate/benchmark", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: updatedMessages.map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            content: `Error: ${data.error ?? "Unknown error"}. Try again.`,
          },
        ]);
        return;
      }

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `${data.workoutDescription}\n\nScoring: ${data.scoringTypeRaw}`,
          workoutDescription: data.workoutDescription,
          scoringTypeRaw: data.scoringTypeRaw,
        },
      ]);
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `Error: ${err instanceof Error ? err.message : "Network error"}. Try again.`,
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="mb-4 border border-navy/20 rounded overflow-hidden">
      {/* Toggle header */}
      <button
        type="button"
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full flex items-center justify-between px-3 py-2 bg-navy/5 hover:bg-navy/10 transition-colors text-sm font-medium text-navy/70"
      >
        <span>AI Assist</span>
        <span className="text-xs">{isExpanded ? "▲" : "▼"}</span>
      </button>

      {isExpanded && (
        <div className="p-3 space-y-3">
          {/* Messages */}
          {messages.length > 0 && (
            <div className="max-h-64 overflow-y-auto space-y-2">
              {messages.map((msg, i) => (
                <div key={i}>
                  <div
                    className={`text-sm rounded px-3 py-2 ${
                      msg.role === "user"
                        ? "bg-navy/10 text-navy"
                        : "bg-orange/10 text-navy"
                    }`}
                  >
                    <span className="font-medium text-xs block mb-1 text-navy/50">
                      {msg.role === "user" ? "You" : "AI"}
                    </span>
                    <span className="whitespace-pre-wrap">{msg.content}</span>
                  </div>
                  {msg.workoutDescription && msg.scoringTypeRaw && (
                    <button
                      type="button"
                      onClick={() =>
                        onApply(msg.workoutDescription!, msg.scoringTypeRaw!)
                      }
                      className="mt-1 text-xs bg-orange text-white px-2 py-1 rounded hover:bg-orange/90 transition-colors"
                    >
                      Apply to form
                    </button>
                  )}
                </div>
              ))}
              {isLoading && (
                <div className="text-sm text-navy/40 px-3 py-2">
                  Generating...
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}

          {/* Input */}
          <div className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder={
                messages.length === 0
                  ? "Enter exercises (e.g., back squat, pull-ups, box jumps)"
                  : "Refine (e.g., make it an AMRAP instead)"
              }
              disabled={isLoading}
              className="flex-1 border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40 disabled:opacity-50"
            />
            <button
              type="button"
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              className="bg-orange text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-orange/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {messages.length === 0 ? "Generate" : "Send"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify the component compiles**

Run: `cd wod-dashboard && npx next lint src/components/benchmark-ai-chat.tsx`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add wod-dashboard/src/components/benchmark-ai-chat.tsx
git commit -m "feat(wod-dashboard): add BenchmarkAIChat component"
```

---

### Task 3: Integrate chat into the Benchmark Editor

**Files:**
- Modify: `wod-dashboard/src/components/benchmark-editor.tsx`

- [ ] **Step 1: Add import at top of file**

After existing imports, add:

```typescript
import { BenchmarkAIChat } from "@/components/benchmark-ai-chat";
```

- [ ] **Step 2: Add onApply handler inside the component**

After the `handleSave` function (after line 56), add:

```typescript
function handleAIApply(desc: string, scoring: string) {
  setWorkoutDescription(desc);
  setScoringTypeRaw(scoring);
}
```

- [ ] **Step 3: Add chat component to JSX**

Insert the `BenchmarkAIChat` between the Workout Description textarea (`</div>` at line 148) and the Actions section (`{/* Actions */}` at line 150):

```tsx
{/* AI Assist */}
<BenchmarkAIChat
  benchmarkId={benchmark.id}
  onApply={handleAIApply}
/>
```

- [ ] **Step 4: Verify the dashboard builds**

Run: `cd wod-dashboard && npx next build`
Expected: Build succeeds with no errors

- [ ] **Step 5: Commit**

```bash
git add wod-dashboard/src/components/benchmark-editor.tsx
git commit -m "feat(wod-dashboard): integrate AI chat into benchmark editor"
```

---

### Task 4: Manual smoke test

- [ ] **Step 1: Start the dev server**

Run: `cd wod-dashboard && npm run dev`

- [ ] **Step 2: Test the flow**

1. Navigate to the Benchmarks page
2. Select or create a benchmark
3. Click "AI Assist" to expand the chat
4. Type exercises (e.g., "back squat, pull-ups, box jumps")
5. Click "Generate" — verify AI response appears
6. Click "Apply to form" — verify `workoutDescription` and `scoringTypeRaw` fields update
7. Type a refinement (e.g., "make it an AMRAP with a 12 minute cap")
8. Click "Send" — verify refined response
9. Switch to a different benchmark — verify conversation resets

- [ ] **Step 3: Final commit if any adjustments were needed**

```bash
git add -u wod-dashboard/src/
git commit -m "fix(wod-dashboard): adjustments from smoke testing AI benchmark chat"
```

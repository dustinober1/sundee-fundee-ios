# AI-Assisted Benchmark Creation

**Date:** 2026-03-22
**Status:** Approved

## Problem

Creating benchmarks in the WOD Dashboard is fully manual. The admin types exercise names, writes the full workout description, and picks the scoring type by hand. This is time-consuming and requires knowledge of standard benchmark formats.

## Solution

Add a conversational AI assistant inside the existing Benchmark Editor. The admin types exercise names, the AI generates a complete benchmark design (rep scheme, scoring method, workout description), and the admin can iteratively refine via free-form replies before applying the result to the form.

## Architecture

Reuses the existing Cloudflare Worker + Gemini integration pattern established by WOD and Program generators.

```
User types exercises -> Chat UI -> /api/generate/benchmark -> Cloudflare Worker -> Gemini
                                                                    |
                        Chat UI <- JSON response <- { workoutDescription, scoringTypeRaw }
                            | (user clicks Apply)
                        Form fields populated
```

## Components

### 1. `wod-dashboard/src/components/benchmark-ai-chat.tsx` (New)

Collapsible chat component embedded in the Benchmark Editor.

**Props:**
- `onApply: (workoutDescription: string, scoringTypeRaw: string) => void`
- `benchmarkId: string` — used as reset key; conversation clears when this changes

**State:**
- `messages: { role: "user" | "assistant", content: string }[]`
- `input: string`
- `isLoading: boolean`
- `isExpanded: boolean`

**UI Elements:**
- "AI Assist" toggle button to expand/collapse
- Message history area (user messages and AI responses in distinct styles)
- Text input for exercises or refinement feedback
- "Generate" / "Send" button
- "Apply" button on each AI response to push values into the form
- Loading spinner during generation

**Behavior:**
- First message: admin types exercises (e.g., "back squat, pull-ups, box jumps")
- AI responds with a structured benchmark design
- Admin can reply with feedback (e.g., "make it an AMRAP instead")
- AI responds with revised version using full conversation context
- "Apply" populates `workoutDescription` and `scoringTypeRaw` in the parent form
- Admin can still manually edit after applying
- Conversation resets when `benchmarkId` prop changes
- On API error, display the error message as a system message in the chat. Admin can retry by sending another message.

### 2. `wod-dashboard/src/app/api/generate/benchmark/route.ts` (New)

API route following the existing WOD/Program generation pattern.

**Request:**
```typescript
POST /api/generate/benchmark
{
  messages: { role: "user" | "assistant", content: string }[]
}
```

**Response:**
```typescript
{
  workoutDescription: string,
  scoringTypeRaw: string
}
```

**System prompt:**
> You are a strength training benchmark designer. Given a list of exercises, create a benchmark workout with a rep scheme and scoring method. Return valid JSON only, no markdown.
>
> Scoring types: "time" (for-time workouts), "reps" (max reps in time), "weight" (max load), "distance" (max distance), "roundsAndReps" (AMRAP-style).
>
> Return format: `{ "workoutDescription": "...", "scoringTypeRaw": "..." }`
>
> The workoutDescription should be a complete, readable workout description including movements, rep scheme, time caps, and any standards.

**Gemini message mapping:**
- The API route maps the `messages` array to Gemini's `contents` format: each message becomes `{ role, parts: [{ text }] }` with `assistant` role mapped to `model` (Gemini convention).
- The system prompt is sent via `systemInstruction`, not as a content message.

**Response validation:**
- After parsing JSON, validate that both `workoutDescription` and `scoringTypeRaw` are present strings.
- Validate `scoringTypeRaw` is one of: `time`, `reps`, `weight`, `distance`, `roundsAndReps`. If invalid, return a 502 with a descriptive error.

**Configuration:**
- Temperature: 0.7
- Max output tokens: 2048
- Full message history sent each request for conversational context
- Response parsing: strip markdown fences, parse JSON (same pattern as existing generators)

### 3. `benchmark-editor.tsx` (Modified)

- Import and render `<BenchmarkAIChat>` between form fields and Save/Delete buttons
- Add `onApply` callback that sets `workoutDescription` and `scoringTypeRaw` on the current benchmark
- No changes to save/publish/delete logic

## Scope

**In scope:**
- Chat UI component
- API route for Gemini generation
- Integration into existing editor

**Out of scope:**
- No changes to the iOS app
- No changes to the benchmark data model
- No new AI models or endpoints
- No changes to CloudKit publish flow

## Admin Controls

- **Admin sets:** benchmark name, category (hardcoded to "Sundee Fundee" in the editor), sort order
- **AI generates:** workoutDescription, scoringTypeRaw
- **Admin can override:** all AI-generated fields are editable after apply

# AI Workout Remote Generation

**Date:** 2026-03-24
**Status:** Approved

## Overview

Replace the offline-only AI workout generator with a Gemini-backed remote generation flow. The iOS app builds a prompt from the user's `WorkoutGenerationContext`, sends it to the existing Cloudflare Worker proxy (Gemini), parses the structured JSON response into a `GeneratedWorkout`, and falls back to `OfflineWorkoutGenerator` on any failure.

## Architecture

```
QuestionnaireViewModel.generateWorkout()
    -> SwiftDataAIWorkoutService.generateWorkout(context:)
        -> GeminiWorkoutPrompt.build(from: context)  // pure function
        -> POST to Cloudflare Worker (Gemini proxy)
        -> Parse Gemini JSON response
        -> RemoteWorkoutResponse.toGeneratedWorkout()  // map to domain model
        -> Persist GeneratedWorkoutRecord to SwiftData
        -> Return GeneratedWorkout
    X On any failure -> OfflineWorkoutGenerator.generate(from:) fallback
```

No changes to the Cloudflare Worker. It already accepts Gemini-native format and proxies to Gemini.

## Gemini Request Format

The Cloudflare Worker expects:

```json
{
  "contents": [{ "role": "user", "parts": [{ "text": "<prompt>" }] }],
  "systemInstruction": {
    "parts": [{ "text": "<system prompt>" }]
  },
  "generationConfig": { "temperature": 0.7, "maxOutputTokens": 4096 }
}
```

### System Instruction

"You are a certified strength and conditioning coach designing personalized workouts. Return valid JSON only. No markdown fences, no explanation outside the JSON."

### User Prompt

Built by `GeminiWorkoutPrompt.build(from:)` — a pure static function. Includes:

- Time target, focus area, energy level, equipment access
- 1RM maxes (if available) with exercise names and weights
- Recent workout history (last 14 days) to avoid repetition
- Cycle phase (if tracked) for hormonal adaptation
- Active injuries with locations and recovery phases
- Experience level, primary goal, gender, weight unit preference

The prompt asks Gemini to return JSON matching the lean response schema below.

## Gemini Response Schema

The prompt instructs Gemini to return:

```json
{
  "coachingSummary": "2-3 sentences of personalized coaching context",
  "exercises": [
    {
      "name": "Back Squat",
      "sets": 4,
      "reps": "5",
      "weightKg": 80.0,
      "restMinutes": 3.0,
      "notes": "Drive through heels, brace core",
      "reasoning": "Primary compound for quad/glute development",
      "bodyweightOnly": false
    }
  ]
}
```

Fields `weightKg`, `restMinutes`, `notes`, and `reasoning` are nullable. This is intentionally lean — no IDs, timestamps, or questionnaire data. Those are added client-side during mapping.

## iOS-Side Mapping

`RemoteWorkoutResponse.toGeneratedWorkout(questionnaire:)` maps the lean response to the existing `GeneratedWorkout` model:

- Generates UUID `id` for the workout and each exercise
- Sets `createdAt = .now`, `isFavorite = false`
- Attaches `QuestionnaireAnswers` from the original context
- Each exercise field maps 1:1 to `GeneratedExercise`

No changes to `GeneratedWorkout`, `GeneratedExercise`, or `GeneratedWorkoutRecord` models.

## Error Handling

- 30-second timeout on the network request
- Any failure (network error, non-2xx status, JSON parse failure, missing fields) falls back to `OfflineWorkoutGenerator`
- Failure reason is logged to console (`print`) for debugging
- No user-facing error message — the user always gets a workout
- The coaching summary from offline fallback says "Generated offline:" to distinguish

## Response Parsing

The Gemini proxy returns:
```json
{ "candidates": [{ "content": { "parts": [{ "text": "<json string>" }] } }] }
```

Parsing steps:
1. Extract `candidates[0].content.parts[0].text`
2. Strip markdown code fences if present (````json ... ```)
3. Decode as `RemoteWorkoutResponse`
4. Map to `GeneratedWorkout`

## Files

### New Files

1. **`Domain/AIWorkout/GeminiWorkoutPrompt.swift`**
   - `static func build(from: WorkoutGenerationContext) -> String`
   - Pure function, no dependencies, fully unit-testable
   - Constructs the user prompt string from context data

2. **`Domain/AIWorkout/RemoteWorkoutResponse.swift`**
   - `struct RemoteWorkoutResponse: Codable` — lean Gemini response
   - `struct RemoteExercise: Codable` — exercise within response
   - `func toGeneratedWorkout(questionnaire:) -> GeneratedWorkout` — mapping

### Modified Files

3. **`Repositories/Firebase/FirebaseAIWorkoutService.swift`**
   - Add `generateRemotely(context:)` — builds request, calls worker, parses response
   - Modify `generateWorkout(context:)` — try remote first, fall back to offline
   - Add Gemini proxy response extraction (candidates → text → parse)

### Unchanged

- `OfflineWorkoutGenerator` — untouched, used as fallback
- `QuestionnaireViewModel` / `QuestionnaireView` — no changes
- `WorkoutPreviewViewModel` / `WorkoutPreviewView` — no changes
- `GeneratedWorkout` / `GeneratedExercise` / `GeneratedWorkoutRecord` — no changes
- `AIWorkoutFlowView` — no changes
- Cloudflare Worker — no changes

## Testing

- `GeminiWorkoutPrompt` is a pure function — test that it includes maxes, injuries, cycle phase, etc. when present and omits them when absent
- `RemoteWorkoutResponse` mapping — test with sample JSON, verify UUIDs are generated, questionnaire is attached
- `SwiftDataAIWorkoutService` — test with mock URLSession: success path returns remote workout, failure path returns offline workout
- Existing offline generator tests remain unchanged

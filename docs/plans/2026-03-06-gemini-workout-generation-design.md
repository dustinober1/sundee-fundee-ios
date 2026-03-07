# Gemini-Powered AI Workout Generation — Design

**Date:** 2026-03-06
**Status:** Approved

## Goal

Replace the deterministic `OfflineWorkoutGenerator` as the primary workout generation engine with Gemini Flash Lite (`gemini-flash-lite-latest`), passing all user context (questionnaire answers, cycle phase, injuries, maxes, recent workouts, experience level) to the LLM for personalized workout creation. Fall back to the offline generator when the network call fails.

## Architecture

```
iOS App                    Cloudflare Worker              Gemini API
(GeminiWorkoutService) --> (sundee-fundee-proxy) -------> generativelanguage.googleapis.com
        |                  - injects API key                 model: gemini-flash-lite-latest
        |                  - rate limits per userID          responseSchema enforced
        |                  - validates request
        v (on failure)
OfflineWorkoutGenerator
```

### Why a proxy?

The Gemini API key must not ship in the iOS binary. A Cloudflare Worker acts as a thin pass-through that injects the key server-side. It also enables rate limiting without app updates.

## Components

### 1. Proxy Server (separate repo: `sundee-fundee-proxy`)

Cloudflare Worker responsibilities:
- POST `/generate-workout` endpoint
- Validate request body (reject malformed input)
- Inject `GEMINI_API_KEY` (Cloudflare secret) into Gemini API call
- Forward to `generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent`
- Pass `responseSchema` to enforce structured JSON output
- Return Gemini response to client
- Rate limit: cap requests per userID (e.g., 20/hour)

No authentication beyond userID in request body. Thin pass-through with no business logic.

### 2. GeminiWorkoutService (iOS)

New class implementing `AIWorkoutServiceProtocol`. Responsibilities:
- Build prompt from `WorkoutGenerationContext`
- POST to proxy endpoint via `URLSession`
- Parse structured JSON response into `GeneratedWorkout`
- On any failure, fall back to `OfflineWorkoutGenerator.generate(from:)`
- Delegate persistence to existing SwiftData flow

### 3. Prompt Design

**System prompt:**

```
You are an experienced strength and conditioning coach. Design a workout that:
- Prioritizes compound movements appropriate for the athlete's experience level
- Respects all injury restrictions — never program contraindicated movements
- Accounts for menstrual cycle phase when provided (adjust intensity/volume)
- Applies energy level to load selection
- Avoids repeating exercises from recent workouts when possible
- Uses the athlete's known maxes to calculate working weights
- Provides brief reasoning for each exercise choice
- Includes a coaching summary explaining the overall session design
```

**User prompt:** Serialized `WorkoutGenerationContext` as structured JSON, plus a "preferred exercises" list (exercises the user has maxes for).

**Response schema:** Gemini's `responseSchema` parameter constrains output to match `GeneratedWorkout`:

```json
{
  "type": "object",
  "properties": {
    "coachingSummary": { "type": "string" },
    "exercises": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "sets": { "type": "integer" },
          "reps": { "type": "string" },
          "weightKg": { "type": "number" },
          "restMinutes": { "type": "number" },
          "notes": { "type": "string" },
          "reasoning": { "type": "string" },
          "bodyweightOnly": { "type": "boolean" }
        },
        "required": ["name", "sets", "reps", "bodyweightOnly"]
      }
    }
  },
  "required": ["coachingSummary", "exercises"]
}
```

Exercise selection is guided but flexible: preferred exercises (with maxes) are listed in the prompt, but Gemini may suggest others.

### 4. Integration Point

`SwiftDataAIWorkoutService.generateWorkout()` changes to:

```swift
func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
    let workout: GeneratedWorkout
    do {
        workout = try await geminiService.generate(from: context)
    } catch {
        workout = OfflineWorkoutGenerator.generate(from: context)
    }
    // persist to SwiftData (unchanged)
    guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
        throw AIWorkoutServiceError.encodingFailed
    }
    modelContext.insert(record)
    try? modelContext.save()
    return workout
}
```

### 5. What Doesn't Change

- `WorkoutGenerationContext` — already carries all needed data
- `GeneratedWorkout` / `GeneratedExercise` — Gemini outputs this shape via responseSchema
- `QuestionnaireView` / `QuestionnaireViewModel` — same UI, same data collection
- `WorkoutPreviewView` / `WorkoutPreviewViewModel` — same editing and display
- `GeneratedWorkoutRecord` — same persistence
- `AIWorkoutServiceProtocol` — same interface
- `OfflineWorkoutGenerator` — retained as fallback

## Error Handling

| Scenario | Behavior |
|---|---|
| Network unreachable | Silent fallback to offline generator |
| Proxy returns 429 (rate limit) | Silent fallback to offline generator |
| Proxy returns 5xx | Silent fallback to offline generator |
| Gemini returns malformed JSON | Silent fallback to offline generator |
| Response missing required fields | Silent fallback to offline generator |
| Timeout (>15s) | Silent fallback to offline generator |

The coaching summary indicates whether the workout was AI-generated or offline-generated.

## Configuration

- **Proxy URL:** Constant in iOS app (e.g., `https://workout-proxy.sundee-fundee.workers.dev/generate-workout`)
- **Gemini API key:** Cloudflare Worker secret (`GEMINI_API_KEY`), never in iOS binary
- **Model:** `gemini-flash-lite-latest`

## Testing Strategy

### iOS Tests
- **`GeminiWorkoutService`**: Unit tested with `URLProtocol` mock. Verify prompt construction, response parsing, fallback.
- **Prompt construction**: Extracted as static function, tested with known context inputs.
- **Response parsing**: Fixture JSON files covering valid, edge-case, and malformed responses.
- **Fallback behavior**: Simulate network failure, verify `OfflineWorkoutGenerator` is called.
- **Existing tests**: `MockAIWorkoutService` unchanged. All ViewModel/UI tests unaffected.

### Proxy Tests
- Tested in its own repo with integration tests against Gemini API.

## Files to Create/Modify

### New Files (iOS)
- `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift` — LLM client + prompt builder
- `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift` — prompt construction (pure, testable)
- `SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift` — response parsing (pure, testable)
- `SundeeFundeTests/GeminiWorkoutServiceTests.swift` — unit tests

### Modified Files (iOS)
- `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift` — add Gemini call with fallback
- `project.yml` — add new source files to target (if not auto-discovered)

### New Repo
- `sundee-fundee-proxy` — Cloudflare Worker project

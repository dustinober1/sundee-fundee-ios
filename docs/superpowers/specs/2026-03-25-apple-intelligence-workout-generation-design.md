# Apple Intelligence Workout Generation

Replace Gemini-based AI workout generation with Apple Foundation Models (on-device). Remove server dependency from the iOS app. Keep Cloudflare Worker for WOD Dashboard.

## Decisions

- Deployment target: iOS 26+ (drop iOS 17 support)
- Fallback: `OfflineWorkoutGenerator` when Apple Intelligence is unavailable on device
- Prompt strategy: Simplified prompt to AI, deterministic post-processing for personalization math
- Usage tracking: Removed entirely — unlimited free AI workouts
- Cloudflare Worker: Retained for WOD Dashboard only

## Architecture

```
QuestionnaireViewModel.buildContext()
    |
    v
WorkoutGenerationContext
    |
    v
AppleIntelligenceWorkoutService (implements AIWorkoutServiceProtocol)
    |
    +-- Foundation Models available?
    |       |
    |       v
    |   On-device LLM generates AIWorkoutOutput (@Generable)
    |       |
    |       v
    |   WorkoutPostProcessor.process(raw:context:)
    |       +-- Apply weight calculations from 1RM maxes
    |       +-- Apply energy level multipliers
    |       +-- Apply cycle phase multipliers
    |       +-- Enrich coaching summary
    |       |
    |       v
    |   GeneratedWorkout
    |
    +-- Not available?
            |
            v
        OfflineWorkoutGenerator.generate(from:) (unchanged)
    |
    v
Persist to SwiftData (GeneratedWorkoutRecord) -- unchanged
    |
    v
WorkoutPreviewView -- unchanged
```

## Foundation Models Integration

### Generable Types

```swift
@Generable
struct AIWorkoutOutput {
    @Guide(description: "Short motivational coaching note")
    var coachingSummary: String

    @Guide(description: "List of exercises for the workout")
    var exercises: [AIExerciseOutput]
}

@Generable
struct AIExerciseOutput {
    @Guide(description: "Exercise name")
    var name: String

    @Guide(description: "Number of sets")
    var sets: Int

    @Guide(description: "Rep scheme like '8-10', '5', or 'AMRAP'")
    var reps: String

    @Guide(description: "True if no equipment needed")
    var bodyweightOnly: Bool

    @Guide(description: "Optional coaching note for this exercise")
    var notes: String?
}
```

### Prompt

Simplified compared to Gemini prompt. Includes only:
- Time available, focus area, energy level, equipment access
- Active injuries with restrictions (safety-critical)

Excludes (handled by post-processor):
- 1RM maxes and weight calculations
- Cycle phase adjustments
- Recent workout history

### Availability Check

```swift
if FoundationModelAvailability().supportsOnDeviceGeneration {
    // Foundation Models path
} else {
    // OfflineWorkoutGenerator fallback
}
```

## WorkoutPostProcessor

New pure-function module extracted from `OfflineWorkoutGenerator` logic.

```swift
enum WorkoutPostProcessor {
    static func process(
        raw: AIWorkoutOutput,
        context: WorkoutGenerationContext
    ) -> GeneratedWorkout
}
```

Processing steps in order:
1. Weight calculation -- match exercise names to user's 1RM data, compute working weight
2. Energy level adjustment -- multipliers (low: 0.85x, medium: 1.0x, high: 1.05x)
3. Cycle phase adjustment -- multipliers (menstrual: 0.90x, ovulation: 1.12x, etc.)
4. Coaching summary enrichment -- append notes about applied adjustments
5. Map to GeneratedWorkout -- assign IDs, attach QuestionnaireAnswers, set createdAt

## Files: Removed

| File | Reason |
|------|--------|
| `Domain/AIWorkout/GeminiWorkoutPrompt.swift` | Replaced by simplified Foundation Models prompt |
| `Domain/AIWorkout/RemoteWorkoutResponse.swift` | Replaced by @Generable types |
| `GeminiResponseParser` (in FirebaseAIWorkoutService.swift) | No longer needed |
| `Domain/Subscription/AIUsageTracker.swift` | No usage limits |

## Files: Added

| File | Purpose |
|------|---------|
| `Domain/AIWorkout/AIWorkoutOutput.swift` | @Generable types for structured output |
| `Domain/AIWorkout/WorkoutPostProcessor.swift` | Deterministic personalization post-processing |
| `Repositories/AIWorkout/AppleIntelligenceWorkoutService.swift` | New AIWorkoutServiceProtocol implementation |

## Files: Modified

| File | Changes |
|------|---------|
| `project.yml` | Deployment target iOS 17 -> iOS 26 |
| `Features/AIWorkout/QuestionnaireViewModel.swift` | Remove usage tracking, paywall, simplify generateWorkout() |
| `Features/AIWorkout/QuestionnaireView.swift` | Remove upgrade button |
| `Repositories/Firebase/FirebaseAIWorkoutService.swift` | Delete (replaced by AppleIntelligenceWorkoutService) |

## Files: Unchanged

| File | Reason |
|------|--------|
| `Domain/AIWorkout/OfflineWorkoutGenerator.swift` | Fallback path, untouched |
| `Domain/AIWorkout/GeneratedWorkout.swift` | Domain types stay the same |
| `Domain/AIWorkout/WorkoutGenerationContext.swift` | Input types stay the same |
| `Models/GeneratedWorkoutRecord.swift` | Persistence unchanged |
| `Features/AIWorkout/WorkoutPreviewView.swift` | UI unchanged |
| `Features/AIWorkout/WorkoutPreviewViewModel.swift` | UI unchanged |
| `Repositories/Protocols/RepositoryProtocols.swift` | AIWorkoutServiceProtocol unchanged |
| Cloudflare Worker | WOD Dashboard continues using it |

## Test Strategy

### New Tests
- `WorkoutPostProcessorTests` -- weight calc, cycle phase multipliers, energy adjustments, coaching summary, edge cases
- `AppleIntelligenceWorkoutServiceTests` -- mock Foundation Models, verify fallback, verify persistence

### Adapted Tests
- `AIWorkoutTests` -- update to new service, remove Gemini assertions
- `AIWorkoutViewModelTests` -- remove usage tracking/paywall tests

### Deleted Tests
- `GeminiWorkoutPromptTests` -- prompt removed
- `AIWorkoutServiceRemoteTests` -- Gemini parser removed
- `RemoteWorkoutResponseTests` -- type removed

### Coverage
100% line coverage maintained. WorkoutPostProcessor is a pure function (trivially testable). Foundation Models call is protocol-abstracted for mock injection.

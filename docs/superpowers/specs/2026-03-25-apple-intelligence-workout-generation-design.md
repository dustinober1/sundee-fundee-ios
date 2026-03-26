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
    |       +-- Assign rest periods based on focus/exercise type
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

The new service takes a `ModelContext` (same as the old `SwiftDataAIWorkoutService`) to implement all four protocol methods: `generateWorkout`, `fetchHistory`, `toggleFavorite`, `fetchFavorites`. History/favorites logic is unchanged.

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

### Edge Cases

- **Empty exercises array:** If the LLM returns zero exercises, fall back to `OfflineWorkoutGenerator`
- **Exercise name matching:** Use case-insensitive contains matching when mapping AI exercise names to user's 1RM keys (e.g., "Barbell Bench Press" matches "Flat Barbell Bench Press")
- **Unsupported hardware:** Devices running iOS 26 without Apple Intelligence hardware get `OfflineWorkoutGenerator` transparently

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
1. Weight calculation -- match exercise names to user's 1RM data, compute working weight using fuzzy name matching
2. Rest period assignment -- assign rest minutes based on exercise type and focus (strength: 2-3 min, hypertrophy: 60-90s, conditioning: 30-45s)
3. Energy level adjustment -- multipliers (low: 0.85x, medium: 1.0x, high: 1.05x)
4. Cycle phase adjustment -- multipliers (menstrual: 0.90x, ovulation: 1.12x, etc.)
5. Coaching summary enrichment -- append notes about applied adjustments
6. Map to GeneratedWorkout -- assign IDs, attach QuestionnaireAnswers, set createdAt, set reasoning to nil

## Files: Removed

| File | Reason |
|------|--------|
| `Repositories/Firebase/FirebaseAIWorkoutService.swift` | Entire file removed (contains `SwiftDataAIWorkoutService` + `GeminiResponseParser`) |
| `Domain/AIWorkout/GeminiWorkoutPrompt.swift` | Replaced by simplified Foundation Models prompt |
| `Domain/AIWorkout/RemoteWorkoutResponse.swift` | Replaced by @Generable types |
| `Domain/Subscription/AIUsageTracker.swift` | No usage limits |

## Files: Added

| File | Purpose |
|------|---------|
| `Domain/AIWorkout/AIWorkoutOutput.swift` | @Generable types for structured output |
| `Domain/AIWorkout/WorkoutPostProcessor.swift` | Deterministic personalization post-processing |
| `Repositories/AIWorkout/AppleIntelligenceWorkoutService.swift` | New AIWorkoutServiceProtocol implementation (takes ModelContext, same as old service) |

## Files: Modified

| File | Changes |
|------|---------|
| `project.yml` | Deployment target iOS 17 -> iOS 26 in all three places (lines 5, 12, 27). SundeeFundeeShared package platform minimum also updated. |
| `Features/AIWorkout/QuestionnaireViewModel.swift` | Remove usage tracking, paywall sheet, `checkUsageLimit()`, simplify `generateWorkout()` |
| `Features/AIWorkout/QuestionnaireView.swift` | Remove upgrade button, `showPaywall` state, `PaywallView` sheet, `PremiumBadge` reference |
| `Features/AIWorkout/AIWorkoutFlowView.swift` | Switch `SwiftDataAIWorkoutService` instantiation to `AppleIntelligenceWorkoutService` |
| `Features/Dashboard/DashboardView.swift` | Remove `AIUsageTracker.usageThisMonth()` and `FeatureEntitlement.aiWorkoutsRemaining` references |
| `Features/Subscription/ManageSubscriptionView.swift` | Remove `AIUsageTracker` and `FeatureEntitlement` AI limit references |
| `Domain/Subscription/FeatureEntitlement.swift` | Remove `aiWorkoutLimit()`, `aiWorkoutsRemaining()`, `canGenerateAIWorkout()` methods |
| `Packages/SundeeFundeeShared/Package.swift` | Platform minimum `.iOS(.v17)` -> `.iOS(.v26)` |
| `CLAUDE.md` | Update AI Workout Generation section to reflect Foundation Models architecture |

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

## Infrastructure Notes

- **CI:** GitHub Actions workflow will need Xcode 26 and an iOS 26 simulator. Runner image and simulator name may need updating.
- **Xcode Cloud:** `ci_scripts/ci_post_clone.sh` may need updates if Xcode 26 changes toolchain paths.
- **Swift version:** Verify `SWIFT_VERSION` in project.yml is compatible with iOS 26 SDK.

## Test Strategy

### New Tests
- `WorkoutPostProcessorTests` -- weight calc, cycle phase multipliers, energy adjustments, rest period assignment, coaching summary, edge cases (no maxes, no injuries, empty exercises)
- `AppleIntelligenceWorkoutServiceTests` -- mock Foundation Models via protocol, verify fallback to OfflineWorkoutGenerator, verify persistence to SwiftData

### Adapted Tests
- `AIWorkoutTests` -- update to new service, remove Gemini assertions
- `AIWorkoutViewModelTests` -- remove usage tracking/paywall tests
- `SubscriptionTests` -- remove `AIUsageTrackerTests` suite, adapt `FeatureEntitlement` tests that reference AI limit methods

### Deleted Tests
- `GeminiWorkoutPromptTests` -- prompt removed
- `AIWorkoutServiceRemoteTests` -- Gemini parser removed
- `RemoteWorkoutResponseTests` -- type removed

### Coverage
100% line coverage maintained. WorkoutPostProcessor is a pure function (trivially testable). Foundation Models call is protocol-abstracted for mock injection in tests.

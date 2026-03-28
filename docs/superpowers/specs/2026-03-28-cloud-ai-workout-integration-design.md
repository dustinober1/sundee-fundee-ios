# Cloud AI Workout Integration Design

**Date:** 2026-03-28
**Status:** Approved

## Purpose

Wire the iOS app to call the `ai-coach` Cloudflare Worker for Plus/Premium users, with a user-controlled toggle in the questionnaire, JWT auth, and graceful fallback to on-device generation.

## Generation Flow

```
QuestionnaireView
  → User fills time/focus/energy/equipment
  → If paid user: "Use Cloud AI" toggle visible (with remaining count)
  → User taps Generate
  → QuestionnaireViewModel checks toggle state:
      ON  → CloudAIWorkoutService.generateWorkout(context)
              → Build JWT (userID + tier + iat, signed HMAC-SHA256)
              → POST to ai-coach.sundeefundee.workers.dev/generate-workout
              → Parse response → WorkoutPostProcessor.process()
              → On failure: fall back to on-device generation
      OFF → AppleIntelligenceWorkoutService.generateWorkout(context)
              → On-device Foundation Models → WorkoutPostProcessor
              → On failure: OfflineWorkoutGenerator
```

Free users never see the toggle — they always get the on-device path.

## New Files

### 1. `CloudAIWorkoutService.swift` (Repositories/AIWorkout/)

Conforms to `AIWorkoutServiceProtocol`. Builds the prompt from `WorkoutGenerationContext` (reusing `AppleIntelligenceWorkoutService.buildPrompt()`), creates a JWT, POSTs to the worker, parses the response into `GeneratedWorkout`.

### 2. `CloudAIConfig.swift` (Domain/AIWorkout/)

Worker URL, JWT shared secret as a hardcoded constant, and `createJwt()` function using CryptoKit HMAC-SHA256. Threat model is low — rate limiting via KV is the real backstop. Secret is rotatable via the worker if compromised.

### 3. `CloudAIUsageTracker.swift` (Domain/AIWorkout/)

Tracks daily cloud generation count locally via UserDefaults (keyed by date). Client-side enforcement — the worker has its own KV-based backstop.

## Modified Files

### 1. `QuestionnaireView.swift`

Add "Use Sundee AI" toggle section between equipment picker and Generate button. Visible only for Plus/Premium users.

### 2. `QuestionnaireViewModel.swift`

Add `useCloudAI` state and `cloudAIRemaining` computed property. Route to `CloudAIWorkoutService` or `AppleIntelligenceWorkoutService` based on toggle. Increment usage tracker on cloud success only.

## Toggle UI Behavior

| State | Toggle | Label | Subtitle |
|-------|--------|-------|----------|
| Free user | Hidden | — | — |
| Plus, has remaining | Enabled | "Use Sundee AI" | "1 of 1 remaining today" |
| Plus, at limit | Disabled, off | "Use Sundee AI" | "Come back tomorrow" |
| Premium, has remaining | Enabled | "Use Sundee AI Pro" | "7 of 10 remaining today" |
| Premium, at limit | Disabled, off | "Use Sundee AI Pro" | "Come back tomorrow" |

## Error Handling

Every cloud failure silently degrades to on-device generation with a brief toast: "Cloud AI unavailable — generated on-device instead." Cloud AI never blocks workout generation.

| Error | Behavior |
|-------|----------|
| Network unreachable | Fall back to on-device, toast |
| 401 (bad JWT) | Fall back to on-device, toast |
| 429 (rate limited) | Update local tracker to match, disable toggle, fall back to on-device |
| 500 (AI failure) | Fall back to on-device, toast |
| Malformed response | Fall back to on-device, toast |

On 429, the local tracker is updated to reflect the server-side count so the toggle disables immediately.

## Testing Strategy

- **`CloudAIConfig` tests**: JWT creation produces valid tokens with correct payload structure
- **`CloudAIUsageTracker` tests**: Increment, daily reset, remaining count per tier
- **`QuestionnaireViewModel` tests**: Toggle visibility per tier, routing to correct service, fallback on failure
- **`QuestionnaireView` static tests**: Toggle label/subtitle text per tier and usage state

No network integration tests — `CloudAIWorkoutService` is tested via protocol mocking in ViewModel tests.

## Out of Scope

- Edit-before-start flow (already exists in WorkoutPreviewView)
- Persisting cloud vs on-device provenance on the workout record
- Analytics events for cloud generation (already defined in AnalyticsEvent)
- Re-enabling StoreKit (Sub-project 4)

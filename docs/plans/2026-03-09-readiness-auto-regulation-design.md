# Readiness & Auto-Regulation — v1 Design

## Overview

Add a daily readiness check-in that scores the user's training readiness (0-10) and auto-adjusts workout intensity. Blends manual survey with optional HealthKit data.

## Readiness Survey (Domain Layer)

`ReadinessSurvey` in `Domain/` — pure Swift, no dependencies:

- **Inputs:** sleepQuality (1-10), stressLevel (1-10), sorenessLevel (1-10), optional sleepHoursOverride from HealthKit
- **Scoring:** Weighted average (sleep 40%, stress 30%, soreness 30%) → 0-10 scale
- **HealthKit blending:** When HRV/RHR available, blend 70% survey + 30% HealthKit
- **Output:** `ReadinessResult` with `score: Double` and `tier: AdaptationReadinessTier` (reuses existing enum)
- **Persistence:** `UserDefaults` keyed by date string — one score per day

Existing `ReadinessMetrics.readinessScore` stays for pure HealthKit. The new scorer wraps both sources.

## UI Components

### Dashboard Readiness Card
- Shows score (gauge/ring), tier label (Prime/Normal/Fatigued/Recovery), "Check In" button if no survey today
- If survey done, shows score with subtle "Update" option
- Positioned at top of dashboard, before enrollment card

### Pre-Workout Survey Sheet
- `.sheet` presented when starting a workout with no readiness score for today
- Three sliders: Sleep Quality, Stress Level, Soreness Level (1-10 each)
- Sleep slider auto-filled from HealthKit if available (editable)
- Live tier preview as sliders move
- "Start Workout" button submits and proceeds; "Skip" proceeds with neutral tier

### Workout Adjustment Banner
- One-line banner at top of WorkoutExecutionView and WODExecutionView
- Only shown for `.low` or `.high` tier (not neutral)
- Examples: "Intensity boosted 20% — high readiness" / "Volume reduced 40% — low readiness"
- Orange background for high, warm rose for low

## Data Flow

```
DashboardView loads → check UserDefaults for today's score
  → Score exists: show ReadinessCard with score/tier
  → No score: show ReadinessCard with "Check In" prompt

User taps "Start Workout" → check today's score
  → Score exists: proceed, pass tier
  → No score: present ReadinessSurveySheet
    → Submit: save to UserDefaults, proceed with tier
    → Skip: proceed with .neutral tier
```

### HealthKit Activation
- Settings toggle: "Use HealthKit for Readiness" (off by default)
- When enabled, requests permissions and passes HealthKitReadinessRepository into DashboardViewModel
- Sleep auto-fills survey slider; HRV/RHR blend into final score

### AI Workout Integration
- `QuestionnaireViewModel.buildContext()` reads today's tier from UserDefaults (replaces hardcoded nil)
- Flows into `GeminiPromptBuilder` which already handles `readinessTier`

### Program Workout Integration
- Already wired — `DashboardViewModel` passes `readinessScore` to `CycleProgramGenerator.adaptProgram()`
- Just needs score populated from survey instead of only HealthKit

## Testing

- **Domain:** ReadinessSurvey scoring (weighted average, HealthKit blending, edge cases, tier mapping)
- **ViewModel:** Slider state, UserDefaults persistence, HealthKit auto-fill, dashboard card states
- **Integration:** AI workout generation receives tier; existing CycleAdaptationPolicy tests cover adjustment math
- Static helper pattern for testability (project convention)

## Scope Boundaries

**In scope:** Survey, dashboard card, pre-workout gate, adjustment banner, HealthKit toggle, AI integration
**Out of scope:** HealthKit background refresh, historical readiness trends, exercise swapping (Phase 3 per issue)

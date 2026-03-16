---
phase: 05-differentiating-features
plan: "08"
subsystem: ai-workout
tags: [ai, workout-generation, cloud-functions, offline-fallback, config-ui, preview-ui]
dependency_graph:
  requires: [05-01, 05-02, 05-03, 05-04, 05-05]
  provides: [ai-workout-config-screen, ai-workout-preview-screen, adaptation-chip, config-cards]
  affects: [history-tab, workout-session]
tech_stack:
  added: []
  patterns:
    - Module-level shared state for cross-screen data passing (avoids URL param serialization limits)
    - Static helper exported from component (buildAdaptationText) for testability
    - Connectivity check before Cloud Function call (not after) per anti-pattern research
    - Platform-branched Firebase Functions call (web: getFunctions/httpsCallable, native: require)
key_files:
  created:
    - SundeeFundeeRN/app/(app)/ai-workout/config.tsx
    - SundeeFundeeRN/app/(app)/ai-workout/preview.tsx
    - SundeeFundeeRN/src/components/ai-workout/AdaptationChip.tsx
    - SundeeFundeeRN/src/components/ai-workout/ConfigCards.tsx
    - SundeeFundeeRN/src/components/ai-workout/__tests__/AdaptationChip.test.tsx
  modified: []
decisions:
  - "Module-level shared state (getSharedWorkout/setSharedWorkout) used to pass GeneratedWorkout from config to preview — Expo Router params have serialization limits unsuitable for full workout objects"
  - "OnboardingProfile.cycleOptIn gates cycle phase loading — CycleSettings has no cycleTrackingEnabled field; opt-in flag lives in onboarding profile"
  - "Platform-branched Firebase Functions call — web uses firebase/functions JS SDK dynamic import, native uses @react-native-firebase/functions require"
  - "Cloud Function failure falls back to generateOfflineWorkout() with Alert notification — single offline code path for both no-network and function-error cases"
  - "WorkoutRecord saved ONLY on Start Workout tap — not on preview load, per pitfall 7 in research"
metrics:
  duration: 15 min
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_created: 5
  files_modified: 0
---

# Phase 05 Plan 08: AI Workout Generation Flow Summary

**One-liner:** AI workout config+preview flow with Cloud Function call, offline template fallback, adaptation context chip, and history save gated on Start tap.

## What Was Built

### Task 1: Config Screen + Components

**ConfigCards.tsx** — Reusable horizontal scrollable card-row component. Each option is an 80×80 tappable card (Uber ride-selection style). Selected card: orange border + 1.04x scale. Four rows used in config screen: Time, Focus, Equipment, Energy.

**AdaptationChip.tsx** — Context summary pill: "Adapting for: Luteal phase · Right knee · Readiness 7/10". Returns null if no adaptations apply. Active injuries only (resolved excluded). `buildAdaptationText` exported as static helper for unit testing.

**config.tsx** — Main AI workout config screen:
- Loads adaptation context on mount (cycle phase via OnboardingProfile.cycleOptIn gate, active injuries, today's readiness)
- Checks network connectivity BEFORE calling Cloud Function
- Online path: Firebase Cloud Function `generateWorkout` with error fallback to offline
- Offline path: `generateOfflineWorkout(context)` with offline badge flag set
- Module-level shared state (setSharedWorkout) passes GeneratedWorkout to preview without URL serialization

### Task 2: Preview Screen

**preview.tsx** — Preview screen:
- Reads GeneratedWorkout from shared state (set by config screen)
- Exercise list: number, name, sets×reps, weight, rest; BW badge for bodyweight exercises
- Injury substitution labels: "Substituted for [original] due to injury" shown in orange italic
- Offline badge shown when `isOffline=true` from shared state
- AdaptationChip (cycle/injuries/readiness shown when available)
- Start Workout: saves WorkoutRecord with `source: 'ai'` then navigates to /workout-session
- Regenerate: clears shared state and navigates back (no save)

## Test Results

```
Tests: 12 passed, 12 total
Test Suites: 1 passed, 1 total
```

Tests cover buildAdaptationText: all combinations (phase+injury+readiness, subsets, none→null), resolved injury exclusion, bodyLocation fallback display, all 4 cycle phase labels, readiness score rounding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CycleSettings has no cycleTrackingEnabled field**
- **Found during:** Task 1 implementation
- **Issue:** Plan referenced `cycleSettings?.cycleTrackingEnabled` but CycleSettings interface only has `averageCycleLengthDays`, `averagePeriodLengthDays`, `lutealPhaseLengthDays`. The cycle tracking opt-in flag lives in `OnboardingProfile.cycleOptIn`.
- **Fix:** Load OnboardingProfile first to check `cycleOptIn === true` before loading cycle data
- **Files modified:** `app/(app)/ai-workout/config.tsx`
- **Commit:** 3dab480

**2. [Rule 1 - Bug] AdaptationChip readiness prop uses full record not raw score**
- **Found during:** Task 1 component design
- **Issue:** Plan described `readinessScore?: number` but the actual readiness data available at screen level is a `ReadinessSurveyRecord` (from `getReadinessRepo`). The score is `record.result.score` (0–1).
- **Fix:** Changed AdaptationChip prop to `readiness?: ReadinessSurveyRecord | null`, computed `score * 10` rounded for display inside `buildAdaptationText`
- **Files modified:** `src/components/ai-workout/AdaptationChip.tsx`

**3. [Rule 1 - Bug] InjuryProfile chip prop uses records not domain type**
- **Found during:** Task 1 component design
- **Issue:** Plan described `injuries?: InjuryProfile[]` (domain type) but the screen works with `InjuryProfileRecord[]` from the repository layer
- **Fix:** Changed AdaptationChip injuries prop to `InjuryProfileRecord[]` for consistency with what repositories return
- **Files modified:** `src/components/ai-workout/AdaptationChip.tsx`

## Self-Check: PASSED

Files exist:
- FOUND: SundeeFundeeRN/app/(app)/ai-workout/config.tsx
- FOUND: SundeeFundeeRN/app/(app)/ai-workout/preview.tsx
- FOUND: SundeeFundeeRN/src/components/ai-workout/AdaptationChip.tsx
- FOUND: SundeeFundeeRN/src/components/ai-workout/ConfigCards.tsx
- FOUND: SundeeFundeeRN/src/components/ai-workout/__tests__/AdaptationChip.test.tsx

Commits exist:
- 3dab480: feat(05-08): build AI workout config screen with ConfigCards and AdaptationChip
- efa49f0: feat(05-08): build AI workout preview screen with Start/Regenerate and history save

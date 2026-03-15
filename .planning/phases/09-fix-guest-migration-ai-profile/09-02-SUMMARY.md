---
phase: 09-fix-guest-migration-ai-profile
plan: "02"
subsystem: ai-workout
tags: [react-native, workout-generation, onboarding-profile, settings, exercise-maxes, workout-history, context-wiring]

# Dependency graph
requires:
  - phase: 05-differentiating-features
    provides: "AI workout generation screen (config.tsx) and WorkoutGenerationContext type"
  - phase: 04-core-workout-loop
    provides: "ExerciseMaxRepo (getAllMaxes), WorkoutRepo (getHistory), WorkoutRecord type"
  - phase: 03-data-layer-and-offline-architecture
    provides: "SettingsRepo (getSettings), OnboardingProfileRepo (getProfile)"
provides:
  - "Real user gender, experienceLevel, primaryGoal read from OnboardingProfileRepo in AI workout context"
  - "Real weightUnit read from SettingsRepo in AI workout context"
  - "Exercise maxes from ExerciseMaxRepo mapped to WorkoutGenerationContext.maxes"
  - "Last 5 workouts from WorkoutRepo mapped to WorkoutGenerationContext.recentWorkouts"
  - "Safe fallbacks to hardcoded defaults when profile/settings are null"
  - "12 tests covering all wiring scenarios and fallback behavior"
affects: [ai-workout-generation, workout-personalization, cloud-function-context]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Profile data reuse: existing getProfile call extended with setProfile() — no duplicate repo calls"
    - "Independent try/catch per data source: settings/maxes/workouts each silently degrade on failure"
    - "useCallback dep array includes all state used in callback — prevents stale closure on generate"
    - "Test strategy: mock expo-network offline to avoid dynamic import() — verify via generateOfflineWorkout context capture"

key-files:
  created:
    - "SundeeFundeeRN/app/(app)/ai-workout/__tests__/config.test.tsx"
  modified:
    - "SundeeFundeeRN/app/(app)/ai-workout/config.tsx"

key-decisions:
  - "Profile state set via setProfile() after existing getProfile call — no duplicate fetch per plan constraint"
  - "Test verification via generateOfflineWorkout mock (context capture) instead of callCloudFunction — avoids dynamic import() Jest limitation in CommonJS mode"
  - "recentWorkouts.focus reads from w.workout?.questionnaire?.focus for AI records; exercises from w.exercises[].exerciseName for custom/program records"
  - "durationMinutes computed as Math.round(durationSeconds / 60) from WorkoutRecord"

patterns-established:
  - "Independent try/catch blocks for each non-critical data load — one failure does not block others"
  - "Offline test path for context verification: mock expo-network isConnected=false, capture via generateOfflineWorkout mock"

requirements-completed: [AIWK-02]

# Metrics
duration: 7min
completed: 2026-03-15
---

# Phase 9 Plan 02: AI Workout Profile Wiring Summary

**Six hardcoded AI workout values replaced with real user data from OnboardingProfileRepo, SettingsRepo, ExerciseMaxRepo, and WorkoutRepo — with null-safe fallbacks**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-15T21:37:22Z
- **Completed:** 2026-03-15T21:44:17Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Replaced 4 hardcoded profile values (gender, experienceLevel, primaryGoal, weightUnit) with real data from OnboardingProfileRepo and SettingsRepo
- Added exercise maxes from ExerciseMaxRepo mapped to `{ name: exerciseId, weightLb: weight }` for WorkoutGenerationContext
- Added last-5 workouts from WorkoutRepo mapped to `RecentWorkout[]` with correct date/focus/exercises/durationMinutes fields
- Each new data source has an independent try/catch so one failure doesn't block others
- 12 tests verify all wiring, mapping, and fallback scenarios

## Task Commits

1. **Task 1: Wire real user profile, settings, maxes, and recent workouts into AI config** - `318b073` (feat)

## Files Created/Modified
- `SundeeFundeeRN/app/(app)/ai-workout/config.tsx` - Added 4 new state variables, extended loadAdaptationContext with 3 new try/catch blocks, replaced 6 hardcoded values, updated dependency array
- `SundeeFundeeRN/app/(app)/ai-workout/__tests__/config.test.tsx` - 12 tests covering profile wiring, settings wiring, maxes mapping, recentWorkouts mapping, fallback behavior, injuryToSummary helper

## Decisions Made
- Reused the existing `getProfile()` call in `loadAdaptationContext` and added `setProfile(fetchedProfile)` immediately after — no duplicate repo call
- Tests use offline network mock (`isConnected: false`) to verify the `WorkoutGenerationContext` via `generateOfflineWorkout` mock instead of fighting the dynamic `import()` inside `callGenerateWorkoutFunction`
- `recentWorkouts.focus` reads from `w.workout?.questionnaire?.focus` (AI records) with `'full_body'` fallback
- `durationMinutes` computed as `Math.round(durationSeconds / 60)` from `WorkoutRecord.durationSeconds`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `callGenerateWorkoutFunction` uses a dynamic `import()` which Jest in CommonJS mode does not transform via `jest.mock`. Solution: mock `expo-network` to return `isConnected: false`, forcing the offline path through `generateOfflineWorkout` which was mockable. The `WorkoutGenerationContext` is the same object regardless of online/offline path.
- Observed transient parallel Jest worker contamination on `useGuestSignIn` tests (unrelated to plan 02) — passes consistently in `--runInBand` mode and in parallel on re-run. Pre-existing flake from Jest module isolation between workers.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AI workout generation now sends real user data to the Cloud Function for personalized workouts
- Phase 09-03 (if any) can build on the fully wired WorkoutGenerationContext
- The 6 previously hardcoded values are now dynamic — Cloud Function prompts will receive accurate user profile data

---
*Phase: 09-fix-guest-migration-ai-profile*
*Completed: 2026-03-15*

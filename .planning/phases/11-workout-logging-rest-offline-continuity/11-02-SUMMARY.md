---
phase: 11
plan: "02"
subsystem: workout-ui
tags: [riverpod, flutter, workout-session, set-logging, ui-components]

dependency-graph:
  requires:
    - "11-01: SetData model, WorkoutRepository, workoutRepositoryProvider"
    - "10-03: activeCycleProvider (FutureProvider<ActiveCycle?>)"
    - "10-02: programsProvider (FutureProvider<List<ProgramV2>>)"
    - "10-01: userProvider (FutureProvider<User?>)"
  provides:
    - "WorkoutSessionState: immutable ephemeral session model with setDataMap/completedSets"
    - "WorkoutSessionNotifier: startSession, logSet, completeWorkout, cancelWorkout"
    - "workoutSessionProvider: NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>"
    - "SetInputWidget: weight/reps input row with test keys"
    - "ExerciseAccordion: collapsible exercise list with set progress counters"
    - "WorkoutScreen: full ConsumerStatefulWidget session UI"
  affects:
    - "11-03: RestTimerProvider integrates with WorkoutScreen._handleLogSet"
    - "12+: workoutSessionProvider.completeWorkout() populates CompletedWorkouts/Sets for history"

tech-stack:
  added: []
  patterns:
    - "NotifierProvider<Notifier, State?> pattern for nullable ephemeral state"
    - "Immutable copyWith pattern: spread operator for Map/Set updates in state"
    - "ConsumerStatefulWidget with initState async session loading via ref.read(.future)"
    - "GoRouter captured before async gap to satisfy use_build_context_synchronously lint"
    - "PopScope.onPopInvokedWithResult with discard confirmation dialog"
    - "ExpansionPanelList for collapsible exercise accordion"

file-tracking:
  created:
    - flutter_app/lib/data/models/workout_session_state.dart
    - flutter_app/lib/shared/providers/workout_session_provider.dart
    - flutter_app/lib/features/workout/set_input_widget.dart
    - flutter_app/lib/features/workout/exercise_accordion.dart
  modified:
    - flutter_app/lib/features/workout/workout_screen.dart

decisions:
  - id: D1
    decision: "WorkoutSessionState.setDataMap uses '$exerciseId-$setNumber' composite key"
    rationale: "Unique per exercise+set combination; supports O(1) lookup for completion status check"
  - id: D2
    decision: "ExerciseAccordion uses index-suffixed exerciseId ('${exercise.exercise}-$index')"
    rationale: "Same exercise may appear multiple times in a session; index disambiguates"
  - id: D3
    decision: "GoRouter.of(context) captured before await in PopScope/onPressed callbacks"
    rationale: "Satisfies use_build_context_synchronously lint; context unavailable after async gap in closures"
  - id: D4
    decision: "WorkoutScreen.initState loads session eagerly via ref.read (not ref.watch)"
    rationale: "Session loading is one-shot initialization; watching would re-trigger on provider rebuild"

metrics:
  duration: "~22m"
  completed: "2026-02-21"
  tasks-completed: 3
  tests-added: 0
  deviations: 3
---

# Phase 11 Plan 02: WorkoutSessionProvider + Workout UI Summary

**One-liner:** Riverpod NotifierProvider managing ephemeral set state with ConsumerStatefulWidget UI featuring collapsible exercises and weight/reps inputs

## What Was Built

WorkoutSessionProvider and workout session UI enabling users to log sets (weight/reps) during workouts.

### WorkoutSessionState (immutable model)
- `setDataMap: Map<String, SetData>` — keyed by `"$exerciseId-$setNumber"`
- `completedSets: Set<String>` — tracks which set keys are logged
- `copyWith` with spread operator for Map/Set immutable updates
- Helper methods: `getSet()`, `isSetCompleted()`, `completedSetCount`

### WorkoutSessionNotifier (NotifierProvider)
- `startSession()` — initializes state with program/week/session context
- `logSet()` — adds SetData and marks set complete (immutable state update)
- `completeWorkout()` — calls `workoutRepositoryProvider.saveWorkout()` then clears state
- `cancelWorkout()` — clears state without persisting
- Exposed as `NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>`

### SetInputWidget
- Weight field (decimal keyboard), reps field (number keyboard), log button
- Test keys: `set-N-weight-input`, `set-N-reps-input`, `set-N-log-button`, `set-N-row`
- Completed state: visual container color change + check icon badge + disabled inputs

### ExerciseAccordion
- `ExpansionPanelList` with collapsible exercise panels
- Set progress counter in header trailing text (`completedCount/setCount`)
- Auto-expands first exercise on load (`_expandedIndex = 0`)
- Test key: `exercise-accordion`; header keys: `exercise-header-N`

### WorkoutScreen (ConsumerStatefulWidget)
- `initState` async session loading from `activeCycleProvider` + `programsProvider`
- Session header: week number + focus label + sets logged counter
- `PopScope` with discard confirmation dialog (prevents accidental data loss)
- Complete Workout button enabled only when `completedSetCount > 0`
- Test keys: `workout-screen`, `complete-workout-button`
- Pre-integrated with Plan 03 rest timer (auto-starts after each logged set)

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | Composite key `"$exerciseId-$setNumber"` for setDataMap | O(1) completion lookup |
| D2 | Index-suffixed exerciseId `"${exercise.exercise}-$index"` | Same exercise may repeat in session |
| D3 | GoRouter captured before await in callbacks | Satisfies `use_build_context_synchronously` lint |
| D4 | ref.read (not ref.watch) in initState for session loading | One-shot initialization, avoids re-trigger |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ExpansionPanel does not accept 'key' parameter**
- **Found during:** Task 2
- **Issue:** Plan specified `key: Key('exercise-panel-$index')` on `ExpansionPanel`, but that widget has no `key` parameter in its constructor
- **Fix:** Removed the unsupported `key` from `ExpansionPanel` (parent `ExpansionPanelList` already has `key: 'exercise-accordion'`)
- **Files modified:** `exercise_accordion.dart`

**2. [Rule 1 - Bug] use_build_context_synchronously lint in async callbacks**
- **Found during:** Task 3
- **Issue:** `if (shouldPop && mounted) context.go('/dashboard')` pattern fires lint because `mounted` guard is combined with another condition
- **Fix:** Captured `GoRouter.of(context)` before await, then used early-return pattern `if (!shouldPop || !mounted) return;`
- **Files modified:** `workout_screen.dart`

**3. [Rule 1 - Bug] workout_screen.dart pre-populated with Plan 03 rest timer content**
- **Found during:** Task 3
- **Issue:** The `workout_screen.dart` file was already pre-populated from a prior Plan 03 execution with rest timer imports, `timerState` watch, and rest timer pill widget. The `timerState` variable appeared unused to the linter because the watch was removed, but it IS used in the rest timer pill further down.
- **Fix:** Kept all Plan 03 rest timer content intact (it was already correctly committed); restored the `timerState` watch variable that was needed by the rest timer pill widget.
- **Files modified:** `workout_screen.dart`

## Next Phase Readiness

Plan 03 (RestTimerProvider + RestTimerSheet) was already executed in a prior session. Phase 11 is complete.

**Phase 12 prerequisites satisfied:**
- ✅ CompletedWorkouts/CompletedSets tables in Drift schema v3 (Plan 01)
- ✅ WorkoutRepository.saveWorkout() atomic transaction (Plan 01)
- ✅ WorkoutSessionProvider completes to Drift (this plan)
- ✅ RestTimerProvider with background recalculation (Plan 03 — pre-executed)

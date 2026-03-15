---
phase: 04-core-workout-loop
plan: "05"
subsystem: ui-hooks
tags: [workout-session, hooks, rest-timer, pr-detection, exercise-picker, drag-to-reorder, expo-notifications, expo-haptics]
dependency_graph:
  requires:
    - 04-01  # domain types: Exercise, MuscleGroup, TimerState, WorkoutSession
    - 04-02  # domain functions: session-actions, checkForPR
    - 04-03  # repositories: ExerciseRepo, ExerciseMaxRepo, WorkoutRepo
  provides:
    - useWorkoutSession hook (session state, auto-save, crash recovery, finishWorkout)
    - useRestTimer hook (countdown, notification scheduling, AppState sync)
    - usePRDetection hook (max cache, checkAndRecordPR, recentPRs queue)
    - MuscleGroupGrid component
    - ExerciseSearch component (live filter + inline custom creation)
    - SetRow component (weight/reps inputs, ghost text, PR badge)
    - ExerciseCard component (set rows + drag handle + add-set)
    - RestTimerBar component (animated bottom bar)
    - PRToast component (top-of-screen celebration)
    - exercise-picker.tsx modal screen
    - workout-session.tsx active logging screen
  affects:
    - 04-06  # history tab UI will consume WorkoutRecord written by finishWorkout
    - 04-07  # maxes tab reads ExerciseMax records written by usePRDetection
tech_stack:
  added: []
  patterns:
    - React hooks wrap pure domain functions with state + side effects
    - AsyncStorage auto-save on every set completion (crash recovery on mount)
    - expo-notifications scheduled on rest timer start, cancelled on skip/unmount
    - AppState listener re-syncs rest timer on foreground return
    - DraggableFlatList with long-press drag handle for exercise reordering
    - Animated.Value slide-in/out for RestTimerBar and PRToast
    - useFocusEffect picks up exercise selection params from exercise-picker modal
key_files:
  created:
    - SundeeFundeeRN/src/hooks/useWorkoutSession.ts
    - SundeeFundeeRN/src/hooks/useRestTimer.ts
    - SundeeFundeeRN/src/hooks/usePRDetection.ts
    - SundeeFundeeRN/src/hooks/__tests__/useRestTimer.test.ts
    - SundeeFundeeRN/src/components/workout/SetRow.tsx
    - SundeeFundeeRN/src/components/workout/ExerciseCard.tsx
    - SundeeFundeeRN/src/components/workout/RestTimerBar.tsx
    - SundeeFundeeRN/src/components/workout/PRToast.tsx
    - SundeeFundeeRN/src/components/exercises/ExerciseSearch.tsx
    - SundeeFundeeRN/src/components/exercises/MuscleGroupGrid.tsx
    - SundeeFundeeRN/app/(app)/exercise-picker.tsx
    - SundeeFundeeRN/app/(app)/workout-session.tsx
  modified:
    - SundeeFundeeRN/app/(app)/_layout.tsx (added workout-session + exercise-picker Stack.Screen entries)
decisions:
  - "useFocusEffect + router.setParams used for exercise-picker → workout-session result passing — Expo Router has no native modal result callback"
  - "useRestTimer: tick interval is 100ms for smooth display; AppState listener re-syncs from timestamps on foreground to avoid drift"
  - "PRToast uses recentPRs queue — multiple PRs in one set completion won't be lost"
  - "finishWorkout converts WorkoutSession to WorkoutRecord with completedAt timestamp and computed totalVolume"
  - "ExerciseCard drag handle fires on long-press (200ms delay) to avoid conflict with scroll"
metrics:
  duration_minutes: 8
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_created: 12
  files_modified: 1
---

# Phase 4 Plan 05: Workout Session UI Summary

**One-liner:** Complete workout logging UI with exercise picker modal (muscle group grid + search + inline custom creation), active session screen (DraggableFlatList of ExerciseCards with SetRows), auto rest timer (expo-notifications + AppState sync), and PR detection toasts (expo-haptics).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Workout hooks (useWorkoutSession, useRestTimer, usePRDetection) + tests | d13f9ac | 4 files |
| 2 | UI components + screens (all components + exercise-picker + workout-session) | d047f39 | 9 files |

## What Was Built

### Hooks (Task 1)

**useWorkoutSession** (`src/hooks/useWorkoutSession.ts`): Wraps all session-action domain functions. Starts with `startWorkout()` (creates session, persists to `@sundee/active-workout`). Dispatchers for addExercise/removeExercise/addSet/completeSet/reorderExercises all call the pure domain function then persist to AsyncStorage. `finishWorkout(uid)` converts WorkoutSession to WorkoutRecord (completed exercises, totalVolume, durationSeconds) and saves via WorkoutRepo. `getPreviousValues(exerciseId)` queries last workout for ghost-text placeholders. On mount, restores active workout from AsyncStorage for crash recovery.

**useRestTimer** (`src/hooks/useRestTimer.ts`): Timer state built on `createTimerState('rest', ...)`. `start(seconds)` schedules expo-notifications local notification, starts 100ms tick interval. `skip()` cancels notification and clears state. AppState 'active' listener re-syncs remaining time from timestamps after backgrounding. Cleans up both interval and notification on unmount.

**usePRDetection** (`src/hooks/usePRDetection.ts`): Loads all ExerciseMax records into memory on `loadMaxes(uid)`. `checkAndRecordPR(uid, exerciseId, exerciseName, weight, reps)` calls `checkForPR` domain function, saves new ExerciseMax via repo if PR detected, updates in-memory cache, enqueues PRCheckResult in `recentPRs`.

### Components (Task 2)

**MuscleGroupGrid**: 2-column FlatList of 7 muscle group cards. CREAM_LIGHT cards, NAVY text, ORANGE border on selection.

**ExerciseSearch**: Live-filtered FlatList using `filterExercises`. When query has no matches, shows "Create [query]" button at bottom. Tapping reveals inline form with name pre-fill and muscle group picker chips.

**SetRow**: Weight/reps TextInputs with ghost-text placeholders from previous workout. Checkmark button (disabled until both inputs filled). Orange "PR" badge when `set.isPersonalRecord`. Completed sets are grayed and locked.

**ExerciseCard**: Exercise name header with muscle group badge + set progress count. Lists SetRows. Long-press drag handle (200ms delay) for DraggableFlatList. "+ Add Set" footer button. Remove button.

**RestTimerBar**: Fixed bottom bar with `Animated.Value` slide-in/out. ORANGE progress bar fills left-to-right. Large countdown text in CREAM on NAVY background. Skip button.

**PRToast**: Slides down from top with spring animation. `expo-haptics.notificationAsync(Success)` on show. Auto-dismisses after 3s with slide-out. ORANGE background, CREAM text.

**exercise-picker.tsx**: Modal screen. Loads custom exercises from ExerciseRepo on mount. Top: ExerciseSearch (always visible). Below: MuscleGroupGrid (when no filter active). Exercise selection navigates back with params for useFocusEffect in workout-session to pick up.

**workout-session.tsx**: Full session screen. DraggableFlatList of ExerciseCards. Header shows elapsed time (seconds interval). `handleCompleteSet` checks PR, starts rest timer, dispatches completeSet. Finish button with confirmation dialog. FAB for adding exercises. RestTimerBar + PRToast overlays.

## Verification Results

- useRestTimer.test.ts: 10/10 tests pass
- Full suite: 921/921 tests pass
- `npx expo export --platform web`: clean bundle (4.3MB), no errors

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Added `@testing-library/react-hooks` → `@testing-library/react-native` import correction**

- **Found during:** Task 1 test run
- **Issue:** Test file initially imported from `@testing-library/react-hooks` which is not installed; project uses `@testing-library/react-native` v13+ which exports `renderHook`
- **Fix:** Updated test import to `@testing-library/react-native`
- **Files modified:** `src/hooks/__tests__/useRestTimer.test.ts`
- **Commit:** d13f9ac (included in task commit)

**2. [Rule 2 - Missing functionality] Used explicit jest.mock() instead of __mocks__ auto-resolution for expo-notifications**

- **Found during:** Task 1 test run
- **Issue:** `__mocks__/expo-notifications.ts` global mock requires explicit `jest.mock('expo-notifications')` call for node_modules in Jest (unlike relative path mocks). Without the call, the mock wasn't being used.
- **Fix:** Added hoisted `jest.mock('expo-notifications', ...)` factory at top of test file with restored mock implementations in `beforeEach`
- **Files modified:** `src/hooks/__tests__/useRestTimer.test.ts`
- **Commit:** d13f9ac (included in task commit)

## Self-Check: PASSED

Files verified present:
- SundeeFundeeRN/src/hooks/useWorkoutSession.ts - FOUND
- SundeeFundeeRN/src/hooks/useRestTimer.ts - FOUND
- SundeeFundeeRN/src/hooks/usePRDetection.ts - FOUND
- SundeeFundeeRN/src/hooks/__tests__/useRestTimer.test.ts - FOUND
- SundeeFundeeRN/src/components/workout/SetRow.tsx - FOUND
- SundeeFundeeRN/src/components/workout/ExerciseCard.tsx - FOUND
- SundeeFundeeRN/src/components/workout/RestTimerBar.tsx - FOUND
- SundeeFundeeRN/src/components/workout/PRToast.tsx - FOUND
- SundeeFundeeRN/src/components/exercises/ExerciseSearch.tsx - FOUND
- SundeeFundeeRN/src/components/exercises/MuscleGroupGrid.tsx - FOUND
- SundeeFundeeRN/app/(app)/exercise-picker.tsx - FOUND
- SundeeFundeeRN/app/(app)/workout-session.tsx - FOUND

Commits verified:
- d13f9ac - Task 1 hooks
- d047f39 - Task 2 UI components and screens

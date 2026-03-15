---
phase: 04-core-workout-loop
verified: 2026-03-15T02:30:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Complete workout flow end-to-end on a real device or simulator"
    expected: "Start Workout -> add exercise via muscle group grid or search -> log sets with ghost text -> complete set -> rest timer appears at bottom -> skip rest timer -> finish workout -> workout appears in History tab as Custom source"
    why_human: "React Native UI behavior, gesture handling (swipe-to-delete, drag-to-reorder), haptic feedback, and notification delivery cannot be verified programmatically via grep"
  - test: "Rest timer background and screen-lock behavior"
    expected: "Start a rest timer, lock the screen or background the app for 30 seconds, return to app — timer shows correct remaining time (uses timestamp math, not interval) and notification fires at 0"
    why_human: "Background/screen-lock behavior requires a real iOS or Android device or simulator with notification permissions granted"
  - test: "ForTime/AMRAP/EMOM timed workout modes"
    expected: "From dashboard, tap ForTime / AMRAP / EMOM — 3-2-1-Go countdown plays with beep sounds, then timer starts. AMRAP counts down with red urgency at <30s. EMOM shows minute progress and fires per-minute notification when backgrounded."
    why_human: "Audio playback (expo-av beeps), countdown animation, and background notification delivery require device testing"
  - test: "PR detection with toast notification and haptic"
    expected: "Log a set with higher weight than any previous best for that exercise — orange PR toast appears at top of screen with haptic feedback; PR badge appears inline on the set row"
    why_human: "Visual toast animation, haptic feedback (expo-haptics), and inline PR badge rendering must be confirmed visually on device"
  - test: "Exercise detail 1RM line chart renders correctly"
    expected: "Tap an exercise in the Maxes tab — exercise-detail screen opens showing a line chart of estimated 1RM over time (orange line, cream background) and a rep-range PR table with 5 rows"
    why_human: "react-native-gifted-charts LineChart rendering must be confirmed visually; empty states and data shape correctness need visual confirmation"
---

# Phase 4: Core Workout Loop Verification Report

**Phase Goal:** Users can log any workout, execute timed workouts, and see their progress — entirely offline if needed
**Verified:** 2026-03-15T02:30:00Z
**Status:** human_needed (all automated checks passed; 5 items require device testing)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | User can log sets with reps and weight for any exercise from a 200+ exercise library, including custom exercises, with no network connection required | VERIFIED | `exercises.json` 202 entries across 7 muscle groups; `ExerciseRepo` + `LocalExerciseRepo` work offline; `useWorkoutSession` auto-saves to AsyncStorage; full session screen at `workout-session.tsx` (468 lines) |
| 2 | Rest timer counts down between sets, continues while screen is locked, and survives app backgrounding | VERIFIED | `useRestTimer.ts` uses timestamp-based `TimerState` (not interval); schedules `expo-notifications` (`scheduleNotificationAsync`) for background; AppState listener recalculates on foreground return |
| 3 | ForTime, AMRAP, and EMOM timers all function correctly; timer state survives screen lock | VERIFIED | `useWorkoutTimer.ts` imports from `timer-state.ts` (timestamp math); schedules individual EMOM notifications per minute; `timer-mode.tsx` (534 lines) with full-screen UI, pause/stop controls |
| 4 | App automatically detects and displays a PR notification when a set exceeds previous best weight | VERIFIED | `checkForPR` function in `check-pr.ts` checks weight and estimated-1RM PRs; `usePRDetection.ts` wired into `workout-session.tsx`; `PRToast` rendered conditionally; `RestTimerBar` starts on set completion |
| 5 | User can view workout history filtered by source, delete individual workouts, view per-exercise progress charts, and track 1RM history | VERIFIED | `history.tsx` (275 lines) wired to `getWorkoutRepo`/`getHistory`; `HistoryCard` has `Swipeable` swipe-to-delete; `maxes.tsx` (308 lines) wired to `getExerciseMaxRepo`/`getAllMaxes`; `exercise-detail.tsx` uses `prepare1RMChartData`; `ProgressChart.tsx` uses `LineChart` from `react-native-gifted-charts` |

**Score:** 5/5 truths verified

---

## Required Artifacts

### Wave 1 — Domain Foundation (Plans 01-02)

| Artifact | Status | Details |
|----------|--------|---------|
| `src/domain/exercises/exercise-types.ts` | VERIFIED | Exports `Exercise`, `MuscleGroup`, `MUSCLE_GROUPS`, `EquipmentType` |
| `src/domain/exercises/exercise-filter.ts` | VERIFIED | Exports `filterExercises`; imports `Exercise`/`MuscleGroup` from `exercise-types` |
| `src/domain/timers/timer-state.ts` | VERIFIED | All 7 functions exported; uses `Date.now()` for timestamp math; 105 lines substantive |
| `src/domain/workout-session/session-types.ts` | VERIFIED | `LoggedSet`, `ActiveExercise`, `WorkoutSession` types |
| `src/domain/pr-detection/pr-types.ts` | VERIFIED | `ExerciseMax`, `PRCheckResult`, `TrackedRepRange`, `TRACKED_REP_RANGES` |
| `src/resources/exercises.json` | VERIFIED | 202 exercises; all 7 muscle groups covered (30 each except Full Body at 22) |
| `src/domain/pr-detection/check-pr.ts` | VERIFIED | Exports `checkForPR`, `findClosestRepRange`; imports `estimated1RM` from `epley-formula` |
| `src/domain/workout-session/session-actions.ts` | VERIFIED | All 7 functions exported: `createSession`, `addExercise`, `removeExercise`, `addSet`, `removeSet`, `completeSet`, `reorderExercises` |

### Wave 2 — Repositories + History Domain (Plans 03-04)

| Artifact | Status | Details |
|----------|--------|---------|
| `src/repositories/ExerciseRepo.ts` | VERIFIED | `ExerciseRepository` interface + `getExerciseRepo(isGuest)` factory; imports `Exercise` from domain |
| `src/repositories/ExerciseMaxRepo.ts` | VERIFIED | `ExerciseMaxRepository` interface + `getExerciseMaxRepo(isGuest)` factory; imports `ExerciseMax` from `pr-detection` |
| `src/repositories/WorkoutRepo.ts` | VERIFIED | `WorkoutRecord` expanded with optional `exercises`, `workoutName`, `timerMode`, `totalVolume`, `exerciseCount` fields; `CompletedExercise`, `CompletedSet` exported |
| `src/domain/history/history-filter.ts` | VERIFIED | `filterHistoryBySource`, `groupHistoryByDate` exported; imports `HistoryItem` from `history-item` |
| `src/domain/history/history-item.ts` | VERIFIED | `HistoryItemSource` includes `{ kind: 'custom' }` alongside `aiWorkout` and `program` |
| `src/domain/progress/progress-data.ts` | VERIFIED | `prepare1RMChartData`, `prepareVolumeChartData`, `prepareRepRangePRs` exported; imports `ExerciseMax` from `pr-detection` |

### Wave 3 — Workout UI + Timer UI (Plans 05-06)

| Artifact | Status | Details |
|----------|--------|---------|
| `app/(app)/exercise-picker.tsx` | VERIFIED | 224 lines; loads bundled + custom exercises; passes to `ExerciseSearch` which calls `filterExercises` |
| `app/(app)/workout-session.tsx` | VERIFIED | 468 lines; uses `useWorkoutSession`, `useRestTimer`, `usePRDetection`; `DraggableFlatList` for reorder; `PRToast` + `RestTimerBar` rendered |
| `src/hooks/useWorkoutSession.ts` | VERIFIED | Imports from `session-actions.ts`; auto-saves to AsyncStorage; crash recovery on mount; `getPreviousValues` for ghost text |
| `src/hooks/useRestTimer.ts` | VERIFIED | Imports `expo-notifications`; `scheduleNotificationAsync` for background; AppState listener |
| `src/hooks/usePRDetection.ts` | VERIFIED | Loads `ExerciseMaxRepo`; `checkAndRecordPR` calls `checkForPR`; `recentPRs` queue for toast |
| `src/components/workout/RestTimerBar.tsx` | VERIFIED | File exists; rendered in `workout-session.tsx` |
| `src/components/workout/PRToast.tsx` | VERIFIED | File exists; rendered in `workout-session.tsx` with `currentPR` conditional |
| `src/components/workout/SetRow.tsx` | VERIFIED | File exists |
| `src/components/workout/ExerciseCard.tsx` | VERIFIED | File exists |
| `src/components/exercises/ExerciseSearch.tsx` | VERIFIED | Imports and calls `filterExercises`; inline custom creation form |
| `src/components/exercises/MuscleGroupGrid.tsx` | VERIFIED | File exists |
| `app/(app)/timer-mode.tsx` | VERIFIED | 534 lines; uses `useWorkoutTimer`; full-screen with `CountdownOverlay`, `TimerDisplay`, pause/stop |
| `src/hooks/useWorkoutTimer.ts` | VERIFIED | Imports from `timer-state.ts`; uses `scheduleNotificationAsync`; all 3 modes implemented |
| `src/components/timer/TimerDisplay.tsx` | VERIFIED | File exists |
| `src/components/timer/CountdownOverlay.tsx` | VERIFIED | File exists |
| `src/components/timer/EMOMClock.tsx` | VERIFIED | File exists |

### Wave 4 — History + Maxes Tabs (Plan 07)

| Artifact | Status | Details |
|----------|--------|---------|
| `app/(app)/(tabs)/history.tsx` | VERIFIED | 275 lines; calls `getWorkoutRepo`/`getHistory`; `SectionList` with `groupHistoryByDate`; `SourceFilter` + `HistoryCard`; swipe-to-delete |
| `app/(app)/(tabs)/maxes.tsx` | VERIFIED | 308 lines; calls `getExerciseMaxRepo`/`getAllMaxes`; search filter; navigates to `exercise-detail` |
| `app/(app)/workout-detail.tsx` | VERIFIED | 505 lines; full exercise + set detail with PR badges |
| `app/(app)/exercise-detail.tsx` | VERIFIED | 272 lines; uses `prepare1RMChartData`; `ProgressChart` and `RepRangePRTable` components |
| `src/components/charts/ProgressChart.tsx` | VERIFIED | Imports `LineChart` from `react-native-gifted-charts` |
| `src/components/charts/RepRangePRTable.tsx` | VERIFIED | File exists |
| `src/components/history/HistoryCard.tsx` | VERIFIED | Uses `Swipeable` from `react-native-gesture-handler` for swipe-to-delete |
| `src/components/history/SourceFilter.tsx` | VERIFIED | File exists |

### Wave 5 — Navigation Wire-Up (Plan 08)

| Artifact | Status | Details |
|----------|--------|---------|
| `app/(app)/(tabs)/_layout.tsx` | VERIFIED | `Tabs.Screen name="history"` and `Tabs.Screen name="maxes"` registered |
| `app/(app)/_layout.tsx` | VERIFIED | `Stack.Screen` for `workout-session`, `exercise-picker` (modal), `timer-mode`, `workout-detail`, `exercise-detail` all registered |
| `app/(app)/(tabs)/index.tsx` | VERIFIED | `router.push('/workout-session')` on "Start Workout" button; timed workout grid with `timerMode` param |
| `app/(app)/(tabs)/settings.tsx` | VERIFIED | "Rest Timer" section with `defaultRestDuration` picker (30–300 seconds) persisted to `SettingsRepo` |

---

## Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `exercise-filter.ts` | `exercise-types.ts` | `import type { Exercise, MuscleGroup }` | WIRED |
| `timer-state.ts` | `Date.now()` | timestamp math in `createTimerState`, `getElapsedMs` | WIRED |
| `check-pr.ts` | `epley-formula.ts` | `import { estimated1RM }` | WIRED |
| `ExerciseRepo.ts` | `domain/exercises/exercise-types.ts` | `import type { Exercise }` | WIRED |
| `ExerciseMaxRepo.ts` | `domain/pr-detection/pr-types.ts` | `import type { ExerciseMax }` | WIRED |
| `history-filter.ts` | `history-item.ts` | `import type { HistoryItem }` | WIRED |
| `progress-data.ts` | `pr-detection/pr-types.ts` | `import type { ExerciseMax, TrackedRepRange }` | WIRED |
| `workout-session.tsx` | `useWorkoutSession.ts` | `const { ... } = useWorkoutSession(isGuest)` | WIRED |
| `useWorkoutSession.ts` | `session-actions.ts` | `import { createSession, addExercise, ... }` | WIRED |
| `useRestTimer.ts` | `expo-notifications` | `scheduleNotificationAsync` | WIRED |
| `useWorkoutTimer.ts` | `timer-state.ts` | `import { createTimerState, getElapsedMs, ... }` | WIRED |
| `useWorkoutTimer.ts` | `expo-notifications` | `scheduleNotificationAsync` (EMOM per-minute) | WIRED |
| `timer-mode.tsx` | `useWorkoutTimer.ts` | `const timer = useWorkoutTimer()` | WIRED |
| `history.tsx` | `WorkoutRepo.ts` | `getWorkoutRepo(isGuest)` + `.getHistory(uid)` | WIRED |
| `maxes.tsx` | `ExerciseMaxRepo.ts` | `getExerciseMaxRepo(isGuest)` + `.getAllMaxes(uid)` | WIRED |
| `ProgressChart.tsx` | `react-native-gifted-charts` | `import { LineChart }` | WIRED |
| `tabs/_layout.tsx` | `history.tsx, maxes.tsx` | `Tabs.Screen name="history"` + `name="maxes"` | WIRED |
| `tabs/index.tsx` | `workout-session.tsx` | `router.push('/workout-session')` | WIRED |
| `app/_layout.tsx` | modal screens | `Stack.Screen presentation="modal"` for exercise-picker, timer-mode, etc. | WIRED |

---

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| WORK-01 | 04-02, 04-05, 04-08 | User can log sets with reps and weight for any exercise | SATISFIED | `workout-session.tsx` + `useWorkoutSession` + `session-actions.ts` |
| WORK-02 | 04-01, 04-05, 04-06, 04-08 | User can start rest timer between sets that works in background | SATISFIED | `useRestTimer.ts` with `expo-notifications`; `RestTimerBar` in workout-session |
| WORK-03 | 04-01, 04-05, 04-06, 04-08 | Rest timer survives screen lock and app backgrounding | SATISFIED | Timestamp-based `TimerState`; AppState listener; background notifications |
| WORK-04 | 04-01, 04-05, 04-08 | User can search and filter exercise library (200+ exercises) | SATISFIED | 202-entry `exercises.json`; `filterExercises` pure function; `ExerciseSearch` in picker |
| WORK-05 | 04-03, 04-05, 04-08 | User can create custom exercises | SATISFIED | `ExerciseSearch` inline creation form; `ExerciseRepo` persists `isCustom: true` |
| WORK-06 | 04-02, 04-05, 04-08 | App auto-detects personal records on set completion | SATISFIED | `checkForPR` in `check-pr.ts`; `usePRDetection` checks on `completeSet`; `PRToast` displayed |
| WORK-07 | 04-04, 04-07, 04-08 | User can view workout history in chronological order | SATISFIED | `history.tsx` with `groupHistoryByDate` date-grouped `SectionList` |
| WORK-08 | 04-04, 04-07, 04-08 | User can filter history by source (AI/Program/Custom) | SATISFIED | `SourceFilter` component; `filterHistoryBySource` with 'all'/'ai'/'program'/'custom' |
| WORK-09 | 04-03, 04-07, 04-08 | User can delete workouts from history | SATISFIED | `HistoryCard` `Swipeable` swipe-to-delete; calls `deleteWorkout` on WorkoutRepo |
| WORK-10 | 04-04, 04-07, 04-08 | User can view progress charts per exercise | SATISFIED | `exercise-detail.tsx` with `ProgressChart` (1RM over time) and `RepRangePRTable` |
| WORK-12 | 04-02, 04-05, 04-08 | User can build custom workout routines with drag-and-drop ordering | SATISFIED | `DraggableFlatList` in `workout-session.tsx`; `reorderExercises` called on `onDragEnd` |
| EXEC-01 | 04-01, 04-06, 04-08 | User can execute ForTime workouts with countdown timer | SATISFIED | `useWorkoutTimer.startForTime()`; `timer-mode.tsx` ForTime mode |
| EXEC-02 | 04-01, 04-06, 04-08 | User can execute AMRAP workouts with countdown timer | SATISFIED | `useWorkoutTimer.startAMRAP()`; `timer-mode.tsx` AMRAP mode with urgency styling |
| EXEC-03 | 04-01, 04-06, 04-08 | User can execute EMOM workouts with interval timer | SATISFIED | `useWorkoutTimer.startEMOM()`; per-minute `scheduleNotificationAsync`; `EMOMClock` |
| EXEC-04 | 04-01, 04-06, 04-08 | Timer state preserves through screen lock | SATISFIED | Timestamp-based `TimerState` in `useWorkoutTimer` with AppState listener |
| MAX-01 | 04-02, 04-03, 04-07, 04-08 | User can track one-rep max for any lift | SATISFIED | `ExerciseMaxRepo` persists `ExerciseMax` records; `maxes.tsx` shows per-exercise bests |
| MAX-02 | 04-04, 04-07, 04-08 | User can view 1RM history over time | SATISFIED | `exercise-detail.tsx` uses `prepare1RMChartData`; `ProgressChart` line chart |
| MAX-03 | 04-02, 04-08 | App estimates 1RM from logged sets using standard formulas | SATISFIED | `checkForPR` calls `estimated1RM(weight, reps)` from `epley-formula.ts` on set completion |

All 18 Phase 4 requirements are SATISFIED. No orphaned requirements found.

---

## Test Suite Results

| Suite | Tests | Status |
|-------|-------|--------|
| `exercises.test.ts` | 16 | Passed |
| `timers.test.ts` | 25 | Passed |
| `pr-detection.test.ts` | Part of 122 domain tests | Passed |
| `workout-session.test.ts` | Part of 122 domain tests | Passed |
| `history-filter.test.ts` | Part of 122 domain tests | Passed |
| `progress-data.test.ts` | Part of 122 domain tests | Passed |
| `useRestTimer.test.ts` | Part of 58 hook/repo tests | Passed |
| `useWorkoutTimer.test.ts` | Part of 58 hook/repo tests | Passed |
| `ExerciseRepo.test.ts` | Part of 58 hook/repo tests | Passed |
| `ExerciseMaxRepo.test.ts` | Part of 58 hook/repo tests | Passed |
| **Full suite (37 suites)** | **921 total** | **All passed** |

---

## Anti-Patterns Found

No blocker or warning-level anti-patterns found. The two `placeholder` strings found in `maxes.tsx` are React Native `TextInput` props (`placeholder="Search exercises..."`) — not stub implementations.

---

## Human Verification Required

### 1. Complete Workout Flow (End-to-End)

**Test:** `cd SundeeFundeeRN && npx expo start`, sign in, tap "Start Workout", add exercises via muscle group grid and search, enter weights/reps, tap checkmark to complete set, verify rest timer appears, tap Skip, tap Finish, verify workout appears in History tab as "Custom" source with correct exercise count.

**Expected:** Full workout loop executes without errors; History tab shows the workout with date group "Today" and "Custom" orange badge; workout detail shows all exercises and sets.

**Why human:** React Native gesture handling, navigation transitions, and data persistence flow require a running app to verify.

### 2. Rest Timer Background/Screen-Lock Persistence

**Test:** Complete a set to auto-start the rest timer, lock the device screen, wait until the timer would expire, unlock — verify timer shows correct remaining time and a notification fired.

**Expected:** Timer uses timestamp math (not interval) so it shows accurate remaining time after returning from locked screen; local notification fires at 0 seconds.

**Why human:** Screen lock behavior and iOS/Android notification delivery require a physical device or simulator with notification permissions granted.

### 3. ForTime / AMRAP / EMOM Timed Workout Modes

**Test:** From Dashboard, tap ForTime, AMRAP, and EMOM buttons. For each: verify 3-2-1-Go countdown plays with beep sounds, then timer starts. For AMRAP: verify red urgency styling at <30 seconds. For EMOM: background the app mid-workout, verify per-minute notification fires.

**Expected:** `CountdownOverlay` shows animated countdown with audio beeps (expo-av). Each mode shows correct timer behavior. EMOM schedules individual notifications per minute.

**Why human:** Audio playback, animations, and background notification delivery require device testing.

### 4. PR Detection Toast and Haptic Feedback

**Test:** Start a workout, log a set for any exercise with a higher weight than any previous record (or first workout — all are PRs). Verify orange PR toast appears at top of screen, PR badge appears inline on the set row, haptic feedback fires.

**Expected:** `PRToast` slides in from top with orange background; `SetRow` shows small "PR" badge; haptic plays via `expo-haptics`.

**Why human:** Visual animation rendering, inline badge display, and haptic feedback require device observation.

### 5. Exercise Detail 1RM Line Chart

**Test:** Complete at least 2 workouts logging the same exercise with different weights. Navigate to Maxes tab, tap the exercise. Verify 1RM line chart renders with an upward trend, and rep-range PR table shows 5 rows (1RM, 3RM, 5RM, 8RM, 10RM).

**Expected:** `ProgressChart` (react-native-gifted-charts `LineChart`) renders with orange line on cream background; `RepRangePRTable` shows "--" for rep ranges with no data and actual values for recorded rep ranges.

**Why human:** Chart rendering with real data, responsive layout, and visual correctness require a running app.

---

## Summary

Phase 4 automated verification passes completely. All 5 observable success criteria from the ROADMAP are supported by substantive, wired code. All 18 requirements (WORK-01 through WORK-12, EXEC-01 through EXEC-04, MAX-01 through MAX-03) have traceable implementation evidence. The full test suite of 921 tests passes across 37 suites.

The phase is gated on 5 items that require human verification on a running device: the end-to-end workout flow, background timer persistence, timed workout modes with audio/animations, PR toast and haptics, and chart rendering. These cannot be verified programmatically and should be tested before Phase 4 is marked complete.

---

_Verified: 2026-03-15T02:30:00Z_
_Verifier: Claude (gsd-verifier)_

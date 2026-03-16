---
phase: 04-core-workout-loop
plan: "06"
subsystem: ui
tags: [expo-notifications, expo-av, expo-keep-awake, react-native-reanimated, timer, emom, amrap, fortime]

# Dependency graph
requires:
  - phase: 04-01
    provides: timer-state.ts domain functions (createTimerState, getElapsedMs, getRemainingMs, pauseTimer, resumeTimer, isTimerComplete, getEMOMCurrentMinute)
  - phase: 04-03
    provides: workout session data shape and exercise list format

provides:
  - useWorkoutTimer hook supporting ForTime (stopwatch), AMRAP (countdown), EMOM (interval + per-minute notifications)
  - 3-2-1-Go countdown with expo-av beep sounds
  - TimerDisplay component (large MM:SS, urgency styling for AMRAP < 30s)
  - CountdownOverlay component (full-screen NAVY modal with spring animation)
  - EMOMClock component (circular progress, minute X of Y, pulse on boundary)
  - timer-mode.tsx full-screen Expo Router screen with pause/stop/completion flow

affects:
  - 04-07
  - 05-ai-workout-generation
  - workout session save flow

# Tech tracking
tech-stack:
  added:
    - expo-keep-awake ~55.0.4 (screen wake lock during timer)
  patterns:
    - Individual EMOM notifications (not repeating) — one scheduleNotificationAsync per minute mark
    - Timestamp-based timer state (no setInterval for time tracking, only for display ticks)
    - Pause = cancel notifications + record pausedAt; Resume = resumeTimer + reschedule remaining minutes
    - expo-av Sound.createAsync best-effort pattern (catch silences audio failures gracefully)

key-files:
  created:
    - SundeeFundeeRN/src/hooks/useWorkoutTimer.ts
    - SundeeFundeeRN/src/hooks/__tests__/useWorkoutTimer.test.ts
    - SundeeFundeeRN/src/components/timer/TimerDisplay.tsx
    - SundeeFundeeRN/src/components/timer/CountdownOverlay.tsx
    - SundeeFundeeRN/src/components/timer/EMOMClock.tsx
    - SundeeFundeeRN/app/(app)/timer-mode.tsx
    - SundeeFundeeRN/__mocks__/expo-notifications.ts
    - SundeeFundeeRN/__mocks__/expo-av.ts
    - SundeeFundeeRN/__mocks__/expo-keep-awake.ts
  modified:
    - SundeeFundeeRN/app/(app)/_layout.tsx (register timer-mode as fullScreenModal Stack.Screen)
    - SundeeFundeeRN/package.json (added expo-keep-awake)

key-decisions:
  - "expo-keep-awake activateKeepAwakeAsync called on timer-mode mount, deactivated on unmount — keeps screen awake during active timed workout"
  - "EMOM schedules N individual notifications (not repeating) — iOS minimum repeat interval is 60s which equals EMOM interval, using individual schedule per minute for reliability"
  - "forTime durationMs=0 sentinel preserved from domain layer — isTimerComplete always false for stopwatch mode, user stops manually"
  - "Audio sound loading is best-effort (try/catch silences failures) — timer functionality must not break if audio assets are missing"
  - "timer-mode registered as fullScreenModal in (app)/_layout.tsx — immersive headerShown:false experience"

patterns-established:
  - "Timer sound: Audio.Sound.createAsync + playAsync + unloadAsync pattern, always wrapped in try/catch"
  - "Notification scheduling: scheduleEMOMNotifications helper takes startedAt + totalMinutes + remainingStartMinute for clean reschedule on resume"
  - "Screen wake lock: activateKeepAwakeAsync on mount, deactivateKeepAwake in useEffect cleanup"

requirements-completed:
  - EXEC-01
  - EXEC-02
  - EXEC-03
  - EXEC-04
  - WORK-02
  - WORK-03

# Metrics
duration: 22min
completed: 2026-03-14
---

# Phase 4 Plan 06: Timed Workout Execution Summary

**ForTime/AMRAP/EMOM timer hook with per-minute EMOM notifications, 3-2-1-Go countdown overlay, and full-screen immersive timer mode screen with pause/resume/stop controls**

## Performance

- **Duration:** 22 min
- **Started:** 2026-03-15T00:40:00Z
- **Completed:** 2026-03-15T01:02:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- `useWorkoutTimer` hook implements all 3 timed modes using the timestamp-based `timer-state.ts` domain functions — timer persists through background via elapsed math on foreground return
- EMOM schedules N individual per-minute `expo-notifications` entries (not repeating) — pause cancels all, resume reschedules remaining minutes from current position
- Full-screen `timer-mode.tsx` screen with 3-2-1-Go overlay, AMRAP round counter, urgency styling at < 30s, completion results screen, and screen-awake enforcement

## Task Commits

Each task was committed atomically:

1. **Task 1: Create useWorkoutTimer hook with all 3 timed modes and notification scheduling** - `f9535d4` (feat)
2. **Task 2: Build timer UI components and full-screen timer mode screen** - `785810c` (feat)

**Plan metadata:** _(added in final commit)_

## Files Created/Modified
- `SundeeFundeeRN/src/hooks/useWorkoutTimer.ts` - Hook with ForTime/AMRAP/EMOM start methods, pause/resume/stop, 3-2-1-Go countdown, AppState foreground recalculation
- `SundeeFundeeRN/src/hooks/__tests__/useWorkoutTimer.test.ts` - 22 tests covering initialization, formatting, EMOM notification scheduling, pause/resume/stop
- `SundeeFundeeRN/src/components/timer/TimerDisplay.tsx` - Large centered MM:SS display with mode label; AMRAP turns ORANGE_DARK when urgent; EMOM shows minute number prominently
- `SundeeFundeeRN/src/components/timer/CountdownOverlay.tsx` - Full-screen NAVY modal with spring-animated 3-2-1-Go numbers, blocks interaction
- `SundeeFundeeRN/src/components/timer/EMOMClock.tsx` - Circular progress indicator with pulse animation on minute boundary and "Minute X of Y" label
- `SundeeFundeeRN/app/(app)/timer-mode.tsx` - Full-screen Expo Router screen (150+ lines), auto-starts on mount, AMRAP round counter, Pause/Resume overlay, Stop confirmation, completion results
- `SundeeFundeeRN/app/(app)/_layout.tsx` - Added timer-mode as fullScreenModal Stack.Screen
- `SundeeFundeeRN/__mocks__/expo-notifications.ts` - Jest mock for notification scheduling
- `SundeeFundeeRN/__mocks__/expo-av.ts` - Jest mock for audio playback
- `SundeeFundeeRN/__mocks__/expo-keep-awake.ts` - Jest mock for screen wake lock

## Decisions Made
- `expo-keep-awake` installed (was not in package.json) — `activateKeepAwakeAsync` on mount, `deactivateKeepAwake` in cleanup
- Individual EMOM notifications (not repeating) — iOS minimum repeat interval is exactly 60s which equals EMOM interval, individual scheduling per minute is more reliable and easier to cancel/reschedule on pause
- Audio Sound loading wrapped in try/catch throughout — audio assets may be missing in dev builds; timer must not crash
- `timer-mode` registered as `fullScreenModal` in the app Stack — immersive experience, no header chrome

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing expo-keep-awake dependency**
- **Found during:** Task 2 (timer-mode screen implementation)
- **Issue:** `expo-keep-awake` not in package.json; plan specified using it for screen wake lock
- **Fix:** Ran `npx expo install expo-keep-awake`; added Jest mock at `__mocks__/expo-keep-awake.ts`
- **Files modified:** package.json, package-lock.json, `__mocks__/expo-keep-awake.ts`
- **Verification:** Import resolves; 921 tests pass
- **Committed in:** `785810c` (Task 2 commit)

**2. [Rule 3 - Blocking] Created missing expo-notifications and expo-av Jest mocks**
- **Found during:** Task 1 (useWorkoutTimer tests)
- **Issue:** `expo-notifications` and `expo-av` had no `__mocks__/` stubs; tests would error on import
- **Fix:** Created `__mocks__/expo-notifications.ts` and `__mocks__/expo-av.ts` with full jest.fn() stubs
- **Files modified:** `__mocks__/expo-notifications.ts`, `__mocks__/expo-av.ts`
- **Verification:** All 22 hook tests pass; mock call assertions work correctly
- **Committed in:** `f9535d4` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking dependency/mock gaps)
**Impact on plan:** Both fixes required for correctness. No scope creep.

## Issues Encountered
None — plan executed as written after resolving the two blocking gaps.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Timer infrastructure complete: hook + UI components + full-screen screen all wired up
- `timer-mode.tsx` navigable via `router.push('/(app)/timer-mode', { params: { mode, durationSeconds, exerciseList } })`
- Sound assets (`beep.mp3`, `go.mp3`, `complete.mp3`) should be added to `src/assets/sounds/` before production — hook silently degrades without them
- EMOM notifications require `expo-notifications` permissions to be requested at workout start (plan 04-07 or earlier screens should prompt)

---
*Phase: 04-core-workout-loop*
*Completed: 2026-03-14*

## Self-Check: PASSED

All files verified present and commits confirmed:
- `SundeeFundeeRN/src/hooks/useWorkoutTimer.ts` — FOUND
- `SundeeFundeeRN/src/hooks/__tests__/useWorkoutTimer.test.ts` — FOUND
- `SundeeFundeeRN/src/components/timer/TimerDisplay.tsx` — FOUND
- `SundeeFundeeRN/src/components/timer/CountdownOverlay.tsx` — FOUND
- `SundeeFundeeRN/src/components/timer/EMOMClock.tsx` — FOUND
- `SundeeFundeeRN/app/(app)/timer-mode.tsx` — FOUND
- `.planning/phases/04-core-workout-loop/04-06-SUMMARY.md` — FOUND
- Commit `f9535d4` — FOUND
- Commit `785810c` — FOUND

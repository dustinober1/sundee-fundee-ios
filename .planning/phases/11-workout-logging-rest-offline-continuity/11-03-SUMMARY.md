---
phase: 11
plan: 03
subsystem: workout-ui
tags: [flutter, riverpod, rest-timer, vibration, bottom-sheet, background-handling]
one-liner: "Rest timer with timestamp-based background recalculation, modal sheet UI, and pill overlay in WorkoutScreen"

dependency-graph:
  requires:
    - "11-01: WorkoutRepository, SetData, vibration package in pubspec"
    - "11-02: WorkoutSessionProvider, WorkoutScreen, ExerciseAccordion"
  provides:
    - restTimerProvider (NotifierProvider with background lifecycle handling)
    - RestTimerState (immutable model with countdown + status)
    - RestTimerSheet (modal bottom sheet with countdown + controls)
    - WorkoutScreen rest timer integration (pill overlay + auto-start on set log)
  affects:
    - "11-04 (if exists): offline continuity — restTimerProvider persists across backgrounding"
    - "12+: any phase testing workout UX should validate rest timer flow"

tech-stack:
  added:
    - "vibration: ^2.0.0 (already in pubspec from 11-01)"
  patterns:
    - "NotifierProvider (Riverpod 3.x) for rest timer state"
    - "WidgetsBindingObserver for app lifecycle (background/foreground) handling"
    - "Timestamp-based elapsed time recalculation on foreground return"
    - "showModalBottomSheet with isDismissible: false for persistent timer UI"
    - "Stack + Positioned pill overlay for collapsed timer state"

key-files:
  created:
    - flutter_app/lib/shared/providers/rest_timer_provider.dart
    - flutter_app/lib/features/workout/rest_timer_sheet.dart
  modified:
    - flutter_app/lib/features/workout/workout_screen.dart

decisions:
  - id: background-timer-strategy
    choice: "Timestamp recalculation on foreground return (not status='paused' on background)"
    rationale: "_pauseTimerForBackground only cancels the Dart Timer without changing status; on foreground, elapsed = now - startedAt gives accurate remaining time regardless of how long app was backgrounded"
    alternatives: ["Store paused status on background (loses accuracy for long backgrounds)", "Use WorkManager/background isolate (over-engineered for rest timer)"]

  - id: auto-dismiss-delay
    choice: "1-second delay before Navigator.pop() on completion"
    rationale: "Gives user visual feedback ('Done!' state) before sheet closes; avoids jarring instant dismiss"
    alternatives: ["Instant dismiss", "Manual dismiss only"]

  - id: vibration-error-swallow
    choice: "Vibration errors are silently swallowed"
    rationale: "Web and simulator don't support vibration; crashing or warning on these platforms is worse than silent no-op"
    alternatives: ["Check platform before calling", "Log warning in debug mode"]

  - id: rest-duration-default
    choice: "3-minute (180s) default rest if program has no restMinutes"
    rationale: "Standard strength training rest recommendation; program JSON can override per exercise via restMinutes field"

metrics:
  duration: "19 minutes"
  completed: "2026-02-21"
  tasks-completed: 3
  tasks-total: 3
  commits: 3
---

# Phase 11 Plan 03: Rest Timer Provider + Sheet Summary

## What Was Built

Rest timer feature for workout logging: a Riverpod `NotifierProvider` managing countdown state with background accuracy, a modal bottom sheet UI with pause/resume/skip/cancel controls, and integration into `WorkoutScreen` that auto-starts the timer after each set.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create RestTimerState model and RestTimerProvider | 5227864 | rest_timer_provider.dart |
| 2 | Create RestTimerSheet modal bottom sheet | f2452b4 | rest_timer_sheet.dart |
| 3 | Integrate rest timer with WorkoutScreen | 2de2186 | workout_screen.dart |

## Architecture

```
WorkoutScreen (_handleLogSet)
  └── ref.read(restTimerProvider.notifier).startRest(duration, exerciseName)
  └── RestTimerSheet.show(context)          ← modal sheet
      └── ref.watch(restTimerProvider)      ← live countdown

restTimerProvider (NotifierProvider)
  └── RestTimerNotifier
      ├── _LifecycleObserver (WidgetsBindingObserver)
      │   ├── onPaused → _pauseTimerForBackground (cancel Timer, keep 'running' status)
      │   └── onResumed → _recalculateRemainingTime (elapsed = now - startedAt)
      ├── startRest / pause / resume / skip / cancel
      ├── addTime / subtractTime (+/-15s)
      └── _triggerVibration (Vibration.vibrate, errors swallowed)
```

## Key Behaviors

- **Background handling:** Timer pauses tick without changing `status`. On foreground return, elapsed time is recalculated from `startedAt` timestamp — accurate even after hours backgrounded.
- **Vibration:** Fires `Vibration.vibrate(duration: 500)` on completion. All exceptions swallowed (web/simulator safe).
- **Auto-dismiss:** Sheet pops after 1-second delay when `status == 'complete'`.
- **Pill overlay:** `Stack + Positioned` pill in `WorkoutScreen` shows collapsed timer when sheet is dismissed. Tap reopens sheet.
- **Test keys:** `rest-timer-sheet`, `rest-timer-display`, `rest-timer-progress`, `rest-timer-pause-resume-button`, `rest-timer-skip-button`, `rest-timer-cancel-button`, `rest-timer-add-button`, `rest-timer-subtract-button`, `rest-timer-pill`.

## Decisions Made

1. **Background timer strategy:** `_pauseTimerForBackground` cancels `Timer` without changing status to 'paused'. `_recalculateRemainingTime` uses `DateTime.now().difference(startedAt)` for accuracy — no manual offset tracking needed.

2. **Vibration error handling:** All `Vibration` calls wrapped in try/catch with empty catch. Web and simulator platforms throw; silently swallowing is correct behavior.

3. **3-minute default rest:** Used when `exercise.restMinutes` is null. Overridable per-exercise via program JSON `restMinutes` field.

4. **Auto-dismiss delay:** 1-second grace period on complete gives user a chance to see "Done!" before sheet auto-closes.

## Deviations from Plan

### Context-driven changes

**1. Plan 02 was partially complete when Plan 03 ran**

- **Found during:** Task 3 — checking workout_screen.dart
- **Situation:** Plan 02 had committed WorkoutSessionProvider and component widgets, and wrote the full WorkoutScreen (with `// Plan 03 will auto-start rest timer here` TODO). The file was already the full ConsumerStatefulWidget version, not the stub.
- **Action:** Integrated rest timer into Plan 02's existing WorkoutScreen (targeted edits: add import, update `_handleLogSet`, watch `restTimerProvider`, wrap body in Stack with pill).
- **Result:** Clean integration — no Plan 02 work overwritten.

## Next Phase Readiness

- ✅ Rest timer works standalone (startRest/pause/resume/skip)
- ✅ Background accuracy via timestamp recalculation
- ✅ WorkoutScreen auto-starts timer after each set log
- ✅ `flutter analyze` passes with no issues
- 📋 Phase 11 Plan 03 complete — Phase 11 is now fully executed (all 3 plans done)

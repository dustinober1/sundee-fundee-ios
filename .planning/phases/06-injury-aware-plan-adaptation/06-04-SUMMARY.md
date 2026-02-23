---
phase: 06
plan: 04
subsystem: workout-execution-ui
tags: [flutter, injury-aware, workout-execution, ui, recovery-prep, replacement-labels, revert-warning, mid-workout-prompt]
depends_on: ["06-02"]
provides: ["injury UI in workout execution screen"]
affects: []
tech-stack:
  added: []
  patterns:
    - "session-scoped state for injury UI overrides (recoveryPrepSkipped, revertedExercises)"
    - "callback-based revert propagation from ConsumerWidget to StatefulWidget state"
    - "injury vs cycle change detection in mid-workout update prompt"
key-files:
  created: []
  modified:
    - flutter_app/lib/features/workouts/presentation/workout_execution_screen.dart
decisions:
  - "Recovery prep skip is session-local only — no persistence, next session shows it again"
  - "Exercise revert is session-local only — Set<String> in state, no provider/Firestore writes"
  - "isInjuryRelated detection uses recoveryPrepExercises.length diff + injuryReplacedOriginal field diff"
  - "Exercises.nameById() used to resolve display names from injuryReplacedOriginal exercise IDs"
  - "No global injury adaptation disable toggle (per CONTEXT.md constraint)"
metrics:
  duration: "~8 minutes"
  completed: "2026-02-23"
---

# Phase 6 Plan 04: Workout Execution Injury UI Summary

**One-liner:** Recovery prep block (orange card, skip-with-warning), inline replacement labels (swap icon + reason + 'Use original instead'), contraindicated revert warning dialog, and injury-aware mid-workout update prompt wired into workout_execution_screen.dart.

## Objective

Add exercise-level injury UI to the workout execution screen: inline replacement labels, recovery prep block, override-to-contraindicated warning, and mid-workout injury context change prompt.

## What Was Built

### Task 1: Recovery prep block + inline replacement labels

**Recovery prep block:**
- Rendered above training exercises when `_session.recoveryPrepExercises.isNotEmpty && !_recoveryPrepSkipped`
- Orange/amber `Card` (`Colors.orange.shade50`) with `Icons.healing` header and "Recovery Prep" title
- "Skip" `TextButton` triggers `_confirmSkipRecoveryPrep()` → AlertDialog with "KEEP PREP" (ElevatedButton) / "SKIP THIS SESSION" (TextButton)
- On skip: sets `_recoveryPrepSkipped = true` (session-local `bool` in state, not persisted)
- Recovery exercise rows: exercise name, `{sets} × {reps}`, notes in grey italic — **no set-logging inputs**
- `Divider` separates recovery prep from training exercises

**Inline replacement labels on `_ExerciseCard`:**
- `revertedExercises: Set<String>` and `onRevertExercise: void Function(String)` added as required parameters
- When `injuryReplacedOriginal != null` and not reverted: shows `Icons.swap_horiz` + "Replaces {originalName}" in orange (13px, w500)
- `injuryReplacementReason` shown in grey italic below if non-null
- "Use original instead" `TextButton` (grey, compact) triggers revert warning dialog
- Reverted/contraindicated exercises show red banner: "⚠ Using contraindicated exercise — consult healthcare professional"
- Display name switches to `Exercises.nameById(injuryReplacedOriginal!)` when reverted

**Session signature update:**
- `_buildSessionSignature` now appends `exercise.injuryReplacedOriginal ?? ''` per exercise so injury-driven exercise swaps are detected as meaningful changes

### Task 2: Mid-workout injury change prompt + override revert warning

**Revert warning dialog:**
- Local async function `showRevertWarningDialog()` inside `_ExerciseCard.build` (avoids StatefulWidget conversion)
- `AlertDialog` with title "⚠ Warning: Contraindicated Exercise"
- Content: `'${originalName}' was replaced due to your active injury. Performing it may worsen... This app does not provide medical advice. Consult a healthcare professional...`
- "STAY SAFE" (primary color `TextButton`) dismisses; "REVERT ANYWAY" (red `TextButton`) calls `onRevertExercise(exercise.exercise)`
- Parent `_WorkoutExecutionScreenState` adds exerciseId to `_revertedExercises` and calls `setState`

**Mid-workout injury context change prompt:**
- `_isInjuryRelatedChange(previous, next)` helper: returns `true` if `recoveryPrepExercises.length` differs OR any exercise's `injuryReplacedOriginal` changed
- `_promptForPhaseUpdate` gains `bool isInjuryRelated = false` parameter (default preserves cycle-only behavior)
- Injury-related dialog: title "Injury Update Available", content about injury profile change, actions "KEEP CURRENT" / "APPLY SAFE"
- Non-injury dialog: existing copy "Cycle Update Available" with "DEFER" / "APPLY"
- Apply/defer logic unchanged — `_applyDeferredUpdate()` / `_hasDeferredUpdate = true`

## Verification

```
flutter analyze --no-pub
```
✅ No errors in modified file. Pre-existing `info`-level deprecation in `onboarding_profile_screen.dart` unrelated.

```
flutter test -r expanded
```
✅ All 137 tests passed.

## Decisions Made

| Decision | Rationale |
|---|---|
| Session-local recovery prep skip | Per plan spec: "local state only, does not persist" |
| Session-local exercise revert via `Set<String>` | Per plan spec: "LOCAL-ONLY override, does not affect provider or Firestore" |
| `isInjuryRelated` detection checks `recoveryPrepExercises.length` and `injuryReplacedOriginal` fields | Reliable, minimal surface area — injury changes always manifest in these two fields |
| `Exercises.nameById()` for `injuryReplacedOriginal` display | Field stores exercise ID; display name needs lookup |
| No global disable toggle | Enforced by CONTEXT.md: "No disable toggle while injury status is active" |

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

Phase 6 is now complete with all 4 plans executed (06-01 through 06-04). The injury-aware plan adaptation feature is fully implemented:

- **06-01**: `InjuryAdaptationEngine` domain logic
- **06-02**: Provider wiring (`injuryAdaptedActiveProgramProvider`, disclaimer persistence)
- **06-03**: `InjuryAdaptationBanner` widget + screen integration
- **06-04**: Workout execution screen injury UI (this plan)

No blockers for future phases.

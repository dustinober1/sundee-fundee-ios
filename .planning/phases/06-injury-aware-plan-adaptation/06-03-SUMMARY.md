---
phase: "06"
plan: "03"
subsystem: injury-ui
tags: [flutter, riverpod, widget, ui, injury, disclaimer, banner, safety]
requires: ["06-02"]
provides: ["InjuryAdaptationBanner widget", "injury disclaimer gate on programs/workout screens", "dashboard injury indicator"]
affects: ["06-04"]
tech-stack:
  added: []
  patterns: ["parent-managed visible/onToggleVisibility for collapsible widgets", "StatefulWidget disclaimer gate", "hard-gate content visibility behind acknowledgment"]
key-files:
  created:
    - flutter_app/lib/features/programs/presentation/widgets/injury_adaptation_banner.dart
  modified:
    - flutter_app/lib/features/programs/presentation/programs_screen.dart
    - flutter_app/lib/features/workouts/presentation/workout_landing_screen.dart
    - flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart
decisions:
  - "InjuryAdaptationBanner uses parent-managed visible/onToggleVisibility (matches CycleAdjustmentExplainer pattern)"
  - "DisclaimerGateCard handles its own loading state internally (_acknowledging bool)"
  - "Changelog building: deduplicated Set<String>; uses injuryReplacementReason for exercise reason text; recovery prep count uses max across sessions"
  - "programs_screen hard gate: shows italic grey text in place of week list until disclaimer acknowledged"
  - "workout_landing_screen hard gate: START SESSION button gets onPressed:null + white70 helper text"
  - "workout_landing_screen userId resolved from authSessionStreamProvider (EnrolledProgramModel has no userId field)"
  - "dashboard uses simple _InjuryActiveIndicator row with warning_amber_rounded icon — no full banner"
metrics:
  duration: "~6 minutes"
  completed: "2026-02-23"
---

# Phase 6 Plan 03: Injury Adaptation Banner Summary

**One-liner:** InjuryAdaptationBanner widget with 3-state disclaimer gate, collapsible changelog, and integration into programs, workout, and dashboard surfaces with hard content gates.

## What Was Built

### Task 1: InjuryAdaptationBanner Widget

Created `injury_adaptation_banner.dart` with three distinct visual states:

- **State A (disclaimer gate):** Orange card with `health_and_safety` icon, bold "Injury-Adapted Plan" title, full disclaimer text (including "not medical advice" + "consult healthcare professional"), and an "I UNDERSTAND" `ElevatedButton`. The button fires `onAcknowledgeDisclaimer` once per unacknowledged active injury. Internally manages `_acknowledging` loading state.
- **State B (acknowledged, expanded):** Compact card with injury count badge pill (orange border, `_InjuryCountBadge`), `swap_horiz`-icon changelog entries (max 4 + overflow counter), and persistent grey italic reminder text ("Not medical advice. Consult a healthcare professional.").
- **State C (acknowledged, collapsed):** `TextButton.icon` with `health_and_safety_outlined` + "Show injury adaptations" label.

Parent screen manages `visible` / `onToggleVisibility` state (same pattern as `CycleAdjustmentExplainer`). Widget does not own expanded/collapsed state.

### Task 2: Screen Integrations

**`programs_screen.dart`:**
- Added `bool? _injuryBannerVisibleOverride` state variable.
- Watches `injuryAdaptationContextProvider` and renders `InjuryAdaptationBanner` below `CycleAdjustmentExplainer` when `hasActiveInjuries`.
- **Hard gate:** When `hasActiveInjuries && !disclaimerAcknowledgedForAll`, week list is replaced with `"Acknowledge the injury disclaimer above to view your adapted plan."` (grey italic).
- `_buildAdaptationChangelog()` deduplicates replaced-exercise entries using a `Set<String>`; appends recovery prep entry with max exercise count.
- `onAcknowledgeDisclaimer` calls `profileRepositoryProvider.acknowledgeInjuryDisclaimer` per injury ID.

**`workout_landing_screen.dart`:**
- Converted from `ConsumerWidget` to `ConsumerStatefulWidget` (Rule 3 deviation — required for banner visibility state).
- Watches `injuryAdaptationContextProvider` and renders `InjuryAdaptationBanner` above the session card.
- **Hard gate:** `startBlocked = hasActiveInjuries && !disclaimerAcknowledgedForAll` → START SESSION button gets `onPressed: null` with greyed styling; helper text "Acknowledge the injury disclaimer to start your workout." shown in white70.
- `userId` resolved from `authSessionStreamProvider` (correct approach since `EnrolledProgramModel` has no `userId` field).

**`dashboard_screen.dart`:**
- Watches `injuryAdaptationContextProvider`.
- When `hasActiveInjuries`, renders `_InjuryActiveIndicator` chip below "Next Workout" header: orange `warning_amber_rounded` icon + "{N} active injur{y/ies} — plan adapted".
- Informational only — no navigation on tap.

## Verification Results

```
flutter analyze --no-pub: 1 issue (pre-existing info/deprecated_member_use in onboarding_profile_screen.dart — not in modified files)
flutter test -r expanded: 137 tests passed
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `workout_landing_screen.dart` required `ConsumerStatefulWidget` conversion**

- **Found during:** Task 2
- **Issue:** `WorkoutLandingScreen` was a `ConsumerWidget` but needed `_injuryBannerVisibleOverride` state to satisfy the visible/onToggleVisibility pattern.
- **Fix:** Converted to `ConsumerStatefulWidget` + `ConsumerState`. Moved `_buildNextSessionInfo` from instance method with `WidgetRef ref` param to state method using `this.ref`.
- **Files modified:** `workout_landing_screen.dart`
- **Commit:** 7294dbc

**2. [Rule 1 - Bug] `EnrolledProgramModel` has no `userId` field**

- **Found during:** Task 2 (workout_landing_screen acknowledgment callback)
- **Issue:** Initial code referenced `enrollment.userId` which doesn't exist — model only has `id` (enrollment doc ID).
- **Fix:** Resolved userId from `authSessionStreamProvider` directly in the method.
- **Files modified:** `workout_landing_screen.dart`
- **Commit:** 7294dbc

**3. [Rule 2 - Missing Critical] Missing type annotation on `_buildAdaptationChangelog` in workout_landing_screen**

- **Found during:** Task 2 flutter analyze run
- **Issue:** `strict_top_level_inference` lint flagged untyped `program` parameter.
- **Fix:** Changed to `ProgramV2?` typed parameter, added `import program_models.dart`.
- **Files modified:** `workout_landing_screen.dart`
- **Commit:** 7294dbc

## Next Phase Readiness

Phase 06-04 can proceed. The injury-UI layer is complete:
- Banner widget exports `InjuryAdaptationBanner` cleanly.
- `injuryAdaptationContextProvider` and `injuryAdaptedActiveProgramProvider` are wired everywhere.
- Disclaimer acknowledgment persists to Firestore via `acknowledgeInjuryDisclaimer`.
- Hard content gates are active on both plan-overview and workout-start surfaces.

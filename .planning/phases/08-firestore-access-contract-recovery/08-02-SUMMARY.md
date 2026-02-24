---
phase: 08
plan: 02
subsystem: recoverable-access-ux
tags: [flutter, riverpod, firestore, resilience, ui]
depends_on: ["08-01"]
provides:
  - lifecycle access-state model for valid-empty vs recoverable vs blocking failures
  - shared top-banner retry guidance for recoverable access issues
  - consistent retry/escalation UX across Home, Programs, and Workout tabs
affects:
  - lifecycle state handling and retry orchestration
  - tab-level access failure rendering
tech-stack:
  added: []
  patterns:
    - "stream-composed lifecycle state with bounded auto-retry"
    - "shared recoverable banner component reused across core surfaces"
    - "app-resume refresh hook via shell lifecycle observer"
key-files:
  created:
    - flutter_app/lib/features/shared/presentation/recoverable_access_banner.dart
    - flutter_app/test/features/dashboard/presentation/dashboard_screen_test.dart
    - .planning/phases/08-firestore-access-contract-recovery/08-02-SUMMARY.md
  modified:
    - flutter_app/lib/features/programs/providers/enrollment_lifecycle_provider.dart
    - flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart
    - flutter_app/lib/features/programs/presentation/programs_screen.dart
    - flutter_app/lib/features/workouts/presentation/workout_landing_screen.dart
    - flutter_app/lib/features/shell/presentation/main_shell_screen.dart
    - flutter_app/test/features/programs/presentation/programs_screen_test.dart
    - flutter_app/test/features/workouts/presentation/workout_landing_screen_test.dart
decisions:
  - "Lifecycle state now encodes `validEmpty`, `recoverableFailure`, and `blockingFailure` explicitly rather than surfacing raw AsyncError to UI"
  - "Recoverable read failures auto-retry up to 3 attempts before escalating to blocking retry-required state"
  - "App resume triggers a silent lifecycle refresh to revalidate access without tab navigation loss"
  - "Home/Programs/Workout preserve content skeleton/empty states while recoverable banner guidance is shown"
commits:
  - hash: 3eb405c
    message: "feat(08-02): add recoverable lifecycle access model"
  - hash: b134ed1
    message: "feat(08-02): apply recoverable access UX across core screens"
  - hash: 432f58b
    message: "test(08-02): cover recoverable access retry states"
metrics:
  completed: "2026-02-24"
---

# Phase 8 Plan 02 Summary

## Objective
Implement recoverable access UX for core training surfaces so backend read failures no longer render terminal broken-tab states.

## What Was Built

### Task 1: Lifecycle access-state classifier with bounded retry
- Reworked lifecycle provider to model:
  - `active`
  - `canceled`
  - `validEmpty`
  - `recoverableFailure`
  - `blockingFailure`
- Added recoverable Firestore/timeout error classification with bounded auto-retry (3 attempts).
- Added shared refresh hook (`refreshEnrollmentLifecycleAccess`) to support silent resume refresh and manual retry actions.
- Added reusable `RecoverableAccessBanner` component with retry guidance and explicit retry action.

### Task 2: Home/Programs/Workout recoverable UX integration
- Updated Dashboard, Programs, and Workout Landing surfaces to:
  - show recoverable top-banner guidance instead of raw exception text
  - preserve content/empty-state rendering while recoverable failures are retried
  - show blocking retry-required state after retry exhaustion
- Added shell-level app lifecycle observer to trigger silent access revalidation on app resume.
- Added valid-empty fallback copy for missing upcoming-session data where appropriate.

### Task 3: Widget regression coverage
- Added/expanded widget tests to verify:
  - recoverable banner rendering on Programs, Workout, and Dashboard
  - underlying content remains visible during recoverable failures
  - blocking states include manual retry affordance
  - raw terminal error strings are not rendered for these access paths.

## Verification
Executed successfully:
- `cd flutter_app && flutter test test/features/programs/presentation/programs_screen_test.dart test/features/workouts/presentation/workout_landing_screen_test.dart test/features/dashboard/presentation/dashboard_screen_test.dart -r expanded`

## Deviations
- None. Plan scope was implemented as specified.

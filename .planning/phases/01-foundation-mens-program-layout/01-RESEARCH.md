# Phase 01 Research - Foundation and Men's Program Layout

**Phase:** 01-foundation-mens-program-layout
**Date:** 2026-02-23
**Research Mode:** Fresh phase research (no existing phase RESEARCH.md)

## Objective

Research what is required to plan and execute Phase 01 so the team can:
- keep authentication and cycle tracking behavior stable,
- convert the men's program UX to week-by-week navigation,
- show cycle cues consistently (including sharkweek behavior), and
- validate Firestore reads/writes plus rule compatibility for baseline flows.

## Locked Context from 01-CONTEXT.md

### Decisions to honor
- Week cards must include: week title/number, completion status, workout count, intensity tag, and short note.
- Progress must use a percentage bar.
- Week completion is manual; sequence is recommended but users can jump weeks.
- Sharkweek cue appears only during menstrual phase and should be prominent on the cycle screen.
- If cycle data is missing/uncertain, use a neutral "cycle data unavailable" state.
- Program view also needs cycle cue context text.
- Firestore write failures should show a non-blocking inline banner.
- Relevant screens need persistent "last synced" visibility.
- Missing/legacy fields should not crash UI; show "incomplete data" notice instead.

### Claude discretion areas
- Exact visual placement and styling details.
- Final wording of user-facing copy.
- Concrete component structure for banners, timestamps, and metadata chips.

## Current Codebase Findings

### AUTH-01 status (mostly implemented, needs hardening + regression coverage)
- Routing already depends on `authSessionStreamProvider` and handles loading/unauthenticated/authenticated paths in `flutter_app/lib/app/router.dart`.
- Firebase session persistence is enabled in `flutter_app/lib/bootstrap.dart` (`persistenceEnabled: true`).
- Auth flows and profile watching are centralized in `flutter_app/lib/features/auth/data/auth_repository.dart`.
- Gaps:
  - No dedicated auth repository regression tests for session/guest edge behavior.
  - Limited evidence for restart-routing behavior beyond a shallow widget smoke test.

### CYCLE-01 status (implemented, needs confidence state UX)
- Cycle status calculations and recommendations are implemented via providers in `flutter_app/lib/features/cycle/providers.dart`.
- Cycle screen already renders a sharkweek image when phase is menstrual in `flutter_app/lib/features/cycle/presentation/cycle_tracking_screen.dart`.
- Gaps:
  - Missing explicit neutral "cycle data unavailable" state in program context.
  - Missing persistent sync timestamp pattern.
  - Missing explicit incomplete-data notice pattern for legacy/missing fields.
  - No dedicated widget tests for cycle cue visibility rules.

### PROG-01/PROG-02 status (core data exists, week UX not implemented)
- Program data model already has `weeks` and `sessions` in `flutter_app/lib/domain/models/program_models.dart`.
- Baseline 12-week data is present in `flutter_app/lib/features/programs/data/squad_squat_program.dart`.
- Existing `ProgramsScreen` currently renders program-level cards only; no week-by-week cards, no manual week completion controls.
- Workout progression auto-advances week/day in `flutter_app/lib/features/workouts/presentation/workout_execution_providers.dart`, which conflicts with manual week-complete decision.

### UI-01 status (partially implemented)
- Cycle screen has menstrual cue support.
- Program and dashboard views do not yet provide concise cycle cue context tied to current phase.

### Firestore reads/writes and rules
- Repositories target `users/{userId}/...` subcollections and top-level program collection usage in `ProgramRepository` (`collection('programs')`).
- Firestore rules currently define `programCatalog/{programId}` read-only, but not `programs/{programId}`.
- This path mismatch can force fallback behavior and undermines phase requirement to validate basic reads/writes against rules.

## Risks and Mitigations

1. **Rules/path mismatch creates false positives**
- Risk: App appears to work due to local fallback while Firestore integration is effectively blocked.
- Mitigation: Align rules and repository path strategy in early plan wave; add tests that assert expected collection behavior.

2. **Manual week completion conflicts with auto progression**
- Risk: UX promises manual completion but execution logic still auto-advances weeks.
- Mitigation: Introduce explicit enrollment progress semantics and tests before UI rollout.

3. **Confidence-state UI drift across screens**
- Risk: cycle/program/dashboard show inconsistent error/sync states.
- Mitigation: Define reusable display contract (error banner + last synced + incomplete data message) and verify via widget tests.

4. **Phase quality target requires more than happy-path tests**
- Risk: regressions ship because only smoke tests run.
- Mitigation: add focused regression tests for auth routing, week completion behavior, and cue visibility rules.

## Recommended Planning Split

### Wave 1 (parallel)
- **Plan 01:** Auth + Firestore baseline hardening and regression coverage.
- **Plan 02:** Enrollment/manual-week semantics and progression behavior updates.

### Wave 2
- **Plan 03 (depends on 02):** Programs and cycle UI implementation for week cards, cues, confidence states.

### Wave 3
- **Plan 04 (depends on 01,02,03):** Phase-level hardening suite and final verification commands.

This split keeps the highest-risk contracts (rules + progression semantics) ahead of UI polish, and preserves parallelizable work where file ownership allows it.

# Project State

## Reference
**Project**: Strength (Workout Tracker)
**Core Value**: Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current Focus**: Implementing v1 features (Recommendations, Charts, Sync).

## Current Position
**Phase**: 1. Smart Guidance (1 of 4) — **PHASE COMPLETE**
**Plan**: 01-03 complete (3 of 3 in phase)
**Status**: Phase complete — ready for Phase 02 (Visualization)
**Progress**: [███░░░░░░░] 25% (3/12 plans)

Last activity: 2026-02-18 - Completed 01-03-PLAN.md (Smart Guidance UI Integration — recommendations, PR celebration, plateau modal)

## Performance Metrics
- **Velocity**: In progress
- **Blockers**: None

## Context & Memory

### Decisions
- **Phasing**: Grouped remaining work into 4 functional phases: Guidance, Visualization, Sync, Testing.
- **Priority**: Recommendations first to enhance the daily workout experience immediately.
- **activeCycleId resolution**: In `onComplete` handler, resolves via `getActiveCycles()`; falls back to `generateId()` if no active cycle exists. Keeps persistence working without blocking on cycle setup.
- **exerciseId on ExerciseCardV2**: Made required (not optional) to keep data contract explicit and type-safe.
- **CollectedSetData**: Exported named type from `workout-session-view.tsx` for use across the workout completion flow.
- **No PR on first session**: Weight PR requires `currentMax > 0`; Volume PR requires prior session data — prevents noise when no baseline exists.
- **Session failure definition**: ANY set with `actualReps < prescribedReps` = failed session for plateau detection purposes.
- **Volume PR granularity**: Per single session volume (not cumulative) — avoids conflating volume growth with frequency increase.

- **Weight PR priority over volume PR**: When both are detected on the same set, weight PR celebration shown — single celebration is cleaner UX.
- **Override reason trigger**: `onBlur` not `onChange` — prevents dialog flickering while user is mid-type.
- **Plateau weight override**: Deload weight replaces recommendation entirely — user sees one number, not two conflicting values.
- **Per-exercise 1RM lookup**: Dynamic `find()` on `oneRepMaxes` array removes hardcoded `backSquat1RM` assumption.

### Todo
- [x] 01-01: Wire workout data persistence + DB schema v4 + Tooltip component
- [x] 01-02: Build recommendation engine, plateau detection, PR detection logic
- [x] 01-03: Integrate recommendation UI, PR celebrations, plateau modals into workout flow

### Session Continuity
- **Last session**: 2026-02-18
- **Stopped at**: Completed 01-03-PLAN.md (Phase 01 complete)
- **Resume file**: None — start Phase 02


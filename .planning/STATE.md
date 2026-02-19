# Project State

## Reference
**Project**: Strength (Workout Tracker)
**Core Value**: Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current Focus**: Implementing v1 features (Recommendations, Charts, Sync).

## Current Position
**Phase**: 2. Visual Progress (2 of 4) — **In progress**
**Plan**: 02-02 complete (2 of 3 in phase)
**Status**: In progress
**Progress**: [████░░░░░░] 33% (4/12 plans)

Last activity: 2026-02-19 - Completed 02-02-PLAN.md (Weekly Volume Chart + Workout Heatmap — CHART-02 + CHART-03)

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

- **named-export-activity-calendar**: `react-activity-calendar` v3 uses named export `{ ActivityCalendar }`, not default export. Plan specified default import (incorrect for v3).
- **Override reason trigger**: `onBlur` not `onChange` — prevents dialog flickering while user is mid-type.
- **Plateau weight override**: Deload weight replaces recommendation entirely — user sees one number, not two conflicting values.
- **Per-exercise 1RM lookup**: Dynamic `find()` on `oneRepMaxes` array removes hardcoded `backSquat1RM` assumption.

### Todo
- [x] 02-01: Build weight progress line chart (CHART-01) — weight-progress-chart.tsx
- [x] 02-02: Build weekly volume bar chart (CHART-02) + workout heatmap (CHART-03)
- [x] 01-02: Build recommendation engine, plateau detection, PR detection logic
- [x] 01-03: Integrate recommendation UI, PR celebrations, plateau modals into workout flow

### Session Continuity
- **Last session**: 2026-02-19
- **Stopped at**: Completed 02-02-PLAN.md (CHART-02 + CHART-03)
- **Resume file**: None — continue with 02-03


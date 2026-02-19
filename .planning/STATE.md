# Project State

## Reference
**Project**: Strength (Workout Tracker)
**Core Value**: Users can reliably track their strength training progress offline and receive actionable insights to improve performance.
**Current Focus**: Implementing v1 features (Recommendations, Charts, Sync).

## Current Position
**Phase**: 4. E2E Verification (4 of 4) — **Not started**
**Plan**: No plans created yet
**Status**: Phase 03 verified (15/15 must-haves) — Ready to plan Phase 04
**Progress**: [█████████░] 75% (9/12 plans complete)

Last activity: 2026-02-19 - Phase 03 Cloud Sync complete and verified

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
- **1RM auto-select via derived state**: `effectiveExerciseId = selectedId || exercises[0]?.id` avoids `setState` in `useEffect` (lint rule compliance).

- **CardDescription-available**: `CardDescription` was already exported from shadcn/ui card — no fallback needed in progress page.

- **singleton-supabase-client**: Module-level singleton for browser Supabase client to prevent multiple GoTrueClient instances.
- **localstorage-offline-queue**: localStorage for pending workout IDs — survives page refreshes, works without service worker.
- **bulkput-merge-strategy**: Dexie bulkPut (insert-or-replace) for pull — merges cloud without deleting local-only records.
- **duck-typing-date**: Duck-type guard (`'toISOString' in value`) instead of `instanceof Date` — TypeScript strict mode compatible.

- **null-supabase-client**: `createClient()` returns null when env vars not set — prevents @supabase/ssr throw during Next.js prerender; app works offline-only.
- **sync-configured-flag**: `isSyncConfigured = supabase !== null` gates all sync/auth ops in UserContext.
- **error-status-after-retry**: `setSyncStatus('error')` after withRetry exhaustion — distinguishes from pending (offline).

- **status-config-map**: SyncStatus config map provides icon/label/color per variant — avoids switch/case repetition in sync-status-popover.
- **use-client-dashboard**: Added 'use client' to dashboard/page.tsx for useUser hook access.
- **formatTimeAgo-inline**: formatTimeAgo implemented as pure function in sync-status-popover — no external dep needed.

### Todo
- [x] 02-01: Build weight progress line chart (CHART-01) — weight-progress-chart.tsx
- [x] 02-02: Build weekly volume bar chart (CHART-02) + workout heatmap (CHART-03)
- [x] 02-03: Integrate all three charts into /progress page
- [x] 01-02: Build recommendation engine, plateau detection, PR detection logic
- [x] 01-03: Integrate recommendation UI, PR celebrations, plateau modals into workout flow

- [x] 03-01: Build sync infrastructure — middleware, auth callback, sync engine, schema
- [x] 03-02: Auth UI + sync integration — AuthDialog, SyncNudge, UserContext auth state

- [x] 03-03: Dashboard sync UI — DashboardHeader, SyncStatusPopover, OfflineBanner, dashboard page update

### Session Continuity
- **Last session**: 2026-02-19
- **Stopped at**: Completed 03-03-PLAN.md (dashboard sync UI)
- **Resume file**: None (Phase 03 complete)

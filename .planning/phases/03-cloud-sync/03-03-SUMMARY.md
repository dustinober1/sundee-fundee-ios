---
phase: "03"
plan: "03"
subsystem: "dashboard-sync-ui"
tags: ["sync", "dashboard", "header", "popover", "offline", "react", "shadcn"]

dependency-graph:
  requires:
    - "03-01"  # sync infrastructure (syncStatus, pullFromCloud, UserContext)
    - "03-02"  # auth UI (AuthDialog, SyncNudge, useUser hook)
  provides:
    - "dashboard-header with sync status indicator"
    - "sync status popover with manual sync and time-ago display"
    - "offline banner that auto-hides when online"
    - "dashboard page with integrated sync nudge flow"
  affects:
    - "03-04 (testing) — all three new components need E2E coverage"

tech-stack:
  added: []
  patterns:
    - "formatTimeAgo utility for human-readable date deltas"
    - "getPendingCount reads localStorage sync_pending_workout_ids"
    - "Status config map (SyncStatus → icon + label + color)"
    - "'use client' on dashboard page to access useUser hook"

key-files:
  created:
    - "src/components/dashboard/sync-status-popover.tsx"
    - "src/components/dashboard/dashboard-header.tsx"
    - "src/components/dashboard/offline-banner.tsx"
  modified:
    - "src/app/dashboard/page.tsx"

decisions:
  - id: "status-config-map"
    description: "SyncStatus config object maps each status variant to its icon, label, and color — avoids switch/case repetition"
  - id: "localstorage-pending-count"
    description: "getPendingCount() reads sync_pending_workout_ids from localStorage to show accurate pending upload count without prop drilling"
  - id: "use-client-dashboard"
    description: "Added 'use client' to dashboard page.tsx — required since useUser hook uses React state/effects"
  - id: "formatTimeAgo-inline"
    description: "formatTimeAgo implemented locally in sync-status-popover.tsx — simple pure function with no dependency needed"

metrics:
  duration: "~8 minutes"
  completed: "2026-02-19"
  tasks-completed: 4
  tasks-total: 4
  deviations: 0
---

# Phase 03 Plan 03: Dashboard Sync UI Summary

**One-liner:** Dashboard header with sync status popover (formatTimeAgo, Sync now), offline banner, and SyncNudge integration replacing bare h1.

## What Was Built

Four components completing the dashboard sync UI layer:

1. **`sync-status-popover.tsx`** — Clickable sync status trigger button (icon + label) opening a popover showing: status header, last synced time via `formatTimeAgo()`, pending workout count from localStorage, offline message, and a "Sync now" button that calls `pullFromCloud()`.

2. **`dashboard-header.tsx`** — Top bar with `h1 Dashboard` heading, `SyncStatusPopover` on the right, and either a user avatar (with initials, hover popover showing name/email/sign out) or a Sign in button opening `AuthDialog`.

3. **`offline-banner.tsx`** — Renders `null` when online; when offline shows a yellow warning banner with wifi-off icon and "You're offline — data will sync when reconnected."

4. **`src/app/dashboard/page.tsx`** — Added `'use client'`, imports and renders `DashboardHeader`, `OfflineBanner`, and `SyncNudge` (gated by `!isAuthenticated`) while preserving all existing `ActiveCyclesCard` and `CycleWidget`.

## Verification Results

- `npm run build` ✅ — zero TypeScript errors, all 10 pages generated
- All three new component files present ✅
- `DashboardHeader` imported and rendered in dashboard page ✅
- `SyncNudge` (not `SyncNudgeCard`) used in dashboard page ✅
- "Sync now" text present in `sync-status-popover.tsx` ✅

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- **03-04 (Testing):** All three new components are client-side with hooks — E2E tests should cover: sync status indicator visibility, offline banner appearance, Sync now button interaction, sign in/sign out flows from header.

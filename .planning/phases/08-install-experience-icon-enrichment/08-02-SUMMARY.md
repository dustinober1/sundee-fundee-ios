---
phase: 08
plan: 02
subsystem: ui-icon-enrichment
tags: [lucide-react, icons, ux, dashboard, workout, bottom-navigation, pwa]
requires: [08-01]
provides: [ICON-01, ICON-02, ICON-03, ICON-04]
affects: []
tech-stack:
  added: []
  patterns: [lucide-named-import, icon-in-card-title, icon-in-button, semantic-tab-icon]
key-files:
  created: []
  modified:
    - src/components/dashboard/offline-banner.tsx
    - src/components/dashboard/active-cycles-card.tsx
    - src/components/dashboard/cycle-widget.tsx
    - src/components/program/exercise-card-v2.tsx
    - src/components/program/workout-session-view.tsx
    - src/components/layout/bottom-navigation.tsx
decisions:
  - id: d1
    summary: "Activity icon chosen over ClipboardPlus for Workout tab"
    rationale: "Activity (heartbeat/ECG line) is fitness-semantic and visually distinct from Dumbbell (Programs tab); ClipboardPlus was clipboard-oriented, not exercise-oriented"
  - id: d2
    summary: "AlarmClockCheck in session header, not session name wrapper element"
    rationale: "h1 wraps session name — icon placed inline in h1 via flex to keep header semantic and scannable"
  - id: d3
    summary: "Dumbbell icon uses text-muted-foreground, not text-primary"
    rationale: "Keeps exercise card header neutral; the exercise name itself is the primary focus"
metrics:
  duration: "~4 minutes"
  completed: "2026-02-20"
---

# Phase 8 Plan 02: Icon Enrichment Summary

**One-liner:** Six UI components enriched with 8 Lucide icons (WifiOff, Trophy, Flame, BarChart2, Dumbbell, Target, AlarmClockCheck, CircleCheck) plus Activity replacing ClipboardPlus in bottom nav (ICON-01–04).

## What Was Built

Consistent Lucide icon vocabulary applied across all major app surfaces:

- **OfflineBanner (ICON-01):** Inline `<svg>` wifi-off path fully replaced with `<WifiOff>` named import — single source of truth for icon, no raw SVG in components.
- **ActiveCyclesCard (ICON-02):** `<Trophy className="h-5 w-5 text-yellow-500" />` added to both card headers (empty-state and active-programs), giving users an immediate visual cue for the achievement context.
- **CycleWidget (ICON-02):** `<Flame className="h-5 w-5 text-orange-500" />` in both card headers (Cycle Tracking + Cycle Phase); `<BarChart2 className="h-4 w-4 text-muted-foreground" />` in "Today's Focus" heading for data-context signaling.
- **ExerciseCardV2 (ICON-03):** `<Dumbbell>` in card title (fitness identity), `<Target>` on prescribed weight/1RM line (training target context).
- **WorkoutSessionView (ICON-03):** `<AlarmClockCheck>` in session header h1 (session-in-progress indicator), `<CircleCheck>` inside "Complete Workout" button (completion action CTA).
- **BottomNavigation (ICON-04):** `ClipboardPlus` removed; `Activity` (heartbeat line) used for Workout tab — semantically fitness-oriented and visually distinct from Dumbbell (Programs tab).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | ICON-01 + ICON-02 — OfflineBanner WifiOff + dashboard card icons | 889683d | offline-banner.tsx, active-cycles-card.tsx, cycle-widget.tsx |
| 2 | ICON-03 + ICON-04 — workout page icons + bottom nav update | 50af431 | exercise-card-v2.tsx, workout-session-view.tsx, bottom-navigation.tsx |

## Verification Results

| Check | Result |
|-------|--------|
| `npx tsc --noEmit` | ✅ 0 errors |
| `npm run build` | ✅ Compiled successfully |
| `npx playwright test` | ✅ 11/11 passed |
| `grep -n "svg" offline-banner.tsx` | ✅ No results — inline SVG fully removed |
| `grep "ClipboardPlus" src/` | ✅ No results — fully removed |
| All 8 Lucide icons imported | ✅ WifiOff, Trophy, Flame, BarChart2, Dumbbell, Target, AlarmClockCheck, CircleCheck |
| `grep "Activity" bottom-navigation.tsx` | ✅ Import + navItems usage confirmed |

## Decisions Made

1. **`Activity` (not `Dumbbell` or another) for Workout tab** — The Workout tab is where the user actively performs a session, so the heartbeat/ECG `Activity` icon best represents live training. `Dumbbell` is already used for the Programs tab (browsing exercises/programs) so this differentiation is important.
2. **`AlarmClockCheck` placed inline inside `<h1>`** — The session header `<h1>` carries `flex items-center gap-2` to hold the icon without breaking heading semantics or requiring a wrapper `<div>`.
3. **Muted foreground for `Dumbbell` in exercise card** — Using `text-muted-foreground` keeps the icon subordinate to the exercise name (which is the primary label), matching established card title patterns in the app.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing TypeScript errors in RestTimer test mocks**

- **Found during:** Task 1 — `npx tsc --noEmit` returned 2 errors in test files
- **Issue:** `RestTimerExpanded.test.tsx` and `RestTimerPill.test.tsx` both initialized `mockContext.status` with `'running' as const`, which TypeScript narrowed to the literal type `'running'`. Subsequent test cases assigning `'paused'` or `'idle'` to the same field caused type errors.
- **Fix:** Changed `'running' as const` → `'running' as TimerStatus` (importing the `TimerStatus` union from `@/types/rest-timer`) in both test files, allowing all valid status values to be assigned.
- **Files modified:** `tests/unit/components/RestTimerExpanded.test.tsx`, `tests/unit/components/RestTimerPill.test.tsx`
- **Commit:** 889683d (included in Task 1 commit)

## Authentication Gates

None.

## Next Phase Readiness

- **Phase 8 complete** — INSTALL-01, INSTALL-02 (08-01) and ICON-01–ICON-04 (08-02) are all delivered. Milestone v1.1 icon enrichment target fully met.
- **Lighthouse PWA audit** — The app now has consistent icon usage across all major surfaces. A Lighthouse run should show ≥90 PWA score given Phase 7 SW + Phase 8 install experience.
- **No blockers.**

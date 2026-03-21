---
phase: 05-differentiating-features
plan: 02
subsystem: pwa-ux
tags: [skeleton-loading, shimmer, ux, loading-states]
dependency_graph:
  requires: []
  provides: [SkeletonCard component, shimmer loading states on all data routes]
  affects: [Dashboard, Programs, History, Cycle, Maxes]
tech_stack:
  added: []
  patterns: [shimmer CSS animation, CSS custom properties for theme tokens, TDD red-green]
key_files:
  created:
    - pwa/src/components/SkeletonCard.tsx
    - pwa/src/components/SkeletonCard.module.css
    - pwa/src/components/SkeletonCard.test.tsx
  modified:
    - pwa/src/routes/Dashboard.tsx
    - pwa/src/routes/Programs.tsx
    - pwa/src/routes/History.tsx
    - pwa/src/routes/Cycle.tsx
    - pwa/src/routes/Maxes.tsx
    - pwa/src/routes/Programs.module.css
    - pwa/src/routes/History.module.css
    - pwa/src/routes/Maxes.module.css
    - pwa/src/routes/Cycle.module.css
decisions:
  - Dashboard isLoading uses Promise.all([profileFetch, wodFetch]).finally() — single effect consolidates two fetches, skeleton visible until both complete
  - Cycle loading shows title + skeleton (not full early-return blank) — keeps page context visible during load
  - Removed .center/.spinner CSS from all 4 route module files — no longer referenced after spinner replacement
metrics:
  duration: 3min
  completed_date: "2026-03-21"
  tasks_completed: 2
  files_changed: 9
requirements: [UX-02]
---

# Phase 05 Plan 02: Skeleton Loading States Summary

**One-liner:** Shimmer SkeletonCard component with @keyframes animation wired into Dashboard, Programs, History, Cycle, and Maxes loading branches.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create SkeletonCard component with tests (TDD) | 0a692ea (RED), 7405033 (GREEN) | SkeletonCard.tsx, SkeletonCard.module.css, SkeletonCard.test.tsx |
| 2 | Wire SkeletonCard into all 5 data-fetching routes | d5697e8 | Dashboard.tsx, Programs.tsx, History.tsx, Cycle.tsx, Maxes.tsx + 4 CSS files |

## What Was Built

**SkeletonCard component** (`pwa/src/components/SkeletonCard.tsx`):
- Accepts `count` (default: 4) and `height` (default: 80px) props
- Renders `count` shimmer divs using `Array.from({ length: count })`
- Each div has `aria-hidden="true"` (decorative placeholder)
- CSS module uses `@keyframes shimmer` with `background-position` sweep

**CSS shimmer animation** (`pwa/src/components/SkeletonCard.module.css`):
- Uses `--color-grey-light` and `--color-cream-light` design tokens
- `background-size: 200% 100%` + `background-position` animation for sweep effect
- 1.4s `ease-in-out infinite` timing

**Route wiring:**
- Dashboard: consolidated two separate useEffects into one `Promise.all` + `isLoading` state; skeleton replaces quick-links grid and WOD card
- Programs: `isLoading ? <SkeletonCard count={4} height={72} />` replaces spinner div
- History: same pattern, count=4, height=72
- Cycle: early-return spinner replaced with page container + title + `<SkeletonCard count={3} height={100} />`
- Maxes: count=4, height=64 (compact row height)
- Removed `.center` and `.spinner` CSS classes from all 4 route module files

## Verification

- 797 vitest tests pass (22 test files)
- TypeScript compiles with zero errors (`npx tsc -b --noEmit`)
- SkeletonCard test suite: 5 tests covering default count, count=2, count=6, CSS class presence, height style

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `pwa/src/components/SkeletonCard.tsx` — FOUND
- `pwa/src/components/SkeletonCard.module.css` — FOUND
- `pwa/src/components/SkeletonCard.test.tsx` — FOUND
- Commits: 0a692ea, 7405033, d5697e8 — all verified in git log

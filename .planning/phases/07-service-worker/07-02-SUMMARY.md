---
phase: "07"
plan: "02"
name: "Service Worker Layout Wiring"
subsystem: "pwa"
tags: ["service-worker", "serwist", "offline", "layout", "react", "pwa"]
one-liner: "SerwistProvider in root layout with workout-safe controllerchange deferral and branded /offline fallback page"

dependency-graph:
  requires:
    - "07-01: @serwist/turbopack installed, SW served at /serwist/sw.js, 45 precache entries"
  provides:
    - "SW registered via SerwistProvider wrapping root body"
    - "Offline fallback page at /offline with local-first messaging"
    - "SerwistReloadHandler deferring SW updates during active workouts"
  affects:
    - "08-xx: Lighthouse PWA audit can now score against production build"
    - "All pages: SerwistProvider registers SW on every route"

tech-stack:
  added: []
  patterns:
    - "Client re-export pattern ('use client' wrapper for server-safe layout imports)"
    - "sessionStorage-persisted reload deferral for workout safety"
    - "SerwistProvider with reloadOnOnline=false (manual sync control)"

key-files:
  created:
    - "src/app/offline/page.tsx"
    - "src/app/serwist-client.ts"
    - "src/components/SerwistReloadHandler.tsx"
  modified:
    - "src/app/layout.tsx"

decisions:
  - id: "D-07-02-01"
    choice: "SerwistProvider placed outside Providers wrapper"
    rationale: "SW registration must happen regardless of app provider state; outer placement ensures earliest possible registration"
  - id: "D-07-02-02"
    choice: "reloadOnOnline={false} on SerwistProvider"
    rationale: "Prevents uncontrolled page reload on reconnect; app handles sync explicitly via offline queue"
  - id: "D-07-02-03"
    choice: "sessionStorage for pending reload flag"
    rationale: "Survives within-session navigation (e.g. exercise selection within workout) but clears on tab close; no stale-reload risk"
  - id: "D-07-02-04"
    choice: "'use client' on offline/page.tsx"
    rationale: "onClick handler on Try Again button requires client component; Next.js 16 prerender rejects server components with event handlers"

metrics:
  duration: "~8 minutes"
  completed: "2026-02-20"
  tasks-completed: 3
  tasks-total: 3
---

# Phase 7 Plan 02: Service Worker Layout Wiring Summary

## What Was Built

SerwistProvider wired into the root layout, a branded offline fallback page, and a workout-safe `controllerchange` reload handler — completing the service worker integration for the PWA foundation.

## Tasks Completed

| # | Name | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Create offline fallback page and client re-export | fc96341 | `src/app/offline/page.tsx`, `src/app/serwist-client.ts` |
| 2 | Create SerwistReloadHandler component | 7187239 | `src/components/SerwistReloadHandler.tsx` |
| 3 | Wire SerwistProvider and handler into layout | 1ed9bdf | `src/app/layout.tsx` |

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D-07-02-01 | SerwistProvider wraps outside `<Providers>` | Earliest SW registration, independent of app state |
| D-07-02-02 | `reloadOnOnline={false}` | Manual sync control; prevents uncontrolled reload on reconnect |
| D-07-02-03 | `sessionStorage` for pending reload flag | Survives intra-workout navigation, clears on tab close |
| D-07-02-04 | `"use client"` on offline page | onClick requires client component; Next.js 16 prerender blocks server-side event handlers |

## Verification Results

- **`npm run build`**: ✅ Compiled — 45 precache entries, 14 static routes, `/offline` included
- **`npm run test:e2e`**: ✅ 11/11 tests pass (SW blocked by `serviceWorkers: 'block'` in playwright.config.ts)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing `"use client"` on offline/page.tsx**

- **Found during:** Task 3 (build verification)
- **Issue:** `onClick` handler on "Try again" button caused Next.js prerender error: *"Event handlers cannot be passed to Client Component props"*
- **Fix:** Added `"use client"` directive to `src/app/offline/page.tsx`
- **Files modified:** `src/app/offline/page.tsx`
- **Commit:** 1ed9bdf (included in Task 3 commit)

## Next Phase Readiness

- **Phase 8 (Lighthouse audit):** Ready. SW registers at `/serwist/sw.js`, `/offline` is in precache, SerwistProvider active on all routes.
- **Blockers:** None. All must-haves satisfied.
- **Open items:** Lighthouse PWA audit score (≥90) to be verified in Phase 8 against production build.

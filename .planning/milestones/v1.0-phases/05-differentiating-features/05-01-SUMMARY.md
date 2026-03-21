---
phase: 05-differentiating-features
plan: 01
subsystem: ui
tags: [react-router, error-boundary, 404, vitest, css-modules]

# Dependency graph
requires:
  - phase: 04-pwa-quality
    provides: Expo Router + CSS Modules design system with Art Deco tokens in place
provides:
  - RootErrorBoundary component (full-page recovery, hard-reload anchor to /)
  - AppErrorBoundary component (in-app recovery, SPA Link to dashboard)
  - NotFound component (branded 404 page with Back to App link)
  - router.tsx wired with ErrorBoundary on root + AppLayout routes, path='*' catch-all outside AppLayout
affects: [05-differentiating-features, future-router-changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - useRouteError + isRouteErrorResponse pattern for React Router error boundaries
    - ErrorBoundary property on route objects (not class-based React error boundaries)
    - path='*' catch-all as sibling of AppLayout (not nested) so unauthenticated users see 404 not redirect

key-files:
  created:
    - pwa/src/routes/RootErrorBoundary.tsx
    - pwa/src/routes/RootErrorBoundary.module.css
    - pwa/src/routes/RootErrorBoundary.test.tsx
    - pwa/src/routes/AppErrorBoundary.tsx
    - pwa/src/routes/AppErrorBoundary.module.css
    - pwa/src/routes/AppErrorBoundary.test.tsx
    - pwa/src/routes/NotFound.tsx
    - pwa/src/routes/NotFound.module.css
    - pwa/src/routes/NotFound.test.tsx
  modified:
    - pwa/src/routes/router.tsx

key-decisions:
  - "RootErrorBoundary uses anchor tag (not Link) for Reload App — hard-reload bypasses broken SPA state"
  - "AppErrorBoundary uses Link (not anchor) — AppLayout shell may still be functional so SPA nav preferred"
  - "path='*' catch-all placed as sibling of AppLayout in router — unauthenticated users hit 404 not sign-in redirect"
  - "vi.mock('react-router', async (importOriginal) => ...) spread pattern for AppErrorBoundary tests — preserves MemoryRouter from actual module while mocking useRouteError/isRouteErrorResponse"

patterns-established:
  - "Error boundary components use getErrorMessage() helper to handle isRouteErrorResponse / Error / unknown union"
  - "CSS Modules for error/404 pages follow same Art Deco token system as rest of app"

requirements-completed: [UX-01, UX-03]

# Metrics
duration: 3min
completed: 2026-03-21
---

# Phase 5 Plan 01: Error Boundaries and 404 Page Summary

**React Router ErrorBoundary components (RootErrorBoundary, AppErrorBoundary) and branded NotFound page wired into router.tsx, replacing white screens and silent sign-in redirects with Art Deco recovery UI**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-21T21:55:10Z
- **Completed:** 2026-03-21T21:57:42Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- RootErrorBoundary renders full-page recovery UI with hard-reload anchor to "/" — JavaScript render errors no longer show white screen
- AppErrorBoundary renders in-app recovery card with SPA Link to Dashboard for errors within authenticated shell
- NotFound renders branded 404 page (orange "404" heading, "This page doesn't exist.", Back to App link)
- router.tsx wired: ErrorBoundary on root route, ErrorBoundary on AppLayout route, path='*' catch-all as sibling of AppLayout
- 13 vitest tests passing across all 3 components (TDD red → green cycle)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create error boundary components with tests** - `d56a039` (feat)
2. **Task 2: Create NotFound page and wire router** - `9bff623` (feat)

## Files Created/Modified
- `pwa/src/routes/RootErrorBoundary.tsx` - Full-page error recovery with anchor Reload App link
- `pwa/src/routes/RootErrorBoundary.module.css` - Art Deco card layout, orange button
- `pwa/src/routes/RootErrorBoundary.test.tsx` - 5 tests: heading, reload link, Error message, route response, unknown fallback
- `pwa/src/routes/AppErrorBoundary.tsx` - In-app error recovery with SPA Link to Dashboard
- `pwa/src/routes/AppErrorBoundary.module.css` - Matching Art Deco card layout
- `pwa/src/routes/AppErrorBoundary.test.tsx` - 5 tests: heading, dashboard link, Error message, route response, unknown fallback
- `pwa/src/routes/NotFound.tsx` - Branded 404 page, large orange "404", Back to App Link
- `pwa/src/routes/NotFound.module.css` - Centered layout, display-size 404 in accent color
- `pwa/src/routes/NotFound.test.tsx` - 3 tests: 404 heading, message text, home link href
- `pwa/src/routes/router.tsx` - Added ErrorBoundary imports, wired ErrorBoundary properties, added path='*' catch-all

## Decisions Made
- RootErrorBoundary uses `<a href="/">` (hard reload) not `<Link>` — necessary when the SPA state itself is broken
- AppErrorBoundary uses `<Link to="/">` — SPA navigation since AppLayout shell is likely still intact
- path='*' catch-all placed outside (as sibling of) AppLayout so unauthenticated users navigating to an unknown URL see a 404 page rather than being redirected to sign-in
- AppErrorBoundary test uses `vi.mock('react-router', async (importOriginal) => ...)` with spread to preserve MemoryRouter from actual module while mocking error hooks

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Error resilience foundation complete — white screens eliminated, 404 handled with branded UI
- Ready for Phase 05-02 and subsequent differentiating features plans

---
*Phase: 05-differentiating-features*
*Completed: 2026-03-21*

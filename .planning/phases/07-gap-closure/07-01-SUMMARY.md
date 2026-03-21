---
phase: 07-gap-closure
plan: 01
subsystem: infra
tags: [firebase, firestore, ci-cd, github-actions, react-router, tdd, vitest]

# Dependency graph
requires:
  - phase: 03-security-hardening
    provides: "firestore.rules file and firebase.json firestore block already wired"
  - phase: 05-differentiating-features
    provides: "Dashboard component and router.tsx with canonical route paths"
provides:
  - "Firestore security rules deployed to production on every CI/CD run"
  - "Dashboard Start Workout link navigates to /workout-session"
  - "Dashboard AI Workout card link navigates to /ai-workout/config"
  - "Regression tests preventing future route link regressions"
affects: [v1.0-milestone, sec-01, sec-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Firestore rules deploy step uses --only firestore:rules (not --only firestore) to avoid missing indexes.json error"
    - "TDD route regression tests use MemoryRouter for Link href resolution in vitest/jsdom"

key-files:
  created:
    - pwa/src/routes/Dashboard.test.tsx
  modified:
    - .github/workflows/deploy.yml
    - pwa/src/routes/Dashboard.tsx

key-decisions:
  - "Use --only firestore:rules not --only firestore — firestore.indexes.json does not exist; --only firestore would fail attempting indexes deploy"
  - "Deploy Firestore rules step placed after Cloud Functions step with identical SA_KEY credential pattern for consistency"
  - "Dashboard.test.tsx uses MemoryRouter (not createBrowserRouter) to resolve Link href attributes in jsdom environment"

patterns-established:
  - "Firestore rules step: write SA key to /tmp, set GOOGLE_APPLICATION_CREDENTIALS, deploy, rm key — same pattern as Cloud Functions"
  - "Dashboard async test uses screen.findByText (await) for content inside isLoading conditional, getByText (sync) for content outside"

requirements-completed: [SEC-01, SEC-02]

# Metrics
duration: 2min
completed: 2026-03-21
---

# Phase 7 Plan 1: Gap Closure — Firestore Rules Deploy + Dashboard Routes Summary

**Firestore security rules wired into CI/CD deploy pipeline and Dashboard route mismatches corrected with TDD regression coverage**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-21T23:21:33Z
- **Completed:** 2026-03-21T23:23:51Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added Deploy Firestore rules step to deploy.yml — SEC-01/SEC-02 rules now deploy to production on every production deploy, closing the Stripe paywall bypass gap
- Fixed Dashboard Start Workout link from /workout to /workout-session (matches router.tsx path)
- Fixed Dashboard AI Workout link from /ai-workout to /ai-workout/config (matches router.tsx path)
- Created Dashboard.test.tsx with 2 regression tests confirming route correctness — full pwa suite 813/813 passing

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Firestore rules deploy step to CI/CD pipeline** - `8583c84` (feat)
2. **Task 2 RED: Add failing Dashboard route regression tests** - `2823b2b` (test)
3. **Task 2 GREEN: Fix Dashboard Link paths to match router canonical routes** - `f7fc42c` (feat)

**Plan metadata:** (docs commit — see final commit hash)

_Note: TDD task has two commits (test RED then feat GREEN)_

## Files Created/Modified

- `.github/workflows/deploy.yml` — Added Deploy Firestore rules step + manual fallback comment
- `pwa/src/routes/Dashboard.tsx` — Fixed /workout -> /workout-session and /ai-workout -> /ai-workout/config
- `pwa/src/routes/Dashboard.test.tsx` — New file: 2 regression tests for route correctness

## Decisions Made

- Use `--only firestore:rules` not `--only firestore` — firestore.indexes.json does not exist in repo; `--only firestore` would attempt indexes deploy and fail
- Manual deploy fallback comment added at bottom of deploy.yml documenting full deployment procedure including Firestore rules
- MemoryRouter used in Dashboard test (not createBrowserRouter) to resolve Link href attributes cleanly in jsdom

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- SEC-01 and SEC-02 requirements now complete — Firestore rules protect premiumEntitlement from direct writes
- Dashboard navigation routes corrected — Start Workout and AI Workout primary user flows are functional
- v1.0 milestone gap closure complete for this plan
- All 813 pwa tests pass, no regressions introduced

---
*Phase: 07-gap-closure*
*Completed: 2026-03-21*

# Project State

## Current Position

Phase: 11 (ci-integration-lane-unblocking) — complete
Plan: 11-02 complete (phase done)
Status: Phase 11 fully executed — Linux desktop CI lane wired, flutter analyze clean
Last activity: 2026-02-25 - Executed 11-02-PLAN.md

Progress: Phase 11 ██ 2/2 plans complete (11-01 ✅, 11-02 ✅)

## Accumulated Context

- Milestone archives:
  - `.planning/milestones/v1-ROADMAP.md`
  - `.planning/milestones/v1-REQUIREMENTS.md`
  - `.planning/milestones/v1.1-ROADMAP.md`
  - `.planning/milestones/v1.1-REQUIREMENTS.md`
  - `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
- Milestone index:
  - `.planning/MILESTONES.md`

## Key Decisions (Recent)

| Decision | Choice | Source |
|---|---|---|
| Injury adaptation serialization boundary | Keep injury-only adaptation metadata out of persisted program JSON | 06-01 |
| Disclaimer acknowledgment persistence | Store per-injury acknowledgment map on user profile with merge writes | 06-02 |
| Cancellation UX safety | Two-step confirmation with immediate lifecycle transition and explicit replacement state | 07-02 |
| Re-enrollment guardrail | Heal duplicate-active state before restore/new re-enrollment commit | 07-03 |
| Workout history integrity | Persist `enrollmentId` on completed workouts and show canceled-plan markers | 07-03 |
| Enrollment access resiliency | Separate `validEmpty` vs `recoverableFailure` vs `blockingFailure` lifecycle states with bounded auto-retry | 08-02 |
| Workout write durability | Queue recoverable completion writes with sync-gated finalization and manual retry UX | 08-03 |
| Onboarding completeness authority | Route auth bootstrap through one evaluator contract and auto-heal stale onboardingComplete states | 09-01 |
| Legacy resume bypass notice | Emit one-time recovery notice only for max-only legacy recovery path | 09-02 |
| Restart reset contract | Clear onboarding fields and injury/disclaimer state together on restart | 09-03 |
| initializeHarness() guard strategy | Single combined early-return for `!_firebaseEnabled \|\| !_useEmulators` | 11-01 |
| Linux desktop CI target choice | xvfb-run Linux desktop (not web/chromedriver) | 11-02 |
| Firebase emulator removal from CI | Removed entirely — provider overrides + harness guard make emulators unnecessary | 11-02 |

## Open Follow-ups

- Capture manual checkpoint artifacts for run `run-20260225T205700Z` in `.planning/phases/10-verification-evidence-and-regression-guardrails/10-UAT.md`.
- ~~Re-run emulator-backed integration lane and confirm CI pass for `integration_test/critical_access_flow_test.dart`.~~ → **11-02** complete — Linux desktop CI lane wired.
- Observe first CI run on push to confirm xvfb-run + GTK build succeeds on ubuntu-latest runners.

## Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Fix Firestore insights permission and timeout errors | 2026-02-24 | f325ea8 | [001-fix-firestore-insights-permission-and-ti](./quick/001-fix-firestore-insights-permission-and-ti/) |

## Session Continuity

Last session: 2026-02-25T03:26:00Z
Stopped at: Completed 11-02-PLAN.md (Linux desktop platform + CI job rewrite)
Resume file: None

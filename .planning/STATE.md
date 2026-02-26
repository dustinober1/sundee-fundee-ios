# Project State

## Current Position

Phase: v1.2 archived
Milestone: v1.2 complete (2026-02-25) — archive: `.planning/milestones/v1.2-ROADMAP.md`
Status: No active phase. Start next milestone with `/gsd-new-milestone`
Last activity: 2026-02-26 - v1.2 milestone archived

## Accumulated Context

- Milestone archives:
  - `.planning/milestones/v1-ROADMAP.md`
  - `.planning/milestones/v1-REQUIREMENTS.md`
  - `.planning/milestones/v1.1-ROADMAP.md`
  - `.planning/milestones/v1.1-REQUIREMENTS.md`
  - `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
  - `.planning/milestones/v1.2-ROADMAP.md`
  - `.planning/milestones/v1.2-REQUIREMENTS.md`
  - `.planning/milestones/v1.2-MILESTONE-AUDIT.md`
- Milestone index:
  - `.planning/MILESTONES.md`

## Key Decisions (Stable)

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
| CI integration strategy | xvfb-run Linux desktop with provider overrides (no Firebase emulators in CI) | 11-02 |

## Open Follow-ups

- Observe first CI run on push to confirm `quality-integration` job passes with xvfb-run + GTK build on ubuntu-latest.
- Dashboard UX cleanup: `_WorkoutHistoryList` raw error text, `_BlockingAccessCard` double-render, no-op CTAs (carry to v1.3).

## Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Fix Firestore insights permission and timeout errors | 2026-02-24 | f325ea8 | [001-fix-firestore-insights-permission-and-ti](./quick/001-fix-firestore-insights-permission-and-ti/) |

## Session Continuity

Last session: 2026-02-26T00:00:00Z
Stopped at: v1.2 milestone archived
Resume file: None

# Phase 04 Research: Full-Suite Test Stabilization & Verification Hardening

Date: 2026-02-23
Phase: 04-full-suite-test-stabilization-verification-hardening

## Objective
Define a low-risk execution strategy to convert v1 verification from targeted-suite evidence to documented full-suite evidence without reopening completed feature scope.

## Inputs Reviewed
- `.planning/ROADMAP.md` (Phase 04 goal + success criteria)
- `.planning/v1-MILESTONE-AUDIT.md` (2 tech debt items, no blocker gaps)
- `.planning/phases/01-foundation-mens-program-layout/01-VERIFICATION.md`
- `.planning/phases/03-polish-future-prep/03-VERIFICATION.md`
- Prior plan patterns in Phase 01-03 `*-PLAN.md`

## Findings
1. There are no unsatisfied v1 requirements and no integration/flow blockers; remaining work is verification hardening.
2. Phase 01 verification explicitly notes historical unrelated full-suite failures; this is the main unresolved confidence debt.
3. Phase 03 added broad targeted verification and fixed at least one previously drifting test, suggesting remaining failures are likely concentrated in legacy or brittle test assumptions.
4. Fastest reliable closure path is to separate:
   - failure inventory and triage,
   - targeted stabilization/retirement decisions,
   - one final full-suite proof run with recorded evidence artifacts.

## Risks
- Running full-suite first without triage can create noisy loops and mask root causes.
- Fixing tests without a retirement policy can keep flaky/obsolete tests alive.
- A one-off green run is insufficient unless evidence is captured in durable planning artifacts.

## Recommended Execution Shape
- **Wave 1:** Baseline inventory and categorization of full-suite failures.
- **Wave 2:** Stabilize legitimate regressions, retire obsolete tests with rationale, and keep fixes behavior-safe.
- **Wave 3:** Perform clean `flutter analyze` + full `flutter test` run and publish verification evidence into phase and milestone artifacts.

## Verification Strategy
- Each plan should include an executable verify command.
- Final verification must run from `flutter_app` root and include complete suite, not targeted subsets.
- Phase close requires updating `04-VERIFICATION.md` and appending audit evidence references.

## Scope Guardrails
- No net-new product features.
- No redesign of test architecture unless required to remove flakiness.
- No changes that alter shipped user behavior beyond correcting regressions discovered by tests.

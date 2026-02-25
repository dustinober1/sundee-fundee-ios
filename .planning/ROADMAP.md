# Roadmap

## Milestones
- [x] **v1 Foundation Release** (shipped 2026-02-23) - 4 phases, 14 plans, audit passed. Archive: `.planning/milestones/v1-ROADMAP.md`
- [x] **v1.1 Onboarding Persistence + Injury-Aware Plans** (shipped 2026-02-24) - 3 phases, 10 plans, 11/11 requirements satisfied, audit status `tech_debt` (no blockers). Archive: `.planning/milestones/v1.1-ROADMAP.md`
- [ ] **v1.2 UAT Access + Onboarding Reliability** (in progress; phase 10 execution complete with human verification pending as of 2026-02-25) - 5 phases, 9 requirements.

## Current Milestone: v1.2 UAT Access + Onboarding Reliability

**Goal:** Resolve UAT-blocking Firestore access failures and onboarding resume false positives while preserving the reliability baseline shipped in v1/v1.1.

### Phase 8: Firestore Access Contract Recovery

**Goal:** Restore authenticated read/write access for core training surfaces by aligning Firestore rules and repository/query contracts.
**Requirements:** ACL-01, ACL-02, ACL-03, ACL-04, ACL-05
**Status:** ✅ Complete (verified 2026-02-24)
**Plans:** 3/3 complete

Plans:
- [x] 08-01-PLAN.md - Enrollment/rules/deploy contract recovery and legacy-safe normalization
- [x] 08-02-PLAN.md - Recoverable access lifecycle model and cross-surface retry UX
- [x] 08-03-PLAN.md - Workout write queue, replay, and sync-gated recovery flow

**Success criteria:**
1. Home loads "Next Workout" for authenticated users with active enrollment without permission-denied errors.
2. Programs and Workout tabs load enrollment/session-backed data for authenticated users without permission-denied errors.
3. Workout start and session progress writes succeed against Firestore in expected authenticated flows.
4. Genuine backend access failures render recoverable error UX (retry + guidance) instead of broken tab states.

### Phase 9: Onboarding Resume Eligibility Hardening

**Goal:** Eliminate false onboarding prompts for returning users while preserving resume for genuinely incomplete profiles.
**Requirements:** ONB-04, ONB-05
**Status:** ✅ Complete (verified 2026-02-25)
**Plans:** 3/3 complete

Plans:
- [x] 09-01-PLAN.md - Deterministic onboarding eligibility evaluation and bootstrap fallback handling
- [x] 09-02-PLAN.md - Recovery notice and injury-first resume/restart UX hardening
- [x] 09-03-PLAN.md - Regression guardrails for bootstrap matrix, restart resets, and recovery notice behavior

**Success criteria:**
1. Returning users with complete onboarding data bypass "Resume Onboarding" and land in product flows.
2. Users with missing required onboarding fields are correctly prompted to resume onboarding.
3. Existing user records with workout/max history are interpreted consistently by onboarding completeness checks.

### Phase 10: Verification Evidence and Regression Guardrails

**Goal:** Add durable automated and manual evidence proving repaired UAT flows stay stable.
**Supports:** QA-01, QA-02 (scaffold + guardrails; closure in phases 11-12)
**Status:** ⚠ Human verification needed (executed 2026-02-25)
**Plans:** 3/3 executed, manual checkpoint artifacts pending

Plans:
- [x] 10-01-PLAN.md - Emulator-backed integration guardrails and CI quality lane
- [x] 10-02-PLAN.md - UAT evidence scaffold, playbook, and run metadata/log structure
- [x] 10-03-PLAN.md - Verification artifact consolidation and milestone/state propagation

Verification artifact:
- `.planning/phases/10-verification-evidence-and-regression-guardrails/10-VERIFICATION.md` (`status: human_needed`)

**Success criteria:**
1. Automated tests cover authenticated data access/write paths for Home, Programs, and Workout critical flows.
2. UAT execution evidence is recorded for login -> dashboard -> programs -> workout start using the verification account path.
3. Milestone artifacts show resolved status for the reported `permission-denied` and onboarding false-prompt findings.

### Phase 11: CI Integration Lane Unblocking

**Goal:** Make the emulator-backed critical-access integration test runnable and passing in GitHub Actions.
**Requirements:** QA-01
**Status:** 🟡 Planned (gap closure)
**Plans:** 2 plans

Plans:
- [ ] 11-01-PLAN.md — Add Firebase emulator port configuration and harness no-op guard refactor
- [ ] 11-02-PLAN.md — Generate Linux desktop platform and rewrite CI quality-integration job

**Success criteria:**
1. `quality-integration` CI job runs `integration_test/critical_access_flow_test.dart` on Linux desktop via xvfb-run and passes.
2. Release build jobs are no longer blocked by `quality-integration`.

### Phase 12: UAT Evidence Capture Closeout

**Goal:** Capture and attach manual UAT checkpoint artifacts proving the repaired `login -> dashboard -> programs -> workout start` journey.
**Requirements:** QA-02
**Status:** 🟡 Planned (human-run evidence)
**Plans:** 0/1

Plans:
- [ ] 12-01-PLAN.md - Run UAT capture for `run-20260225T205700Z` (or a fresh run) and update Phase 10 verification artifacts

**Success criteria:**
1. Checkpoint artifacts attached in `.planning/phases/10-verification-evidence-and-regression-guardrails/10-UAT.md`.
2. Phase 10 verification updated from `human_needed` to `passed` once evidence is complete.

## Coverage Check
- Requirements mapped: 9/9
- Requirement overlap: none (each requirement mapped to exactly one phase)
- Starting phase number: 8 (continues from v1.1 phase 7)

## Next Command
`$gsd-plan-phase 11`

# Roadmap

## Milestones
- [x] **v1 Foundation Release** (shipped 2026-02-23) - 4 phases, 14 plans, audit passed. Archive: `.planning/milestones/v1-ROADMAP.md`
- [x] **v1.1 Onboarding Persistence + Injury-Aware Plans** (shipped 2026-02-24) - 3 phases, 10 plans, 11/11 requirements satisfied, audit status `tech_debt` (no blockers). Archive: `.planning/milestones/v1.1-ROADMAP.md`
- [ ] **v1.2 UAT Access + Onboarding Reliability** (in progress; phase 8 complete on 2026-02-24) - 3 phases, 9 requirements.

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

**Success criteria:**
1. Returning users with complete onboarding data bypass "Resume Onboarding" and land in product flows.
2. Users with missing required onboarding fields are correctly prompted to resume onboarding.
3. Existing user records with workout/max history are interpreted consistently by onboarding completeness checks.

### Phase 10: Verification Evidence and Regression Guardrails

**Goal:** Add durable automated and manual evidence proving repaired UAT flows stay stable.
**Requirements:** QA-01, QA-02

**Success criteria:**
1. Automated tests cover authenticated data access/write paths for Home, Programs, and Workout critical flows.
2. UAT execution evidence is recorded for login -> dashboard -> programs -> workout start using the verification account path.
3. Milestone artifacts show resolved status for the reported `permission-denied` and onboarding false-prompt findings.

## Coverage Check
- Requirements mapped: 9/9
- Requirement overlap: none (each requirement mapped to exactly one phase)
- Starting phase number: 8 (continues from v1.1 phase 7)

## Next Command
`$gsd-discuss-phase 9`

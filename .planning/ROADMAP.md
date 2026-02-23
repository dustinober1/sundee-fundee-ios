# Roadmap

## Milestones
- [x] **v1 Foundation Release** (shipped 2026-02-23) - 4 phases, 14 plans, audit passed. Archive: `.planning/milestones/v1-ROADMAP.md`
- [ ] **v1.1 Onboarding Persistence + Injury-Aware Plans** (planning)

## Current Milestone: v1.1 Onboarding Persistence + Injury-Aware Plans

**Goal:** Remove repeat onboarding friction while introducing injury-aware plan customization and safe plan cancellation.

**Phases:** 3 (Phase 5-7)  
**Requirements mapped:** 11/11 (100%)

| # | Phase | Goal | Requirements | Success Criteria |
|---|---|---|---|---|
| 5 | Profile Persistence Foundation | Persist onboarding/injury profile state reliably across sessions/devices | ONB-01, ONB-02, ONB-03, INJ-01, INJ-02 | 4 |
| 6 | Injury-Aware Plan Adaptation | Generate safer alternates/recovery additions and show legal disclaimer copy | INJ-03, INJ-04, INJ-05 | 4 |
| 7 | Enrollment Cancellation Lifecycle | Let users cancel enrolled plans safely while preserving history and re-enrollment | PLN-01, PLN-02, PLN-03 | 4 |

## Phase Details

### Phase 5: Profile Persistence Foundation (completed 2026-02-23)
Goal: Persist onboarding and injury profile data so users are not repeatedly prompted and settings are stable across devices.

Requirements: ONB-01, ONB-02, ONB-03, INJ-01, INJ-02

Success criteria:
1. Returning authenticated users with completed onboarding bypass onboarding by default.
2. Editing onboarding answers in profile persists and is reflected on next session bootstrap.
3. Injury context can be created, updated, and cleared without schema/regression errors.
4. Existing pre-v1.1 accounts with missing fields receive safe defaults and no crash paths.

Plans:
- [x] 05-01-PLAN.md - Canonical profile schema, repository normalization, and Firestore rules hardening
- [x] 05-02-PLAN.md - Bootstrap state machine, resume/restart onboarding flow, and injury-required routing gates
- [x] 05-03-PLAN.md - Settings profile edit surfaces, non-blocking save retry handling, and plan-refresh wiring

### Phase 6: Injury-Aware Plan Adaptation
Goal: Adapt generated plans when injuries are present using safe alternates/recovery additions with explicit legal disclaimers.

Requirements: INJ-03, INJ-04, INJ-05

Success criteria:
1. Contraindicated planned movements are replaced by deterministic pattern-equivalent alternatives.
2. Recovery-support additions appear when injury context is present and disappear when cleared.
3. Disclaimer text appears on all injury-guidance plan surfaces.
4. Adaptation behavior is covered by automated tests for at least representative injury scenarios.

### Phase 7: Enrollment Cancellation Lifecycle
Goal: Provide explicit cancel-plan flow that preserves history and supports future enrollment.

Requirements: PLN-01, PLN-02, PLN-03

Success criteria:
1. Users can cancel active enrollment from supported plan management surface.
2. Post-cancel state is visible and unambiguous in UI (inactive/canceled).
3. Historical completed workouts remain intact after cancellation.
4. Users can enroll in a new plan after cancellation with no conflicting active-state artifacts.

## Next Command
`$gsd-discuss-phase 6`

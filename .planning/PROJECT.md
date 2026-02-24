# Project: Sundee-Fundee

## What This Is
Sundee-Fundee is a cross-platform strength training tracker with cycle-aware and injury-aware programming support. It provides structured progression, adaptive safety-focused plan adjustments, and lifecycle-safe enrollment controls across core training surfaces.

## Core Value
Help users follow a structured strength plan with reliable progression and adaptation to their current context.

## Current State
- Latest shipped milestone: **v1.1** (2026-02-24)
- Milestone status: `tech_debt` (11/11 requirements satisfied; no blockers)
- Verification status: phase verification complete for Phases 05-07, audit coverage complete for requirements/integration/flows
- Open debt from audit:
  - Manual UAT scenarios documented in Phase 06 verification were not captured as executed evidence in the audit run.
  - One pre-existing analyzer info remains: `deprecated_member_use` in `onboarding_profile_screen.dart`.
- Core platform: Flutter + Riverpod + Firebase (Firestore/Auth)

## Current Milestone: v1.2 UAT Access + Onboarding Reliability

**Goal:** Restore core training flow access for authenticated users and remove false onboarding prompts for returning users.

**Target features:**
- Fix Firestore access paths and rules so Home "Next Workout", Programs, and Workout surfaces load reliably.
- Ensure workout start/session writes succeed for active enrollments without permission-denied failures.
- Show onboarding resume only for truly incomplete profiles; route complete users directly to product flows.
- Capture repeatable verification evidence for the repaired dashboard/program/workout journey.

## Active Requirements Focus
- Firestore permission hardening for enrollment/program/workout data paths.
- Onboarding completion-state gating for returning users.
- Regression and UAT evidence for authentication, dashboard, programs, and workout startup flows.

## Key Decisions
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Brownfield initialization | Existing app had production-relevant behavior | Enabled rapid verification-first delivery |
| Cycle-aware programming policy layer | Needed deterministic adaptation by phase/confidence | Delivered stable adaptation runtime with tests |
| Injury adaptation metadata stays view-layer only | Keep persisted program schema stable and backward compatible | Engine/UI can annotate adapted exercises without Firestore schema churn |
| Enrollment lifecycle moved to explicit status + event model | Needed deterministic cancel/re-enroll semantics and history integrity | Lifecycle-safe cancellation/re-enrollment shipped with atomic event writes |

## Constraints
- Flutter/Dart stack and Firebase backend remain foundational.
- Guest mode must remain supported when Firebase is unavailable.
- Milestone changes should keep deterministic verification evidence.

<details>
<summary>Milestone Snapshots (Archived)</summary>

- v1 requirements archive: `.planning/milestones/v1-REQUIREMENTS.md`
- v1 roadmap archive: `.planning/milestones/v1-ROADMAP.md`
- v1.1 requirements archive: `.planning/milestones/v1.1-REQUIREMENTS.md`
- v1.1 roadmap archive: `.planning/milestones/v1.1-ROADMAP.md`
- v1.1 audit archive: `.planning/milestones/v1.1-MILESTONE-AUDIT.md`

</details>

---
*Last updated: 2026-02-24 for milestone v1.2 initialization*

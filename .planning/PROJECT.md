# Project: Sundee-Fundee

## What This Is
Sundee-Fundee is a cross-platform strength training tracker with cycle-aware and injury-aware programming support. It provides structured progression, adaptive safety-focused plan adjustments, and lifecycle-safe enrollment controls across core training surfaces.

## Core Value
Help users follow a structured strength plan with reliable progression and adaptation to their current context.

## Current State
- Latest shipped milestone: **v1.2** (2026-02-25)
- Milestone status: `complete` — all 5 phases (8-12) executed and verified
- Verification status: phases 8-10, 12 fully passed; phase 11 wired (CI run confirmation pending)
- Open debt:
  - QA-01: `quality-integration` CI lane wired by Phase 11; first live GitHub Actions run not yet confirmed.
  - Dashboard UX: `_WorkoutHistoryList` surfaces raw error text; `_BlockingAccessCard` double-renders; BROWSE PLANS / REFRESH CTAs are no-ops.
  - One pre-existing analyzer info remains: `deprecated_member_use` in `onboarding_profile_screen.dart`.
- Core platform: Flutter + Riverpod + Firebase (Firestore/Auth)

## Current Milestone

No active milestone — v1.2 shipped. Start the next with `/gsd-new-milestone`.

<details>
<summary>v1.2 Milestone (Archived)</summary>

**Goal:** Restore core training flow access for authenticated users and remove false onboarding prompts for returning users.

**Delivered:**
- Fixed Firestore access paths and rules so Home "Next Workout", Programs, and Workout surfaces load reliably.
- Workout start/session writes succeed for active enrollments without permission-denied failures.
- Onboarding resume only for truly incomplete profiles; complete users route directly to product flows.
- Automated test evidence for the repaired dashboard/program/workout journey (critical_access_flow_test.dart).
- GitHub Actions CI integration lane wired with Linux desktop + xvfb-run.

**Archive:** `.planning/milestones/v1.2-ROADMAP.md`

</details>

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
- v1.2 requirements archive: `.planning/milestones/v1.2-REQUIREMENTS.md`
- v1.2 roadmap archive: `.planning/milestones/v1.2-ROADMAP.md`
- v1.2 audit archive: `.planning/milestones/v1.2-MILESTONE-AUDIT.md`

</details>

---
*Last updated: 2026-02-26 — v1.2 milestone archived*

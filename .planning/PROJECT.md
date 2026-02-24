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

## Next Milestone Goals
- Clear outstanding non-blocking debt from v1.1 audit evidence.
- Define next product slice (from deferred items: OAuth/social sign-in, user-authored templates, social/community).
- Preserve v1/v1.1 reliability baseline while expanding capability.

## Active Requirements Focus
- Pending next milestone definition (`$gsd-new-milestone`).

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
*Last updated: 2026-02-24 after v1.1 milestone completion*

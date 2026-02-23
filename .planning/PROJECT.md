# Project: Sundee-Fundee

## What This Is
Sundee-Fundee is a cross-platform strength training tracker with cycle-aware programming support. It ships week-by-week progression controls, adaptive prescription logic for female cycle phases, and confidence-oriented sync UX across primary surfaces.

## Core Value
Help users follow a structured strength plan with reliable progression and cycle-informed adaptation.

## Current State
- Latest shipped milestone: **v1** (2026-02-23)
- Milestone status: passed (`.planning/v1-MILESTONE-AUDIT.md`)
- Verification status: clean `flutter analyze` + full `flutter test`
- Core platform: Flutter + Riverpod + Firebase (Firestore/Auth)

## Next Milestone Goals
- Define v2 product goals and requirement set.
- Decide priority among deferred items (OAuth, custom programs, social sharing).
- Preserve v1 reliability baseline while expanding feature scope.

## Key Decisions
| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Brownfield initialization | Existing app had production-relevant behavior | Enabled rapid verification-first delivery |
| Cycle-aware programming policy layer | Needed deterministic adaptation by phase/confidence | Delivered stable adaptation runtime with tests |
| Full-suite hardening phase | Milestone confidence required clean global verification | Closed legacy test drift and achieved clean suite |

## Constraints
- Flutter/Dart stack and Firebase backend remain foundational.
- Guest mode must remain supported when Firebase is unavailable.
- Milestone changes should keep deterministic verification evidence.

<details>
<summary>v1 Planning Snapshot (Archived)</summary>

- Requirements archive: `.planning/milestones/v1-REQUIREMENTS.md`
- Roadmap archive: `.planning/milestones/v1-ROADMAP.md`

</details>

---
*Last updated: 2026-02-23 after v1 milestone completion*

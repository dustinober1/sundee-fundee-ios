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

## Current Milestone: v1.1 Onboarding Persistence + Injury-Aware Plans

**Goal:** Remove repeat onboarding friction while introducing injury-aware plan customization and safe plan cancellation.

**Target features:**
- Save onboarding profile inputs and stop re-prompting on each login.
- Adjust generated plans when users report current injuries, including safer alternates and recovery-support additions.
- Add legal disclaimer copy clarifying the app is not medical advice or physical therapy.
- Let users cancel an enrolled plan without breaking progression history.

## Active Requirements Focus
- Persist onboarding completion state per user account and honor it on future sessions.
- Collect and store injury context that can influence workout generation rules.
- Provide explicit cancel-plan controls and data/state transitions for enrolled plans.
- Preserve v1 reliability baseline while expanding scope.

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
*Last updated: 2026-02-23 for v1.1 milestone initialization*

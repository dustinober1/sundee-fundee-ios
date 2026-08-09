# Coach Report and Return-to-Training Program Implementation Plan

**Date:** 2026-08-08
**Status:** Proposed
**Target:** Next release. Both features ship free — no paywall, no gating. This app is a hobby project, not a revenue product, so scope is deliberately kept small enough for one person to actually finish.

## Context

Two feature ideas came out of competitive research against Wild.AI, FitrWoman, and Flo, and both turned out to line up unusually well with work that already exists in this codebase rather than requiring anything new architecturally:

- **Coach-Shareable Training Report.** None of the three competitors researched offer anything like this — Wild.AI and FitrWoman keep their intelligence locked inside in-app charts, and Flo doesn't address strength training at all. `DataExportService` already assembles every relevant record in one call, and `CycleAwareProgressInsightService`, `MonthlyReviewService`, and `SymptomTrainingTrendService` already compute the analysis a report needs to narrate. This is a presentation problem, not an analysis problem.
- **Return-to-Training Program.** The original pain-point research flagged "exercise safety assurance" as the single biggest thing generic programs fail to give people returning after a break (postpartum research specifically, but it generalizes). `ReturnToLiftingRampService` and `InjuryAdaptationEngine` already implement graduated, reasoned load ramping for injury returns — this generalizes an existing, tested mechanism rather than inventing new physiology logic.

Two features NOT chosen here, and why: deeper Oura/Whoop integration is real value but depends on external developer-API approval timelines outside our control, so it doesn't belong in a single release. A perimenopause-specific cycle mode is also promising but, like Training Intelligence 2.0, probably deserves its own design spec rather than being squeezed into this one — the physiological claims need more care than a patch release should carry.

## Global Constraints

- Both features ship free. No StoreKit entitlement checks, no new IAP products.
- Every new DomainLayer type is a pure, `Sendable` value type with no I/O, consistent with the rest of the codebase (see `ReadinessAssessmentService`, `CycleAwareProgressInsightService` for the existing pattern). I/O stays in DataLayer / dedicated service structs.
- Reuse existing data and existing insight services wherever possible. Neither feature should duplicate a calculation that `CycleAwareProgressInsightService`, `MonthlyReviewService`, `SymptomTrainingTrendService`, or `ReturnToLiftingRampService` already performs.
- Sensitive data (pain locations, injuries, cycle dates) defaults to the same privacy posture the rest of the app already uses: nothing leaves the device automatically, nothing is included in a shared artifact without an explicit, per-action user choice.
- Every adaptation or recommendation surfaced to the user gets a structured, human-readable reason — this app's whole differentiation against Wild.AI's opaque readiness score is that nothing here is a black box. Don't regress that.
- New CloudKit record types (if any) go through the same schema-definition guard pattern already used for `DailyReadinessRecord` / `TodayWorkoutPreference` — add schema, don't mutate existing record shapes.
- Full `swift test` suite plus focused tests for anything new, matching the existing bar (149 test files against 411 source files today — keep that ratio, don't ship either feature without tests).

## What Already Exists (build on this, don't rebuild it)

- `DomainLayer/Export/DataExportService.swift` — `exportAll()` already fetches Workouts, OneRepMaxRecords, CompletedWorkoutRecords, CyclePhaseInfo, BenchmarkResults, Injuries, DailyPainLog, CelebrationEventRecords, EnrolledProgramRecords, WeeklyTrainingPlans, EquipmentProfiles, WorkoutEffortLogs, WorkoutAdaptationDecisionRecords, SymptomCheckInRecords, ReturnToLiftingRampRecords, and BuddyCheckInRecords in parallel, tolerating partial failures.
- `DomainLayer/Analytics/CycleAwareProgressInsightService.swift`, `SymptomTrainingTrendService.swift`, `MonthlyReviewService.swift`, `ProgressSnapshotService.swift` — the analytical content a report needs to narrate already exists.
- `DomainLayer/Injury/ReturnToLiftingRampService.swift`, `ReturnToLiftingRampRecord.swift`, `InjuryAdaptationEngine.swift` — graduated load-percentage ramping with structured `reason: String` output, currently triggered from the injury flow only.
- `DomainLayer/Program/ProgramTemplateGenerator.swift`, `ProgramRecommendationService.swift`, `ProgramSessionAdaptationService.swift` — the existing program engine for generating and adapting multi-week structured programs.
- `UI/Views/Export/ExportView.swift` — the natural integration point for the report feature's entry point.

---

## Feature 1: Coach-Shareable Training Report

### Goal

A polished, plain-language summary a user can hand to a physical therapist, doctor, or trainer — or just keep for themselves — instead of raw exported JSON. Turns intelligence that's currently locked inside in-app charts into something portable.

### Scope for this release

One report type: a "Training Summary" over a selectable window (last 30 / 90 / 365 days), not a configurable report builder. Sections: session overview (count, adherence, volume trend), a plain-language cycle-aware pattern summary (narrating `CycleAwareProgressInsightService` output rather than reproducing its charts), and a pain/injury timeline (from `DailyPainLog`, `Injury`, and `ReturnToLiftingRampRecord`) — this last section is the one most directly useful to a clinician. Output is a PDF generated on-device, shared via the system share sheet.

### Explicitly deferred

Emailing directly from the app (share sheet only — far less surface to build and maintain), multiple configurable report types, saved/versioned report history, any server-side rendering.

### Task 1 — `TrainingReportContent` value type and `TrainingReportBuilder`

New file: `DomainLayer/Reporting/TrainingReportContent.swift` — a pure, `Sendable`, `Codable` value type holding the report's sections as plain data (date range, session stats, narrated cycle pattern strings, pain/injury timeline entries). New file: `DomainLayer/Reporting/TrainingReportBuilder.swift` — a pure function/struct taking `ExportedData` plus outputs from the three existing insight services and producing `TrainingReportContent`. No I/O in this type; it's built and tested exactly like `ReadinessAssessmentService` is today. Unit tests cover empty-state input, partial data, and a full-history fixture.

### Task 2 — Plain-language narration layer

The insight services currently drive charts, not sentences. Add a small narration step inside `TrainingReportBuilder` (or a sibling `ReportNarrator`) that turns structured insight output into short, plain sentences a non-technical reader — including a clinician who's never opened the app — can understand at a glance. This is the piece most worth spending real design time on, since it's the actual differentiator.

### Task 3 — PDF rendering

New file: `DomainLayer/Reporting/TrainingReportPDFRenderer.swift` (or in a UI-adjacent location if `ImageRenderer`-based SwiftUI-to-PDF is the chosen approach — decide during implementation based on layout complexity). Takes `TrainingReportContent` and produces `Data` (a PDF). This is the one genuinely new technical surface in this feature; everything upstream of it is composition of existing, tested services.

### Task 4 — Entry point and share sheet

Add a "Share Training Report" action to `UI/Views/Export/ExportView.swift`: date-range picker, a privacy toggle for whether cycle-specific dates/phase labels are included (default off for anything leaving the device — see Privacy below), then `UIActivityViewController` / `ShareLink` with the generated PDF.

### Privacy considerations

This report can contain the most sensitive data in the app in one artifact. Cycle dates and phase labels should require an explicit per-report opt-in, not be included by default, even though they're visible elsewhere in the app — sharing context with a clinician is different from personal use. Nothing generates or leaves the device without the user actively tapping share in that moment; no background generation, no caching of a previously generated report with stale data.

---

## Feature 2: Return-to-Training Program

### Goal

A structured way to come back after any extended break — postpartum, illness, travel, a long deload, life getting in the way — reusing the graduated ramp logic that already exists for injury returns, instead of restarting at full intensity or guessing. Deliberately framed broadly (multiple selectable reasons, not a single "postpartum program") so it serves that audience without requiring the app to make specific, unverified medical claims about postpartum recovery timelines that would need clinical review.

### Scope for this release

A new entry point (Programs tab and/or the existing onboarding "Help Me Choose" quiz) offering a small set of "coming back after..." reasons. The underlying ramp math reuses `ReturnToLiftingRampService` rather than being rebuilt — this task is mostly about generalizing its trigger vocabulary and content, not new algorithm design. Output is a structured multi-week program (via `ProgramTemplateGenerator`) that starts conservative and ramps, with the same deterministic per-session explanation the rest of the app already gives.

### Explicitly deferred

Any postpartum-specific physiological modeling (e.g., core/pelvic-floor-aware exercise exclusions) — flag this clearly as real, valuable future work that deserves its own careful, ideally clinically-reviewed design pass, not something to fold into a general-purpose ramp in one release.

### Task 1 — Generalize the ramp trigger

`ReturnToLiftingRampService` currently keys its recommendations off injury patterns. Add a break-reason input (postpartum / illness / extended time off / other) alongside the existing injury pattern input, and extend `rampReason(for:loadPercent:)` (and siblings) to produce reasons appropriate to a non-injury return rather than only injury language. Existing injury-triggered behavior must not change — this is additive.

### Task 2 — "Return to Training" program template

New content via `ProgramTemplateGenerator`: a multi-week template whose per-week load targets are driven by the generalized ramp service from Task 1 rather than hand-authored fixed percentages, so it inherits the same reasoning/explanation behavior the rest of the app already has.

### Task 3 — Selection entry point

Surface the new program as a selectable option where programs are already chosen (Programs tab, and/or as an additional branch in the existing "Help Me Choose" quiz flow added in the 1.6.5 onboarding work). Copy should avoid specific medical claims — "gentle, structured return, paced by how you're feeling" rather than any clinical timeline promise.

### Task 4 — Tests

Extend existing `ReturnToLiftingRampService` test coverage to the new non-injury trigger paths. Add program-generation tests confirming week-over-week load progression stays within the same bounds already enforced for injury ramps.

---

## Suggested Sequencing

Coach Report first — it's lower-risk (no new adaptation logic, mostly composition of already-tested services plus one new rendering concern) and ships something screenshot-able for the App Store page while the discovery/ASO fix from the last release is still settling. Return-to-Training second, since generalizing `ReturnToLiftingRampService` deserves the injury-path regression tests to be green and stable first.

## Completion Definition

- Both features behind no paywall, no entitlement checks.
- Full `swift test` suite green, including new tests for both features.
- Coach Report: PDF generates correctly for empty-state, partial-data, and full-history fixtures; nothing leaves the device without an explicit share action; cycle data excluded by default.
- Return-to-Training: existing injury-ramp tests still pass unmodified; new non-injury trigger paths covered; generated program respects the same load-progression bounds as injury ramps.
- CHANGELOG entry added for both under the next version bump.

## Open Questions for a Future Release

- Should the Coach Report support a second, more clinical format (e.g., structured fields instead of prose) if user feedback asks for it?
- Is a perimenopause-specific cycle mode worth its own design spec, following the Training Intelligence 2.0 process (design doc → production plan → privacy audit)?
- Does deeper Oura/Whoop integration become worth pursuing once App Store discovery is fixed and there's a larger installed base to justify the API approval overhead?

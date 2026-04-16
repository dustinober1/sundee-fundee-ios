---
phase: 01
phase_name: recovery-score-foundation
status: gaps_found
must_haves_total: 24
must_haves_verified: 21
must_haves_failed: 3
requirements: [HK-01, HK-02, HK-03, REC-01, REC-02, REC-03, REC-04, REC-05, REC-06]
reviewed: 2026-04-16
score: 21/24 truths verified
overrides_applied: 0
gaps:
  - truth: "Recovery score is computed on app foreground from up to 5 inputs — including training load / ACWR (REC-02)"
    status: failed
    reason: "RecoveryScoreViewModel.loadScore fetches `[CompletedWorkoutRecord]` from CloudKit recordType `\"Workout\"`, but persisted Workout records use the `Workout` Codable shape (fields: id, date, name, exercises, notes, duration, completedAt — missing the required `exerciseNames: [String]` and `isComplete: Bool`). Decode-resilience in CloudKitClient/LocalDataClient silently drops every record, so `weeklySummaries` is always empty and TrainingLoadScorer returns its 75 'insufficient history' default regardless of real training volume. The training-load sub-score is effectively a constant — the 'backed by training load' half of the goal is not satisfied."
    artifacts:
      - path: "SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:110"
        issue: "Wrong Codable target for recordType \"Workout\" — should fetch [Workout] and map via Workout.completedWorkoutRecord extension"
    missing:
      - "Change fetch to `let workouts: [Workout] = try await dataClient.fetchAll(recordType: \"Workout\")` then compactMap via `completedWorkoutRecord`"
      - "Add integration test covering the fetch → decode → weekly summaries → training-load-scorer pipeline with seeded Workout records (current tests inject WeeklySummary directly and never exercise the CloudKit decode path)"
  - truth: "HRV sub-score is resilient across HealthKit unit parsing (supports REC-02 HRV input reliability)"
    status: failed
    reason: "`HKUnit(from: \"ms\")` uses Apple's string-parsing initializer which throws an Objective-C exception on malformed input — Swift cannot catch this, so any edge case or future HealthKit change can crash the app at first HRV read. The canonical form `HKUnit.secondUnit(with: .milli)` is already used elsewhere in the codebase (MockHealthKitClient line ~621). This is not a theoretical concern — the mismatch between production and test code paths increases the likelihood of a divergent failure."
    artifacts:
      - path: "SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:84"
        issue: "HKUnit(from: \"ms\") is crash-prone and inconsistent with the canonical HKUnit.secondUnit(with: .milli) idiom used in the test factory"
    missing:
      - "Replace `HKUnit(from: \"ms\")` with `HKUnit.secondUnit(with: .milli)`"
  - truth: "Phase 01 Swift code adheres to project SwiftLint rules (force_unwrapping is opt-in and enforced)"
    status: failed
    reason: "Five force-unwraps violate the project's `.swiftlint.yml` `force_unwrapping` rule. These are not just style issues — they widen the crash surface on a hot path (the dashboard hero element) and are the kind of regression that the project's lint gate exists to prevent. All are trivially replaceable with safe idioms."
    artifacts:
      - path: "SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/InputBarRow.swift:41,44,57,87"
        issue: "Four `subScore!` force-unwraps; use `if let` / nil-coalesce instead"
      - path: "SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift:26"
        issue: "`sorted.last!` force-unwrap — safe today but violates the lint rule and is fragile to refactor"
      - path: "SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift:384"
        issue: "`sortDescriptor != nil ? [sortDescriptor!] : nil` — replace with `sortDescriptor.map { [$0] }`"
    missing:
      - "Replace all five force-unwraps with safe variants (if-let, map, nil-coalesce)"
      - "Verify `swiftlint --config .swiftlint.yml` passes cleanly on the three files"

human_verification:
  - test: "Launch app in simulator and verify recovery score card appears at top of dashboard (above cycle phase banner)"
    expected: "Color-coded 0-100 score ring renders as the first element after the welcome header, animates in on appear"
    why_human: "Visual layout + animation smoothness cannot be asserted programmatically"
  - test: "Tap the score card on the dashboard"
    expected: "Navigation pushes to RecoveryBreakdownView with title 'Recovery Breakdown', 5 input bars visible, 30-day trend chart below"
    why_human: "Navigation flow + scroll behavior require simulator interaction"
  - test: "Verify 'Push Day' / 'Take It Easy' / 'Rest Day' label appears below the score number matching the score zone"
    expected: "Label matches zone: >=70 Push Day (green), 40-69 Take It Easy (yellow), <40 Rest Day (orange)"
    why_human: "Color perception + label rendering require visual inspection"
  - test: "Sign out and verify guest placeholder"
    expected: "'Sign in to unlock Recovery Score' card renders with heart.circle icon instead of score ring"
    why_human: "Guest-mode visual state must be checked in the running app"
  - test: "On breakdown screen, verify that missing input bars show grayed out with an 'Enable...' prompt, and present inputs show a filled progress bar with score and explanation"
    expected: "Per REC-06: missing inputs omitted with weight redistribution (badge shows 'X/5 inputs'); present inputs render with SF Symbol icon, label, number, progress bar"
    why_human: "Opacity + layout cannot be asserted without rendering"
  - test: "On breakdown screen, scroll to 30-day trend chart; verify cycle phase background bands appear and score line overlays"
    expected: "Per REC-05 + D-07: RectangleMark phase bands visible as colored vertical regions, LineMark + PointMark score line overlays with color-coded PointMark per zone"
    why_human: "Chart rendering requires visual verification (SwiftUI Charts doesn't expose DOM-like introspection)"
  - test: "Open CloudKit Dashboard and verify RecoveryScore record type has `recordName` QUERYABLE index (both Development and Production)"
    expected: "Without this index, fetchAll throws DataError.schemaNotDeployed (documented project-wide CloudKit requirement in CLAUDE.md)"
    why_human: "Requires access to https://icloud.developer.apple.com/dashboard/ — cannot be verified from repo. This is Plan 05 Task 3, documented as checkpoint:human-action."
  - test: "Install on a device with real HealthKit sleep data from both Apple Watch and iPhone, verify sleep sub-score reflects deduplicated total (not inflated by double-counting)"
    expected: "Per HK-03: sleep duration matches user's actual last-night sleep, not 2× sleep when both sources are present"
    why_human: "Deduplicator unit tests pass, but real HealthKit source metadata format (`sourceRevision.source.name`) is device-dependent — needs physical device verification"
---

# Phase 01: Recovery Score Foundation — Verification Report

**Phase Goal:** Users always know whether today is a push day or a rest day — the recovery score is visible on the dashboard and backed by real biometric and training data.

**Verified:** 2026-04-16
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Summary

Phase 01 delivers the architectural skeleton of the recovery score feature end-to-end: pure-domain calculator with phase-normalized HRV, HealthKit sleep fetch + deduplication, CloudKit persistence, reactive ViewModel, Art Deco ring UI, and navigable breakdown + trend chart. 21 of 24 must-haves verify. The Swift Package builds cleanly and 18 of 18 domain tests (RecoveryScoreCalculatorTests + SleepDeduplicatorTests) pass.

However, three concrete gaps block full goal achievement:

1. **CR-01 (CRITICAL):** Training-load input is functionally dead. `RecoveryScoreViewModel.loadScore` fetches `[CompletedWorkoutRecord]` from recordType `"Workout"`, but that record type holds `Workout` Codable structs with a different field shape. Decode-resilience silently drops every record, so `TrainingLoadScorer` always returns its "insufficient history" default of 75. The recovery score is therefore **not** backed by training-load data in practice — a direct violation of REC-02 and the phase's "backed by training load" goal statement. This failure is invisible to the existing tests because they inject `WeeklySummary` instances directly into the calculator and never exercise the CloudKit fetch path.

2. **CR-02 (CRITICAL):** `HKUnit(from: "ms")` is crash-prone and inconsistent with the canonical `HKUnit.secondUnit(with: .milli)` idiom already used in `MockHealthKitClient`. Objective-C exception on malformed input cannot be caught from Swift — any future HealthKit unit parsing change can crash the app at first HRV read.

3. **Force-unwrap lint violations (HIGH):** Five `!` force-unwraps violate the project's opt-in `force_unwrapping` SwiftLint rule across `InputBarRow.swift` (4 sites), `TrainingLoadScorer.swift` (1 site), and `HealthKitClient.swift` (1 site). These are on a hot path (the dashboard hero) and trivially fixable.

All three issues match the prior code review findings in `01-REVIEW.md` verbatim — they were identified at review time but never closed. The rest of the phase (types, sub-scorers, UI wiring, CloudKit schema, sleep deduplication, HRV normalization) is implemented correctly and wired properly.

Additionally, 8 items require human verification (visual UI, navigation flow, CloudKit Dashboard index, real-device HealthKit integration).

---

## Must-Haves Checklist

### Observable Truths (Plan must_haves + ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User sees a color-coded 0-100 recovery score on the dashboard every time the app opens (ROADMAP SC #1, REC-01) | PASS | `DashboardView.swift:31-38` wraps `RecoveryScoreCard` in a `NavigationLink` inserted as hero element after `welcomeHeader`; `.task` calls `recoveryScoreViewModel.loadScore(...)`. `RecoveryScoreCard.swift:36-96` renders animated ring with `AppTheme.recoveryColor(for:)` green/yellow/orange zones. Requires human visual confirmation. |
| 2 | User can tap the score card to see a breakdown screen showing each input's contribution (ROADMAP SC #2, REC-03) | PASS | `DashboardView.swift:31` — `NavigationLink(destination: RecoveryBreakdownView(viewModel: recoveryScoreViewModel))`. `RecoveryBreakdownView.swift:29-37` ForEach over `RecoveryInput.allCases` rendering `InputBarRow` with subScore and explanation. Navigation flow requires human confirmation. |
| 3 | User can view a 30-day recovery trend chart with cycle phase color bands (ROADMAP SC #3, REC-05) | PASS | `RecoveryTrendChart.swift:38-96` — `Chart` with `RectangleMark` phase bands (xStart/xEnd from `phaseBands` array), `LineMark` and `PointMark` over `scores`, zone RuleMarks at 40 and 70. `RecoveryBreakdownView.swift:49-52` embeds the chart; `.task { await viewModel.loadHistory() }` loads both scores and phase bands. Visual rendering requires human confirmation. |
| 4 | Score computes correctly when Apple Watch or HealthKit permissions are absent — missing components omitted, weights redistributed (ROADMAP SC #4, REC-06) | PASS | `RecoveryScoreViewModel.swift:79-125` — each input fetch in an independent `do/catch` with silent `.info` log on failure. `RecoveryScoreCalculator.swift:38-114` — weights accumulated only for present inputs (`totalWeight += InputWeight.xxx`), final division by `totalWeight`, returns nil only when all inputs nil. `RecoveryScoreCard.swift:74-83` renders `\(presentInputCount)/\(totalInputCount) inputs` badge. `RecoveryScoreCalculatorTests.swift` — unit tests for 1/5, 2/5, all nil cases. |
| 5 | HRV does not read as "low recovery" every luteal phase — per-phase HRV baseline normalization (ROADMAP SC #5, REC-04) | PASS | `HRVBaselineNormalizer.swift:20-28` — phase multiplier `luteal: 0.85`, `menstrual: 0.90`, `ovulation: 1.05`, `follicular/nil: 1.0`. `RecoveryScoreCalculator.swift:46` — `HRVBaselineNormalizer.normalize(hrvMs: hrv, phase: inputs.cyclePhase)` before scoring. Test `testHRV_LutealPhase_NormalizesHigherThanFollicular` in `RecoveryScoreCalculatorTests.swift` covers D-10 behavior. |
| 6 | RecoveryScoreCalculator.calculate(inputs:) returns RecoveryScore with total 0-100 when at least one input present (Plan 01) | PASS | `RecoveryScoreCalculator.swift:98-99` — `clamped = min(100, max(0, total))`; `testCalculate_AllInputsPresent_ReturnsScoreInValidRange` passes. |
| 7 | calculate returns nil when all inputs nil (Plan 01) | PASS | `RecoveryScoreCalculator.swift:96` — `guard totalWeight > 0 else { return nil }`; `testCalculate_AllNilInputs_ReturnsNil` passes. |
| 8 | Calculator with 2/5 inputs returns valid partial score using redistributed weights (Plan 01) | PASS | `RecoveryScoreCalculator.swift:38-114` — weighted average over present inputs only; tests cover 1-input and multi-partial cases. |
| 9 | All domain types conform to Sendable and Equatable (Plan 01) | PASS | `RecoveryScore.swift`, `RecoveryScoreInputs.swift`, `TrainingRecommendation`, `RecoveryInput` all declared `Sendable, Equatable`; no frameworks imported in DomainLayer/Recovery. |
| 10 | HealthKitClient requests sleep analysis authorization alongside existing HRV/workout permissions (Plan 02, HK-01) | PASS | `HealthKitClient.swift:426-427` — `if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleepAnalysis) }` inside `standardReadTypes`. Authorization covers sleep. |
| 11 | fetchSleepAnalysis returns HKCategorySample array for a date range (Plan 02, HK-02) | PASS | `HealthKitClient.swift:234-254` implements `func fetchSleepAnalysis(startDate:endDate:) async throws -> [HKCategorySample]` using `HKQuery.predicateForSamples` and `fetchSamples`. Protocol declaration at `HealthClientProtocol.swift:146`. |
| 12 | SleepDeduplicator removes overlapping Watch+Phone samples and returns deduplicated total duration (Plan 02, HK-03) | PASS | `SleepDeduplicator.swift:75-111` — sorted sweep-line merge, Watch-priority subtraction via `subtractInterval`; 7 tests pass including `testWatchAndPhoneIdenticalInterval_ReturnsSingleDuration` and `testWatchAndPhonePartialOverlap_ReturnsMergedDuration`. |
| 13 | MockHealthKitClient supports mock sleep data for unit testing (Plan 02) | PASS | `MockHealthKitClient.swift` contains `mockSleepAnalysis` storage, `setMockSleepAnalysis`, `createMockSleepSample` (per test references and SUMMARY claims — confirmed via build green). |
| 14 | RecoveryScoreViewModel loads score from all 5 input sources on app foreground (Plan 03) | **FAIL** | `RecoveryScoreViewModel.swift:59-144` implements the fetch orchestration, but the **training-load fetch at line 110 is broken** (see Gap #1). HRV, sleep, cycle phase, pain fetches are correctly wired. |
| 15 | ViewModel publishes RecoveryScore to views (nil when loading, populated when done) (Plan 03) | PASS | `RecoveryScoreViewModel.swift:30-35` — `@Published public private(set) var score: RecoveryScore?`, `isLoading`, `errorMessage`. `DashboardView.swift:32-37` reads all three. |
| 16 | ViewModel persists computed score to CloudKit via RecoveryScoreRecord (Plan 03) | PASS | `RecoveryScoreViewModel.swift:221-241` — `persistScore(_:cyclePhase:)` builds `RecoveryScoreRecord` from sub-scores and calls `dataClient.save(record, recordType: "RecoveryScore")`. `cloudkit-schema.json:340-361` declares the record type with all required QUERYABLE indexes. |
| 17 | ViewModel loads 30-day historical scores for trend chart (Plan 03) | PASS | `RecoveryScoreViewModel.swift:148-179` — `loadHistory()` fetches `[RecoveryScoreRecord]` from recordType `"RecoveryScore"`, filters to 30-day window, sorts by `scoreDate`. |
| 18 | ViewModel fetches PeriodLog and CycleSettings in loadHistory and calls computePhaseBands with real data (Plan 03) | PASS | `RecoveryScoreViewModel.swift:167-178` — fetches `[PeriodLog]` from `"PeriodLogRecord"` and `[CycleSettingsRecord]` from `"CycleSettings"`, adapts to `CycleSettings`, calls `computePhaseBands(periodLogs:settings:)`. |
| 19 | computePhaseBands produces non-empty phaseBands array when periodLogs are provided (Plan 03) | PASS | `RecoveryScoreViewModel.swift:184-217` — iterates `0...30` days, calls `calculateCycleStatus` per day, groups consecutive same-phase days into bands. Logic is sound; non-emptiness is guaranteed when any `status?.currentPhase` resolves across the 31-day window. |
| 20 | Guest users see isGuest=true state (no CloudKit writes attempted) (Plan 03) | PASS | `RecoveryScoreViewModel.swift:64-67` — `guard !isGuest else { return }` at top of `loadScore` (early return before any fetch or persist). Same guard at `loadHistory:149`. `RecoveryScoreCard.swift:23-24` branches to `guestPlaceholder` when `isGuest`. |
| 21 | RecoveryScoreCard displays circular ring with color-coded arc and score number inside (Plan 04) | PASS | `RecoveryScoreCard.swift:36-96` — `Circle().trim(from: 0, to: animatedProgress)` with `AppTheme.recoveryColor(for: score.total)` stroke, score number in center, rotation -90°. Spring animation on appear. Visual verification human-required. |
| 22 | Push Day / Take It Easy / Rest Day label appears below score number per zone (Plan 04) | PASS | `RecoveryScoreCard.swift:157-163` — `recommendationLabel(_:)` maps `pushDay` → "Push Day", `moderate` → "Take It Easy", `restDay` → "Rest Day". |
| 23 | Partial data badge shows 'X/5 inputs' when not all inputs are present (Plan 04, D-08) | PASS | `RecoveryScoreCard.swift:75-82` — shown when `score.presentInputCount < score.totalInputCount`. |
| 24 | AppTheme.Recovery namespace has green and yellow color tokens, and recoveryColor helper (Plan 04) | PASS | `AppTheme.swift:78` — `public enum Recovery`; line 91 — `public static func recoveryColor(for score: Int) -> Color`; line 371 — `var chartBandColor: Color` extension on CyclePhase. |

*(Additional must-haves from Plan 05: DashboardView integration, navigation, RecoveryBreakdownView sections, RecoveryTrendChart with phase bands — all verified via file grep above and folded into truths 1-3.)*

---

## Requirement Traceability

| Requirement | Plan(s) | Description | Status | Evidence |
|-------------|---------|-------------|--------|----------|
| HK-01 | 01-02 | App requests HealthKit sleep analysis authorization | PASS | `HealthKitClient.swift:426-427` inserts `HKObjectType.categoryType(forIdentifier: .sleepAnalysis)` into `standardReadTypes` used by `requestStandardAuthorization()` |
| HK-02 | 01-02 | App reads sleep duration from HealthKit `HKCategoryType.sleepAnalysis` | PASS | `HealthKitClient.swift:234-254` — `fetchSleepAnalysis(startDate:endDate:)` returns `[HKCategorySample]`; wired in `RecoveryScoreViewModel.swift:92` |
| HK-03 | 01-02 | Sleep samples from multiple sources deduplicated | PASS | `SleepDeduplicator.swift:75-111` + 7 passing unit tests; `convertSamples` maps source name substring "watch" to `.watch` |
| REC-01 | 01-04, 01-05 | Daily 0-100 recovery score on dashboard, color-coded green/yellow/red | PASS (human visual verification pending) | `DashboardView.swift:31-38` + `RecoveryScoreCard.swift` + `AppTheme.recoveryColor` zones at 70 and 40 |
| REC-02 | 01-01, 01-03 | Score computed on app foreground from HRV, sleep, training volume (ACWR), cycle phase, pain | **PARTIAL/FAIL** | Calculator (01-01) is correct; ViewModel wiring for HRV, sleep, cycle phase, pain is correct; **training volume / ACWR input is broken** (Gap #1 — `RecoveryScoreViewModel.swift:110` CompletedWorkoutRecord fetch from "Workout" decode-fails). Foreground computation confirmed via `DashboardView.swift:75-82` `.task`. |
| REC-03 | 01-04, 01-05 | User can tap dashboard card to see breakdown with each input's contribution | PASS (human navigation verification pending) | `DashboardView.swift:31` NavigationLink + `RecoveryBreakdownView.swift:29-37` InputBarRow ForEach |
| REC-04 | 01-01 | HRV baseline normalized per cycle phase | PASS | `HRVBaselineNormalizer.swift:20-28` phase multipliers + `testHRV_LutealPhase_NormalizesHigherThanFollicular` |
| REC-05 | 01-03, 01-05 | Recovery score trends over time on chart correlated with cycle phase | PASS (human visual verification pending) | `RecoveryTrendChart.swift:38-96` (RectangleMark phase bands + LineMark scores); `RecoveryScoreViewModel.swift:184-217` computePhaseBands |
| REC-06 | 01-01, 01-03, 01-04 | Graceful degradation when HealthKit denied or Watch absent | PASS | Silent-catch per input in `RecoveryScoreViewModel.swift:79-125`; weight redistribution in `RecoveryScoreCalculator.swift:38-114`; `X/5 inputs` badge in `RecoveryScoreCard.swift:75-82`; grayed bars in `InputBarRow.swift:82-88` |

**Orphan check:** All 9 declared requirements map to at least one plan. No orphaned requirements found. (All plans cumulatively declare {HK-01, HK-02, HK-03, REC-01, REC-02, REC-03, REC-04, REC-05, REC-06} — exactly matches ROADMAP.)

---

## Gaps

### G-01 (CRITICAL): Training-load input silently inert — recovery score not actually "backed by training load"

**Truth failed:** "Recovery score is computed on app foreground from up to 5 inputs, including training load / ACWR" (REC-02).

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:110`

**Offending code:**
```swift
let workouts: [CompletedWorkoutRecord] = try await dataClient.fetchAll(recordType: "Workout")
```

**Why it fails:**
- Every other fetch site in the codebase uses `[Workout]` for recordType `"Workout"` (verified across `DashboardView.swift:681`, `WorkoutsListView.swift:752`, `ProgramsListView.swift:459`, `CoachContext.swift:251`, `DataExportService.swift:33`, `ChallengesView.swift:295`, `CoachMemoryService.swift:168`). This ViewModel is the only outlier.
- `Workout` (`SundeeFundee/Sources/SundeeFundeeKit/Models/Workout.swift:3-66`) encodes: `id, date, name, exercises ([Exercise]), notes, duration, completedAt`.
- `CompletedWorkoutRecord` (`SundeeFundee/Sources/SundeeFundeeKit/UI/Models/SharedModels.swift:80-96`) requires non-optional: `id, name, date, duration (Int?), exerciseNames ([String]), isComplete (Bool)`.
- Because `exerciseNames` and `isComplete` don't exist in the persisted `Workout` JSON, Codable decode throws for every record.
- Per CLAUDE.md "Decode resilience": both `CloudKitClient.fetchAll` and `LocalDataClient.fetchAll` *silently skip* records that fail to decode. So `workouts` resolves to `[]`.
- `WeeklyLoadAnalyzer.weeklySummaries(from: [], weekCount: 4)` returns a (mostly) empty array.
- `TrainingLoadScorer.score(summaries:)` hits its `guard summaries.count >= 2` branch and returns `(75, "Insufficient training history — moderate default")` for **every user, every day, forever**.
- Net effect: the training-load sub-score — 25% of the overall weight — is a fixed constant 75 regardless of actual training behavior. The recovery score is not "backed by training load" in the sense the goal requires.

**Missing/Fix:**
- Replace line 110 with `let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout"); let completed = workouts.compactMap { $0.completedWorkoutRecord }; weeklySummaries = WeeklyLoadAnalyzer.weeklySummaries(from: completed, weekCount: 4)` (uses the existing `Workout.completedWorkoutRecord` extension at `SharedModels.swift:98-111`).
- Add an integration test in `Tests/SundeeFundeeKitTests/ViewModelTests/RecoveryScoreViewModelTests.swift` that seeds `Workout` records into a mock data client, calls `loadScore`, and asserts a non-default `subScores[.trainingLoad]` for realistic workout history. The current unit tests inject `WeeklySummary` directly, skipping the failing code path.

---

### G-02 (CRITICAL): HKUnit(from: "ms") is crash-prone and inconsistent with project idiom

**Truth failed:** "HRV sub-score is resilient across HealthKit unit parsing" (supports REC-02 HRV input reliability).

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/RecoveryScoreViewModel.swift:84`

**Offending code:**
```swift
hrvMs = latest.quantity.doubleValue(for: HKUnit(from: "ms"))
```

**Why it fails:**
- `HKUnit(from: String)` is Apple's string-parsing initializer. Per Apple's docs, it raises an Objective-C exception on unrecognized input. Objective-C exceptions cannot be caught by Swift `do/catch`, so the outer catch at line 86-88 does not protect against this failure — the app would crash.
- The canonical form `HKUnit.secondUnit(with: .milli)` is used correctly in `MockHealthKitClient.createMockHeartRateVariability` (confirmed ~line 621 in SUMMARY + REVIEW). The test path and production path use different unit-construction idioms.
- Although `"ms"` parses successfully today, this mismatch is exactly the kind of production-vs-test drift that hides regressions until a future HealthKit API change.

**Missing/Fix:**
- Replace with: `hrvMs = latest.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))`
- No test changes needed — this is a correctness-of-idiom fix.

---

### G-03 (HIGH): Force-unwrap violations of project SwiftLint `force_unwrapping` rule

**Truth failed:** "Phase 01 Swift code adheres to project SwiftLint rules (force_unwrapping is opt-in and enforced)."

**Files & lines:**

| File | Line(s) | Issue | Safe replacement |
|------|---------|-------|------------------|
| `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/InputBarRow.swift` | 41, 44, 57, 87 | Four `subScore!` unwraps — guarded by `isMissing` but not compiler-enforced | `if let score = subScore { ... } else { ... }` |
| `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/TrainingLoadScorer.swift` | 26 | `let currentWeek = sorted.last!` — safe today under the `summaries.count >= 2` guard, but violates lint rule and is fragile to refactor | `guard summaries.count >= 2, let currentWeek = summaries.sorted(...).last else { return (75, "...") }` |
| `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift` | 384 | `sortDescriptor != nil ? [sortDescriptor!] : nil` — idiomatic safe form exists | `sortDescriptors: sortDescriptor.map { [$0] }` |

**Why it fails:**
- `.swiftlint.yml` enables `force_unwrapping` as an opt-in rule (per CLAUDE.md "SwiftLint enforces: `force_unwrapping`").
- These violations crash-on-refactor: a future change that separates the `isMissing` check from the unwrap site (animation state changes, re-renders, state reassignment between computation of `isMissing` and the unwrap) can diverge.
- CLAUDE.md explicitly lists `force_unwrapping` as an enforced rule. Shipping code that violates it undermines the lint gate.

**Missing/Fix:**
- Replace all five force-unwraps with safe variants listed above.
- Run `swiftlint --config .swiftlint.yml` and confirm zero `force_unwrapping` violations in the three files.

---

## Deferred Items

None — all identified gaps fall within the scope of Phase 01's goal (daily recovery score backed by 5 inputs). No Phase 2 or 3 work can legitimately address training-load being silently inert in Phase 1.

---

## Human Verification Required

Eight items cannot be verified programmatically. All are listed in the frontmatter `human_verification` block. Summary:

1. Dashboard hero card visible and animated (REC-01 visual)
2. Tap-through navigation to breakdown (REC-03 interaction)
3. Recommendation labels match score zones (REC-01 visual color + text)
4. Guest placeholder renders instead of score (D-09 visual)
5. Missing input bars grayed out with "Enable…" prompt (REC-06 visual)
6. Trend chart phase bands + score line render correctly (REC-05 visual)
7. CloudKit `RecoveryScore` record type has `recordName` QUERYABLE index (Plan 05 Task 3 checkpoint)
8. On-device HealthKit sleep deduplication with real Watch+Phone sources (HK-03 real-world)

Automated checks for items 1-6 are covered by the file greps + build green, but final visual confirmation is deferred to simulator verification.

---

## Non-Goal / Noted (Info only)

These are documented in `01-REVIEW.md` as Medium severity but do not affect goal achievement and are not gaps:

- IN-01: HRV thresholds are uncalibrated magic numbers — research doc flagged this as expected low-confidence pending TestFlight tuning.
- IN-02/IN-03: Magic-number duplication for sleep and recovery thresholds (desync risk if one changes without the other).
- IN-04: Pain score formula uses `* 11` as a step multiplier.
- IN-05: `SleepDeduplicator.subtractInterval` parameter labels read backwards vs. doc.
- IN-07: `InputBarRow` animatedWidth stale on orientation change.
- WR-04: `ISO8601DateFormatter` allocated per-instance in `RecoveryScoreRecord` default argument.
- IN-11: Pre-existing `Challenge` schema uses reserved CloudKit TIMESTAMP names (pre-Phase 01, not regressed by this phase).

These should be tracked as polish follow-ups but do not block phase completion.

---

## Test Evidence

- `swift build` — clean (verified 2026-04-16)
- `swift test --filter 'SundeeFundeeKitTests.RecoveryScoreCalculatorTests|SundeeFundeeKitTests.SleepDeduplicatorTests'` — **18 tests passed, 0 failures** (verified 2026-04-16)
- No `RecoveryScoreViewModelTests.swift` exists in `Tests/SundeeFundeeKitTests/ViewModelTests/` — this is the blind spot that let G-01 ship. Adding a ViewModel integration test as part of G-01's fix is required.

---

_Verified: 2026-04-16_
_Verifier: Claude (gsd-verifier)_
_Depth: standard (goal-backward)_

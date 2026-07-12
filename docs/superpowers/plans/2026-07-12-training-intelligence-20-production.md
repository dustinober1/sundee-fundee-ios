# Training Intelligence 2.0 Production Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a directly visible, privacy-safe 2.0 release with readiness guidance, conservative deload programming, and social sharing integrated into the existing SwiftUI app.

**Architecture:** Keep the existing readiness foundation as a typed domain/data contract. Build readiness UI, deload policy, and share variants as independent workstreams, then integrate them at app-shell and workout-entry boundaries through view models. Preserve CloudKit/local fallback and keep all raw HealthKit, cycle, pain, and private-note data out of share payloads and analytics.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, XCTest/Swift Testing, CloudKit, HealthKit, existing Fastlane/XcodeGen workflows, zero external packages.

## Global Constraints

- iOS 18+; Swift 6 strict concurrency throughout.
- All 2.0 features are free; no paywalls, purchase flows, or paid access gates.
- HealthKit denial must leave the app usable and lower confidence instead of blocking workouts.
- CloudKit-only backend; local guest fallback remains supported.
- CloudKit dates are ISO8601 strings; avoid reserved `createdAt`, `modifiedAt`, `startDate`, and `endDate` field names.
- New CloudKit record types require queryable `recordName` indexes and production deployment as a separately authorized release step.
- Use `AppTheme.*` tokens, semantic icon sizes, and `HapticFeedback` helpers; do not hardcode semantic colors.
- User-facing errors use actionable copy, never raw `error.localizedDescription`.
- No archive-for-upload, TestFlight distribution, App Store upload, or App Review submission without explicit authorization.
- Target version is `2.0.0`; build number increments only when release preparation is explicitly approved.

---

## File map

- Readiness UI: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/DailyReadinessViewModel.swift`, `UI/Views/Dashboard/ReadinessCardView.swift`, `UI/Views/Dashboard/ReadinessDetailsSheet.swift`.
- Deload domain: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/DeloadDecisionService.swift`, `DomainLayer/Workout/DeloadDecision.swift`, `DomainLayer/Workout/ActiveRecoveryWorkoutBuilder.swift`.
- Workout integration: `UI/ViewModels/BestNextWorkoutViewModel.swift`, `DomainLayer/Workout/BestNextWorkoutRequestBuilder.swift`, related workout tests.
- Sharing: `DomainLayer/Growth/ShareSanitizedSummary.swift`, `UI/Share/ShareCardVariant.swift`, `UI/Share/ShareCardRenderer.swift`, `UI/Share/Variants/ReadinessShareView.swift`, `UI/Share/Variants/DeloadShareView.swift`.
- Persistence/schema: existing readiness records and `SundeeFundeeApp/cloudkit-schema.json`; add only fields/records required by the approved design.
- Release validation: `scripts/readiness-foundation-gate.sh`, new `scripts/training-intelligence-20-gate.sh`, `docs/release/training-intelligence-20-checklist.md`, Fastlane metadata and screenshots.

## Task 1: Establish 2.0 contracts and release fixtures

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Recovery/ReadinessModels.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/DeloadDecision.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Growth/ShareSanitizedSummary.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/DeloadDecisionTests.swift`
- Test: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ShareSanitizedSummaryTests.swift`

**Interfaces:**
- `DeloadDecisionService` consumes `ReadinessAssessment`, recent training-load evidence, pain severity, and deload history; it produces a deterministic `DeloadDecision` with `mode`, `volumeMultiplier`, `intensityMultiplier`, `reasonCodes`, and `confidence`.
- `ShareSanitizedSummary` consumes only explicitly permitted display metadata and produces a Codable/sendable summary with no HealthKit, cycle, pain, notes, prompt, or generated-text fields.

- [ ] Write failing tests for normal/reduced/active-recovery decisions and for sanitized summaries rejecting prohibited fields.
- [ ] Run the focused tests and verify they fail for missing contracts.
- [ ] Implement the minimal enums/structs with Codable/Sendable/Equatable conformance and explicit invariants (multipliers in `0...1`, non-empty model version, no raw-health fields).
- [ ] Run focused tests and the existing readiness suite.
- [ ] Commit `feat(2.0): define deload and sanitized sharing contracts`.

## Task 2: Build readiness dashboard and details flow

**Files:**
- Create: `UI/ViewModels/DailyReadinessViewModel.swift`
- Create: `UI/Views/Dashboard/ReadinessCardView.swift`
- Create: `UI/Views/Dashboard/ReadinessDetailsSheet.swift`
- Modify: `UI/Views/Dashboard/DashboardView.swift`
- Test: `UI/ViewModels/DailyReadinessViewModelTests.swift`

**Interfaces:**
- View model consumes `DailyReadinessService`, `AuthViewModel` guest state, and `Calendar`; it publishes loading/content/empty/error state and a `DailyReadinessSnapshot`.
- Views receive a view model or immutable snapshot and never access HealthKit/data clients directly.

- [ ] Add tests for current assessment, no assessment, HealthKit-denied lower confidence, stale snapshot, retryable error, and guest mode.
- [ ] Run the focused tests to establish red.
- [ ] Implement `@MainActor` loading/retry behavior and actionable copy.
- [ ] Implement readiness card/details using `AppTheme` tokens, Dynamic Type, accessibility labels, semantic icons, and existing haptics.
- [ ] Add the card to the Today/dashboard hierarchy without duplicating score calculations.
- [ ] Run focused tests plus simulator build.
- [ ] Commit `feat(2.0): surface daily readiness guidance`.

## Task 3: Implement deload decision policy

**Files:**
- Create: `DomainLayer/Workout/DeloadDecisionService.swift`
- Modify: `DomainLayer/Workout/ActiveRecoveryWorkoutBuilder.swift`
- Test: `DomainTests/DeloadDecisionServiceTests.swift`
- Test: `DomainTests/ActiveRecoveryWorkoutBuilderTests.swift`

**Interfaces:**
- `DeloadDecisionService.evaluate(readiness:trainingLoad:pain:history:) -> DeloadDecision` is pure and deterministic.
- `ActiveRecoveryWorkoutBuilder.build(from:equipment:) -> WorkoutDraft` remains pure and produces a safe alternative without mutating records.

- [ ] Add red tests for stable normal training, repeated high load, low readiness, high pain, incomplete history, and deterministic boundary behavior.
- [ ] Implement explicit thresholds from the approved design, preserving `.maintain`, `.reduce`, and `.activeRecovery` modes.
- [ ] Add reason codes suitable for UI and analytics without raw health values.
- [ ] Verify all multipliers are bounded and high pain never produces an aggressive session.
- [ ] Run focused domain tests and full package tests.
- [ ] Commit `feat(2.0): add conservative deload policy`.

## Task 4: Integrate deload guidance into workout entry

**Files:**
- Modify: `DomainLayer/Workout/BestNextWorkoutRequestBuilder.swift`
- Modify: `UI/ViewModels/BestNextWorkoutViewModel.swift`
- Modify: `UI/Views/Train/TrainHubView.swift` and `UI/Views/Workouts/WorkoutsListView.swift` for the workout-entry adjustment surface.
- Test: existing `BestNextWorkout*Tests` and new `DeloadWorkoutIntegrationTests.swift`.

**Interfaces:**
- Workout entry consumes a `DeloadDecision` and emits a typed adjustment explanation plus the selected draft.
- Existing completed workouts and history remain immutable.

- [ ] Add red integration tests showing normal, reduced, and active-recovery entry behavior, including guest mode and missing readiness.
- [ ] Thread the decision through request building without changing unrelated workout selection behavior.
- [ ] Add concise user-facing explanation and an explicit “use standard session” escape hatch.
- [ ] Run focused workout tests, then full package tests.
- [ ] Commit `feat(2.0): apply deload guidance to workout entry`.

## Task 5: Add sanitized readiness and deload sharing

**Files:**
- Modify: `UI/Share/ShareCardVariant.swift`
- Modify: `UI/Share/ShareCardRenderer.swift`
- Modify: `UI/Share/ShareCardSheet.swift`
- Create: `UI/Share/Variants/ReadinessShareView.swift`
- Create: `UI/Share/Variants/DeloadShareView.swift`
- Test: `UI/Share/ShareSanitizedSummaryTests.swift`
- Test: `UI/Share/ShareCardRendererTests.swift`

**Interfaces:**
- Renderer consumes `ShareSanitizedSummary` only; privacy options determine which safe fields appear.
- Share sheet keeps system cancellation behavior and never writes a share event containing raw details.

- [ ] Add red tests for allowed outcome metadata, default exclusion of HealthKit/cycle/pain/private notes, explicit optional fields, and cancellation.
- [ ] Implement two 2.0 share variants using existing art direction and `AppTheme` tokens.
- [ ] Add accessibility labels and a pre-share privacy summary.
- [ ] Verify clipboard/URL behavior remains privacy-safe and existing variants remain unchanged.
- [ ] Run focused tests and screenshot smoke tests.
- [ ] Commit `feat(2.0): add privacy-first readiness sharing`.

## Task 6: Integrate persistence and CloudKit schema

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/Models/DailyReadinessRecord.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Readiness/DailyReadinessService.swift`
- Modify: `SundeeFundeeApp/cloudkit-schema.json`
- Modify: `scripts/next-release-gate.sh`
- Test: `DataLayerTests/DailyReadinessRecordTests.swift`, `DailyReadinessServiceTests.swift`, and schema guard tests.

- [ ] Add red tests for versioned decoding, unknown fields, same-day replacement, local guest fallback, and CloudKit-safe dates/booleans.
- [ ] Add only the fields needed by the integrated UI/deload/share flows; preserve stable day IDs.
- [ ] Add schema checks for record type and queryable `___recordID`; do not import or deploy schema in this task.
- [ ] Run schema validation and focused data tests.
- [ ] Commit `feat(2.0): persist training intelligence safely`.

## Task 7: Wire app navigation and direct visibility

**Files:**
- Modify: `UI/Views/Dashboard/DashboardView.swift`
- Modify: current tab/navigation root discovered from `UI/Views`.
- Modify: `UI/Views/Workouts/WorkoutsListView.swift`
- Modify: settings/share privacy entry points as needed.
- Test: UI smoke tests and affected view-model tests.

- [ ] Add red navigation tests for Today → readiness details → workout entry → share flow.
- [ ] Integrate the three surfaces directly with no feature flag.
- [ ] Preserve guest onboarding and existing tab order unless a tested accessibility improvement is required.
- [ ] Add loading/empty/error states to every new route.
- [ ] Run UI smoke tests on iPhone 17 Pro Simulator.
- [ ] Commit `feat(2.0): integrate training intelligence surfaces`.

## Task 8: Privacy, accessibility, and performance audit

**Files:**
- Modify only files identified by failing tests/audit.
- Create: `docs/release/training-intelligence-20-privacy-audit.md`
- Test: accessibility/privacy scenario tests and existing dark-mode/Dynamic-Type suites.

- [ ] Verify no raw HealthKit/cycle/pain/private-note fields enter share summaries, analytics, logs, or CloudKit derived records.
- [ ] Verify guest mode, HealthKit denial, CloudKit failure, stale data, and no-history states.
- [ ] Verify VoiceOver labels, Dynamic Type, dark mode, contrast, and semantic icon sizing.
- [ ] Run focused performance checks for dashboard loading and share rendering; avoid blocking the main actor.
- [ ] Document findings and remediations.
- [ ] Commit `docs(2.0): record privacy accessibility audit`.

## Task 9: Prepare release metadata and screenshots

**Files:**
- Modify: `SundeeFundeeApp/project.yml` and generated project settings for `MARKETING_VERSION` `2.0.0`; increment build only when authorized.
- Modify: `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt` and review notes.
- Regenerate/capture: `SundeeFundeeApp/fastlane/screenshots/en-US/` through the existing screenshot lane.
- Create: `docs/release/training-intelligence-20-app-review-checklist.md`.

- [ ] Validate metadata character limits, privacy/support URLs, review notes, and feature claims against the shipped UI.
- [ ] Capture fresh screenshots for iPhone 17 Pro and iPad Pro 13-inch using seeded, deterministic data.
- [ ] Verify screenshots do not contain raw health values, private notes, or misleading claims.
- [ ] Document manual App Review paths, HealthKit denial, guest mode, account deletion, export, and share cancellation.
- [ ] Do not run `fastlane release`; this lane uploads and submits.
- [ ] Commit `docs(release): prepare 2.0 metadata and review checklist`.

## Task 10: Final integration gate

**Files:**
- Create: `scripts/training-intelligence-20-gate.sh`
- Create: `docs/release/training-intelligence-20-checklist.md`
- Modify: `scripts/next-release-gate.sh` only for additive checks.

- [ ] Add executable checks for Swift tests, simulator build, targeted UI smoke tests, schema guards, privacy-safe source scan, and metadata/screenshots presence.
- [ ] Run the complete gate from a clean checkout and record all results.
- [ ] Verify git status is clean and no archive/upload/submission occurred.
- [ ] Commit `test(release): add training intelligence 2.0 gate`.

## Task 11: Final review and release handoff

- [ ] Generate a whole-branch review package against `main`.
- [ ] Fix all P0/P1/P2 findings and rerun the affected tests.
- [ ] Run the final gate again after fixes.
- [ ] Present the user with the production-ready commit, remaining manual App Store Connect steps, and an explicit separate choice for archive/upload/submission.

# Sundee Fundee Improvement Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the app's substantial unused capacity into shipped user value, then close the four platform gaps that limit it — offline writes, real multi-user reach, the wrist, and non-English markets.

**Architecture:** Release 2.1 adds no architecture; it wires existing, already-tested services to UI and call sites. Releases 2.2 and 2.3 change the data layer (offline queue activation, a shareable CloudKit zone) and are gated behind their own plan documents. Releases 2.4 through 2.6 add surfaces (watchOS, widgets, Health integration, localization) on top of the unchanged deterministic domain layer.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, Swift Charts, WidgetKit, ActivityKit, App Intents, HealthKit, CloudKit through `DataClientProtocol`, UserNotifications, XCTest and Swift Testing, XcodeGen, SwiftLint. iOS 18+, zero external package dependencies.

---

## Scope Check

This roadmap covers 17 improvements plus 1 confirmed defect across six releases (a second suspected defect was investigated during 2.1 execution and found to already be fixed — see Task 1.2 and the corrected row 1 of Verified Current State). It is a sequencing document, not a single implementable branch.

**Release 2.1 is specified to task level and is ready to execute.** Every claim behind its tasks was verified against the source on 2026-08-30 (see Verified Current State). Releases 2.2 through 2.6 are specified to outcome, file, decision, and risk level. Each one **requires its own detailed plan document before implementation**, following the convention already used by `2026-07-11-readiness-foundation-shadow-assessment.md` and `2026-07-26-v2-daily-presence-momentum.md`.

Do not submit to App Store review as part of this plan unless the user explicitly asks for submission after implementation and verification.

## Verified Current State

Each finding below was confirmed by direct source inspection on 2026-08-30. These are the factual basis for the tasks; re-verify before implementing if significant time has passed.

| # | Finding | Evidence |
|---|---|---|
| 1 | **Correction (2026-08-30, during 2.1 execution):** the original entry here claimed `ReviewPromptCoordinator.recordSuccessfulAction` had zero callers. That was a verification error — the initial grep searched for the struct name `ReviewPromptEligibilityService` rather than the type actually used at call sites, `ReviewPromptCoordinator`. The review prompt is in fact fully wired: `ActiveWorkoutSessionViewModel.requestReviewIfEligible()` is called unconditionally on every workout completion and covers `thirdWorkoutCompleted`, `firstCoachPlanCompleted`, `painAwareSwapWorkoutCompleted`, and `personalRecordLogged`; `BenchmarksListView.saveResult()` covers `benchmarkLogged`; `MainTabView` observes `.appReviewPromptRequested` and calls `requestReview()`. No defect exists here. Task 1.2 below is retained as a record of the investigation rather than an implementation task. | `UI/ViewModels/ActiveWorkoutSessionViewModel.swift:459,719-745`; `UI/Views/Benchmarks/BenchmarksListView.swift:619-624`; `UI/App/SundeeFundeeApp.swift:83-84,115`. |
| 2 | A placeholder ships in the Today tab. | `UI/Views/Dashboard/DashboardView.swift:807` — `NavigationLink("Start This Workout", destination: Text("Workout Detail"))`. |
| 3 | `PlateCalculator.calculatePlates` has zero call sites. | Only its definition in `Calculations/PlateCalculator.swift:22` and a doc comment in `Exports.swift:40`. |
| 4 | `SyncQueue` is never constructed. CloudKit writes are online-only. | `SyncQueue` absent from `DataLayer/DataClientFactory.swift`. `DataLayer/Diagnostics/SyncQueueDiagnosticsService.swift` exposes `attach(_:)` that is never called with a real queue, so the sync UI in `DataTrustCenterView` is permanently empty. |
| 5 | `experienceLevel` has no picker. Every user is `.intermediate`. | `OnboardingView.swift:306` and `SettingsView.swift:362` declare the property; the only `Picker`s in those views are weight unit, goal, and equipment (`OnboardingView.swift:135,183`; `SettingsView.swift:36,41,48`). It feeds `DomainLayer/Workout/StartingWeightCalibrationService.swift:37`. |
| 6 | **Correction (2026-08-30, during Task 1.7 execution):** the original entry here said no shared or public database existed anywhere, based on `CloudKitClient`'s *default* parameter being `.private`. That missed an explicit override: `SocialChallengeService` constructs its own `CloudKitClient(containerIdentifier:databaseScope: .public)` and saves `ChallengeInvite`, `ChallengeParticipant`, `ChallengeReaction`, and `SocialChallengeProgressSnapshot` there. A challenge invite code genuinely is fetchable by a second person today (`fetchInvite(token:)` queries the public database by token) — the "friends can never read this" claim was wrong for the challenge system specifically. It still holds for buddy check-ins, which have zero `CloudKitClient`/`databaseScope` references and use the default private client. There is still no `CKShare`, `UICloudSharingController`, or CloudKit subscription anywhere, and finding 7 (no custom zone) still stands — `CKShare` remains unimplemented regardless of this correction. | `DomainLayer/Challenge/SocialChallengeService.swift:6-15` (public scope), `:33-41` (cross-user fetch by token). `DomainLayer/Social/BuddyCheckInService.swift` (no scope override — private). |
| 7 | **No custom record zone exists.** All records are in the private *default* zone. | Zero `CKRecordZone`/`zoneID`/`recordZone` references in `SundeeFundee/Sources/`. `CKShare` cannot share default-zone records — this is the gating constraint for Release 2.3. |
| 8 | No push notifications or CloudKit subscriptions. | Zero `CKQuerySubscription`/`CKSubscription`/`registerForRemoteNotifications` references. No `aps-environment` in `SundeeFundeeApp/SundeeFundee/SundeeFundee.entitlements`. |
| 9 | No HealthKit background delivery. Data is pulled on view appear only. | Zero `HKObserverQuery`/`HKAnchoredObjectQuery`/`enableBackgroundDelivery` references. |
| 10 | `heartRate` read authorization is requested but never queried. | Inserted into read types at `DataLayer/Actors/HealthKitClient.swift:411`; no query anywhere. |
| 11 | No watchOS target, though the package supports watchOS. | `SundeeFundeeApp/project.yml` declares 4 targets (app, widget extension, unit tests, UI tests). `SundeeFundee/Package.swift:11` declares `.watchOS(.v11)`. |
| 12 | No localization. | Zero `.strings`, `.xcstrings`, or `.lproj` files; `developmentRegion = en`. |
| 13 | No associated domains, so invites cannot be links. | No `com.apple.developer.associated-domains` entitlement; `UI/App/DeepLinkRouter.swift` handles a custom scheme with 2 routes. |
| 14 | `ChallengeReaction` and `SocialChallengeProgressSnapshot` persist but never render. | `DomainLayer/Challenge/SocialChallengeService.swift` has `saveReaction`/`saveProgressSnapshot`; no UI reads them. |
| 15 | Readiness history persists but is never charted; the readiness snapshot reaches the app group but no widget reads it. | `Models/DailyReadinessRecord.swift` written by `DataLayer/Readiness/DailyReadinessService.swift`; `SharedSnapshotStore.writeReadiness` is read back only by `DashboardView`. The 4 Swift Charts in `UI/Views/Analytics/` cover strength, volume, frequency, and cycle correlation only. |

## Cross-Cutting Decisions

These decisions apply across releases and should not be re-litigated per task.

1. **Social is confirmed in scope.** This roadmap builds the `CKShare` foundation rather than trimming the invite and buddy surfaces back to solo logging. Finding 7 makes this a real data-layer project, not a UI project.
2. **Share a new custom zone; do not migrate existing data.** Personal training records stay in the private default zone. Release 2.3 introduces one custom zone used exclusively for shareable social records. This avoids a whole-database zone migration for every existing user, and it matches the approved principle that social is a supporting layer rather than the core.
3. **Localization infrastructure lands before the new surfaces, translation lands after.** The String Catalog migration is in Release 2.2 so that the social, watch, and Health surfaces added in 2.3 through 2.5 do not compound hardcoded-string debt. Actual translated languages ship in 2.6.
4. **Readiness stays deterministic.** Nothing in this roadmap introduces model-driven or probabilistic training prescription. New surfaces display existing `ReadinessAssessmentService` output; they do not compute their own.
5. **Every release keeps guest mode whole.** Guest users lose only features that inherently require an account (sharing with another person). Widgets, watch, plate math, charts, and offline writes must all work for `isGuest == true`.
6. **The readiness score is not restored as the legacy Recovery Score.** Per the 2.0 design, `readiness-v1` with confidence and provenance is the model; do not reintroduce fixed cycle-phase penalties in any new surface.

## Global Constraints

- iOS 18+; CloudKit-only remote backend; zero external package dependencies.
- Swift 6 strict concurrency. View models are `@MainActor`, data clients are actors, pure domain services import Foundation only and contain no logging.
- Use `AppTheme.*` tokens only. Never hardcode `Color.red/.orange/.green`. Use semantic Dynamic Type sizes.
- Use the `HapticFeedback` helper for user-triggered feedback; it is MainActor-isolated.
- Never display `error.localizedDescription` to users. Wrap with actionable copy and keep the raw error in logs.
- CloudKit: dates encode as ISO8601 strings; avoid the reserved names `createdAt`, `modifiedAt`, `startDate`, `endDate`; Bool decodes may arrive as `Int64`; new record types need a queryable `recordName` / `___recordID` index in the checked-in schema and must be deployed to Production.
- HealthKit denial and missing data stay non-blocking.
- All features remain free. Do not add paywalls, purchase flows, or paid feature gates.
- Do not build for upload, upload, distribute through TestFlight, or submit to App Review without explicit user authorization.
- Commit one file at a time. Never use `git add .` or `git add -A`, never amend, never force-push. Delegate routine git to a Haiku subagent per `CLAUDE.md`.
- Run `cd SundeeFundeeApp && xcodegen generate` after any `project.yml` change.

## Delivery Sequence

| Release | Theme | Items | Risk | Gate |
|---|---|---|---|---|
| 2.1 | Wire the Dark Matter | 1 defect (+ 1 investigated, not a defect) + 6 orphaned features | Low | Ready to execute |
| 2.2 | Foundations: Offline Writes and Localization Infrastructure | SyncQueue activation, String Catalog migration | Medium (data layer) | Needs own plan |
| 2.3 | Multi-User Foundation | Custom zone, `CKShare`, universal links, subscriptions and push | High (data layer + web dependency) | Needs own plan |
| 2.4 | Wrist and Glance | watchOS app, interactive widgets, Controls, Live Activity buttons | Medium (new targets) | Needs own plan |
| 2.5 | Signals | HealthKit background delivery, cycle write-back, heart-rate resolution, honest energy, deeper onboarding | Medium (privacy surface) | Needs own plan |
| 2.6 | Reach and Moat | Translated languages, Spotlight and Handoff, cycle variant modes, phase forecast | Low to medium | Needs own plan |

Rationale for the order: 2.1 is pure payoff with no architecture. 2.2 makes writes durable before new surfaces multiply write paths. 2.3 unblocks the already-approved buddy and group roadmap, which is otherwise structurally impossible. 2.4 depends on 2.2 for reliable offline logging on a watch. 2.5 and 2.6 are independent and may be reordered by market priority.

---

# Release 2.1: Wire the Dark Matter

**Outcome:** Two shipped defects are fixed and six built-and-tested capabilities become reachable by users. No new architecture, no new record types, no schema changes.

**Why first:** Every item is verified dead or broken code with tests already in place. This is the highest value-per-line work in the repository and it can ship as a fast point release.

## Task 1.1: Replace the Dashboard placeholder destination

**Defect.** A literal `Text("Workout Detail")` is the navigation destination on the Today tab.

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` (line 807)
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/DashboardViewModelTests.swift`

- [ ] **Step 1: Identify the correct destination**

`viewModel.nextWorkout` is a display string at this point. Determine whether the underlying model is reachable on the view model; if only a name is published, add the workout identity alongside it rather than re-fetching in the view.

- [ ] **Step 2: Route to the real destination**

Navigate to the same destination the Train tab uses for a scheduled session (`WorkoutDetailView`, or `ActiveWorkoutView` if the intent is to start immediately). Match the surrounding navigation idiom in `DashboardView`; do not introduce a new navigation pattern.

- [ ] **Step 3: Cover the published identity**

Add a view-model test asserting that when a next workout exists the published value carries enough identity to navigate, and that the no-workout branch still yields the "No workout scheduled" state.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter DashboardViewModelTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
fix(dashboard): route Start This Workout to the real destination
```

## Task 1.2: Restore the App Store review prompt — CLOSED, NOT A DEFECT

**Original claim (wrong):** `ReviewPromptCoordinator.recordSuccessfulAction` was believed to have zero callers, making the App Store review prompt unreachable.

**Investigation finding (2026-08-30):** the claim was based on grepping for the wrong symbol (`ReviewPromptEligibilityService`, a type used only internally by the coordinator) instead of the type actually referenced at call sites (`ReviewPromptCoordinator`). Re-grepping for `ReviewPromptCoordinator` and `recordSuccessfulAction` directly found the system fully wired:

- `ActiveWorkoutSessionViewModel.swift:459` calls `requestReviewIfEligible()` unconditionally at the end of every workout completion.
- `requestReviewIfEligible()` (`ActiveWorkoutSessionViewModel.swift:719-745`) builds and evaluates triggers for `thirdWorkoutCompleted`, `firstCoachPlanCompleted` (gated on `isCoachPlanWorkout`), `painAwareSwapWorkoutCompleted` (gated on `usedPainAwareSwap`), and one `personalRecordLogged` trigger per PR in `personalRecordExerciseNames`.
- `BenchmarksListView.swift:619-624` calls the coordinator directly for `benchmarkLogged` after a successful `saveResult`.
- `SundeeFundeeApp.swift:83-84` observes `.appReviewPromptRequested` and calls the SwiftUI `requestReview()` environment action; the notification name is declared at `SundeeFundeeApp.swift:115`.

All five `ReviewPromptTrigger` cases are covered end to end. **No code change was made.** This task is retained, closed, as a record of the investigation rather than deleted, so the correction is traceable — see the corrected row 1 of Verified Current State above.

**Lesson applied to the rest of this plan:** before treating any "has zero callers" claim as ground truth, grep for every plausible name a call site could use — including wrapper or coordinator types — not just the type that defines the behavior.

## Task 1.3: Add the experience level picker

**Outcome:** Users can state their experience level, so starting-weight guidance stops treating every lifter as intermediate.

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/OnboardingViewModelTests.swift`

- [ ] **Step 1: Add the Settings picker**

Add a `Picker` for `ExperienceLevel` in the Training section of `SettingsView`, adjacent to the existing goal picker (around line 41). The `@Published var experienceLevel` and its persistence into `UserSettingsRecord` already exist — this is UI only.

- [ ] **Step 2: Add the onboarding control**

Add experience level to the preferences step of `OnboardingView`. Match the existing control idiom: the goal selector uses `goalPickerButton` cards while unit and equipment use `Picker`. Prefer the card idiom if experience level deserves description text, since a beginner benefits from knowing what the choice changes.

- [ ] **Step 3: Reconcile the default mismatch**

`OnboardingViewModel` and `SettingsViewModel` default to `.intermediate` (`OnboardingView.swift:306`, `SettingsView.swift:362`), but fallback paths in `ActiveWorkoutSessionViewModel.swift:558` and `DashboardView.swift:1575` default to `.beginner`. Pick one default, apply it everywhere, and state the choice in the commit body. Conservative starting loads argue for `.beginner`.

- [ ] **Step 4: Verify and commit**

```bash
cd SundeeFundee && swift test --filter OnboardingViewModelTests
cd SundeeFundee && swift test --filter StartingWeightCalibrationServiceTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
feat(settings): let users set their experience level
```

## Task 1.4: Surface the plate calculator

**Outcome:** During a barbell set, the app shows the plates to load per side.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/PlateBreakdownView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/Exports.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/PlateBreakdownViewTests.swift`

- [ ] **Step 1: Add a bar weight setting**

`calculatePlates(targetWeight:barWeight:)` defaults `barWeight` to 45. Add a bar weight preference to the Training section of Settings so kilogram users and users on a 35 lb or training bar are not silently given wrong math. Persist it as an additive optional field on `UserSettingsRecord` with a backwards-compatible decode; do not use a reserved CloudKit field name.

- [ ] **Step 2: Build the breakdown view**

Render the plate list from `calculatePlates` using `AppTheme` tokens. Show per-side plates. Handle the cases the calculator cannot satisfy exactly — display the achievable weight and the remainder rather than silently rounding.

- [ ] **Step 3: Gate it to barbell movements**

Only show the breakdown for exercises whose equipment tags include a barbell. Use the existing `TrainingExerciseDefinition.equipmentTags` vocabulary; do not string-match exercise names.

- [ ] **Step 4: Respect units**

`calculatePlates` assumes a plate inventory. Confirm which unit its plate set represents and convert through `UnitConverter` when the user's `weightUnit` is kilograms. If the calculator is pounds-only, either add a kilogram plate set or hide the breakdown for kilogram users and record that limitation in the commit body. Do not display pound plates to a kilogram user.

- [ ] **Step 5: Update the export doc comment**

`Exports.swift:40` documents the function as available; keep it accurate.

- [ ] **Step 6: Verify and commit**

```bash
cd SundeeFundee && swift test --filter PlateCalculatorTests
cd SundeeFundee && swift test --filter PlateBreakdownViewTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
feat(workouts): show plate breakdown during barbell sets
```

## Task 1.5: Chart readiness over time

**Outcome:** Readiness history, already persisted, becomes visible as a trend.

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/ReadinessTrendChart.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AnalyticsViewModel.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ReadinessTrendAggregationTests.swift`

- [ ] **Step 1: Aggregate readiness history**

Fetch `DailyReadinessRecord` history and aggregate through the existing `ChartDataAggregator.TimeRange` vocabulary (month, 3 months, 6 months, year, all time) so the range selector stays consistent across charts.

- [ ] **Step 2: Represent confidence honestly**

`readiness-v1` carries a confidence value and a `presentInputCount`. Low-confidence days must be visually distinguishable — reduced opacity, an unfilled point, or exclusion with a footnote. Do not plot a low-confidence score identically to a high-confidence one; that overstates precision the model does not claim.

- [ ] **Step 3: Band the states**

Use `AppTheme.Recovery.*` tokens to band ready / maintain / recover / rest so the chart reads at a glance. Do not hardcode colors.

- [ ] **Step 4: Handle the empty and sparse cases**

Fewer than roughly 7 days of history should show guidance to keep checking in rather than a near-empty chart. Follow the `MinimalSurfacePolicy` progressive-disclosure convention already used elsewhere.

- [ ] **Step 5: Verify and commit**

```bash
cd SundeeFundee && swift test --filter ReadinessTrendAggregationTests
cd SundeeFundee && swift test --filter ChartDataAggregatorTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```
feat(analytics): chart readiness history
```

## Task 1.6: Ship a readiness widget

**Outcome:** Today's readiness state is glanceable from the Home Screen and Lock Screen.

**Files:**
- Create: `SundeeFundeeApp/SundeeFundeeWidgets/ReadinessWidget.swift`
- Modify: `SundeeFundeeApp/SundeeFundeeWidgets/` widget bundle declaration
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/DeepLinkRouter.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/DeepLinkRouterTests.swift` (extend existing)

- [ ] **Step 1: Read the existing snapshot**

`SharedSnapshotStore.writeReadiness` already publishes `DailyReadinessSnapshot` to the app group `group.com.sundeefundee.shared`. Read it; do not recompute readiness in the widget process and do not add HealthKit access to the extension.

- [ ] **Step 2: Support the families**

Provide `.systemSmall`, `.accessoryCircular`, and `.accessoryRectangular`. The rectangular family is where state plus a short reason fits, and the app currently ships no rectangular widget.

- [ ] **Step 3: Handle stale and absent data**

A snapshot older than today must render as stale with a prompt to open the app, never as a confident stale score. Mirror the stale handling already exercised by the manual QA gate for existing widgets.

- [ ] **Step 4: Add a deep link route**

`DeepLinkRouter` currently handles 2 routes. Add a readiness route so tapping the widget lands on the readiness detail rather than a generic tab, and extend `DeepLinkRouterTests`.

- [ ] **Step 5: Verify and commit**

```bash
cd SundeeFundee && swift test --filter DeepLinkRouterTests
cd SundeeFundeeApp && xcodegen generate
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Manual check: add the widget, confirm each family renders, confirm the stale path, confirm the deep link.

```
feat(widgets): add a readiness widget
```

## Task 1.7: Surface challenge reactions — PARTIALLY SCOPED DOWN DURING EXECUTION

**Original outcome:** The reaction and progress-snapshot models that already persist become visible in the challenge UI.

**What execution found (2026-08-30):** the premise was more incomplete than assumed, in two ways beyond the private-vs-public correction already recorded in Verified Current State row 6:

1. `SocialChallengeService` already saves to a **public** database and already queries cross-user by token (`fetchInvite(token:)`), so reactions and progress snapshots for a given invite are not structurally stuck in one user's private data the way the original Step 2 assumed.
2. But **no screen persists the invite token anywhere durable.** `ChallengeInviteShareLink.prepareInvite()` calls `createInvite` fresh every time the view appears and only keeps the resulting token in a local `@State` string used to build share text — it is never written onto the local `Challenge`. On the joining side, `JoinChallengeView`'s callback (`ChallengesView.swift:73`) passes only the `ChallengeShareTemplate` forward into `CreateChallengeView`, dropping the token entirely. Because a fresh, unlinked token is minted on every view load, there is no stable identifier to fetch reactions or progress *for* — building the display UI now would either show nothing (an ephemeral token has never been reacted to) or require adding a persisted `Challenge.inviteToken` field and rewiring both the share and join flows to set it, which is materially more than "surface an existing method."

**Decision:** ship the missing read half of the service — the part that genuinely is just wiring an orphaned save method — and leave the UI and the token-persistence prerequisite as follow-up work, tracked below rather than folded into this task.

**Done:**
- Added `SocialChallengeService.fetchReactions(inviteToken:)` and `fetchProgressSnapshots(inviteToken:)`, mirroring `fetchInvite(token:)`'s existing query-by-token pattern.
- Added `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/SocialChallengeServiceReadTests.swift` (this service had no test file at all before).
- Documented `ChallengeInvite`, `ChallengeParticipant`, `ChallengeReaction`, and `SocialChallengeProgressSnapshot` in `SundeeFundeeApp/cloudkit-schema.json` — none were present there, and their live CloudKit deployment status is unverified (the schema file is known to drift from the live schema; see `UserSettings.defaultEquipmentRaw`, also undocumented until this same session added `barWeight` in Task 1.4). **Do not trust `fetchReactions`/`fetchProgressSnapshots` to return real data in production without confirming these record types are actually deployed** (CloudKit Dashboard, or the `cloudkit-validate` skill).

**Not done, follow-up work:** add `inviteToken: String?` to `Challenge` (additive, CloudKit-safe), set it in `ChallengeInviteShareLink.prepareInvite()` and thread it through `JoinChallengeView`'s callback into `CreateChallengeView`, then add read-only reaction/progress display gated on `challenge.inviteToken != nil`. This is genuinely new plumbing, not orphaned-code wiring, so it belongs in a release with room to design it properly — it fits naturally alongside Release 2.3's multi-user work, or as its own small slice of 2.2/2.3 planning.

```bash
cd SundeeFundee && swift test --filter SocialChallengeServiceReadTests
```

```
feat(challenges): add the missing read half of social challenge data
```

## Task 1.8: Release verification

- [ ] **Step 1: Full gate**

```bash
cd SundeeFundee && swift test
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
swiftlint --config .swiftlint.yml
```

- [ ] **Step 2: Work `docs/release/next-release-gate.md`**

Including the light and dark passes, Dynamic Type, VoiceOver on icon-only actions, and the HealthKit-denied path.

- [ ] **Step 3: Update the changelog and release notes**

Modify `CHANGELOG.md` under Unreleased and `SundeeFundeeApp/fastlane/metadata/en-US/release_notes.txt`. Describe user-visible outcomes, not internal wiring.

- [ ] **Step 4: Do not submit.** Version bump only if the user asks.

---

# Release 2.2: Foundations — Offline Writes and Localization Infrastructure

**Gate: write `docs/superpowers/plans/<date>-offline-and-localization-foundation.md` before implementing.**

**Outcome:** CloudKit mutations survive being offline, and the codebase is ready to be translated.

## 2.2a: Activate the SyncQueue — IMPLEMENTED (2026-08-30), see `2026-08-30-syncqueue-activation.md`

`SyncQueue`, `PendingMutation`, and `NetworkMonitor` exist under `DataLayer/SyncQueue/`, are covered by `SyncQueueTests` and `SyncQueueStuckTests`, implement stuck-mutation handling after `maxRetryAttempts`, and have a replay path in `CloudKitClient.saveFromJSON` (line 410). `DataClientFactory` never constructs one. The prior 2.0 plan listed offline queue activation as its own pre-release gate; it was never executed.

Implemented as its own sub-plan (`2026-08-30-syncqueue-activation.md`) rather than inline here, since it needed real design work: `DataClientFactory.activate()` now wraps a `CloudKitClient` in a `SyncQueue` scoped to a per-`ownerID` `UserDefaults` suite (never `LocalDataClient`, and without touching `AuthViewModel`, whose `destinationClientFactory` closure has no `ownerID` parameter to scope by). The per-owner scoping is the load-bearing decision — a single shared queue store would replay one account's offline mutations into a different account that signs in on the same device before the first account reconnects. Also wires `SyncQueueDiagnosticsService.shared.attach(_:)`, which had no caller, so `DataTrustCenterView`'s sync section starts reflecting real state. Not yet exercised against a real device/simulator in airplane mode — that verification is the user's to run.

2.2b (String Catalog / localization) is unrelated in kind and scale to 2.2a and remains a separate, not-yet-started effort — everything below this point is as originally planned, unchanged by 2.2a's completion.

Key work and decisions for the plan document:

- Wire a `SyncQueue` into `DataClientFactory` and call `SyncQueueDiagnosticsService.shared.attach(_:)` so the existing sync UI in `DataTrustCenterView` and `ActiveWorkoutView` starts reflecting real state.
- **Decide the ordering guarantee.** Replaying mutations out of order can resurrect deleted records or apply a stale settings write over a newer one. `CloudKitClient` already has `serverRecordChanged` merge handlers for presence and reminder settings; confirm every queued record type either has a merge policy or is safe to replay last-write-wins.
- **Decide guest and account-switch behavior.** A queue must not replay one account's mutations into another after sign-in. `GuestDataMigrator` runs before the factory swap; the queue must be drained or scoped to the session it was created in.
- Bound queue growth and surface stuck mutations to the user as actionable copy.
- Verify the replay path end to end in the simulator with airplane mode, not only in unit tests.

**Risk:** This changes the write path for every CloudKit mutation in the app. It deserves its own release and its own soak period.

## 2.2b: Adopt the String Catalog

Add a `.xcstrings` catalog and migrate existing user-facing strings. Translation is deferred to 2.6; the point of doing the migration now is that Releases 2.3 through 2.5 add substantial new copy across social, watch, and Health surfaces, and retrofitting those later costs more than authoring them correctly.

Note the scale honestly: user-facing copy is spread across very large view files (`DashboardView` ~1600 lines, `ProgramsListView` ~1879, `AIWorkoutView` ~1358) plus the coach copy templates in `DomainLayer/Coach/`. Coach copy is generated from `CoachCopyTemplates` with a validator and fallback, so templated sentence assembly needs a localization strategy that does not assume English word order. Treat coach copy as its own sub-task, not an afterthought.

---

# Release 2.3: Multi-User Foundation

**Gate: write `docs/superpowers/plans/<date>-multi-user-foundation.md` before implementing.**

**Outcome:** A second person can actually receive an invite, see a buddy's check-in, and be notified about it.

**The blocking constraint:** finding 7. All records live in the private default zone, and `CKShare` cannot share default-zone records. This is the single largest piece of unspecified work in the roadmap, and it is why the approved buddy and group plans (plans 2 through 4 of the daily-presence sequence) could not have shipped as written.

Key work and decisions for the plan document:

- **Introduce one custom record zone for shareable social records only.** Per cross-cutting decision 2, do not migrate personal training data. `CloudKitClient` currently takes a `databaseScope` but has no zone concept; adding zone awareness touches the save, fetch, and delete paths and the `saveFromJSON` replay path that Release 2.2 activates. **Sequence 2.2 before 2.3** so the queue is not rewritten twice.
- Add `CKShare` creation and acceptance, including the `CKSharingSupported` Info.plist key and scene-delegate acceptance handling.
- Decide what a participant may read. The privacy design says sensitive context is private by default; `ShareSanitizedSummary` and `SharePrivacyOptions` already exist for share cards and should govern shared records too.
- Replace the paste-an-8-character-code flow with universal links. This requires the `com.apple.developer.associated-domains` entitlement and an `apple-app-site-association` file hosted on sundeefundee.com. **That is a dependency outside this repository** — confirm web access before committing to the release.
- Add `CKDatabaseSubscription` on the shared database plus APNs. This needs `aps-environment` in the entitlements, the remote-notification background mode, and push registration, none of which exist today.
- Decide guest behavior explicitly: social requires Apple Sign-In, and the invite surfaces must degrade honestly for guests rather than failing at the last step.

**Risk:** High. Zone-aware persistence, a new sharing lifecycle, an external web dependency, and a first-ever push implementation. Consider splitting into 2.3a (zone and share plumbing, buddies only) and 2.3b (links, push, groups).

---

# Release 2.4: Wrist and Glance

**Gate: write `docs/superpowers/plans/<date>-watch-and-glance.md` before implementing.**

**Outcome:** Sets can be logged from the wrist, and the existing widgets and Live Activity become interactive.

Key work and decisions for the plan document:

- **Add a watchOS target.** `Package.swift` already declares `.watchOS(.v11)` and views carry watchOS availability annotations, so the domain layer is ready; `project.yml` needs the target and `xcodegen generate` must be re-run. Audit which Kit types actually compile for watchOS — the declaration is not proof.
- Scope the watch app to the between-sets loop: log a set, run the rest timer with wrist haptics, glance at readiness. Do not port program browsing or analytics.
- **Decide the watch sync mechanism.** `WatchConnectivity` for a paired session versus CloudKit for independence. The Live Activity state in `Activity/LiveWorkoutActivityAttributes.swift` already models current set, next-up, rest timer, and progress — it is close to the right shape for a watch session payload. Offline write durability from 2.2 matters here.
- Add interactive widgets and a Control Center control. `StartWorkoutIntent` and `LogWorkoutSetIntent` already exist under `Intents/`, so the App Intent surface for a button or `ControlWidget` is largely in place; the widgets are currently plain `TimelineProvider` with no interactivity or configuration.
- Add Live Activity buttons for the common in-session actions.
- Note the current test gap: the widget extension and `LiveWorkoutActivityManager` have no tests. Add coverage as part of this release rather than expanding untested surface.

---

# Release 2.5: Signals

**Gate: write `docs/superpowers/plans/<date>-health-signals.md` before implementing.**

**Outcome:** Readiness is fresh before the user opens the app, Health integration is two-way and honest, and onboarding collects what the intelligence layer needs.

Key work and decisions for the plan document:

- **HealthKit background delivery.** Add `HKObserverQuery` and `HKAnchoredObjectQuery` with `enableBackgroundDelivery` so overnight sleep and HRV produce a readiness assessment before waking, feeding the morning widget from Release 2.1. Pair with a `BGAppRefreshTask`. Requires the background-modes capability.
- **Resolve the heart-rate permission.** `heartRate` read access is requested but never queried (`HealthKitClient.swift:411`). Either use it or remove it. Requesting unused health permissions is a privacy smell and an App Review risk. If used, it also fixes the next item.
- **Make workout energy honest.** `ActiveWorkoutSessionViewModel.swift:435` writes workouts to Health with energy estimated as `completedSets * 6.0` kcal. That number is fabricated and lands in the user's permanent Health record. Either derive it from heart rate, or stop writing an energy sample. Also note the save currently fails silently as "non-critical" — surface repeated failures in Diagnostics.
- **Cycle write-back.** The app reads `menstrualFlow` but never writes, so manual period logs fork away from the Health ecosystem. Add opt-in write-back with explicit consent. This needs a `HKCategoryType` write authorization the app does not currently request, and the merge logic in `CyclePhaseCache` (which dedupes manual and HealthKit logs within 24 hours) must not create a write-read feedback loop.
- **Deepen onboarding.** Currently two steps with no HealthKit prompt, no cycle setup, and no starting maxes — all inputs the readiness and calibration engines want on day one. Add progressive steps that remain fully skippable, and keep guest mode whole. This depends on the experience-level picker from Task 1.3.

---

# Release 2.6: Reach and Moat

**Gate: write `docs/superpowers/plans/<date>-reach-and-moat.md` before implementing.**

**Outcome:** The app opens new storefronts and serves cycle situations it currently ignores.

Key work and decisions for the plan document:

- **Ship translated languages** on the String Catalog foundation from 2.2. Suggested first set: German, French, Spanish, Portuguese. Localize App Store metadata alongside the app, since discovery is the point. Verify Dynamic Type layouts survive longer German strings.
- **Cycle variant modes.** Add irregular-cycle, hormonal-birth-control, and perimenopause handling. This is mostly routing and copy rather than new science: `ReadinessAssessmentService` already treats cycle phase as context rather than an automatic penalty, `CycleAdaptationPolicy` already resolves confidence, and `CycleConfidenceExplainer` already produces low-confidence copy. A user on hormonal birth control should get symptom-and-readiness-first guidance with phase prediction suppressed rather than low-confidence phase estimates presented as if meaningful. This widens the addressable audience and is genuinely rare among competitors.
- **Phase forecast on Today.** A forward-looking 7-day strip turning the existing cycle engine from explanatory into anticipatory ("luteal starts Thursday — heavy sessions fit best Monday through Wednesday"). `CycleCalendar` already computes phase-for-day with wraparound and `WeeklyPlanService` already does cycle-aware planning; this is a presentation layer over both. Gate it on phase confidence and suppress it entirely in the variant modes above where prediction is not meaningful.
- **Spotlight and Handoff.** Index exercises, programs, and benchmarks with `CSSearchableItem`; add `NSUserActivity` for continuity. Cheap surface area, currently zero usage.

---

## Risks and Watch Items

1. **Release 2.3 is the schedule risk.** Zone-aware persistence, sharing lifecycle, push, and an external web dependency in one release. Split it if the plan document exceeds roughly 1200 lines.
2. **2.2 must precede 2.3.** Activating the sync queue after adding zone awareness means rewriting the replay path twice.
3. **Untested surfaces are expanding.** The widget extension, Live Activity manager, notification delegate, and Swift Charts views have no tests today, and Releases 2.1, 2.4, and 2.5 all add to exactly those surfaces. Add coverage with each new surface.
4. **The largest view files keep growing.** `ProgramsListView` at ~1879 lines and `DashboardView` at ~1608 already resist testing, and several tasks here add to `DashboardView`. Consider extracting sections as a refactor of opportunity, with no behavior change, when a task touches them.
5. **CloudKit schema deployment is a manual gate.** Any new record type needs a queryable index in Development and a deploy to Production, or `fetchAll` throws `schemaNotDeployed`. Release 2.1 adds no record types by design; 2.2 and 2.3 do.
6. **Do not let honesty regress under feature pressure.** Two items in this roadmap exist because a surface claimed more than it knew — a fabricated energy value and a permission requested but unused. New surfaces, particularly the readiness widget and the phase forecast, must degrade to "not enough data" rather than displaying confident-looking output.

## Final Acceptance Criteria

- No placeholder destinations or unreachable success paths remain in shipped UI.
- The App Store review prompt fires on genuine training wins, subject to unchanged eligibility rules.
- Experience level, bar weight, and plate math are user-controllable and correct in both units.
- Readiness is visible as a trend in the app and as a glance on the Home and Lock Screens, with confidence represented honestly.
- CloudKit mutations made offline are durable and replay in a defined order, with stuck mutations surfaced actionably.
- A second person can receive an invite through a link, read what was deliberately shared with them, and be notified — with sensitive context private by default.
- A set can be logged from the wrist, and the rest timer runs there.
- Readiness is current when the user first looks at it each morning, without opening the app.
- Nothing written to Apple Health is fabricated, and no health permission is requested without being used.
- The app is usable in at least four languages, with App Store metadata to match.
- Users with irregular cycles, on hormonal birth control, or in perimenopause receive guidance that does not depend on phase predictions the app cannot make.
- Guest mode remains fully functional for everything except features that inherently require another person.
- All features remain free.

# Next Release 20-Item Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all 20 static-review recommendations as one phased release program, with each phase independently testable and safe to pause.

**Architecture:** Treat stale review findings as verification tasks and active gaps as scoped implementation tasks. Keep deterministic domain services as the source of training decisions, add small persistence records for feedback/preferences/check-ins, and route UI through view models so SwiftUI changes stay thin. Use `AppTheme.*` tokens only for app UI colors and keep all new tracking metadata privacy-safe.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, CloudKit/local `DataClientProtocol`, HealthKit, StoreKit 2, XCTest/Swift Testing, XcodeGen, Fastlane metadata.

---

## Source Docs

- Design spec: `docs/superpowers/specs/2026-06-30-next-release-20-phase-design.md`
- Static review attachment: `/Users/dustinober/.codex/attachments/7dd9741a-5056-47ed-9d82-1bab67203281/pasted-text.txt`
- Existing UX audit: `docs/superpowers/specs/audit/ux-findings.md`
- Existing perf audit: `docs/superpowers/specs/audit/perf-findings.md`
- Existing code health audit: `docs/superpowers/specs/audit/code-health-findings.md`
- Support tip plan: `docs/superpowers/plans/2026-06-13-repeatable-support-tip-and-release-polish.md`

## Execution Conventions

- Working directory: `/Users/dustinober/Projects/sundee-fundee/sundee-fundee-ios`
- Branch: `main`, unless the user requests a feature branch.
- Use one commit per touched file when practical. When two files are a test/implementation pair that only compile together, commit them together.
- Per `AGENTS.md`, delegate routine git staging/commits to a Haiku subagent when that tool/model is available. Tell it exact files, exact commit message, current branch, and: never `git add .` or `git add -A`, never amend, never force-push, stop on unexpected state.
- Do not upload, submit, or build for App Store review unless the user explicitly asks.

## Status Vocabulary

Use these exact matrix statuses throughout this plan:

- `not started`
- `partial`
- `implemented-needs-verification`
- `implemented-needs-manual-qa`
- `done`
- `blocked`

Use `not started` and `partial` while work is still ahead. Use `implemented-needs-verification` when the code is in place and only review/QA remains. Use `implemented-needs-manual-qa` when code is in place, automated checks passed, and only simulator/manual validation remains. Use `done` only after the item is fully verified. Use `blocked` only for a real external blocker.

## Verification Commands

Run focused tests after each task, then broader verification at phase gates.

```bash
cd /Users/dustinober/Projects/sundee-fundee/sundee-fundee-ios/SundeeFundee && swift test
```

```bash
cd /Users/dustinober/Projects/sundee-fundee/sundee-fundee-ios/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

```bash
cd /Users/dustinober/Projects/sundee-fundee/sundee-fundee-ios && swiftlint --config .swiftlint.yml
```

---

## 20-Item Phase Map

| Static Review Item | Phase | Work Type |
|---|---:|---|
| 1. Dark mode headline fix | 1 | Implement and verify |
| 2. Formal contrast/accessibility audit gate | 1 | Implement checklist/script and verify |
| 3. Loading, error, and empty-state polish | 1 | Implement remaining gaps and verify landed fixes |
| 4. Haptics for meaningful moments | 1 | Verify landed haptics, add missing completion/check-in haptics |
| 5. Easy performance wins | 1 | Verify landed async fetch/share work, add regression notes |
| 6. Smooth share-card rendering | 1 | Verify landed async rendering and loading accessibility |
| 7. Activation funnel | 3 | Implement summary service and settings/debug surface |
| 8. Coach copy quality feedback | 2 | Implement metadata-only feedback |
| 9. Bigger "Why this workout?" trust feature | 2 | Implement trust badges |
| 10. Context-aware Best Next 20 Min | 2 | Implement context builder and Train wiring |
| 11. Learned Coach Plan quick edits | 2 | Implement today preference record/service |
| 12. Post-workout quick check-in | 2 | Implement optional completion check-in |
| 13. Progress discoverability | 4 | Implement preview/empty guidance |
| 14. Progressive onboarding | 3 | Implement prompt policy and point-of-use prompts |
| 15. Privacy and data-control messaging | 3 | Implement copy in onboarding/settings |
| 16. Support tip App Review safety | 5 | Verify StoreKit paths and metadata |
| 17. Widget freshness and deep links | 4 | Add app routes and widget URLs |
| 18. Stale developer docs | 5 | Update package and package README |
| 19. Code-health cleanup | 5 | Verify stale findings and clean remaining low-risk issues |
| 20. Release gate matching app risks | 5 | Add release QA runbook/script |

---

# Phase 0: Inventory and Truth Pass

### Task 0.1: Create the 20-Item Release Matrix

**Files:**
- Create: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Create the matrix document**

Create `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`:

```markdown
# Next Release 20-Item Matrix

| # | Recommendation | Status | Evidence | Phase | Verification |
|---:|---|---|---|---:|---|
| 1 | Make dark mode the headline fix | not started | `AppTheme.Semantic` still uses raw `Color.green/orange/red/blue`; button destructive state uses raw red | 1 | Dark/light screenshots and `AppThemeColorTests` |
| 2 | Add formal contrast and accessibility audit gate | not started | No release gate doc/script exists for dark mode, high contrast, Dynamic Type, VoiceOver, tap targets | 1 | Gate doc created in Phase 1 and checked off |
| 3 | Finish loading, error, and empty-state polish | partial | Benchmarks and Pain now have labels/empty states; remaining unlabeled button spinners exist in share/export/support/programs/AI surfaces | 1 | `scripts/audit-release-polish.sh` plus UI review |
| 4 | Add haptics to important moments | implemented-needs-verification | Haptics exist in active workout, PR/workout completion, challenges, share, settings, symptom check-in | 1 | Grep and simulator smoke test |
| 5 | Take easy performance wins | implemented-needs-verification | Benchmark fetches and share renderer already async; verify program/session paths | 1 | `swift test` and targeted code review |
| 6 | Smooth share-card rendering | implemented-needs-verification | `ShareCardRenderer.render` uses detached task with main-actor rendering | 1 | Share preview smoke test |
| 7 | Build activation funnel | not started | Growth events exist; no funnel service/surface | 3 | `ActivationFunnelServiceTests` |
| 8 | Add Coach Plan copy feedback | not started | No feedback record/service/UI | 2 | `CoachPlanFeedbackServiceTests` |
| 9 | Make "Why this workout?" bigger trust feature | partial | Reason codes/rationale exist; `TodayWhySheet` is plain text | 2 | `WorkoutTrustBadgeBuilderTests` and UI smoke |
| 10 | Make Best Next 20 Min context-aware | not started | `TrainHubView` hardcodes full-body, medium energy, full gym, no pain logs | 2 | `BestNextWorkoutRequestBuilderTests` |
| 11 | Let Coach Plan quick edits become learned preferences | partial | `EditableWorkoutDraft` and `PreferenceLearner` exist; no today preference persistence | 2 | `TodayWorkoutPreferenceServiceTests` |
| 12 | Close loop after workouts with quick check-in | partial | Set RPE exists; no completion check-in record/sheet | 2 | `WorkoutCompletionCheckInViewModelTests` |
| 13 | Improve Progress feature discoverability | not started | `ProgressHubView` hides destinations when empty except export/monthly review | 4 | `ProgressGuidanceServiceTests` |
| 14 | Make onboarding progressive | partial | Onboarding is short; prompts are not point-of-use policy driven | 3 | `ProgressivePromptPolicyTests` |
| 15 | Surface privacy/data-control messaging | partial | Data Trust Center exists; onboarding/settings copy can be clearer | 3 | UI text smoke and data trust screenshot |
| 16 | Keep support tip App Review-safe | implemented-needs-verification | StoreKit/product/tests exist | 5 | StoreKit path rehearsal |
| 17 | Polish widgets with freshness and deep links | partial | Freshness text exists; no `widgetURL` or app route handler | 4 | `DeepLinkRouterTests` and widget smoke |
| 18 | Clean up stale developer docs | not started | `SundeeFundee/README.md` and `Package.swift` comments are stale | 5 | Doc diff review |
| 19 | Small code-health cleanup pass | partial | Some old findings already fixed; verify `MaxRow`, `setsCount`, and lint | 5 | `rg` checks and SwiftLint |
| 20 | Create final release gate | not started | No single runbook/script covers full risk list | 5 | Gate doc created in Phase 5 and checked off |
```

- [ ] **Step 2: Commit**

Commit message:

```bash
docs(release): add next release tracking matrix
```

### Task 0.2: Add a Repeatable Polish Audit Script

**Files:**
- Create: `scripts/audit-release-polish.sh`

- [ ] **Step 1: Create the script**

Run:

```bash
mkdir -p scripts
```

Create `scripts/audit-release-polish.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Hardcoded UI colors =="
rg -n 'Color\.(red|orange|green|blue|yellow|purple|pink|gray|black|white)' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== User-facing localizedDescription candidates =="
rg -n 'localizedDescription' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundee || true

echo ""
echo "== Bare ProgressView candidates =="
rg -n 'ProgressView\(\)' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== Fixed-size app UI font candidates =="
rg -n '\.font\(\.system\(size:' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== Haptic call sites =="
rg -n 'HapticFeedback\.' \
  SundeeFundee/Sources/SundeeFundeeKit/UI || true
```

- [ ] **Step 2: Make it executable**

Run:

```bash
chmod +x scripts/audit-release-polish.sh
```

- [ ] **Step 3: Run it and paste summary into the matrix**

Run:

```bash
./scripts/audit-release-polish.sh
```

Expected: script exits `0` and prints candidate lists. Update the matrix `Evidence` column only for items whose status changes.

- [ ] **Step 4: Commit**

Commit message:

```bash
chore(release): add polish audit helper
```

---

# Phase 1: Release Quality Foundation

### Task 1.1: Harden Adaptive Theme Tokens for Dark Mode

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/AppThemeColorTests.swift`

- [ ] **Step 1: Add failing adaptive semantic color tests**

Append to `AppThemeColorTests` inside `AppThemeColorTests`:

```swift
    @Test("Semantic colors resolve differently in dark appearance")
    func semanticColorsAdaptToDarkAppearance() {
        let pairs: [(Color, String)] = [
            (AppTheme.Semantic.success, "success"),
            (AppTheme.Semantic.warning, "warning"),
            (AppTheme.Semantic.error, "error"),
            (AppTheme.Semantic.info, "info")
        ]

        for (color, name) in pairs {
            let light = resolvedRGBA(color, appearance: .aqua)
            let dark = resolvedRGBA(color, appearance: .darkAqua)
            #expect(light != dark, "\(name) should adapt between appearances")
        }
    }

    @Test("Theme shadow resolves stronger in dark appearance")
    func shadowTokenAdaptsToDarkAppearance() {
        let light = resolvedRGBA(AppTheme.Shadow.subtle, appearance: .aqua)
        let dark = resolvedRGBA(AppTheme.Shadow.subtle, appearance: .darkAqua)

        #expect(dark.3 > light.3)
    }
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd SundeeFundee && swift test --filter AppThemeColorTests
```

Expected: compile failure because `AppTheme.Shadow` does not exist, or test failure because semantic colors are static.

- [ ] **Step 3: Add adaptive semantic and shadow tokens**

In `AppTheme.swift`, replace `Semantic` and add `Shadow` below it:

```swift
    public enum Semantic {
        public static let success = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.118, green: 0.525, blue: 0.263),
            dark: AppThemeColorToken(red: 0.333, green: 0.784, blue: 0.478)
        )
        public static let warning = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.702, green: 0.310, blue: 0.078),
            dark: AppThemeColorToken(red: 1.000, green: 0.627, blue: 0.286)
        )
        public static let error = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.740, green: 0.090, blue: 0.090),
            dark: AppThemeColorToken(red: 1.000, green: 0.404, blue: 0.404)
        )
        public static let info = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.086, green: 0.337, blue: 0.659),
            dark: AppThemeColorToken(red: 0.420, green: 0.678, blue: 1.000)
        )
    }

    public enum Shadow {
        public static let subtle = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0, green: 0, blue: 0, opacity: 0.05),
            dark: AppThemeColorToken(red: 0, green: 0, blue: 0, opacity: 0.30)
        )
    }
```

Replace all `Color.black.opacity(0.05)` shadows in `AppTheme.swift` with `AppTheme.Shadow.subtle`.

Replace the destructive button color in `ArtDecoButtonStyle.backgroundColor(for:)`:

```swift
        case .destructive:
            return isPressed ? AppTheme.Semantic.error.opacity(0.82) : AppTheme.Semantic.error
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter AppThemeColorTests
```

Expected: all `AppThemeColorTests` pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
fix(theme): adapt semantic colors for dark mode
```

### Task 1.2: Clean Remaining Loading and Accessibility Candidates

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Export/ExportView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SupportDeveloperSection.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Update ShareCard preview loading accessibility**

In `ShareCardSheet.previewArea`, replace the bare progress block:

```swift
            } else {
                ProgressView("Rendering share card preview…")
                    .frame(height: 320)
                    .accessibilityLabel("Rendering share card preview")
            }
```

- [ ] **Step 2: Update Export button spinner accessibility**

In `ExportView.exportSection`, change the spinner:

```swift
                    if viewModel.isExporting {
                        ProgressView()
                            .padding(.trailing, AppTheme.Spacing.sm)
                            .accessibilityLabel("Exporting data")
                    }
```

- [ ] **Step 3: Update Support tip purchasing spinner accessibility**

In `SupportDeveloperSection`, change the purchasing spinner:

```swift
                    if viewModel.state == .purchasing {
                        ProgressView()
                            .accessibilityLabel("Sending support tip")
                    }
```

- [ ] **Step 4: Update Coach Plan generating spinner accessibility**

In `AIWorkoutView.generatingView`, change the spinner:

```swift
            ProgressView("Building your Coach Plan…")
                .scaleEffect(1.5)
                .tint(AppTheme.Accent.gold)
                .accessibilityLabel("Building your Coach Plan")
```

- [ ] **Step 5: Run the audit script**

Run:

```bash
./scripts/audit-release-polish.sh
```

Expected: bare `ProgressView()` candidates are either removed or limited to button spinners with explicit accessibility labels.

- [ ] **Step 6: Update matrix statuses**

Set item #3 to `implemented-needs-verification` and add the evidence:

```markdown
Benchmarks/Pain empty states exist; remaining button and share preview spinners now have labels/accessibility labels.
```

- [ ] **Step 7: Commit**

Commit message:

```bash
fix(ui): label remaining loading indicators
```

### Task 1.3: Create the Dark Mode and Accessibility Release Gate

**Files:**
- Create: `docs/release/dark-mode-accessibility-gate.md`

- [ ] **Step 1: Create the gate document**

Run:

```bash
mkdir -p docs/release
```

Create `docs/release/dark-mode-accessibility-gate.md`:

```markdown
# Dark Mode and Accessibility Gate

Run this gate before the next release branch is considered ready.

## Modes

- [ ] Light appearance
- [ ] Dark appearance
- [ ] Increased contrast enabled when available
- [ ] Dynamic Type: default
- [ ] Dynamic Type: Accessibility Large
- [ ] VoiceOver labels for icon-only actions

## Core Flows

- [ ] Auth and guest entry remain legible
- [ ] Onboarding text and controls fit at Accessibility Large
- [ ] Today screen cards, Why Today sheet, and Settings button are legible
- [ ] Train screen, Best Next 20 Min, Coach Plan questionnaire, and Coach Plan preview are legible
- [ ] Active workout set controls and workout options are legible
- [ ] Cycle screen, symptom check-in, cycle settings, and pain tracking are legible
- [ ] Progress screen, analytics, maxes, benchmarks, challenges, and export are legible
- [ ] Settings, Data Trust Center, Support the Developer, and What's New are legible
- [ ] Share card sheet preview and controls are legible
- [ ] Widgets show readable stale/no-data states

## Tap Targets

- [ ] Icon-only toolbar buttons have accessibility labels
- [ ] Primary actions have visible disabled/enabled states
- [ ] Toggle rows are usable with VoiceOver
- [ ] Segmented controls fit without truncating critical words

## Evidence

Capture screenshots or notes for:

- Today light and dark
- Train light and dark
- Active workout large text
- Cycle and Pain dark
- Progress empty/new-user state
- Settings Data Trust Center
- Share card sheet
- Cycle widget stale/no-data
```

- [ ] **Step 2: Commit**

Commit message:

```bash
docs(release): add dark mode accessibility gate
```

### Task 1.4: Verify Existing Performance, Haptics, and Share Rendering

**Files:**
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Verify benchmark and share rendering code paths**

Run:

```bash
rg -n "async let readinessTask|async let userResultsTask|Task.detached|ImageRenderer|HapticFeedback\\." SundeeFundee/Sources/SundeeFundeeKit
```

Expected:

```text
BenchmarksViewModel.swift includes async let readinessTask and async let userResultsTask
ShareCardRenderer.swift includes Task.detached and ImageRenderer
ActiveWorkoutSessionViewModel.swift and ActiveWorkoutView.swift include HapticFeedback calls
ShareCardSheet.swift includes HapticFeedback calls
ChallengesView.swift includes HapticFeedback calls
```

- [ ] **Step 2: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter ShareCardRendererTests
```

Run:

```bash
cd SundeeFundee && swift test --filter ActiveWorkoutSessionViewModelTests
```

Expected: both filtered runs pass.

- [ ] **Step 3: Update matrix statuses**

Set #4, #5, and #6 to `done` if the commands above match expectations and no new bug appears during simulator QA.

- [ ] **Step 4: Commit**

Commit message:

```bash
docs(release): mark landed quality wins verified
```

---

# Phase 2: Training Trust and Personalization

### Task 2.1: Add Metadata-Only Coach Plan Feedback

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/CoachPlanFeedback.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/CoachPlanFeedbackService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/CoachPlanFeedbackServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`

- [ ] **Step 1: Write failing service tests**

Create `CoachPlanFeedbackServiceTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class CoachPlanFeedbackServiceTests: XCTestCase {
    func testSubmitSavesMetadataOnlyFeedback() async throws {
        let client = MockCloudKitClient()
        let service = CoachPlanFeedbackService(dataClient: client)

        try await service.submit(
            rating: .helpful,
            surface: "coach_plan_preview",
            workoutID: "workout-1",
            copySource: "deterministic_fallback",
            promptVersion: "v1",
            reasonCodes: ["lowEnergyReducedVolume", "equipmentLimitedExercisePool"]
        )

        let records: [CoachPlanFeedbackRecord] = try await client.fetchAll(recordType: "CoachPlanFeedback")
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.ratingRaw, "helpful")
        XCTAssertEqual(records.first?.surface, "coach_plan_preview")
        XCTAssertEqual(records.first?.copySource, "deterministic_fallback")
        XCTAssertEqual(records.first?.promptVersion, "v1")
        XCTAssertEqual(records.first?.reasonCodesJSON, "[\"lowEnergyReducedVolume\",\"equipmentLimitedExercisePool\"]")
        XCTAssertNil(records.first?.rawPrompt)
        XCTAssertNil(records.first?.rawOutput)
    }
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd SundeeFundee && swift test --filter CoachPlanFeedbackServiceTests
```

Expected: compile failure because the record and service do not exist.

- [ ] **Step 3: Add the pure feedback model**

Create `CoachPlanFeedback.swift`:

```swift
import Foundation

public enum CoachPlanFeedbackRating: String, Codable, Sendable, Equatable {
    case helpful
    case notHelpful
}

public struct CoachPlanFeedbackRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let ratingRaw: String
    public let surface: String
    public let workoutID: String?
    public let copySource: String
    public let promptVersion: String
    public let reasonCodesJSON: String?
    public let dateCreated: Date

    public var rawPrompt: String? { nil }
    public var rawOutput: String? { nil }

    public init(
        id: String = UUID().uuidString,
        rating: CoachPlanFeedbackRating,
        surface: String,
        workoutID: String?,
        copySource: String,
        promptVersion: String,
        reasonCodesJSON: String?,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.ratingRaw = rating.rawValue
        self.surface = surface
        self.workoutID = workoutID
        self.copySource = copySource
        self.promptVersion = promptVersion
        self.reasonCodesJSON = reasonCodesJSON
        self.dateCreated = dateCreated
    }
}
```

- [ ] **Step 4: Add the feedback service**

Create `CoachPlanFeedbackService.swift`:

```swift
import Foundation

public actor CoachPlanFeedbackService {
    private let dataClient: DataClientProtocol
    private static let recordType = "CoachPlanFeedback"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func submit(
        rating: CoachPlanFeedbackRating,
        surface: String,
        workoutID: String?,
        copySource: String,
        promptVersion: String,
        reasonCodes: [String]
    ) async throws {
        let json: String?
        if reasonCodes.isEmpty {
            json = nil
        } else {
            let data = try JSONEncoder().encode(reasonCodes)
            json = String(data: data, encoding: .utf8)
        }

        let record = CoachPlanFeedbackRecord(
            rating: rating,
            surface: surface,
            workoutID: workoutID,
            copySource: copySource,
            promptVersion: promptVersion,
            reasonCodesJSON: json
        )
        try await dataClient.save(record, recordType: Self.recordType)
    }
}
```

- [ ] **Step 5: Add feedback UI hooks**

In `AIWorkoutViewModel`, add:

```swift
    @Published var submittedFeedback: CoachPlanFeedbackRating?

    private let feedbackService: CoachPlanFeedbackService
```

In the initializer, after `equipmentProfileService` assignment:

```swift
        self.feedbackService = CoachPlanFeedbackService(dataClient: dataClient)
```

Add this method:

```swift
    func submitFeedback(_ rating: CoachPlanFeedbackRating) async {
        submittedFeedback = rating
        let reasonCodes = workoutRationale.map { rationale in
            ([rationale.headline] + rationale.reasons + rationale.cautions)
        } ?? []
        try? await feedbackService.submit(
            rating: rating,
            surface: "coach_plan_preview",
            workoutID: generatedWorkout?.id,
            copySource: "coach_plan_copy",
            promptVersion: "v1",
            reasonCodes: reasonCodes
        )
        await GrowthAnalyticsService(dataClient: dataClient).track(
            rating == .helpful ? "coach_plan_feedback_helpful" : "coach_plan_feedback_not_helpful",
            source: "coach_plan"
        )
    }
```

In `AIWorkoutView.previewView`, insert `feedbackRow` immediately after:

```swift
                    if let rationale = viewModel.workoutRationale {
                        rationaleCard(rationale)
                    }
```

Add this helper in `AIWorkoutView`:

```swift
    private var feedbackRow: some View {
        HStack {
            Text("Was this useful?")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)
            Spacer()
            Button {
                Task { await viewModel.submitFeedback(.helpful) }
            } label: {
                Image(systemName: viewModel.submittedFeedback == .helpful ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            .accessibilityLabel("Coach Plan was useful")

            Button {
                Task { await viewModel.submitFeedback(.notHelpful) }
            } label: {
                Image(systemName: viewModel.submittedFeedback == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .accessibilityLabel("Coach Plan was not useful")
        }
    }
```

- [ ] **Step 6: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter CoachPlanFeedbackServiceTests
```

Expected: pass.

- [ ] **Step 7: Commit**

Commit message:

```bash
feat(coach): add metadata-only plan feedback
```

CloudKit note: add a `CoachPlanFeedback` record type with `recordName` queryable before production use. Fields are strings and ISO8601 date strings through the existing encoder; no reserved field names are used.

### Task 2.2: Build Trust Badges for "Why This Workout?"

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/WorkoutTrustBadge.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/WorkoutTrustBadgeBuilderTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayWhySheet.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`

- [ ] **Step 1: Write failing badge tests**

Create `WorkoutTrustBadgeBuilderTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class WorkoutTrustBadgeBuilderTests: XCTestCase {
    func testBuildsEnergyEquipmentAndRecoveryBadges() {
        let badges = WorkoutTrustBadgeBuilder.badges(
            reasons: [
                "Your higher energy supports a small intensity nudge while keeping form in focus.",
                "Exercises were filtered to match the equipment you have today.",
                "Your weekly training count is high, so recovery stays part of the plan."
            ],
            cyclePhase: .follicular,
            cycleConfidence: 0.74,
            deloadRecommended: false
        )

        XCTAssertTrue(badges.contains { $0.title == "Energy" })
        XCTAssertTrue(badges.contains { $0.title == "Equipment" })
        XCTAssertTrue(badges.contains { $0.title == "Recovery" })
        XCTAssertTrue(badges.contains { $0.title == "Cycle estimate" && $0.detail == "Medium confidence" })
    }

    func testDeloadBadgeWinsWhenActiveRecoveryRecommended() {
        let badges = WorkoutTrustBadgeBuilder.badges(
            reasons: [],
            cyclePhase: nil,
            cycleConfidence: nil,
            deloadRecommended: true
        )

        XCTAssertEqual(badges.first?.title, "Protected recovery")
    }
}
```

- [ ] **Step 2: Add the badge builder**

Create `WorkoutTrustBadge.swift`:

```swift
import Foundation

public struct WorkoutTrustBadge: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let systemImage: String

    public init(title: String, detail: String, systemImage: String) {
        self.id = title + detail
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

public enum WorkoutTrustBadgeBuilder {
    public static func badges(
        reasons: [String],
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?,
        deloadRecommended: Bool
    ) -> [WorkoutTrustBadge] {
        var badges: [WorkoutTrustBadge] = []

        if deloadRecommended {
            badges.append(WorkoutTrustBadge(
                title: "Protected recovery",
                detail: "Active recovery is recommended today",
                systemImage: "heart.text.square"
            ))
        }

        let joined = reasons.joined(separator: " ").lowercased()
        if joined.contains("energy") {
            badges.append(WorkoutTrustBadge(title: "Energy", detail: "Adjusted for today's energy", systemImage: "bolt"))
        }
        if joined.contains("equipment") {
            badges.append(WorkoutTrustBadge(title: "Equipment", detail: "Matched to available gear", systemImage: "dumbbell"))
        }
        if joined.contains("recovery") || joined.contains("rest") {
            badges.append(WorkoutTrustBadge(title: "Recovery", detail: "Recovery load is accounted for", systemImage: "leaf"))
        }
        if cyclePhase != nil {
            badges.append(WorkoutTrustBadge(
                title: "Cycle estimate",
                detail: confidenceLabel(cycleConfidence),
                systemImage: "moon.circle"
            ))
        }

        return orderedUnique(badges)
    }

    private static func confidenceLabel(_ confidence: Double?) -> String {
        guard let confidence else { return "No confidence score" }
        switch confidence {
        case 0.80...1.0: return "High confidence"
        case 0.50..<0.80: return "Medium confidence"
        default: return "Low confidence"
        }
    }

    private static func orderedUnique(_ badges: [WorkoutTrustBadge]) -> [WorkoutTrustBadge] {
        var seen = Set<String>()
        return badges.filter { badge in
            if seen.contains(badge.title) { return false }
            seen.insert(badge.title)
            return true
        }
    }
}
```

- [ ] **Step 3: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter WorkoutTrustBadgeBuilderTests
```

Expected: pass.

- [ ] **Step 4: Render badges in TodayWhySheet**

In `TodayWhySheet`, add:

```swift
    private var trustBadges: [WorkoutTrustBadge] {
        WorkoutTrustBadgeBuilder.badges(
            reasons: decision?.reasons ?? [],
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence,
            deloadRecommended: deloadRecommendation?.isRecommended == true
        )
    }
```

Add a section before the existing `Today` section:

```swift
                if !trustBadges.isEmpty {
                    Section("Why this workout") {
                        ForEach(trustBadges) { badge in
                            Label {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text(badge.title)
                                        .font(AppTheme.Typography.headlineSmall)
                                    Text(badge.detail)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            } icon: {
                                Image(systemName: badge.systemImage)
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                        }
                    }
                }
```

- [ ] **Step 5: Render badges in Coach Plan preview**

Add this helper in `AIWorkoutView`:

```swift
    private var coachPlanTrustBadges: [WorkoutTrustBadge] {
        guard let rationale = viewModel.workoutRationale else { return [] }
        return WorkoutTrustBadgeBuilder.badges(
            reasons: [rationale.headline] + rationale.reasons + rationale.cautions,
            cyclePhase: viewModel.cyclePhase,
            cycleConfidence: nil,
            deloadRecommended: rationale.cautions.contains { $0.localizedCaseInsensitiveContains("recovery") }
        )
    }

    private var coachPlanTrustBadgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(coachPlanTrustBadges) { badge in
                    Label(badge.title, systemImage: badge.systemImage)
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Accent.goldLight)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .accessibilityLabel("\(badge.title), \(badge.detail)")
                }
            }
        }
    }
```

In `AIWorkoutView.previewView`, insert:

```swift
                    if !coachPlanTrustBadges.isEmpty {
                        coachPlanTrustBadgeRow
                    }
```

immediately after `rationaleCard(rationale)`.

- [ ] **Step 6: Commit**

Commit message:

```bash
feat(coach): surface workout trust badges
```

### Task 2.3: Make Best Next 20 Min Context-Aware

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/BestNextWorkoutRequestBuilder.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BestNextWorkoutViewModel.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BestNextWorkoutRequestBuilderTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift`

- [ ] **Step 1: Write failing builder tests**

Create `BestNextWorkoutRequestBuilderTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class BestNextWorkoutRequestBuilderTests: XCTestCase {
    func testLowPainAndDefaultEquipmentBuildsModifyRequest() {
        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: .dumbbells,
            latestEnergy: .high,
            painLogs: [],
            todayDecisionKind: .modify
        )

        XCTAssertEqual(request.timeMinutes, 20)
        XCTAssertEqual(request.energyLevel, .high)
        XCTAssertEqual(request.equipment, .dumbbells)
        XCTAssertEqual(request.todayDecisionKind, .modify)
    }

    func testHighPainBuildsRecoveryRequest() {
        let log = DailyPainLog(
            id: "pain-1",
            locationIds: "lower_back",
            intensity: 7,
            painType: .soreness,
            date: Date(),
            notes: nil
        )

        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: .fullGym,
            latestEnergy: .medium,
            painLogs: [log],
            todayDecisionKind: .modify
        )

        XCTAssertEqual(request.energyLevel, .low)
        XCTAssertEqual(request.todayDecisionKind, .recover)
        XCTAssertEqual(request.painLogs.count, 1)
    }
}
```

- [ ] **Step 2: Add the request builder**

Create `BestNextWorkoutRequestBuilder.swift`:

```swift
import Foundation

public enum BestNextWorkoutRequestBuilder {
    public static func build(
        defaultEquipment: EquipmentAccess,
        latestEnergy: EnergyLevel?,
        painLogs: [DailyPainLog],
        todayDecisionKind: TodayTrainingDecisionKind
    ) -> QuickWorkoutRequest {
        let highPain = painLogs.contains { $0.intensity >= 6 }
        let decision: TodayTrainingDecisionKind = highPain ? .recover : todayDecisionKind
        let energy: EnergyLevel = highPain ? .low : (latestEnergy ?? .medium)

        return QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: energy,
            equipment: defaultEquipment,
            todayDecisionKind: decision,
            painLogs: painLogs
        )
    }
}
```

- [ ] **Step 3: Add the Train view model**

Create `BestNextWorkoutViewModel.swift`:

```swift
import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class BestNextWorkoutViewModel: ObservableObject {
    @Published public var isBuilding = false
    @Published public var errorMessage: String?

    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func buildWorkout() async -> QuickWorkoutResult? {
        isBuilding = true
        defer { isBuilding = false }

        async let settingsTask: [UserSettingsRecord] = fetch("UserSettings")
        async let painTask: [DailyPainLog] = fetch("DailyPainLog")
        async let checkInTask: [SymptomCheckInRecord] = fetch("SymptomCheckInRecord")

        let settings = (try? await settingsTask) ?? []
        let painLogs = recentPainLogs((try? await painTask) ?? [])
        let checkIns = (try? await checkInTask) ?? []

        let defaultEquipment = settings.last?.defaultEquipment ?? .fullGym
        let latestEnergy = latestEnergyLevel(from: checkIns)
        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: defaultEquipment,
            latestEnergy: latestEnergy,
            painLogs: painLogs,
            todayDecisionKind: .modify
        )

        await GrowthAnalyticsService(dataClient: dataClient).track(
            "best_next_20_generated",
            source: "train",
            properties: [
                "equipment": request.equipment.rawValue,
                "energy": request.energyLevel.rawValue,
                "decision": request.todayDecisionKind.rawValue
            ]
        )

        return QuickWorkoutBuilder.build(request: request)
    }

    private func fetch<T>(_ recordType: String) async throws -> [T] where T: Decodable & Sendable {
        try await dataClient.fetchAll(recordType: recordType)
    }

    private func recentPainLogs(_ logs: [DailyPainLog]) -> [DailyPainLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return logs.filter { $0.date >= cutoff }
    }

    private func latestEnergyLevel(from checkIns: [SymptomCheckInRecord]) -> EnergyLevel? {
        guard let latest = checkIns.sorted(by: { $0.date > $1.date }).first else { return nil }
        switch latest.energy {
        case 0...3: return .low
        case 7...10: return .high
        default: return .medium
        }
    }
}
```

- [ ] **Step 4: Wire TrainHubView**

In `TrainHubView`, add:

```swift
    @StateObject private var bestNextViewModel = BestNextWorkoutViewModel()
```

Replace the hardcoded Best Next button action:

```swift
                    Button {
                        Task {
                            if let result = await bestNextViewModel.buildWorkout() {
                                quickWorkout = result.workout
                            }
                        }
                    } label: {
                        Label(
                            bestNextViewModel.isBuilding ? "Building Best Next 20" : "Best Next 20 Min",
                            systemImage: "timer"
                        )
                    }
                    .disabled(bestNextViewModel.isBuilding)
```

- [ ] **Step 5: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter BestNextWorkoutRequestBuilderTests
```

Expected: pass.

- [ ] **Step 6: Commit**

Commit message:

```bash
feat(train): build best next workout from user context
```

### Task 2.4: Persist Today-Only Coach Plan Quick Edit Preferences

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Coach/TodayWorkoutPreferenceRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/TodayWorkoutPreferenceService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/TodayWorkoutPreferenceServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`

- [ ] **Step 1: Write failing tests**

Create `TodayWorkoutPreferenceServiceTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class TodayWorkoutPreferenceServiceTests: XCTestCase {
    func testSaveDurationPreferenceUsesStableDateKey() async throws {
        let client = MockCloudKitClient()
        let service = TodayWorkoutPreferenceService(dataClient: client)
        let date = ISO8601DateFormatter().date(from: "2026-06-30T12:00:00Z")!

        try await service.saveDurationPreference(minutes: 30, date: date)

        let records: [TodayWorkoutPreferenceRecord] = try await client.fetchAll(recordType: "TodayWorkoutPreference")
        XCTAssertEqual(records.first?.id, "today_preferences_2026-06-30")
        XCTAssertEqual(records.first?.preferredMinutes, 30)
    }
}
```

- [ ] **Step 2: Add record and service**

Create `TodayWorkoutPreferenceRecord.swift`:

```swift
import Foundation

public struct TodayWorkoutPreferenceRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let dateKey: String
    public var preferredMinutes: Int?
    public var reduceVolumeSelected: Bool
    public var removedExerciseNamesJSON: String?
    public let dateCreated: Date

    public init(
        id: String,
        dateKey: String,
        preferredMinutes: Int? = nil,
        reduceVolumeSelected: Bool = false,
        removedExerciseNamesJSON: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.preferredMinutes = preferredMinutes
        self.reduceVolumeSelected = reduceVolumeSelected
        self.removedExerciseNamesJSON = removedExerciseNamesJSON
        self.dateCreated = dateCreated
    }
}
```

Create `TodayWorkoutPreferenceService.swift`:

```swift
import Foundation

public actor TodayWorkoutPreferenceService {
    private let dataClient: DataClientProtocol
    private static let recordType = "TodayWorkoutPreference"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func saveDurationPreference(minutes: Int, date: Date = Date()) async throws {
        var record = try await loadOrCreate(date: date)
        record.preferredMinutes = minutes
        try await dataClient.save(record, recordType: Self.recordType)
    }

    public func saveReducedVolume(date: Date = Date()) async throws {
        var record = try await loadOrCreate(date: date)
        record.reduceVolumeSelected = true
        try await dataClient.save(record, recordType: Self.recordType)
    }

    private func loadOrCreate(date: Date) async throws -> TodayWorkoutPreferenceRecord {
        let key = Self.dateKey(for: date)
        let records: [TodayWorkoutPreferenceRecord] = try await dataClient.fetchAll(recordType: Self.recordType)
        if let existing = records.first(where: { $0.dateKey == key }) {
            return existing
        }
        return TodayWorkoutPreferenceRecord(id: "today_preferences_\(key)", dateKey: key)
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
```

- [ ] **Step 3: Record edits in AIWorkoutViewModel**

Add:

```swift
    private let todayPreferenceService: TodayWorkoutPreferenceService
```

Initialize:

```swift
        self.todayPreferenceService = TodayWorkoutPreferenceService(dataClient: dataClient)
```

At the end of `shortenWorkout(to:)`:

```swift
        Task { try? await todayPreferenceService.saveDurationPreference(minutes: minutes) }
```

At the end of `reduceVolume()`:

```swift
        Task { try? await todayPreferenceService.saveReducedVolume() }
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter TodayWorkoutPreferenceServiceTests
```

Expected: pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
feat(coach): remember same-day quick edits
```

CloudKit note: add `TodayWorkoutPreference` with `recordName` queryable. Uses `dateCreated`, not `createdAt`.

### Task 2.5: Add Optional Post-Workout Check-In

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Workout/WorkoutCompletionCheckInRecord.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/WorkoutCompletionCheckInViewModel.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutCompletionCheckInSheet.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/WorkoutCompletionCheckInViewModelTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Write failing view-model tests**

Create `WorkoutCompletionCheckInViewModelTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class WorkoutCompletionCheckInViewModelTests: XCTestCase {
    func testSubmitSavesCheckInAndTracksEvent() async throws {
        let client = MockCloudKitClient()
        let viewModel = WorkoutCompletionCheckInViewModel(workoutID: "workout-1", dataClient: client)
        viewModel.sessionRPE = 8
        viewModel.soreness = 4
        viewModel.pain = 2
        viewModel.wasRightForToday = true

        await viewModel.submit()

        let records: [WorkoutCompletionCheckInRecord] = try await client.fetchAll(recordType: "WorkoutCompletionCheckIn")
        XCTAssertEqual(records.first?.workoutID, "workout-1")
        XCTAssertEqual(records.first?.sessionRPE, 8)
        XCTAssertEqual(records.first?.soreness, 4)
        XCTAssertEqual(records.first?.pain, 2)
        XCTAssertEqual(records.first?.wasRightForToday, true)
    }
}
```

- [ ] **Step 2: Add record, view model, and sheet**

Create `WorkoutCompletionCheckInRecord.swift`:

```swift
import Foundation

public struct WorkoutCompletionCheckInRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let sessionRPE: Int?
    public let soreness: Int
    public let pain: Int
    public let wasRightForToday: Bool
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        workoutID: String,
        sessionRPE: Int?,
        soreness: Int,
        pain: Int,
        wasRightForToday: Bool,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.sessionRPE = sessionRPE
        self.soreness = soreness
        self.pain = pain
        self.wasRightForToday = wasRightForToday
        self.dateCreated = dateCreated
    }
}
```

Create `WorkoutCompletionCheckInViewModel.swift`:

```swift
import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class WorkoutCompletionCheckInViewModel: ObservableObject {
    @Published public var sessionRPE: Int?
    @Published public var soreness: Int = 0
    @Published public var pain: Int = 0
    @Published public var wasRightForToday: Bool = true
    @Published public var isSaving = false

    private let workoutID: String
    private let dataClient: DataClientProtocol

    public init(workoutID: String, dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.workoutID = workoutID
        self.dataClient = dataClient
    }

    public func submit() async {
        isSaving = true
        defer { isSaving = false }

        let record = WorkoutCompletionCheckInRecord(
            workoutID: workoutID,
            sessionRPE: sessionRPE,
            soreness: soreness,
            pain: pain,
            wasRightForToday: wasRightForToday
        )
        try? await dataClient.save(record, recordType: "WorkoutCompletionCheckIn")
        await GrowthAnalyticsService(dataClient: dataClient).track(
            "post_workout_check_in_completed",
            source: "active_workout",
            properties: ["right_for_today": wasRightForToday ? "true" : "false"]
        )
    }
}
```

Create `WorkoutCompletionCheckInSheet.swift`:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutCompletionCheckInSheet: View {
    @ObservedObject private var viewModel: WorkoutCompletionCheckInViewModel
    private let onDismiss: () -> Void

    public init(
        viewModel: WorkoutCompletionCheckInViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Effort") {
                    Picker("Session RPE", selection: $viewModel.sessionRPE) {
                        Text("Skip").tag(Int?.none)
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(Optional(value))
                        }
                    }
                }

                Section("How do you feel?") {
                    Stepper("Soreness \(viewModel.soreness)/10", value: $viewModel.soreness, in: 0...10)
                    Stepper("Pain \(viewModel.pain)/10", value: $viewModel.pain, in: 0...10)
                    Toggle("This was the right workout for today", isOn: $viewModel.wasRightForToday)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.submit()
                            HapticFeedback.light()
                            onDismiss()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView("Saving check-in…")
                        } else {
                            Text("Save Check-In")
                        }
                    }
                    .disabled(viewModel.isSaving)

                    Button("Skip") {
                        onDismiss()
                    }
                }
            }
            .navigationTitle("Workout Check-In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
```

- [ ] **Step 3: Present after workout completion**

In `ActiveWorkoutView`, add state:

```swift
    @State private var showingCompletionCheckIn = false
```

When workout completion succeeds, set:

```swift
    showingCompletionCheckIn = true
```

Add sheet:

```swift
        .sheet(isPresented: $showingCompletionCheckIn) {
            WorkoutCompletionCheckInSheet(
                viewModel: WorkoutCompletionCheckInViewModel(workoutID: viewModel.workout.id)
            ) {
                showingCompletionCheckIn = false
            }
        }
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter WorkoutCompletionCheckInViewModelTests
```

Expected: pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
feat(workouts): add optional completion check-in
```

CloudKit note: add `WorkoutCompletionCheckIn` with `recordName` queryable. Bool decode should try `Bool` first and `Int` fallback if custom decode is added.

---

# Phase 3: Activation and Progressive Trust

### Task 3.1: Add Activation Funnel Summary

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Growth/ActivationFunnelService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ActivationFunnelServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift`

- [ ] **Step 1: Write failing tests**

Create `ActivationFunnelServiceTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class ActivationFunnelServiceTests: XCTestCase {
    func testSummarizesActivationStages() {
        let now = Date()
        let events = [
            GrowthEvent(name: GrowthEventName.onboardingStarted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.onboardingCompleted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.firstWorkoutStarted, dateCreated: now, source: "onboarding"),
            GrowthEvent(name: GrowthEventName.firstWorkoutCompleted, dateCreated: now, source: "active_workout")
        ]

        let snapshot = ActivationFunnelService.snapshot(from: events, now: now)

        XCTAssertTrue(snapshot.onboardingStarted)
        XCTAssertTrue(snapshot.onboardingCompleted)
        XCTAssertTrue(snapshot.firstWorkoutStarted)
        XCTAssertTrue(snapshot.firstWorkoutCompleted)
        XCTAssertFalse(snapshot.secondSessionWithinSevenDays)
    }
}
```

- [ ] **Step 2: Add the service**

Create `ActivationFunnelService.swift`:

```swift
import Foundation

public struct ActivationFunnelSnapshot: Sendable, Equatable {
    public let onboardingStarted: Bool
    public let onboardingCompleted: Bool
    public let firstWorkoutStarted: Bool
    public let firstWorkoutCompleted: Bool
    public let secondSessionWithinSevenDays: Bool
}

public enum ActivationFunnelService {
    public static func snapshot(from events: [GrowthEvent], now: Date = Date()) -> ActivationFunnelSnapshot {
        let names = Set(events.map(\.name))
        let completedWorkouts = events
            .filter { $0.name == GrowthEventName.firstWorkoutCompleted || $0.name == "workout_completed" }
            .sorted { $0.dateCreated < $1.dateCreated }
        let secondWithinSevenDays: Bool
        if completedWorkouts.count >= 2 {
            let first = completedWorkouts[0].dateCreated
            let second = completedWorkouts[1].dateCreated
            secondWithinSevenDays = second.timeIntervalSince(first) <= 7 * 24 * 60 * 60
        } else {
            secondWithinSevenDays = false
        }

        return ActivationFunnelSnapshot(
            onboardingStarted: names.contains(GrowthEventName.onboardingStarted),
            onboardingCompleted: names.contains(GrowthEventName.onboardingCompleted),
            firstWorkoutStarted: names.contains(GrowthEventName.firstWorkoutStarted),
            firstWorkoutCompleted: names.contains(GrowthEventName.firstWorkoutCompleted),
            secondSessionWithinSevenDays: secondWithinSevenDays
        )
    }
}
```

- [ ] **Step 3: Surface the summary privately**

In `DataTrustCenterView`, add state:

```swift
    @State private var activationSnapshot: ActivationFunnelSnapshot?
```

Add this section below `syncStatusSection`:

```swift
            if let activationSnapshot {
                Section("Activation") {
                    activationRow("Onboarding started", isComplete: activationSnapshot.onboardingStarted)
                    activationRow("Onboarding completed", isComplete: activationSnapshot.onboardingCompleted)
                    activationRow("First workout started", isComplete: activationSnapshot.firstWorkoutStarted)
                    activationRow("First workout completed", isComplete: activationSnapshot.firstWorkoutCompleted)
                    activationRow("Second session within 7 days", isComplete: activationSnapshot.secondSessionWithinSevenDays)
                }
            }
```

Add this helper:

```swift
    private func activationRow(_ title: String, isComplete: Bool) -> some View {
        Label(title, systemImage: isComplete ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isComplete ? AppTheme.Semantic.success : AppTheme.Text.secondary)
    }
```

In `loadInventory()`, fetch growth events after the inventory load:

```swift
        let client = DataClientFactory.shared.client
        let events: [GrowthEvent] = (try? await client.fetchAll(recordType: "GrowthEvent")) ?? []
        activationSnapshot = ActivationFunnelService.snapshot(from: events)
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter ActivationFunnelServiceTests
```

Expected: pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
feat(growth): summarize activation funnel
```

### Task 3.2: Add Progressive Prompt Policy

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Growth/ProgressivePromptPolicy.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/ProgressivePromptPolicyTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`

- [ ] **Step 1: Write failing policy tests**

Create `ProgressivePromptPolicyTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class ProgressivePromptPolicyTests: XCTestCase {
    func testHealthPromptWaitsUntilFirstWorkoutCompleted() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 1,
                openedCycle: false,
                isAboutToSharePhoto: false,
                declinedPromptIDs: []
            )
        )

        XCTAssertEqual(prompt, .healthKit)
    }

    func testCyclePromptShowsWhenCycleTabOpened() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 0,
                openedCycle: true,
                isAboutToSharePhoto: false,
                declinedPromptIDs: []
            )
        )

        XCTAssertEqual(prompt, .cycleSetup)
    }

    func testDeclinedPromptIsNotRepeated() {
        let prompt = ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 1,
                openedCycle: false,
                isAboutToSharePhoto: false,
                declinedPromptIDs: ["healthKit"]
            )
        )

        XCTAssertNil(prompt)
    }
}
```

- [ ] **Step 2: Add policy**

Create `ProgressivePromptPolicy.swift`:

```swift
import Foundation

public enum ProgressivePrompt: String, Sendable, Equatable {
    case healthKit
    case cycleSetup
    case photoSharing
    case reminders
}

public struct ProgressivePromptContext: Sendable, Equatable {
    public let completedWorkoutCount: Int
    public let openedCycle: Bool
    public let isAboutToSharePhoto: Bool
    public let declinedPromptIDs: [String]

    public init(
        completedWorkoutCount: Int,
        openedCycle: Bool,
        isAboutToSharePhoto: Bool,
        declinedPromptIDs: [String]
    ) {
        self.completedWorkoutCount = completedWorkoutCount
        self.openedCycle = openedCycle
        self.isAboutToSharePhoto = isAboutToSharePhoto
        self.declinedPromptIDs = declinedPromptIDs
    }
}

public enum ProgressivePromptPolicy {
    public static func nextPrompt(context: ProgressivePromptContext) -> ProgressivePrompt? {
        if context.openedCycle && !context.declinedPromptIDs.contains(ProgressivePrompt.cycleSetup.rawValue) {
            return .cycleSetup
        }
        if context.isAboutToSharePhoto && !context.declinedPromptIDs.contains(ProgressivePrompt.photoSharing.rawValue) {
            return .photoSharing
        }
        if context.completedWorkoutCount >= 1 && !context.declinedPromptIDs.contains(ProgressivePrompt.healthKit.rawValue) {
            return .healthKit
        }
        if context.completedWorkoutCount >= 2 && !context.declinedPromptIDs.contains(ProgressivePrompt.reminders.rawValue) {
            return .reminders
        }
        return nil
    }
}
```

- [ ] **Step 3: Wire prompt copy at point of use**

Add this exact onboarding copy to the final preferences step, below the default equipment card:

```swift
                Text("You can connect Health, cycle setup, reminders, and photo sharing when they become useful.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)
```

Add this reusable prompt row in the UI file where each prompt appears:

```swift
    private func progressivePromptRow(title: String, message: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundColor(AppTheme.Accent.gold)
        }
    }
```

Use these prompt copy strings:

```swift
progressivePromptRow(
    title: "Set up cycle context",
    message: "Add cycle details when you want training adjustments to use phase estimates.",
    systemImage: "moon.circle"
)
progressivePromptRow(
    title: "Connect Health when ready",
    message: "Health access is optional. Sundee Fundee keeps working from your logged workouts and check-ins.",
    systemImage: "heart.text.square"
)
progressivePromptRow(
    title: "Photo sharing uses your permission",
    message: "Choose a photo only when you want it on a share card.",
    systemImage: "photo"
)
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter ProgressivePromptPolicyTests
```

Expected: pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
feat(onboarding): add progressive prompt policy
```

### Task 3.3: Strengthen Privacy and Data-Control Messaging

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/DataTrustCenterView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Add onboarding privacy copy**

In `welcomeStep`, add this text below the value proposition:

```swift
            Text("Guest mode stays local. Sign in with Apple uses iCloud sync. Health access is optional, and the app still works if you decline.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
```

- [ ] **Step 2: Add Data Trust intro copy**

At the top of `DataTrustCenterView.List`, add:

```swift
            Section("Privacy") {
                Text(authViewModel.isGuest
                    ? "You are using guest mode. Workout, cycle, pain, and progress data stays on this device unless you sign in."
                    : "You are signed in with Apple. Sundee Fundee syncs app data with your private iCloud container.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
```

- [ ] **Step 3: Ensure HealthKit denial copy stays non-blocking**

Search:

```bash
rg -n "HealthKit|permission|denied|authorization" SundeeFundee/Sources/SundeeFundeeKit
```

If user-facing HealthKit denial copy is missing at a prompt point, use:

```swift
"Health access is optional. Sundee Fundee will keep using your logged workouts and check-ins."
```

- [ ] **Step 4: Commit**

Commit message:

```bash
fix(privacy): clarify storage and optional health access
```

---

# Phase 4: Progress, Widgets, and Discoverability

### Task 4.1: Add Progress Preview Guidance

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Models/ProgressGuidanceService.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/ProgressGuidanceServiceTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift`

- [ ] **Step 1: Write failing tests**

Create `ProgressGuidanceServiceTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class ProgressGuidanceServiceTests: XCTestCase {
    func testGuidanceShowsAnalyticsUnlockWhenFewWorkouts() {
        let items = ProgressGuidanceService.guidance(
            input: ProgressDestinationInput(
                hasMaxes: false,
                hasBenchmarks: false,
                hasChallenges: false,
                hasBuddyCheckIns: false,
                hasMonthlyReview: false,
                hasAnalytics: false,
                alwaysShowExport: true
            ),
            completedWorkoutCount: 1
        )

        XCTAssertTrue(items.contains { $0.title == "Complete 2 workouts to unlock analytics" })
        XCTAssertTrue(items.contains { $0.title == "Log your first max" })
    }
}
```

- [ ] **Step 2: Add guidance service**

Create `ProgressGuidanceService.swift`:

```swift
import Foundation

public struct ProgressGuidanceItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemImage: String

    public init(title: String, subtitle: String, systemImage: String) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public enum ProgressGuidanceService {
    public static func guidance(
        input: ProgressDestinationInput,
        completedWorkoutCount: Int
    ) -> [ProgressGuidanceItem] {
        var items: [ProgressGuidanceItem] = []
        if !input.hasAnalytics {
            let remaining = max(0, 2 - completedWorkoutCount)
            items.append(ProgressGuidanceItem(
                title: remaining == 0 ? "Analytics are ready" : "Complete 2 workouts to unlock analytics",
                subtitle: remaining == 0 ? "Open analytics to review your training patterns." : "\(remaining) more workout\(remaining == 1 ? "" : "s") to start trends.",
                systemImage: "chart.xyaxis.line"
            ))
        }
        if !input.hasMaxes {
            items.append(ProgressGuidanceItem(
                title: "Log your first max",
                subtitle: "Start strength trends with one lift.",
                systemImage: "scalemass"
            ))
        }
        if !input.hasBenchmarks {
            items.append(ProgressGuidanceItem(
                title: "Try a benchmark",
                subtitle: "Benchmarks make conditioning progress easier to compare.",
                systemImage: "trophy"
            ))
        }
        return items
    }
}
```

- [ ] **Step 3: Render guidance in ProgressHubView**

Store the input used by `MinimalSurfacePolicy` and render:

```swift
                let guidance = ProgressGuidanceService.guidance(
                    input: destinationInput,
                    completedWorkoutCount: completedWorkoutCount
                )
                if !guidance.isEmpty {
                    Section("Start tracking") {
                        ForEach(guidance) { item in
                            Label {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text(item.title)
                                    Text(item.subtitle)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            } icon: {
                                Image(systemName: item.systemImage)
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                        }
                    }
                }
```

- [ ] **Step 4: Run tests**

Run:

```bash
cd SundeeFundee && swift test --filter ProgressGuidanceServiceTests
```

Expected: pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
feat(progress): show guidance before data exists
```

### Task 4.2: Add App Deep Links for Widget Actions

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/DeepLinkRouter.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/DeepLinkRouterTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`
- Modify: `SundeeFundeeApp/SundeeFundee/App.swift`
- Modify: `SundeeFundeeApp/SundeeFundee/Info.plist`
- Modify: `SundeeFundeeApp/SundeeFundeeWidgets/CyclePhaseWidget.swift`

- [ ] **Step 1: Write route tests**

Create `DeepLinkRouterTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class DeepLinkRouterTests: XCTestCase {
    func testParsesCycleRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://cycle")!)
        XCTAssertEqual(route, .cycle)
    }

    func testParsesCheckInRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/check-in")!)
        XCTAssertEqual(route, .todayCheckIn)
    }

    func testRejectsWrongScheme() {
        let route = DeepLinkRouter.route(for: URL(string: "https://sundeefundee.com")!)
        XCTAssertNil(route)
    }
}
```

- [ ] **Step 2: Add router**

Create `DeepLinkRouter.swift`:

```swift
import Foundation

public enum AppDeepLinkRoute: Sendable, Equatable {
    case today
    case todayCheckIn
    case train
    case cycle
    case progress
}

public enum DeepLinkRouter {
    public static func route(for url: URL) -> AppDeepLinkRoute? {
        guard url.scheme == "sundeefundee" else { return nil }
        let host = url.host ?? ""
        let path = url.path

        switch (host, path) {
        case ("today", "/check-in"): return .todayCheckIn
        case ("today", _): return .today
        case ("train", _): return .train
        case ("cycle", _): return .cycle
        case ("progress", _): return .progress
        default: return nil
        }
    }
}
```

- [ ] **Step 3: Register URL scheme**

Add to `Info.plist` before `UIApplicationSceneManifest`:

```xml
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.sundeefundee.app</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>sundeefundee</string>
            </array>
        </dict>
    </array>
```

- [ ] **Step 4: Handle routes in MainTabView**

In `MainTabView`, add:

```swift
        .onOpenURL { url in
            guard let route = DeepLinkRouter.route(for: url) else { return }
            switch route {
            case .today, .todayCheckIn:
                selectedTab = .today
            case .train:
                selectedTab = .train
            case .cycle:
                selectedTab = .cycle
            case .progress:
                selectedTab = .progress
            }
        }
```

- [ ] **Step 5: Add widget URLs**

In `CyclePhaseWidgetEntryView.systemSmall`, add:

```swift
        .widgetURL(URL(string: "sundeefundee://cycle"))
```

For stale/no-data recovery widgets, use `sundeefundee://today/check-in`.

- [ ] **Step 6: Run tests and regenerate project only if needed**

Run:

```bash
cd SundeeFundee && swift test --filter DeepLinkRouterTests
```

Expected: pass.

If Xcode project source membership changes are needed:

```bash
cd SundeeFundeeApp && xcodegen generate
```

- [ ] **Step 7: Commit**

Commit message:

```bash
feat(widgets): deep link stale states into app actions
```

---

# Phase 5: Release Readiness and Maintenance

### Task 5.1: Verify Support Tip App Review Paths

**Files:**
- Create: `docs/release/support-tip-review-gate.md`
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Create review gate**

Run:

```bash
mkdir -p docs/release
```

Create `docs/release/support-tip-review-gate.md`:

```markdown
# Support Tip Review Gate

Product ID: `com.sundeefundee.app.support.tip199`

## Contract

- [ ] Consumable
- [ ] Repeatable
- [ ] Settings-only placement
- [ ] No feature unlocks
- [ ] No paywall
- [ ] No restore UI for this consumable
- [ ] No charity, fundraiser, or medical-benefit language

## Simulator StoreKit Paths

- [ ] Product loads and shows `$1.99`
- [ ] Successful purchase shows thank-you copy
- [ ] Second purchase can be started after first success
- [ ] Pending purchase shows pending copy
- [ ] Cancelled purchase shows no error
- [ ] Unavailable product shows user-facing unavailable copy
- [ ] Unverified transaction shows verification copy

## Commands

```bash
cd SundeeFundee && swift test --filter SupportTip
```

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
```

- [ ] **Step 2: Verify existing tests**

Run:

```bash
cd SundeeFundee && swift test --filter SupportTip
```

Expected: pass.

- [ ] **Step 3: Commit**

Commit message:

```bash
docs(release): add support tip review gate
```

### Task 5.2: Update Stale Developer Docs

**Files:**
- Modify: `SundeeFundee/README.md`
- Modify: `SundeeFundee/Package.swift`
- Modify: `readme.md`

- [ ] **Step 1: Replace package README status**

Replace `SundeeFundee/README.md` with current package/app structure:

```markdown
# Sundee Fundee Kit

Shared Swift package for the Sundee Fundee iOS app.

## What It Contains

- Domain logic for cycle-aware training, Coach Plan decisions, benchmarks, programs, recovery, pain-aware substitutions, growth events, and release notes.
- Data-layer protocols and CloudKit/local/mock implementations.
- SwiftUI views and view models reused by the app target.
- Auth helpers for Apple Sign-In and Keychain session storage.
- Widget/shared snapshot support.

## App Structure

```text
SundeeFundee/          Swift package: SundeeFundeeKit
SundeeFundeeApp/       Xcode project, app target, widget extension, StoreKit config, Fastlane metadata
```

## Commands

```bash
cd SundeeFundee && swift test
```

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Product Model

All features are free and unlocked. The optional support tip in Settings is repeatable and does not unlock anything.
```
```

- [ ] **Step 2: Remove stale Package.swift comment block**

Delete the comment block beginning:

```swift
// NOTE: iOS App UI (SwiftUI views, view models) will be created in an Xcode project.
```

Replace it with:

```swift
// The iOS app target in SundeeFundeeApp imports this package directly.
// UI, view models, data clients, domain logic, widgets, and tests live in the package
// so the app and test targets share one source of truth.
```

- [ ] **Step 3: Update root README if versioned feature list changed**

Ensure `readme.md` mentions:

```markdown
- Optional Support Tip in Settings, with all app features still free and unlocked
- Widgets with freshness copy and deep links
- Data Trust Center for export/delete/sync visibility
```

- [ ] **Step 4: Commit**

Commit message:

```bash
docs: refresh package and release docs
```

### Task 5.3: Finish Code-Health Cleanup

**Files:**
- Modify only files flagged by the commands below.
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Verify old findings**

Run:

```bash
rg -n "\\bMaxRow\\b|let setsCount|var setsCount" SundeeFundee/Sources/SundeeFundeeKit
```

Expected: no unused `MaxRow`, no local variable shadow named `setsCount`. If a shadow exists, rename the local to `setCount` and build.

- [ ] **Step 2: Run SwiftLint**

Run:

```bash
swiftlint --config .swiftlint.yml
```

Expected: pass. If it reports violations, fix only the reported lines in files already in the phase scope.

- [ ] **Step 3: Update matrix item #19**

Set item #19 to `done` and record the `rg` and SwiftLint result.

- [ ] **Step 4: Commit**

Commit message:

```bash
chore(release): verify code health cleanup
```

### Task 5.4: Add the Final Release Gate

**Files:**
- Create: `docs/release/next-release-gate.md`
- Create: `scripts/next-release-gate.sh`

- [ ] **Step 1: Create runbook**

Run:

```bash
mkdir -p docs/release scripts
```

Create `docs/release/next-release-gate.md`:

```markdown
# Next Release Gate

Do not submit to App Store review from this gate. Submission requires explicit user approval.

## Automated

- [ ] `cd SundeeFundee && swift test`
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- [ ] `swiftlint --config .swiftlint.yml`
- [ ] `cd SundeeFundee && swift test --filter SupportTip`
- [ ] `cd SundeeFundee && swift test --filter DeepLinkRouterTests`
- [ ] `cd SundeeFundee && swift test --filter BestNextWorkoutRequestBuilderTests`
- [ ] `cd SundeeFundee && swift test --filter CoachPlanFeedbackServiceTests`

## Manual Simulator QA

- [ ] Light mode Today, Train, Cycle, Progress, Settings
- [ ] Dark mode Today, Train, Cycle, Progress, Settings
- [ ] Accessibility Large active workout and Coach Plan
- [ ] VoiceOver labels for icon-only actions
- [ ] HealthKit denied path still permits guest/local training
- [ ] StoreKit success, pending, cancel, unavailable, unverified paths
- [ ] Widget stale/no-data deep links route to the intended tab
- [ ] Coach Plan fallback works when on-device copy is unavailable
- [ ] Share card preview renders without visible freeze

## App Review Safety

- [ ] No paywalls
- [ ] No feature gates
- [ ] Support tip remains optional and Settings-only
- [ ] No App Store upload or submission performed
```

- [ ] **Step 2: Create script**

Create `scripts/next-release-gate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT/SundeeFundee"
swift test
swift test --filter SupportTip
swift test --filter DeepLinkRouterTests
swift test --filter BestNextWorkoutRequestBuilderTests
swift test --filter CoachPlanFeedbackServiceTests

cd "$ROOT/SundeeFundeeApp"
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

cd "$ROOT"
swiftlint --config .swiftlint.yml
```

- [ ] **Step 3: Make executable**

Run:

```bash
chmod +x scripts/next-release-gate.sh
```

- [ ] **Step 4: Run automated gate**

Run:

```bash
./scripts/next-release-gate.sh
```

Expected: all commands pass.

- [ ] **Step 5: Commit**

Commit message:

```bash
docs(release): add next release gate
```

### Task 5.5: Final Matrix Closeout

**Files:**
- Modify: `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

- [ ] **Step 1: Update every row**

Convert every row to a terminal status:

```text
done
implemented-needs-manual-qa
blocked
```

Use `done` when the item is fully verified. Use `implemented-needs-manual-qa` when code is complete and only manual simulator verification remains. Use `blocked` only for real external blockers such as missing CloudKit schema deployment or missing simulator capability. If any row is still `not started`, `partial`, or `implemented-needs-verification`, keep working that phase until it reaches one of the terminal statuses above.

- [ ] **Step 2: Run final status check**

Run:

```bash
git status --short
```

Expected: only the matrix file is modified before this task's commit.

- [ ] **Step 3: Commit**

Commit message:

```bash
docs(release): close next release matrix
```

---

## Final Phase Verification

Run:

```bash
./scripts/next-release-gate.sh
```

Then run the dark-mode/accessibility manual gate from the gate doc created in Phase 1.

Then run the support-tip review gate from the gate doc created in Phase 5.

No App Store upload or submission is part of this plan.

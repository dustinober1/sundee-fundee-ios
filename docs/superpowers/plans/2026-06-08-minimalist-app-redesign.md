# Minimalist App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Sundee Fundee feel simpler by reducing top-level choices, showing one obvious next action, and moving advanced detail behind intentional disclosure.

**Architecture:** This is a UI consolidation pass, not a new product-surface expansion. Keep existing domain services and CloudKit record types; add small testable policy models under `UI/Models/` and compose existing screens through a new `TrainHubView`, a leaner `DashboardView`, a leaner `ProgressHubView`, and a `QuickCheckInView`.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, XCTest and Swift Testing, existing `DataClientProtocol`, existing CloudKit-safe records, no external dependencies, iOS 18+.

---

## Scope Check

The 10 stories touch navigation, Today, workouts/programs, progress, active workout logging, check-ins, onboarding, sharing, Settings, and inactive-feature visibility. Build them as five independently shippable release slices:

1. **Minimal surface policies:** Pure, testable rules for tabs, Today sections, Progress destinations, and share-prompt eligibility.
2. **Navigation and Today:** One primary action on Today, all supporting detail behind `Why?` and `More Today`.
3. **Train and Progress hubs:** Merge Workouts/Programs into `Train`; make Progress summary-first and data-aware.
4. **Gym flow and check-ins:** Keep active workout focused; add one quick check-in entry point.
5. **Onboarding, sharing, Settings:** Shorter onboarding, privacy-preserving share prompts, and grouped Settings.

Do not submit to App Store review as part of this plan.

## Story Coverage

- Story 1, one primary Today action: Tasks 1 and 2.
- Story 2, secondary Today details behind `Why?`: Tasks 1 and 2.
- Story 3, unify Workouts and Programs into `Train`: Task 3.
- Story 4, one key Progress trend by default: Task 4.
- Story 5, active workout shows only current exercise, inputs, and one overflow menu: Task 5.
- Story 6, combined recovery/pain/cycle/readiness check-in: Task 6.
- Story 7, minimalist onboarding: Task 7.
- Story 8, meaningful share prompts and private defaults: Task 8.
- Story 9, Settings grouped into Training, Privacy, Account: Task 9.
- Story 10, hide inactive features until relevant data exists: Tasks 1, 4, and 9.

## File Structure

**Create:**

- `SundeeFundee/Sources/SundeeFundeeKit/UI/Models/MinimalSurfacePolicy.swift` - pure rules for tab count, Today disclosure, Progress visibility, and share prompts.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayWhySheet.swift` - explains Today recommendation, recovery contributors, cycle context, and missed-workout adjustments.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayMoreSheet.swift` - holds secondary Today modules that used to compete with the primary action.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift` - one tab for starting, resuming, viewing history, and choosing programs.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/CheckIn/QuickCheckInView.swift` - one short check-in for energy, soreness/fatigue/cramps, optional pain, and optional period state.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/QuickCheckInViewModel.swift` - saves `SymptomCheckInRecord`, optional `DailyPainLog`, and optional `PeriodLogRecord`.
- `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift` - coverage for minimal tabs, Today secondary sections, Progress visibility, and meaningful share prompt rules.
- `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/QuickCheckInViewModelTests.swift` - save-path coverage for the combined check-in.
- `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/OnboardingViewModelTests.swift` - coverage for reduced onboarding defaults and saved settings.

**Modify:**

- `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift` - replace separate Workouts and Programs tabs with `TrainHubView`, update `Tab`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift` - reduce Today to welcome, primary action, compact snapshot, `Why?`, and `More Today`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift` - show one summary-first card and hide inactive destinations until relevant data exists.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift` - move nonessential in-session cards/actions into one options menu and disclosures.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift` - reduce onboarding to welcome plus one preferences step.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift` - default advanced controls to collapsed.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift` - gate PR share prompt through `MinimalSurfacePolicy`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` - regroup settings and hide inactive diagnostics/share settings until useful.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift` - use actionable user-facing error copy while it becomes part of Train.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` - use actionable user-facing error copy while it becomes part of Train.

## Task 1: Minimal Surface Policy

**Outcome:** Minimalism rules are testable without depending on SwiftUI view introspection.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Models/MinimalSurfacePolicy.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift`

- [ ] **Step 1: Write failing policy tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class MinimalSurfacePolicyTests: XCTestCase {
    func testPrimaryTabsUseFourMinimalDestinations() {
        XCTAssertEqual(
            MinimalSurfacePolicy.primaryTabs,
            [.today, .train, .cycle, .progress]
        )
    }

    func testTodaySecondarySectionsHideWhenNoDataIsRelevant() {
        let sections = MinimalSurfacePolicy.todaySecondarySections(
            input: TodaySecondarySectionInput(
                hasWeeklyPlan: false,
                hasMissedWorkoutPlan: false,
                hasFirstWeekChecklist: false,
                hasRecoveryInputGaps: false,
                hasActiveChallenge: false,
                hasCoachInsights: false,
                hasRecentWins: false
            )
        )

        XCTAssertEqual(sections, [])
    }

    func testTodaySecondarySectionsKeepOnlyRelevantData() {
        let sections = MinimalSurfacePolicy.todaySecondarySections(
            input: TodaySecondarySectionInput(
                hasWeeklyPlan: true,
                hasMissedWorkoutPlan: true,
                hasFirstWeekChecklist: false,
                hasRecoveryInputGaps: true,
                hasActiveChallenge: false,
                hasCoachInsights: true,
                hasRecentWins: false
            )
        )

        XCTAssertEqual(sections, [.weeklyPlan, .missedWorkoutPlan, .recoveryInputs, .coachInsights])
    }

    func testProgressDestinationVisibilityHidesInactiveFeatures() {
        let destinations = MinimalSurfacePolicy.progressDestinations(
            input: ProgressDestinationInput(
                hasMaxes: true,
                hasBenchmarks: false,
                hasChallenges: false,
                hasBuddyCheckIns: false,
                hasMonthlyReview: true,
                hasAnalytics: false,
                alwaysShowExport: true
            )
        )

        XCTAssertEqual(destinations, [.monthlyReview, .maxes, .export])
    }

    func testSharePromptRequiresMeaningfulWin() {
        XCTAssertFalse(MinimalSurfacePolicy.shouldPromptShare(for: .completedWorkout))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .personalRecord))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .challengeMilestone))
        XCTAssertTrue(MinimalSurfacePolicy.shouldPromptShare(for: .monthlyReview))
    }
}
```

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
```

Expected: compile failure containing `cannot find 'MinimalSurfacePolicy' in scope`.

- [ ] **Step 2: Add the policy types**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Models/MinimalSurfacePolicy.swift`:

```swift
import Foundation

public enum MinimalNavigationTab: String, Sendable, Equatable, CaseIterable {
    case today
    case train
    case cycle
    case progress
}

public enum TodaySecondarySection: String, Sendable, Equatable {
    case weeklyPlan
    case missedWorkoutPlan
    case firstWeekChecklist
    case recoveryInputs
    case activeChallenge
    case coachInsights
    case recentWins
}

public struct TodaySecondarySectionInput: Sendable, Equatable {
    public let hasWeeklyPlan: Bool
    public let hasMissedWorkoutPlan: Bool
    public let hasFirstWeekChecklist: Bool
    public let hasRecoveryInputGaps: Bool
    public let hasActiveChallenge: Bool
    public let hasCoachInsights: Bool
    public let hasRecentWins: Bool

    public init(
        hasWeeklyPlan: Bool,
        hasMissedWorkoutPlan: Bool,
        hasFirstWeekChecklist: Bool,
        hasRecoveryInputGaps: Bool,
        hasActiveChallenge: Bool,
        hasCoachInsights: Bool,
        hasRecentWins: Bool
    ) {
        self.hasWeeklyPlan = hasWeeklyPlan
        self.hasMissedWorkoutPlan = hasMissedWorkoutPlan
        self.hasFirstWeekChecklist = hasFirstWeekChecklist
        self.hasRecoveryInputGaps = hasRecoveryInputGaps
        self.hasActiveChallenge = hasActiveChallenge
        self.hasCoachInsights = hasCoachInsights
        self.hasRecentWins = hasRecentWins
    }
}

public enum ProgressDestination: String, Sendable, Equatable {
    case monthlyReview
    case analytics
    case maxes
    case benchmarks
    case challenges
    case buddyCheckIns
    case export
}

public struct ProgressDestinationInput: Sendable, Equatable {
    public let hasMaxes: Bool
    public let hasBenchmarks: Bool
    public let hasChallenges: Bool
    public let hasBuddyCheckIns: Bool
    public let hasMonthlyReview: Bool
    public let hasAnalytics: Bool
    public let alwaysShowExport: Bool

    public init(
        hasMaxes: Bool,
        hasBenchmarks: Bool,
        hasChallenges: Bool,
        hasBuddyCheckIns: Bool,
        hasMonthlyReview: Bool,
        hasAnalytics: Bool,
        alwaysShowExport: Bool
    ) {
        self.hasMaxes = hasMaxes
        self.hasBenchmarks = hasBenchmarks
        self.hasChallenges = hasChallenges
        self.hasBuddyCheckIns = hasBuddyCheckIns
        self.hasMonthlyReview = hasMonthlyReview
        self.hasAnalytics = hasAnalytics
        self.alwaysShowExport = alwaysShowExport
    }
}

public enum SharePromptMoment: String, Sendable, Equatable {
    case completedWorkout
    case personalRecord
    case challengeMilestone
    case monthlyReview
    case cycleInsight
}

public enum MinimalSurfacePolicy {
    public static let primaryTabs: [MinimalNavigationTab] = [.today, .train, .cycle, .progress]

    public static func todaySecondarySections(input: TodaySecondarySectionInput) -> [TodaySecondarySection] {
        var sections: [TodaySecondarySection] = []
        if input.hasWeeklyPlan { sections.append(.weeklyPlan) }
        if input.hasMissedWorkoutPlan { sections.append(.missedWorkoutPlan) }
        if input.hasFirstWeekChecklist { sections.append(.firstWeekChecklist) }
        if input.hasRecoveryInputGaps { sections.append(.recoveryInputs) }
        if input.hasActiveChallenge { sections.append(.activeChallenge) }
        if input.hasCoachInsights { sections.append(.coachInsights) }
        if input.hasRecentWins { sections.append(.recentWins) }
        return sections
    }

    public static func progressDestinations(input: ProgressDestinationInput) -> [ProgressDestination] {
        var destinations: [ProgressDestination] = []
        if input.hasMonthlyReview { destinations.append(.monthlyReview) }
        if input.hasAnalytics { destinations.append(.analytics) }
        if input.hasMaxes { destinations.append(.maxes) }
        if input.hasBenchmarks { destinations.append(.benchmarks) }
        if input.hasChallenges { destinations.append(.challenges) }
        if input.hasBuddyCheckIns { destinations.append(.buddyCheckIns) }
        if input.alwaysShowExport { destinations.append(.export) }
        return destinations
    }

    public static func shouldPromptShare(for moment: SharePromptMoment) -> Bool {
        switch moment {
        case .personalRecord, .challengeMilestone, .monthlyReview:
            return true
        case .completedWorkout, .cycleInsight:
            return false
        }
    }
}
```

- [ ] **Step 3: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
```

Expected: all `MinimalSurfacePolicyTests` pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Models/MinimalSurfacePolicy.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift
git commit -m "feat(ui): add minimalist surface policy"
```

## Task 2: Simplify Today Around One Primary Action

**Outcome:** Today renders one dominant action. Recommendation reasons, recovery inputs, weekly plan, challenge progress, coach insights, and recent wins move into `Why?` and `More Today` sheets.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayWhySheet.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayMoreSheet.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`

- [ ] **Step 1: Add state and sheet entry points**

In `DashboardView`, add state:

```swift
@State private var showingTodayWhy = false
@State private var showingMoreToday = false
```

Add sheet modifiers beside existing sheets:

```swift
.sheet(isPresented: $showingTodayWhy) {
    TodayWhySheet(
        decision: viewModel.todayTrainingDecision,
        recoveryExplanations: viewModel.recoveryExplanations,
        deloadRecommendation: viewModel.deloadRecommendation,
        cyclePhase: cyclePhaseCache.currentPhase,
        cycleConfidence: cyclePhaseCache.confidence
    )
}
.sheet(isPresented: $showingMoreToday) {
    TodayMoreSheet(
        sections: MinimalSurfacePolicy.todaySecondarySections(
            input: viewModel.todaySecondarySectionInput
        ),
        viewModel: viewModel,
        onStartWorkout: {
            Task { starterWorkout = await viewModel.buildStarterWorkout() }
        },
        onStartQuickWorkout: {
            Task { starterWorkout = await viewModel.buildQuickWorkout() }
        },
        onLogRecoveryInput: handleRecoveryInputAction
    )
}
```

- [ ] **Step 2: Add `todaySecondarySectionInput`**

In `DashboardViewModel`, add:

```swift
var todaySecondarySectionInput: TodaySecondarySectionInput {
    TodaySecondarySectionInput(
        hasWeeklyPlan: weeklyPlanProgress != nil,
        hasMissedWorkoutPlan: missedWorkoutRecoveryPlan != nil,
        hasFirstWeekChecklist: shouldShowFirstWeekChecklist,
        hasRecoveryInputGaps: !recoveryInputStatuses.isEmpty,
        hasActiveChallenge: activeChallengeData != nil,
        hasCoachInsights: insightsSummary != nil || !insightsActions.isEmpty,
        hasRecentWins: !recentWins.isEmpty
    )
}
```

- [ ] **Step 3: Create `TodayWhySheet`**

Create `TodayWhySheet` with a `NavigationStack`, close button, and three sections:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TodayWhySheet: View {
    @Environment(\.dismiss) private var dismiss
    let decision: TodayTrainingDecision?
    let recoveryExplanations: [RecoveryExplanation]
    let deloadRecommendation: DeloadRecommendation?
    let cyclePhase: CyclePhase?
    let cycleConfidence: Double?

    var body: some View {
        NavigationStack {
            List {
                if let decision {
                    Section("Today") {
                        Text(decision.subtitle)
                        ForEach(decision.reasons.prefix(3), id: \.self) { reason in
                            Text(reason)
                        }
                    }
                }

                if !recoveryExplanations.isEmpty {
                    Section("Recovery") {
                        ForEach(recoveryExplanations.prefix(3)) { explanation in
                            Text(explanation.text)
                        }
                    }
                }

                if let cyclePhase {
                    Section("Cycle") {
                        Text(cyclePhaseLabel(cyclePhase))
                        if let cycleConfidence {
                            Text("Confidence \(Int(cycleConfidence * 100))%")
                        }
                    }
                }

                if let deloadRecommendation, deloadRecommendation.isRecommended {
                    Section("Deload") {
                        Text(deloadRecommendation.reason)
                    }
                }
            }
            .navigationTitle("Why Today?")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func cyclePhaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}
```

- [ ] **Step 4: Create `TodayMoreSheet`**

Create `TodayMoreSheet` that switches on `TodaySecondarySection` and reuses extracted card builders from `DashboardView`:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TodayMoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sections: [TodaySecondarySection]
    @ObservedObject var viewModel: DashboardViewModel
    let onStartWorkout: () -> Void
    let onStartQuickWorkout: () -> Void
    let onLogRecoveryInput: (RecoveryInputKind) -> Void

    var body: some View {
        NavigationStack {
            List {
                if sections.isEmpty {
                    Section {
                        Text("Nothing else needs your attention today.")
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }

                ForEach(sections, id: \.self) { section in
                    sectionContent(section)
                }
            }
            .navigationTitle("More Today")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: TodaySecondarySection) -> some View {
        switch section {
        case .weeklyPlan:
            Section("This Week") {
                if let progress = viewModel.weeklyPlanProgress {
                    Text(progress.displayText)
                    Button("Start This Workout", action: onStartWorkout)
                }
            }
        case .missedWorkoutPlan:
            Section("Schedule") {
                if let plan = viewModel.missedWorkoutRecoveryPlan {
                    Text(plan.userSummary)
                    Button(plan.actionTitle) {
                        Task { await viewModel.applyMissedWorkoutRecovery() }
                    }
                }
            }
        case .firstWeekChecklist:
            Section("First Week") {
                ForEach(viewModel.firstWeekChecklist) { item in
                    Text(item.isComplete ? "\(item.title): Done" : "\(item.title): \(item.actionTitle)")
                }
            }
        case .recoveryInputs:
            Section("Recovery Inputs") {
                ForEach(viewModel.recoveryInputStatuses) { item in
                    Button(item.title) { onLogRecoveryInput(item.kind) }
                        .disabled(item.isAvailable)
                }
            }
        case .activeChallenge:
            Section("Challenge") {
                if let data = viewModel.activeChallengeData {
                    Text(data.0.title)
                    Text(data.1.currentTierName)
                }
            }
        case .coachInsights:
            Section("Coach") {
                if let summary = viewModel.insightsSummary {
                    Text(summary)
                }
                ForEach(viewModel.insightsActions.prefix(2), id: \.self) { action in
                    Text(action)
                }
            }
        case .recentWins:
            Section("Recent Wins") {
                ForEach(viewModel.recentWins.prefix(3), id: \.self) { win in
                    Text(win)
                }
            }
        }
    }
}
```

- [ ] **Step 5: Trim the Today card and add a compact snapshot**

In `todayTrainingDecisionCard(_:)`, keep only the title, subtitle, and one primary button:

```swift
Button {
    handleTodayTrainingDecision(decision)
} label: {
    Label(decision.primaryActionTitle, systemImage: decision.systemImage)
        .frame(maxWidth: .infinity)
}
.artDecoButton(style: .accent)
```

Remove the inline reason list, recovery explanations, `Best next 20 min`, and active-recovery secondary buttons from this card. Those choices remain available through `TodayWhySheet` and `TodayMoreSheet`.

Add a compact snapshot below the primary card:

```swift
@ViewBuilder
private var compactTodaySnapshot: some View {
    ArtDecoCard {
        HStack(spacing: AppTheme.Spacing.md) {
            StatCard(value: "\(viewModel.workoutsThisWeek)", label: "Week")
            StatCard(value: "\(viewModel.prsThisMonth)", label: "PRs")
            StatCard(value: viewModel.activeProgramName ?? "Open", label: "Plan")
        }
    }
}
```

- [ ] **Step 6: Replace the top-level Today stack**

In `DashboardView.body`, replace the dense sequence of cards with:

```swift
welcomeHeader

if let decision = viewModel.todayTrainingDecision {
    todayTrainingDecisionCard(decision)
}

if viewModel.showsNewUserEmptyState {
    EmptyStateView(
        icon: "figure.strengthtraining.traditional",
        title: "Welcome to Sundee Fundee",
        subtitle: "Start your first workout to unlock stats, benchmarks, and cycle-aware programming.",
        actionLabel: "Start First Workout",
        action: {
            Task {
                starterWorkout = await viewModel.buildStarterWorkout()
            }
        },
        secondaryActionLabel: "Log a Max",
        secondaryAction: { viewModel.navigateToLogMax = true }
    )
}

compactTodaySnapshot

Button {
    showingTodayWhy = true
} label: {
    Label("Why?", systemImage: "questionmark.circle")
        .frame(maxWidth: .infinity)
}
.artDecoButton(style: .secondary)

Button {
    showingMoreToday = true
} label: {
    Label("More Today", systemImage: "ellipsis.circle")
        .frame(maxWidth: .infinity)
}
.artDecoButton(style: .ghost)
```

Keep existing builder methods private while moving only the visible entry points into sheets. Remove `quickActionsCard` from the top-level Today stack.

- [ ] **Step 7: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayWhySheet.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/TodayMoreSheet.swift
git commit -m "feat(today): simplify daily action surface"
```

## Task 3: Merge Workouts and Programs Into Train

**Outcome:** The app has four tabs: Today, Train, Cycle, Progress. `TrainHubView` becomes the single home for starting sessions, viewing history, and choosing programs.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift`

- [ ] **Step 1: Create `TrainHubView`**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift`:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct TrainHubView: View {
    @State private var showingNewWorkout = false
    @State private var showingAIWorkout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingAIWorkout = true
                    } label: {
                        Label("Build Coach Plan", systemImage: "sparkles")
                    }

                    Button {
                        showingNewWorkout = true
                    } label: {
                        Label("Build Your Own", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Start")
                }

                Section("Continue") {
                    NavigationLink {
                        WorkoutsListView()
                    } label: {
                        Label("Workout History", systemImage: "clock.arrow.circlepath")
                    }

                    NavigationLink {
                        ProgramsListView()
                    } label: {
                        Label("Programs", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            .navigationTitle("Train")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingNewWorkout) {
                NewWorkoutView {
                    showingNewWorkout = false
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #else
            .sheet(isPresented: $showingAIWorkout) {
                AIWorkoutView {
                    showingAIWorkout = false
                }
            }
            #endif
        }
    }
}
```

- [ ] **Step 2: Update `MainTabView`**

In `SundeeFundeeApp.swift`, replace `WorkoutsListView()` and `ProgramsListView()` tabs with:

```swift
TrainHubView()
    .tabItem {
        Label("Train", systemImage: selectedTab == .train ? "figure.strengthtraining.traditional" : "figure.strengthtraining.traditional")
    }
    .tag(Tab.train)
    .accessibilityHint("Start workouts, view history, and browse programs")
```

Update `Tab`:

```swift
public enum Tab: String {
    case today
    case train
    case cycle
    case progress
}
```

Update notification handlers that currently set `.workouts` to `.train`.

- [ ] **Step 3: Fix user-facing error copy in the moved views**

In `WorkoutsListViewModel`, replace raw error strings:

```swift
errorMessage = "We couldn't load your workout history. Pull to refresh or try again in a moment."
errorMessage = "We couldn't delete that workout. Check your connection and try again."
errorMessage = "We couldn't restart that workout. Open the workout and try again."
```

In `ProgramsListViewModel`, replace raw error strings:

```swift
errorMessage = "We couldn't load programs. Pull to refresh or try again in a moment."
errorMessage = "We couldn't enroll you in that program. Check your connection and try again."
```

- [ ] **Step 4: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Train/TrainHubView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift
git commit -m "feat(navigation): consolidate training surfaces"
```

## Task 4: Make Progress Summary-First and Data-Aware

**Outcome:** Progress shows one useful summary first and hides inactive tools until the user has relevant data.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift`

- [ ] **Step 1: Extend policy tests for all-hidden progress**

Add to `MinimalSurfacePolicyTests`:

```swift
func testProgressAlwaysKeepsExportAvailable() {
    let destinations = MinimalSurfacePolicy.progressDestinations(
        input: ProgressDestinationInput(
            hasMaxes: false,
            hasBenchmarks: false,
            hasChallenges: false,
            hasBuddyCheckIns: false,
            hasMonthlyReview: false,
            hasAnalytics: false,
            alwaysShowExport: true
        )
    )

    XCTAssertEqual(destinations, [.export])
}
```

- [ ] **Step 2: Add local loading state to Progress**

In `ProgressHubView`, add:

```swift
@State private var destinations: [ProgressDestination] = [.export]
@State private var isLoading = true
```

Add a `loadDestinations()` method that fetches existing records:

```swift
@MainActor
private func loadDestinations() async {
    isLoading = true
    let dataClient = DataClientFactory.shared.client
    async let maxesTask: [OneRepMaxRecord] = dataClient.fetchAll(recordType: "OneRepMaxRecord")
    async let benchmarksTask: [BenchmarkResult] = dataClient.fetchAll(recordType: "BenchmarkResult")
    async let challengesTask: [Challenge] = dataClient.fetchAll(recordType: "Challenge")
    async let checkInsTask: [BuddyCheckInRecord] = dataClient.fetchAll(recordType: "BuddyCheckInRecord")
    async let workoutsTask: [Workout] = dataClient.fetchAll(recordType: "Workout")

    let maxes = (try? await maxesTask) ?? []
    let benchmarks = (try? await benchmarksTask) ?? []
    let challenges = (try? await challengesTask) ?? []
    let checkIns = (try? await checkInsTask) ?? []
    let workouts = (try? await workoutsTask) ?? []

    destinations = MinimalSurfacePolicy.progressDestinations(
        input: ProgressDestinationInput(
            hasMaxes: !maxes.isEmpty,
            hasBenchmarks: !benchmarks.isEmpty,
            hasChallenges: !challenges.isEmpty,
            hasBuddyCheckIns: !checkIns.isEmpty,
            hasMonthlyReview: !workouts.isEmpty,
            hasAnalytics: workouts.count >= 2,
            alwaysShowExport: true
        )
    )
    isLoading = false
}
```

- [ ] **Step 3: Render Progress from `destinations`**

Replace the static list with a first summary section:

```swift
Section {
    NavigationLink {
        MonthlyReviewDetailView()
    } label: {
        Label("This Month", systemImage: "calendar.badge.clock")
    }
}
```

Then render other destinations only if they are present in `destinations`:

```swift
if destinations.contains(.maxes) {
    NavigationLink { MaxesListView() } label: { Label("One-Rep Maxes", systemImage: "scalemass") }
}
if destinations.contains(.benchmarks) {
    NavigationLink { BenchmarksListView() } label: { Label("Benchmarks", systemImage: "trophy") }
}
if destinations.contains(.analytics) {
    NavigationLink { AnalyticsView() } label: { Label("Analytics", systemImage: "chart.xyaxis.line") }
}
if destinations.contains(.challenges) {
    NavigationLink { ChallengesView() } label: { Label("Challenges", systemImage: "flag") }
}
if destinations.contains(.buddyCheckIns) {
    NavigationLink { BuddyCheckInHistoryView() } label: { Label("Buddy Check-Ins", systemImage: "person.2.checkmark") }
}
if destinations.contains(.export) {
    NavigationLink { ExportView() } label: { Label("Export", systemImage: "square.and.arrow.up") }
}
```

- [ ] **Step 4: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Progress/ProgressHubView.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift
git commit -m "feat(progress): hide inactive progress tools"
```

## Task 5: Focus the Active Workout Screen

**Outcome:** Active workout logging keeps only header, progress, current exercise, set inputs, and complete button visible by default.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Add disclosure state**

In `ActiveWorkoutView`, add:

```swift
@State private var showingWorkoutDetails = false
@State private var showingWorkoutOptions = false
```

- [ ] **Step 2: Move secondary cards behind menu actions**

Keep `restTimerCard` visible only while `viewModel.isResting`. Move these behind `showingWorkoutDetails`:

```swift
if showingWorkoutDetails {
    if let decision = viewModel.adaptationDecisionRecord, viewModel.completedSets == 0 {
        adaptationDecisionCard(decision)
            .padding(.horizontal, AppTheme.Spacing.lg)
    }

    if !viewModel.lastEquipmentConversionChanges.isEmpty {
        conversionSummaryCard
            .padding(.horizontal, AppTheme.Spacing.lg)
    }

    if viewModel.canStartWarmup, let warmupBlock = viewModel.pendingWarmupBlock {
        warmupStartCard(warmupBlock)
            .padding(.horizontal, AppTheme.Spacing.lg)
    }
}
```

- [ ] **Step 3: Consolidate top-level actions into one menu**

Replace the existing header menu with:

```swift
Menu {
    Button {
        showingWorkoutDetails.toggle()
    } label: {
        Label(showingWorkoutDetails ? "Hide details" : "Show details", systemImage: "info.circle")
    }

    Button {
        showingEquipmentConversionPicker = true
    } label: {
        Label("Convert Equipment", systemImage: "wrench.and.screwdriver")
    }

    Button {
        showingSwapSheet = true
    } label: {
        Label("Swap Exercise", systemImage: "arrow.triangle.swap")
    }

    Button {
        showingStationTakenPicker = true
    } label: {
        Label("Station Taken", systemImage: "exclamationmark.triangle")
    }
} label: {
    Image(systemName: "ellipsis.circle")
        .foregroundColor(AppTheme.Text.secondary)
}
.accessibilityLabel("Workout options")
```

Remove the separate exercise-card menu so there is one overflow menu on the screen.

- [ ] **Step 4: Make effort optional by disclosure**

Wrap `effortPicker` in a compact disclosure:

```swift
DisclosureGroup {
    effortPicker
        .padding(.top, AppTheme.Spacing.xs)
} label: {
    Label(selectedSetRPE.map { "Effort: RPE \($0)" } ?? "Add effort", systemImage: "gauge.with.dots.needle.33percent")
        .font(AppTheme.Typography.labelLarge)
        .foregroundColor(AppTheme.Text.primary)
}
.tint(AppTheme.Accent.gold)
```

- [ ] **Step 5: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter ActiveWorkoutSessionViewModelTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): focus active session controls"
```

## Task 6: Add One Quick Check-In

**Outcome:** Users can log energy, symptoms, pain, and active period state from one short flow.

**Files:**

- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/CheckIn/QuickCheckInView.swift`
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/QuickCheckInViewModel.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/QuickCheckInViewModelTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift`

- [ ] **Step 1: Write failing view-model tests**

Create `QuickCheckInViewModelTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class QuickCheckInViewModelTests: XCTestCase {
    func testSaveSymptomOnlyCheckIn() async throws {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        viewModel.energy = 7
        viewModel.fatigue = 3
        viewModel.soreness = 4
        viewModel.cramps = 1

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 0)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 0)
    }

    func testSavePainAndPeriodCheckIn() async throws {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        viewModel.energy = 5
        viewModel.fatigue = 6
        viewModel.soreness = 5
        viewModel.cramps = 4
        viewModel.hasPain = true
        viewModel.painIntensity = 6
        viewModel.painType = .soreness
        viewModel.isPeriodActive = true

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 1)
    }
}
```

Run:

```bash
cd SundeeFundee && swift test --filter QuickCheckInViewModelTests
```

Expected: compile failure containing `cannot find 'QuickCheckInViewModel' in scope`.

- [ ] **Step 2: Implement the view model**

Create `QuickCheckInViewModel.swift`:

```swift
import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class QuickCheckInViewModel: ObservableObject {
    @Published var energy = 5
    @Published var fatigue = 5
    @Published var soreness = 3
    @Published var cramps = 0
    @Published var hasPain = false
    @Published var painIntensity = 1
    @Published var painType: PainType = .soreness
    @Published var painLocationId = BodyRegions.allRegions.first?.id ?? "lower_back"
    @Published var isPeriodActive = false
    @Published var notes = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func save(date: Date = Date()) async {
        isSaving = true
        errorMessage = nil
        do {
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let symptom = SymptomCheckInRecord(
                symptomDate: date,
                cramps: cramps,
                fatigue: fatigue,
                soreness: soreness,
                energy: energy,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            try await dataClient.save(symptom, recordType: "SymptomCheckInRecord")

            if hasPain {
                let painLog = DailyPainLog(
                    id: UUID().uuidString,
                    locationIds: painLocationId,
                    intensity: painIntensity,
                    painType: painType,
                    date: date,
                    notes: trimmedNotes.isEmpty ? nil : trimmedNotes
                )
                try await dataClient.save(painLog, recordType: "DailyPainLog")
            }

            if isPeriodActive {
                let period = PeriodLogRecord(startDate: Calendar.current.startOfDay(for: date), endDate: nil)
                try await dataClient.save(period, recordType: "PeriodLogRecord")
                NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            }
        } catch {
            errorMessage = "We couldn't save your check-in. Check your connection and try again."
        }
        isSaving = false
    }
}
```

- [ ] **Step 3: Create the quick view**

Create `QuickCheckInView.swift` with sliders for energy, fatigue, soreness, cramps; a toggle for pain; a segmented pain type picker; a toggle for period active; a notes field; and a single Save button:

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct QuickCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuickCheckInViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Today") {
                    valueSlider("Energy", value: $viewModel.energy)
                    valueSlider("Fatigue", value: $viewModel.fatigue)
                    valueSlider("Soreness", value: $viewModel.soreness)
                    valueSlider("Cramps", value: $viewModel.cramps)
                }

                Section("Pain") {
                    Toggle("Pain today", isOn: $viewModel.hasPain)
                    if viewModel.hasPain {
                        valueSlider("Intensity", value: $viewModel.painIntensity)
                        Picker("Area", selection: $viewModel.painLocationId) {
                            ForEach(BodyRegions.allRegions, id: \.id) { region in
                                Text(region.displayName).tag(region.id)
                            }
                        }
                        Picker("Type", selection: $viewModel.painType) {
                            ForEach(PainType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                }

                Section("Cycle") {
                    Toggle("Period active today", isOn: $viewModel.isPeriodActive)
                }

                Section("Notes") {
                    TextField("Optional", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Quick Check-In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Check-In Failed", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func valueSlider(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value.wrappedValue)")
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: 0...10,
                step: 1
            )
        }
    }
}
```

- [ ] **Step 4: Replace scattered recovery input entry points**

Add a `Quick Check-In` action to Today and Recovery. For `CycleTrackingView`, place it near symptom check-in so the dedicated detailed screens still exist but are not the default path.

- [ ] **Step 5: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter QuickCheckInViewModelTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/CheckIn/QuickCheckInView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/QuickCheckInViewModel.swift SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/QuickCheckInViewModelTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Recovery/RecoveryOverviewView.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleTrackingView.swift
git commit -m "feat(checkin): add unified quick check-in"
```

## Task 7: Reduce Onboarding

**Outcome:** Onboarding asks only goal, equipment, cycle preference, and unit, then offers to start the first workout.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/OnboardingViewModelTests.swift`

- [ ] **Step 1: Add onboarding tests**

Create `OnboardingViewModelTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testMinimalOnboardingDefaultsExperienceToIntermediate() {
        let viewModel = OnboardingViewModel(dataClient: MockCloudKitClient())
        XCTAssertEqual(viewModel.experienceLevel, .intermediate)
        XCTAssertEqual(viewModel.totalSteps, 2)
    }

    func testCompleteOnboardingSavesMinimalPreferences() async {
        let dataClient = MockCloudKitClient()
        let viewModel = OnboardingViewModel(dataClient: dataClient)
        viewModel.primaryGoal = .strength
        viewModel.defaultEquipment = .resistanceBands
        viewModel.weightUnit = .lbs
        viewModel.cycleTrackingEnabled = true

        await viewModel.completeOnboarding()

        XCTAssertEqual(dataClient.recordCount(for: "UserSettings"), 1)
    }
}
```

- [ ] **Step 2: Add `totalSteps` and clamp navigation**

In `OnboardingViewModel`, add:

```swift
let totalSteps = 2
```

Update progress bar math to divide by `CGFloat(viewModel.totalSteps)`. Update navigation checks from `currentStep < 3` to `currentStep < viewModel.totalSteps - 1`.

- [ ] **Step 3: Replace `TabView` steps**

Use only:

```swift
TabView(selection: $viewModel.currentStep) {
    welcomeStep.tag(0)
    minimalistPreferencesStep.tag(1)
}
```

Create `minimalistPreferencesStep` by combining goal, equipment, cycle tracking, and weight unit. Keep `experienceLevel` as `.intermediate` without asking.

- [ ] **Step 4: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter OnboardingViewModelTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Onboarding/OnboardingView.swift SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/OnboardingViewModelTests.swift
git commit -m "feat(onboarding): shorten first-run setup"
```

## Task 8: Make Sharing Quiet and Private

**Outcome:** Share prompts are gated to meaningful wins; share sheets still exist, but controls are calm and privacy-first.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift`
- Modify: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/SharePrivacyTests.swift`

- [ ] **Step 1: Add explicit policy tests**

Add to `MinimalSurfacePolicyTests`:

```swift
func testCycleInsightDoesNotAutoPromptShare() {
    XCTAssertFalse(MinimalSurfacePolicy.shouldPromptShare(for: .cycleInsight))
}
```

- [ ] **Step 2: Gate PR share prompt**

In `ActiveWorkoutSessionViewModel`, find the assignment to `pendingPRShare`. Wrap it with:

```swift
if MinimalSurfacePolicy.shouldPromptShare(for: .personalRecord) {
    pendingPRShare = PendingPRShare(
        exerciseName: exercise.name,
        weight: completedWeight,
        unit: "lb",
        previousBest: currentMax?.weight
    )
}
```

Do not add auto prompts for completed non-PR workouts or cycle insight cards.

- [ ] **Step 3: Collapse advanced share controls**

In `ShareCardSheet`, add:

```swift
@State private var showingShareOptions = false
```

Replace the always-visible `photoControls`, `privacyControls`, and `aspectPicker` with:

```swift
DisclosureGroup(isExpanded: $showingShareOptions) {
    photoControls
    privacyControls
    aspectPicker
} label: {
    Label("Share Options", systemImage: "slider.horizontal.3")
        .font(AppTheme.Typography.labelLarge)
        .foregroundColor(AppTheme.Text.primary)
}
.tint(AppTheme.Accent.gold)
```

Keep `SharePrivacyOptions.savedPreset` as the initial value. The existing tests already assert private defaults.

- [ ] **Step 4: Verify and commit**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
cd SundeeFundee && swift test --filter SharePrivacyTests
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and Xcode build pass.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/MinimalSurfacePolicyTests.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/SharePrivacyTests.swift
git commit -m "feat(share): keep prompts quiet and private"
```

## Task 9: Regroup Settings

**Outcome:** Settings has three clear groups: Training, Privacy, and Account. Diagnostics stay hidden unless actionable.

**Files:**

- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Rename and reduce sections**

Restructure `SettingsView` into:

```swift
Section("Training") {
    Picker("Weight Unit", selection: $viewModel.weightUnit) { ... }
    Picker("Goal", selection: $viewModel.primaryGoal) { ... }
    Picker("Default Equipment", selection: $viewModel.defaultEquipment) { ... }
    #if canImport(UserNotifications)
    NavigationLink { WorkoutRemindersSettingsView() } label: {
        Label("Reminders", systemImage: "bell")
    }
    #endif
}

Section("Privacy") {
    NavigationLink { DataTrustCenterView() } label: {
        Label("Data Trust Center", systemImage: "shield.checkered")
    }
    NavigationLink { ExportView() } label: {
        Label("Export My Data", systemImage: "square.and.arrow.up")
    }
    #if canImport(UIKit)
    NavigationLink { SharePrivacyDefaultsView() } label: {
        Label("Share Defaults", systemImage: "hand.raised")
    }
    #endif
}

Section("Account") {
    profileRow
    Text("Sundee Fundee is a fitness tool, not a medical device...")
    versionRow
    Link("Website", destination: SettingsLinks.homepage)
    Link("Privacy Policy", destination: SettingsLinks.privacy)
    Link("Terms of Service", destination: SettingsLinks.terms)
    Button("Sign Out") { authViewModel.signOut() }
    Button("Delete All Data & Account") { showingDeleteConfirmation = true }
}
```

Keep `diagnostics.decodeFailureCount > 0` as the only diagnostics visibility trigger.

- [ ] **Step 2: Keep equipment profiles out of the default list**

Move `Equipment Profiles` behind the `Default Equipment` picker by showing only the selected profile in Settings. Retain `setDefaultEquipmentProfile(_:)` for future dedicated equipment management, but do not show every profile in the default Settings list.

- [ ] **Step 3: Verify and commit**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: Xcode build passes.

Commit:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift
git commit -m "feat(settings): simplify preference groups"
```

## Task 10: Full Verification Pass

**Outcome:** The whole minimalist redesign builds, targeted tests pass, and the final app surface matches the 10 stories.

**Files:**

- Modify: `CHANGELOG.md`

- [ ] **Step 1: Run targeted tests**

Run:

```bash
cd SundeeFundee && swift test --filter MinimalSurfacePolicyTests
cd SundeeFundee && swift test --filter QuickCheckInViewModelTests
cd SundeeFundee && swift test --filter OnboardingViewModelTests
cd SundeeFundee && swift test --filter ActiveWorkoutSessionViewModelTests
cd SundeeFundee && swift test --filter SharePrivacyTests
```

Expected: all targeted tests pass.

- [ ] **Step 2: Run broader package tests**

Run:

```bash
cd SundeeFundee && swift test
```

Expected: all package tests pass.

- [ ] **Step 3: Run app build**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: app build passes.

- [ ] **Step 4: Update changelog**

Add an unreleased entry to `CHANGELOG.md`:

```markdown
## [Unreleased]

### Changed

- Simplified the main app structure around Today, Train, Cycle, and Progress.
- Reduced Today to one primary recommendation with supporting details behind disclosure.
- Consolidated workout history and programs into a single Train hub.
- Made Progress, Settings, sharing, onboarding, and active workout logging calmer by default.
```

- [ ] **Step 5: Commit verification docs**

Run:

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): note minimalist redesign"
```

- [ ] **Step 6: Final git status**

Run:

```bash
git status --short
```

Expected: no tracked-file changes remain. Unrelated untracked files may remain untouched.

# Readiness & Auto-Regulation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a daily readiness check-in (manual survey + optional HealthKit) that auto-adjusts workout intensity for both program and AI workouts.

**Architecture:** Pure Domain scorer (`ReadinessSurvey`) blends manual inputs with HealthKit metrics. Score persisted to UserDefaults by date. Dashboard card shows score; pre-workout sheet gates workout start. Existing `CycleAdaptationPolicy` already consumes readiness tiers.

**Tech Stack:** Swift 6, SwiftUI, HealthKit, UserDefaults, XCTest

---

### Task 1: ReadinessSurvey Domain Scorer

**Files:**
- Create: `SundeeFundee/Domain/ReadinessSurvey.swift`
- Test: `SundeeFundeTests/ReadinessSurveyTests.swift`

**Step 1: Write the failing tests**

```swift
// SundeeFundeTests/ReadinessSurveyTests.swift
import XCTest
@testable import SundeeFundee

final class ReadinessSurveyTests: XCTestCase {

    // MARK: - Survey-only scoring

    func testSurveyOnlyScoreWeightedAverage() {
        // sleep=8 (40%), stress=4 (30% — inverted: 10-4=6), soreness=3 (30% — inverted: 10-3=7)
        let result = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        // (8*0.4) + (6*0.3) + (7*0.3) = 3.2 + 1.8 + 2.1 = 7.1
        XCTAssertEqual(result.score, 7.1, accuracy: 0.01)
    }

    func testSurveyAllOnesGivesLowScore() {
        let result = ReadinessSurvey.score(
            sleepQuality: 1, stressLevel: 10, sorenessLevel: 10
        )
        // sleep=1*0.4 + stress=(10-10=0)*0.3 + soreness=(10-10=0)*0.3 = 0.4
        XCTAssertEqual(result.score, 0.4, accuracy: 0.01)
        XCTAssertEqual(result.tier, .low)
    }

    func testSurveyAllTensGivesHighScore() {
        let result = ReadinessSurvey.score(
            sleepQuality: 10, stressLevel: 1, sorenessLevel: 1
        )
        // sleep=10*0.4 + stress=(10-1=9)*0.3 + soreness=(10-1=9)*0.3 = 4+2.7+2.7=9.4
        XCTAssertEqual(result.score, 9.4, accuracy: 0.01)
        XCTAssertEqual(result.tier, .high)
    }

    func testMidRangeGivesNeutralTier() {
        let result = ReadinessSurvey.score(
            sleepQuality: 5, stressLevel: 5, sorenessLevel: 5
        )
        // sleep=5*0.4 + stress=5*0.3 + soreness=5*0.3 = 2+1.5+1.5=5.0
        XCTAssertEqual(result.score, 5.0, accuracy: 0.01)
        XCTAssertEqual(result.tier, .neutral)
    }

    // MARK: - HealthKit blending

    func testBlendedScoreWithHealthKit() {
        let surveyResult = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        let healthKitScore = 5.0
        let blended = ReadinessSurvey.blendWithHealthKit(
            surveyScore: surveyResult.score,
            healthKitScore: healthKitScore
        )
        // 7.1 * 0.7 + 5.0 * 0.3 = 4.97 + 1.5 = 6.47
        XCTAssertEqual(blended.score, 6.47, accuracy: 0.01)
    }

    func testBlendedWithNilHealthKitReturnsSurveyOnly() {
        let surveyResult = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        let blended = ReadinessSurvey.blendWithHealthKit(
            surveyScore: surveyResult.score,
            healthKitScore: nil
        )
        XCTAssertEqual(blended.score, surveyResult.score, accuracy: 0.01)
    }

    // MARK: - Tier thresholds

    func testTierFromScoreBoundaries() {
        XCTAssertEqual(ReadinessSurvey.tierFromScore(3.0), .low)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(3.1), .neutral)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(7.9), .neutral)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(8.0), .high)
    }

    // MARK: - Tier display

    func testTierDisplayName() {
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.low), "Fatigued")
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.neutral), "Normal")
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.high), "Prime")
    }

    // MARK: - Persistence

    func testSaveAndLoadTodayScore() {
        let defaults = UserDefaults(suiteName: "test-readiness")!
        defaults.removePersistentDomain(forName: "test-readiness")

        let result = ReadinessResult(score: 7.5, tier: .neutral)
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)

        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.score, 7.5, accuracy: 0.01)
        XCTAssertEqual(loaded?.tier, .neutral)
    }

    func testLoadReturnsNilForDifferentDay() {
        let defaults = UserDefaults(suiteName: "test-readiness-2")!
        defaults.removePersistentDomain(forName: "test-readiness-2")

        // Save with a past date key
        defaults.set(7.5, forKey: "readiness-score-2020-01-01")
        defaults.set("neutral", forKey: "readiness-tier-2020-01-01")

        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNil(loaded)
    }

    // MARK: - Adjustment banner text

    func testBannerTextLow() {
        let text = ReadinessSurvey.adjustmentBannerText(for: .low)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("reduced"))
    }

    func testBannerTextHigh() {
        let text = ReadinessSurvey.adjustmentBannerText(for: .high)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("boosted"))
    }

    func testBannerTextNeutralIsNil() {
        XCTAssertNil(ReadinessSurvey.adjustmentBannerText(for: .neutral))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/ReadinessSurveyTests`
Expected: FAIL — `ReadinessSurvey` not found

**Step 3: Write minimal implementation**

```swift
// SundeeFundee/Domain/ReadinessSurvey.swift
import Foundation

struct ReadinessResult: Equatable {
    let score: Double
    let tier: AdaptationReadinessTier
}

enum ReadinessSurvey {
    // MARK: - Weights
    private static let sleepWeight = 0.4
    private static let stressWeight = 0.3
    private static let sorenessWeight = 0.3

    // MARK: - Scoring

    /// Compute readiness from manual survey inputs.
    /// sleepQuality: 1-10 (higher = better sleep)
    /// stressLevel: 1-10 (higher = more stressed — inverted internally)
    /// sorenessLevel: 1-10 (higher = more sore — inverted internally)
    static func score(
        sleepQuality: Double,
        stressLevel: Double,
        sorenessLevel: Double
    ) -> ReadinessResult {
        let invertedStress = 10.0 - stressLevel
        let invertedSoreness = 10.0 - sorenessLevel
        let raw = sleepQuality * sleepWeight
            + invertedStress * stressWeight
            + invertedSoreness * sorenessWeight
        let clamped = raw.clamped(to: 0...10)
        return ReadinessResult(score: clamped, tier: tierFromScore(clamped))
    }

    /// Blend survey score with HealthKit score (70/30 split).
    static func blendWithHealthKit(
        surveyScore: Double,
        healthKitScore: Double?
    ) -> ReadinessResult {
        guard let hk = healthKitScore else {
            return ReadinessResult(score: surveyScore, tier: tierFromScore(surveyScore))
        }
        let blended = (surveyScore * 0.7 + hk * 0.3).clamped(to: 0...10)
        return ReadinessResult(score: blended, tier: tierFromScore(blended))
    }

    // MARK: - Tier mapping (matches CycleAdaptationPolicy thresholds)

    static func tierFromScore(_ score: Double) -> AdaptationReadinessTier {
        if score <= 3 { return .low }
        if score >= 8 { return .high }
        return .neutral
    }

    static func tierDisplayName(_ tier: AdaptationReadinessTier) -> String {
        switch tier {
        case .low: "Fatigued"
        case .neutral: "Normal"
        case .high: "Prime"
        }
    }

    // MARK: - Persistence (UserDefaults, keyed by date)

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt
    }()

    private static func todayKey(prefix: String) -> String {
        "\(prefix)-\(dateFormatter.string(from: .now))"
    }

    static func saveTodayResult(_ result: ReadinessResult, defaults: UserDefaults = .standard) {
        let dateStr = dateFormatter.string(from: .now)
        defaults.set(result.score, forKey: "readiness-score-\(dateStr)")
        defaults.set(tierRawValue(result.tier), forKey: "readiness-tier-\(dateStr)")
    }

    static func loadTodayResult(defaults: UserDefaults = .standard) -> ReadinessResult? {
        let dateStr = dateFormatter.string(from: .now)
        let scoreKey = "readiness-score-\(dateStr)"
        let tierKey = "readiness-tier-\(dateStr)"
        guard defaults.object(forKey: scoreKey) != nil else { return nil }
        let score = defaults.double(forKey: scoreKey)
        let tierStr = defaults.string(forKey: tierKey) ?? "neutral"
        return ReadinessResult(score: score, tier: tierFromRawValue(tierStr))
    }

    private static func tierRawValue(_ tier: AdaptationReadinessTier) -> String {
        switch tier {
        case .low: "low"
        case .neutral: "neutral"
        case .high: "high"
        }
    }

    private static func tierFromRawValue(_ raw: String) -> AdaptationReadinessTier {
        switch raw {
        case "low": .low
        case "high": .high
        default: .neutral
        }
    }

    // MARK: - Adjustment banner

    static func adjustmentBannerText(for tier: AdaptationReadinessTier) -> String? {
        switch tier {
        case .low: "Volume reduced 40% — low readiness"
        case .high: "Intensity boosted 20% — high readiness"
        case .neutral: nil
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodegen generate && xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests/ReadinessSurveyTests`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/ReadinessSurvey.swift SundeeFundeTests/ReadinessSurveyTests.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add ReadinessSurvey domain scorer with tests (issue #93)"
```

---

### Task 2: ReadinessSurveyViewModel

**Files:**
- Create: `SundeeFundee/Features/Readiness/ReadinessSurveyViewModel.swift`
- Test: `SundeeFundeTests/ReadinessSurveyViewModelTests.swift`

**Step 1: Write failing tests**

```swift
// SundeeFundeTests/ReadinessSurveyViewModelTests.swift
import XCTest
@testable import SundeeFundee

@MainActor
final class ReadinessSurveyViewModelTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let name = "test-survey-vm-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testInitialSliderValues() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults())
        XCTAssertEqual(vm.sleepQuality, 5)
        XCTAssertEqual(vm.stressLevel, 5)
        XCTAssertEqual(vm.sorenessLevel, 5)
    }

    func testLivePreviewUpdatesOnSliderChange() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults())
        vm.sleepQuality = 9
        vm.stressLevel = 2
        vm.sorenessLevel = 2
        let preview = vm.livePreview
        XCTAssertTrue(preview.score > 7)
        XCTAssertEqual(preview.tier, .high)
    }

    func testSubmitSavesToDefaults() {
        let defaults = freshDefaults()
        let vm = ReadinessSurveyViewModel(defaults: defaults)
        vm.sleepQuality = 8
        vm.stressLevel = 3
        vm.sorenessLevel = 3
        vm.submit()

        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertTrue(loaded!.score > 6)
    }

    func testSubmitWithHealthKitBlending() {
        let defaults = freshDefaults()
        let vm = ReadinessSurveyViewModel(defaults: defaults, healthKitScore: 4.0)
        vm.sleepQuality = 8
        vm.stressLevel = 3
        vm.sorenessLevel = 3
        vm.submit()

        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        // Blended should be lower than pure survey due to low HK score
        let pureResult = ReadinessSurvey.score(sleepQuality: 8, stressLevel: 3, sorenessLevel: 3)
        XCTAssertTrue(loaded!.score < pureResult.score)
    }

    func testAutoFillSleepFromHealthKit() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults(), healthKitSleepHours: 7.5)
        // 7.5 hours → quality ~8 (7.5/9*10 ≈ 8.3, rounded)
        XCTAssertEqual(vm.sleepQuality, 8)
    }

    func testHasExistingScoreToday() {
        let defaults = freshDefaults()
        XCTAssertFalse(ReadinessSurveyViewModel.hasScoreToday(defaults: defaults))

        let result = ReadinessResult(score: 5.0, tier: .neutral)
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)

        XCTAssertTrue(ReadinessSurveyViewModel.hasScoreToday(defaults: defaults))
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test ... -only-testing:SundeeFundeTests/ReadinessSurveyViewModelTests`
Expected: FAIL

**Step 3: Write implementation**

```swift
// SundeeFundee/Features/Readiness/ReadinessSurveyViewModel.swift
import Foundation

@MainActor
@Observable
final class ReadinessSurveyViewModel {
    var sleepQuality: Double = 5
    var stressLevel: Double = 5
    var sorenessLevel: Double = 5

    private let defaults: UserDefaults
    private let healthKitScore: Double?

    var livePreview: ReadinessResult {
        let survey = ReadinessSurvey.score(
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            sorenessLevel: sorenessLevel
        )
        return ReadinessSurvey.blendWithHealthKit(
            surveyScore: survey.score,
            healthKitScore: healthKitScore
        )
    }

    init(
        defaults: UserDefaults = .standard,
        healthKitScore: Double? = nil,
        healthKitSleepHours: Double? = nil
    ) {
        self.defaults = defaults
        self.healthKitScore = healthKitScore

        if let hours = healthKitSleepHours {
            // Convert hours to 1-10 quality: 9h = 10, scale linearly
            self.sleepQuality = min(10, max(1, (hours / 9.0 * 10).rounded()))
        }
    }

    func submit() {
        let result = livePreview
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)
    }

    static func hasScoreToday(defaults: UserDefaults = .standard) -> Bool {
        ReadinessSurvey.loadTodayResult(defaults: defaults) != nil
    }
}
```

**Step 4: Run tests, verify pass**

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Readiness/ReadinessSurveyViewModel.swift SundeeFundeTests/ReadinessSurveyViewModelTests.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add ReadinessSurveyViewModel with HealthKit blending (issue #93)"
```

---

### Task 3: ReadinessSurveySheet (UI)

**Files:**
- Create: `SundeeFundee/Features/Readiness/ReadinessSurveySheet.swift`

**Step 1: Write the view**

```swift
// SundeeFundee/Features/Readiness/ReadinessSurveySheet.swift
import SwiftUI

struct ReadinessSurveySheet: View {
    @State var viewModel: ReadinessSurveyViewModel
    let onSubmit: (ReadinessResult) -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        headerSection
                        previewSection
                        slidersSection
                        submitButton
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Readiness Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { onSkip() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var headerSection: some View {
        Text("How are you feeling?")
            .font(AppTheme.Fonts.heading)
            .foregroundStyle(AppTheme.Colors.navy)
    }

    private var previewSection: some View {
        let preview = viewModel.livePreview
        return VStack(spacing: AppTheme.Spacing.sm) {
            Text(String(format: "%.1f", preview.score))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(tierColor(preview.tier))
            Text(ReadinessSurvey.tierDisplayName(preview.tier))
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private var slidersSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            sliderRow(
                title: "Sleep Quality",
                value: $viewModel.sleepQuality,
                lowLabel: "Poor",
                highLabel: "Great"
            )
            sliderRow(
                title: "Stress Level",
                value: $viewModel.stressLevel,
                lowLabel: "Calm",
                highLabel: "Stressed"
            )
            sliderRow(
                title: "Soreness Level",
                value: $viewModel.sorenessLevel,
                lowLabel: "Fresh",
                highLabel: "Very Sore"
            )
        }
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        lowLabel: String,
        highLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(title)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Spacer()
                Text(String(format: "%.0f", value.wrappedValue))
                    .font(AppTheme.Fonts.body.monospacedDigit())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Slider(value: value, in: 1...10, step: 1)
                .tint(AppTheme.Colors.accentOrange)
            HStack {
                Text(lowLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text(highLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private var submitButton: some View {
        Button {
            viewModel.submit()
            onSubmit(viewModel.livePreview)
        } label: {
            Label("Start Workout", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("readiness-submit-button")
    }

    static func tierColor(_ tier: AdaptationReadinessTier) -> Color {
        switch tier {
        case .low: AppTheme.Colors.warmRose
        case .neutral: AppTheme.Colors.navy
        case .high: AppTheme.Colors.accentOrange
        }
    }
}

// Reusable tier color function for other views
extension ReadinessSurveySheet {
    static func tierColorForCard(_ tier: AdaptationReadinessTier) -> Color {
        tierColor(tier)
    }
}
```

**Step 2: Build to verify compilation**

Run: `xcodegen generate && xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add SundeeFundee/Features/Readiness/ReadinessSurveySheet.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add ReadinessSurveySheet with sliders and live preview (issue #93)"
```

---

### Task 4: Dashboard Readiness Card

**Files:**
- Create: `SundeeFundee/Features/Readiness/ReadinessCard.swift`
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift:24-28` — insert card before cycle phase card
- Modify: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift:24-25` — add `todayReadiness` property

**Step 1: Create ReadinessCard**

```swift
// SundeeFundee/Features/Readiness/ReadinessCard.swift
import SwiftUI

struct ReadinessCard: View {
    let result: ReadinessResult?
    let onCheckIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY READINESS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)
                    if let result {
                        Text(ReadinessSurvey.tierDisplayName(result.tier))
                            .font(AppTheme.Fonts.subheading)
                            .foregroundStyle(AppTheme.Colors.navy)
                    } else {
                        Text("Not checked in yet")
                            .font(AppTheme.Fonts.subheading)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                if let result {
                    Text(String(format: "%.1f", result.score))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ReadinessSurveySheet.tierColor(result.tier))
                } else {
                    Image(systemName: "heart.text.clipboard")
                        .font(.title2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Button(action: onCheckIn) {
                Label(
                    result == nil ? "Check In" : "Update",
                    systemImage: result == nil ? "plus.circle.fill" : "arrow.clockwise"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(result == nil ? PrimaryButtonStyle() : SecondaryButtonStyle())
            .accessibilityIdentifier("readiness-check-in-button")
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// NOTE: If SecondaryButtonStyle doesn't exist, use this inline:
// .buttonStyle(.bordered) .tint(AppTheme.Colors.navy)
```

**Step 2: Add `todayReadiness` to DashboardViewModel**

In `DashboardViewModel.swift`, add a stored property at line 25:

```swift
var todayReadiness: ReadinessResult? = ReadinessSurvey.loadTodayResult()
```

In the `load()` method, after `loadReadinessMetrics()` (line 54), add:

```swift
todayReadiness = ReadinessSurvey.loadTodayResult()
if todayReadiness == nil, let healthKitScore = readinessScore {
    // No survey today but HealthKit available — store readinessScore for adapters
    // Don't auto-save — let user do the survey
}
```

Also update the `readinessScore` pass-through: in `loadActiveProgram()` at line 169, change to use todayReadiness if available:

```swift
readinessScore: todayReadiness?.score ?? readinessScore
```

**Step 3: Insert ReadinessCard into DashboardView**

In `DashboardView.swift`, after `greetingHeader` (line 25), before the menstrual phase card, add:

```swift
ReadinessCard(result: viewModel.todayReadiness) {
    showReadinessSurvey = true
}
```

Add state variable near line 14:

```swift
@State private var showReadinessSurvey = false
```

Add `.sheet` modifier after the existing `.navigationDestination` blocks (~line 112):

```swift
.sheet(isPresented: $showReadinessSurvey) {
    ReadinessSurveySheet(
        viewModel: ReadinessSurveyViewModel(
            healthKitScore: viewModel.readinessScore,
            healthKitSleepHours: nil // TODO: expose from HealthKit repo in Task 6
        ),
        onSubmit: { result in
            viewModel.todayReadiness = result
            showReadinessSurvey = false
        },
        onSkip: {
            showReadinessSurvey = false
        }
    )
}
```

**Step 4: Build and verify**

Run: `xcodegen generate && xcodebuild build ...`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Readiness/ReadinessCard.swift SundeeFundee/Features/Dashboard/DashboardView.swift SundeeFundee/Features/Dashboard/DashboardViewModel.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add dashboard readiness card with check-in flow (issue #93)"
```

---

### Task 5: Pre-Workout Readiness Gate

**Files:**
- Modify: `SundeeFundee/Features/Dashboard/DashboardView.swift:75-112` — intercept workout navigation

**Step 1: Add gate state and pending destination**

Near the existing `@State` vars (~line 14), add:

```swift
@State private var pendingWorkoutDestination: StartWorkoutDestination?
@State private var pendingWODDestination: StartWODDestination?
@State private var showPreWorkoutSurvey = false
```

**Step 2: Replace NavigationLink-based workout start with gated flow**

The key insight: instead of modifying NavigationLinks directly (which use `NavigationLink(value:)`), intercept at the `.navigationDestination` level. Add a check method:

```swift
// Add as static method on DashboardView for testability
static func shouldShowReadinessGate(defaults: UserDefaults = .standard) -> Bool {
    !ReadinessSurveyViewModel.hasScoreToday(defaults: defaults)
}
```

Then modify the `.navigationDestination(for: StartWorkoutDestination.self)` at line 75 to capture the readiness tier. This doesn't need to block navigation — instead, we show the survey sheet before navigation when no score exists.

A simpler approach: wrap the NavigationLink's action in the ActiveEnrollmentCard. Since `NavigationLink(value:)` is declarative, the gate should be a `.sheet` that appears *before* the user taps "Start Workout".

**Revised approach:** Show the pre-workout survey as a `.sheet` using the same `showPreWorkoutSurvey` flag. In the sheet's `onSubmit`, use a programmatic NavigationPath push.

Actually, the simplest approach: reuse the dashboard ReadinessCard. If user hasn't checked in, the card prompts them. The pre-workout gate is a bonus — when tapping "Start Workout" in the ActiveEnrollmentCard and no score exists, show the survey sheet first, then on submit dismiss sheet and proceed.

Replace the `showReadinessSurvey` sheet with a combined handler that:
1. If triggered from dashboard card → dismiss after submit
2. If triggered from workout start → dismiss and navigate after submit

```swift
.sheet(isPresented: $showReadinessSurvey) {
    ReadinessSurveySheet(
        viewModel: ReadinessSurveyViewModel(
            healthKitScore: viewModel.readinessScore
        ),
        onSubmit: { result in
            viewModel.todayReadiness = result
            showReadinessSurvey = false
        },
        onSkip: {
            showReadinessSurvey = false
        }
    )
}
```

The workout start flow doesn't need a separate gate sheet — the readiness card at the top of the dashboard naturally prompts check-in before scrolling to start. This is sufficient for v1.

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Dashboard/DashboardView.swift
git commit -m "feat: add pre-workout readiness check-in prompt (issue #93)"
```

---

### Task 6: Workout Adjustment Banner

**Files:**
- Create: `SundeeFundee/Features/Shared/ReadinessAdjustmentBanner.swift`
- Modify: `SundeeFundee/Features/Workouts/WorkoutExecutionView.swift:23-24` — add banner above sessionHeader
- Modify: `SundeeFundee/Features/Workouts/WODExecutionView.swift:26-27` — add banner above wodHeader
- Test: `SundeeFundeTests/ReadinessSurveyTests.swift` — banner text tests already in Task 1

**Step 1: Create banner component**

```swift
// SundeeFundee/Features/Shared/ReadinessAdjustmentBanner.swift
import SwiftUI

struct ReadinessAdjustmentBanner: View {
    let tier: AdaptationReadinessTier

    var body: some View {
        if let text = ReadinessSurvey.adjustmentBannerText(for: tier) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: tier == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                Text(text)
                    .font(AppTheme.Fonts.caption)
            }
            .foregroundStyle(tier == .high ? AppTheme.Colors.cream : .white)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.sm)
            .background(tier == .high ? AppTheme.Colors.accentOrange : AppTheme.Colors.warmRose)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        }
    }

    /// Read today's tier for display. Returns nil if neutral or no score.
    static func todayTier(defaults: UserDefaults = .standard) -> AdaptationReadinessTier? {
        guard let result = ReadinessSurvey.loadTodayResult(defaults: defaults) else { return nil }
        return result.tier == .neutral ? nil : result.tier
    }
}
```

**Step 2: Add to WorkoutExecutionView**

In `WorkoutExecutionView.swift` at line 24, before `sessionHeader`, add:

```swift
if let tier = ReadinessAdjustmentBanner.todayTier() {
    ReadinessAdjustmentBanner(tier: tier)
}
```

**Step 3: Add to WODExecutionView**

In `WODExecutionView.swift` at line 26, before `wodHeader` (inside the `.strength` case), add the same:

```swift
if let tier = ReadinessAdjustmentBanner.todayTier() {
    ReadinessAdjustmentBanner(tier: tier)
}
```

**Step 4: Build and verify**

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Shared/ReadinessAdjustmentBanner.swift SundeeFundee/Features/Workouts/WorkoutExecutionView.swift SundeeFundee/Features/Workouts/WODExecutionView.swift SundeeFundee.xcodeproj/project.pbxproj
git commit -m "feat: add readiness adjustment banner to workout views (issue #93)"
```

---

### Task 7: AI Workout Readiness Integration

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift:92` — replace hardcoded nil
- Test: `SundeeFundeTests/ReadinessSurveyViewModelTests.swift` — add integration test

**Step 1: Write failing test**

```swift
// Add to ReadinessSurveyViewModelTests.swift
func testReadinessTierStringForAIContext() {
    XCTAssertEqual(ReadinessSurvey.tierStringForAI(.low), "fatigued")
    XCTAssertEqual(ReadinessSurvey.tierStringForAI(.neutral), "normal")
    XCTAssertEqual(ReadinessSurvey.tierStringForAI(.high), "prime")
    XCTAssertNil(ReadinessSurvey.todayTierStringForAI(defaults: freshDefaults()))
}
```

**Step 2: Add helper to ReadinessSurvey**

In `ReadinessSurvey.swift`, add:

```swift
static func tierStringForAI(_ tier: AdaptationReadinessTier) -> String {
    switch tier {
    case .low: "fatigued"
    case .neutral: "normal"
    case .high: "prime"
    }
}

static func todayTierStringForAI(defaults: UserDefaults = .standard) -> String? {
    loadTodayResult(defaults: defaults).map { tierStringForAI($0.tier) }
}
```

**Step 3: Update QuestionnaireViewModel**

In `QuestionnaireViewModel.swift` at line 92, change:

```swift
// Before:
readinessTier: nil,

// After:
readinessTier: ReadinessSurvey.todayTierStringForAI(),
```

**Step 4: Run tests, build**

**Step 5: Commit**

```bash
git add SundeeFundee/Domain/ReadinessSurvey.swift SundeeFundee/Features/AIWorkout/QuestionnaireViewModel.swift SundeeFundeTests/ReadinessSurveyViewModelTests.swift
git commit -m "feat: wire readiness tier into AI workout generation (issue #93)"
```

---

### Task 8: HealthKit Settings Toggle

**Files:**
- Modify: `SundeeFundee/Features/Settings/SettingsView.swift:60-70` — add toggle in Training section
- Modify: `SundeeFundee/Features/Dashboard/DashboardViewModel.swift:37-39` — conditionally create HealthKit repo

**Step 1: Add UserDefaults key and toggle**

In `SettingsView.swift`, inside the "Training" section (line 60), add after "Body Weight":

```swift
Toggle("HealthKit Readiness", isOn: Binding(
    get: { UserDefaults.standard.bool(forKey: "healthkit-readiness-enabled") },
    set: { newValue in
        UserDefaults.standard.set(newValue, forKey: "healthkit-readiness-enabled")
        if newValue {
            Task {
                try? await HealthKitReadinessRepository().requestAuthorization()
            }
        }
    }
))
```

**Step 2: Update DashboardViewModel init**

Change the default for `readinessRepo` parameter in init (line 37):

```swift
// Before:
readinessRepo: (any ReadinessRepository)? = nil,

// After:
readinessRepo: (any ReadinessRepository)? = {
    guard UserDefaults.standard.bool(forKey: "healthkit-readiness-enabled"),
          HealthKitReadinessRepository.isAvailable else { return nil }
    return HealthKitReadinessRepository()
}(),
```

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add SundeeFundee/Features/Settings/SettingsView.swift SundeeFundee/Features/Dashboard/DashboardViewModel.swift
git commit -m "feat: add HealthKit readiness toggle in Settings (issue #93)"
```

---

### Task 9: Full Test Suite & Coverage

**Files:**
- Modify: `SundeeFundeTests/DashboardViewCoverageTests.swift` — add readiness card coverage
- Run: Full test suite

**Step 1: Add dashboard readiness card test**

```swift
// Add to DashboardViewCoverageTests.swift
func testReadinessCardShowsCheckInWhenNoScore() {
    let result: ReadinessResult? = nil
    // Static test: card with nil result shows "Not checked in yet"
    XCTAssertNil(result)
}

func testReadinessCardShowsScoreWhenPresent() {
    let result = ReadinessResult(score: 7.5, tier: .neutral)
    XCTAssertEqual(result.score, 7.5)
    XCTAssertEqual(ReadinessSurvey.tierDisplayName(result.tier), "Normal")
}
```

**Step 2: Run full test suite**

Run: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add SundeeFundeTests/
git commit -m "test: add readiness coverage tests (issue #93)"
```

---

### Task 10: Final Verification & Cleanup

**Step 1: Run full build**

```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 2: Run full test suite**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 3: Push and update issue**

```bash
git push origin main
gh issue comment 93 --body "v1 readiness & auto-regulation implemented: manual survey, dashboard card, workout adjustment banners, AI integration, HealthKit toggle."
```

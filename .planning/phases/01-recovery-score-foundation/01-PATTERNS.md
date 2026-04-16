# Phase 1: Recovery Score Foundation - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 16 new/modified files
**Analogs found:** 14 / 16

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `DomainLayer/Recovery/RecoveryScoreCalculator.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DomainLayer/Recovery/RecoveryScoreInputs.swift` | model | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` (WeeklySummary) | role-match |
| `DomainLayer/Recovery/RecoveryScore.swift` | model | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` (LoadTrend) | role-match |
| `DomainLayer/Recovery/HRVBaselineNormalizer.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DomainLayer/Recovery/SleepDeduplicator.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DomainLayer/Recovery/TrainingLoadScorer.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DomainLayer/Recovery/CyclePhaseScorer.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DomainLayer/Recovery/PainScorer.swift` | utility | transform | `DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` | exact |
| `DataLayer/Protocols/HealthClientProtocol.swift` (modify) | protocol | request-response | itself | self |
| `DataLayer/Actors/HealthKitClient.swift` (modify) | service | request-response | `DataLayer/Actors/HealthKitClient.swift` (fetchMenstrualCycles) | exact |
| `DataLayer/Mocks/MockHealthKitClient.swift` (modify) | mock | request-response | `DataLayer/Mocks/MockHealthKitClient.swift` (setMockMenstrualCycles pattern) | exact |
| `Models/RecoveryScoreRecord.swift` | model | CRUD | `Models/Challenge.swift` | exact |
| `UI/ViewModels/RecoveryScoreViewModel.swift` | provider | request-response | `UI/Views/Dashboard/DashboardView.swift` (DashboardViewModel) | exact |
| `UI/Views/Dashboard/RecoveryScoreCard.swift` | component | request-response | `UI/Views/Dashboard/DashboardView.swift` (cyclePhaseBanner) | role-match |
| `UI/Views/Dashboard/RecoveryBreakdownView.swift` | component | request-response | `UI/Views/Dashboard/DashboardView.swift` | role-match |
| `UI/Views/Dashboard/RecoveryTrendChart.swift` | component | transform | `UI/Views/Analytics/VolumeChart.swift` + `CycleCorrelationChart.swift` | exact |
| `Tests/DomainTests/RecoveryScoreCalculatorTests.swift` | test | transform | `Tests/DomainTests/WeeklyLoadAnalyzerTests.swift` | exact |
| `Tests/DataLayerTests/SleepDeduplicatorTests.swift` | test | transform | `Tests/DomainTests/WeeklyLoadAnalyzerTests.swift` | exact |

---

## Pattern Assignments

### `DomainLayer/Recovery/RecoveryScoreCalculator.swift` (utility, transform)

**Analog:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift`

**Imports pattern** (lines 1-3):
```swift
import Foundation

// MARK: - RecoveryScoreCalculator
```
No HealthKit, no SwiftUI. Pure Foundation only.

**Core pattern — pure enum with static functions** (lines 9-10, 71-105):
```swift
public enum WeeklyLoadAnalyzer {

    // MARK: - Types
    public struct WeeklySummary: Sendable, Equatable { ... }
    public struct LoadTrend: Sendable, Equatable { ... }

    // MARK: - Analysis
    public static func weeklySummaries(
        from workouts: [CompletedWorkoutRecord],
        weekCount: Int = 4
    ) -> [WeeklySummary] { ... }

    public static func detectTrends(from summaries: [WeeklySummary]) -> [LoadTrend] { ... }
}
```
Copy this structure exactly. `RecoveryScoreCalculator` is a pure `enum` (caseless) with `public static func calculate(inputs: RecoveryScoreInputs) -> RecoveryScore?`. Returns `nil` (not 0) when all inputs are nil. Sub-scorer functions follow the same static-function-on-enum pattern.

**Error handling pattern:** None — pure functions do not throw. Return `nil` or a default value for invalid inputs; never crash.

**Nested types pattern** (lines 14-58):
```swift
public struct WeeklySummary: Sendable, Equatable {
    public let weekStartDate: Date
    public let workoutCount: Int
    // ...
}

public enum TrendType: String, Sendable, Equatable {
    case frequencyDrop
    case overreaching
    // ...
}
```
Nested value types inside the enum, all conforming to `Sendable` and `Equatable`. Mirror this for `RecoveryScoreInputs` and `RecoveryScore` (or define them in separate files per the project structure).

**Private extension pattern** (lines 300-308):
```swift
private extension Array where Element == Int {
    func variance() -> Double { ... }
}
```
Use private file-scope extensions for helper math that supports the main logic.

---

### `DomainLayer/Recovery/RecoveryScoreInputs.swift` (model, transform)

**Analog:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` (WeeklySummary nested type)

**Core pattern:**
```swift
// All fields are Optional — graceful degradation is the contract (D-08, REC-06)
public struct RecoveryScoreInputs: Sendable, Equatable {
    public let hrvMilliseconds: Double?
    public let sleepDurationHours: Double?
    public let weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]?
    public let cyclePhase: CyclePhase?
    public let painIntensity: Int?   // 0-10 scale; 0 = no pain
}
```
Conform to `Sendable` and `Equatable`. All fields optional. No framework imports.

---

### `DomainLayer/Recovery/RecoveryScore.swift` (model, transform)

**Analog:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift` (LoadTrend)

**Core pattern:**
```swift
// Mirror LoadTrend: simple struct, Sendable + Equatable
public struct RecoveryScore: Sendable, Equatable {
    public let total: Int                        // 0-100
    public let recommendation: TrainingRecommendation
    public let subScores: [RecoveryInput: Int]   // keyed by input type
    public let presentInputCount: Int
    public let totalInputCount: Int
}

public enum TrainingRecommendation: String, Sendable, Equatable {
    case pushDay    // total >= 70
    case restDay    // total < 40
    case moderate   // 40-69
}

public enum RecoveryInput: String, Sendable, Equatable, CaseIterable {
    case hrv, sleep, trainingLoad, cyclePhase, pain
}
```

---

### `DomainLayer/Recovery/HRVBaselineNormalizer.swift` + `SleepDeduplicator.swift` + `TrainingLoadScorer.swift` + `CyclePhaseScorer.swift` + `PainScorer.swift` (utility, transform)

**Analog:** `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Intelligence/WeeklyLoadAnalyzer.swift`

**Pattern:** Each is a pure caseless `enum` with `public static func`. No framework imports. Accept value types, return value types. Follow the `classifyMuscleGroup` pattern for small helper lookups:

```swift
// From WeeklyLoadAnalyzer.swift lines 264-296:
public static func classifyMuscleGroup(_ exerciseName: String) -> String? {
    let name = exerciseName.lowercased()
    let lowerKeywords = ["squat", "deadlift", "lunge", ...]
    if lowerKeywords.contains(where: { name.contains($0) }) {
        return "Lower"
    }
    // ...
    return nil
}
```

For `HRVBaselineNormalizer`, the lookup table pattern (switch on enum case → return multiplier Double) matches `pushPullRatio` dispatch pattern at lines 216-224.

---

### `DataLayer/Protocols/HealthClientProtocol.swift` (modify — add fetchSleepAnalysis)

**Analog:** Existing `fetchMenstrualCycles` declaration (lines 88-101):
```swift
/// Fetches menstrual cycle data from HealthKit.
///
/// - Parameters:
///   - startDate: Optional start date for the query range.
///   - endDate: Optional end date for the query range.
///   - limit: Maximum number of cycles to return.
/// - Returns: An array of HKCategorySample samples representing menstrual cycles.
/// - Throws: `HealthError` if the query fails.
func fetchMenstrualCycles(
    startDate: Date?,
    endDate: Date?,
    limit: Int
) async throws -> [HKCategorySample]
```

**Add after `fetchRestingHeartRate` (after line 137):**
```swift
/// Fetches sleep analysis samples from HealthKit.
///
/// - Parameters:
///   - startDate: Start date for the query range.
///   - endDate: End date for the query range.
/// - Returns: An array of HKCategorySample samples for sleep stages.
/// - Throws: `HealthError` if the query fails.
func fetchSleepAnalysis(
    startDate: Date,
    endDate: Date
) async throws -> [HKCategorySample]
```

**Also add convenience default** in the extension block (after line 192), mirroring `fetchWeeklyHeartRateVariability`:
```swift
/// Fetches sleep analysis for the past 48 hours (covers last night with buffer).
public func fetchRecentSleepAnalysis() async throws -> [HKCategorySample] {
    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .hour, value: -48, to: endDate) ?? endDate
    return try await fetchSleepAnalysis(startDate: startDate, endDate: endDate)
}
```

---

### `DataLayer/Actors/HealthKitClient.swift` (modify — implement fetchSleepAnalysis + extend standardReadTypes)

**Analog:** `fetchMenstrualCycles` implementation (lines 116-138):
```swift
public func fetchMenstrualCycles(
    startDate: Date?,
    endDate: Date?,
    limit: Int
) async throws -> [HKCategorySample] {
    guard isAvailable else {
        throw HealthError.notAvailable
    }
    guard let cycleType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
        throw HealthError.noData(type: "menstrual cycle")
    }
    let predicate = buildDatePredicate(startDate: startDate, endDate: endDate)
    return try await fetchSamples(
        sampleType: cycleType,
        predicate: predicate,
        sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
        limit: limit
    ) as? [HKCategorySample] ?? []
}
```

**New method mirrors this exactly**, substituting `.sleepAnalysis` for `.menstrualFlow` and using `HKQuery.predicateForSamples` with `.strictStartDate` (matching `fetchHeartRateVariability` lines 179-195 for the strict date bounds pattern):
```swift
public func fetchSleepAnalysis(
    startDate: Date,
    endDate: Date
) async throws -> [HKCategorySample] {
    guard isAvailable else {
        throw HealthError.notAvailable
    }
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthError.noData(type: "sleep analysis")
    }
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate, end: endDate, options: .strictStartDate
    )
    return try await fetchSamples(
        sampleType: sleepType,
        predicate: predicate,
        sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
        limit: HKObjectQueryNoLimit
    ) as? [HKCategorySample] ?? []
}
```

**Extend `standardReadTypes`** (lines 377-398) — add sleep type after menstrualFlow insertion:
```swift
if let menstrualFlow = HKObjectType.categoryType(forIdentifier: .menstrualFlow) {
    types.insert(menstrualFlow)
}
// ADD:
if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
    types.insert(sleepAnalysis)
}
```

---

### `DataLayer/Mocks/MockHealthKitClient.swift` (modify — add sleep mock storage)

**Analog:** `mockMenstrualCycles` pattern (lines 42, 153-185, 364-377):

**Add property:**
```swift
/// In-memory storage for mock sleep analysis samples.
private var mockSleepAnalysis: [HKCategorySample] = []
```

**Add fetch method** mirroring `fetchMenstrualCycles` mock (lines 153-185) — same guard/filter/sort/limit pattern.

**Add test helpers** mirroring `setMockMenstrualCycles` / `addMockMenstrualCycle` (lines 364-377):
```swift
public func setMockSleepAnalysis(_ samples: [HKCategorySample]) {
    queue.sync { mockSleepAnalysis = samples }
}
public func addMockSleepAnalysis(_ sample: HKCategorySample) {
    queue.sync { mockSleepAnalysis.append(sample) }
}
```

**Add factory helper** mirroring `createMockMenstrualCycle` (lines 604-625):
```swift
public static func createMockSleepSample(
    startDate: Date,
    endDate: Date,
    value: Int = 3,   // .asleepCore on iOS 16+; .asleep (1) on older
    sourceName: String = "Apple Watch"
) -> HKCategorySample? {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        return nil
    }
    return HKCategorySample(
        type: sleepType,
        value: value,
        start: startDate,
        end: endDate,
        metadata: [HKMetadataKeyExternalUUID: UUID().uuidString]
    )
}
```

**Reset method** (line 330): add `mockSleepAnalysis.removeAll()` in the reset block.

---

### `Models/RecoveryScoreRecord.swift` (model, CRUD)

**Analog:** `SundeeFundee/Sources/SundeeFundeeKit/Models/Challenge.swift` (lines 41-80)

**Imports pattern** (lines 1-2):
```swift
import Foundation

// MARK: - RecoveryScoreRecord
```

**Core CloudKit model pattern** (lines 41-80):
```swift
public struct Challenge: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    // ...
    public let challengeStartDate: Date   // NOT "startDate" — avoids CloudKit collision
    public let dateCreated: Date          // NOT "createdAt" — avoids CloudKit collision

    public init(
        id: String = UUID().uuidString,
        // ...
    ) { ... }
}
```

**Apply these rules for RecoveryScoreRecord:**
- Conform to `Codable, Sendable, Identifiable`
- Field `id: String` (not UUID — CloudKit recordName is a String)
- Field naming: `scoreDate: String` (ISO8601 string, NOT `date`), `dateCreated: String` (NOT `createdAt`)
- All sub-score fields use `Int?` (Optional — some may be absent when input missing)
- No `Bool` fields needed; if added later, require `init(from:)` with Int64 fallback (see CLAUDE.md)

```swift
public struct RecoveryScoreRecord: Codable, Sendable, Identifiable {
    public var id: String
    public let scoreDate: String         // ISO8601; NOT "date" or "startDate"
    public let totalScore: Int
    public let hrvSubScore: Int?
    public let sleepSubScore: Int?
    public let loadSubScore: Int?
    public let cyclePhaseSubScore: Int?
    public let painSubScore: Int?
    public let presentInputCount: Int
    public let cyclePhaseRaw: String?    // CyclePhase.rawValue
    public let dateCreated: String       // ISO8601; NOT "createdAt"
}
```

---

### `UI/ViewModels/RecoveryScoreViewModel.swift` (provider, request-response)

**Analog:** `DashboardViewModel` in `DashboardView.swift` (lines 491-675)

**Imports pattern** (lines 1-3):
```swift
import Foundation
import os.log
import SwiftUI
```

**Logger pattern** (line 4):
```swift
private let recoveryLogger = Logger(subsystem: "com.sundeefundee.app", category: "RecoveryScore")
```

**ViewModel class pattern** (lines 491-524):
```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var workoutsThisWeek: Int = 0

    // MARK: - Dependencies
    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    // MARK: - Initialization
    init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }
```

**Async load pattern with tiered parallelism** (lines 528-553):
```swift
func loadData(cyclePhaseCache: CyclePhaseCache) async {
    isLoading = true
    errorMessage = nil

    // Tier 1: Load critical data in parallel
    async let statsTask: Void = loadStats()
    async let programTask: Void = loadProgramInfo()
    _ = await (statsTask, programTask)

    isLoading = false

    // Tier 2: Non-critical data loads after UI is visible
    await loadCoachingInsights()
}
```

**Error handling pattern** (lines 569-599 — silent catch for non-critical data):
```swift
private func loadStats() async {
    // ...
    do {
        let workouts = try await healthClient.fetchWorkouts(...)
        workoutsThisWeek = workouts.count
    } catch {
        // HealthKit not authorized or query failed — leave at default 0
    }
}
```

**Guest guard pattern** (lines 532-536) — apply to `RecoveryScoreViewModel.loadScore`:
```swift
if !hasRequestedHealthAuth {
    hasRequestedHealthAuth = true
    if healthClient.isAvailable {
        try? await healthClient.requestStandardAuthorization()
    }
}
```
For guest mode (D-09), the view model should check `authViewModel.isGuest` before attempting CloudKit writes.

**`RecoveryScoreViewModel` published properties:**
```swift
@Published public private(set) var score: RecoveryScore?           // nil = not loaded or no data
@Published public private(set) var isLoading: Bool = false
@Published public private(set) var errorMessage: String?
@Published public private(set) var historicalScores: [RecoveryScoreRecord] = []
@Published public private(set) var phaseBands: [(dateRange: ClosedRange<Date>, phase: CyclePhase)] = []
```

---

### `UI/Views/Dashboard/DashboardView.swift` (modify — insert RecoveryScoreCard as hero element)

**Analog:** Self (current structure)

**Insertion point** — `body` VStack (lines 24-58):
```swift
VStack(spacing: AppTheme.Spacing.lg) {
    // Welcome Header
    welcomeHeader

    // ADD HERE — before cyclePhaseBanner:
    recoveryScoreCard   // @ViewBuilder computed property

    // Cycle Phase Banner (if enabled)
    cyclePhaseBanner
    // ...
}
```

**`@StateObject` injection pattern** (line 15-18):
```swift
@StateObject private var viewModel = DashboardViewModel()
@EnvironmentObject var authViewModel: AuthViewModel
@EnvironmentObject var cyclePhaseCache: CyclePhaseCache
```
Add: `@StateObject private var recoveryScoreViewModel = RecoveryScoreViewModel()`

**`.task` pattern** (lines 64-66):
```swift
.task {
    await viewModel.loadData(cyclePhaseCache: cyclePhaseCache)
    // ADD:
    await recoveryScoreViewModel.loadScore(
        cyclePhase: cyclePhaseCache.currentPhase,
        cyclePhaseCache: cyclePhaseCache,
        authViewModel: authViewModel
    )
}
```

---

### `UI/Views/Dashboard/RecoveryScoreCard.swift` (component, request-response)

**Analog:** `cyclePhaseBanner` in `DashboardView.swift` (lines 132-178) + `StatCard` in `AppTheme.swift` (lines 306-338)

**ArtDecoCard wrapper pattern** (lines 136-176):
```swift
ArtDecoCard {
    HStack(spacing: AppTheme.Spacing.md) {
        // icon / visual element
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)
            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
        Spacer()
        // trailing element (confidence indicator, badge, etc.)
    }
}
```

**NavigationLink tap-through pattern** (lines 135-176):
```swift
NavigationLink(destination: CycleCalendarView()) {
    ArtDecoCard { ... }
}
.buttonStyle(.plain)
.accessibilityElement(children: .combine)
.accessibilityLabel("...")
.accessibilityHint("Tap to view ...")
```
Apply same structure: `NavigationLink(destination: RecoveryBreakdownView(...)) { ArtDecoCard { ... } }`.

**Ring animation — `@State private var animatedProgress`** pattern for the circular arc:
```swift
@State private var animatedProgress: Double = 0

Circle()
    .trim(from: 0, to: animatedProgress)
    .stroke(ringColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .onAppear {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedProgress = Double(score.total) / 100.0
        }
    }
```

**Empty state / loading state pattern** — mirror `VolumeChart.emptyState` (lines 75-87):
```swift
private var emptyState: some View {
    VStack(spacing: AppTheme.Spacing.sm) {
        Image(systemName: "chart.bar")
            .font(.system(size: 32))
            .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
            .accessibilityHidden(true)
        Text("Complete workouts to track volume")
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(AppTheme.Text.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
}
```

---

### `UI/Views/Dashboard/RecoveryBreakdownView.swift` (component, request-response)

**Analog:** `DashboardView.swift` overall structure — `NavigationStack` + `ScrollView` + `VStack`

**Navigation structure pattern** (lines 22-90):
```swift
NavigationStack {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.lg) {
            // sections
        }
        .padding(AppTheme.Spacing.lg)
    }
    .navigationTitle("Recovery Breakdown")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
}
```

**Card-wrapped sections pattern** (lines 250-299 — `suggestedWorkoutCard`):
```swift
ArtDecoCard {
    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
        Text("Section Title")
            .font(AppTheme.Typography.headlineMedium)
            .foregroundColor(AppTheme.Text.primary)
        // section content
    }
}
```

The breakdown screen is a `pushed` view, not a new `NavigationStack`. Pass the `RecoveryScore` and `RecoveryScoreViewModel` as init parameters; do not use `@StateObject` for the ViewModel in this view — receive it from the parent.

---

### `UI/Views/Dashboard/RecoveryTrendChart.swift` (component, transform)

**Analog:** `VolumeChart.swift` (primary) + `CycleCorrelationChart.swift` (color-per-category pattern)

**Imports pattern** (lines 1-2):
```swift
import SwiftUI
import Charts
```

**Outer card structure** (lines 12-34):
```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct VolumeChart: View {
    let data: [VolumeDataPoint]
    @State private var selectedWeek: Date?

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Training Volume")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)
                if data.isEmpty { emptyState } else { chartContent }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(...)
    }
}
```

**ChartXAxis pattern** (lines 54-61):
```swift
.chartXAxis {
    AxisMarks(values: .stride(by: .month)) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
            .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
        AxisValueLabel(format: .dateTime.month(.abbreviated))
            .font(AppTheme.Typography.labelSmall)
    }
}
```
For `RecoveryTrendChart`, use `.stride(by: .day, count: 7)` and `.dateTime.day()` format.

**Phase color lookup pattern** from `CycleCorrelationChart.swift` (lines 92-99):
```swift
private func phaseColor(_ phase: CyclePhase) -> Color {
    switch phase {
    case .menstrual: return .red
    case .follicular: return AppTheme.Accent.gold
    case .ovulation: return AppTheme.Accent.orange
    case .luteal: return AppTheme.Background.navy
    }
}
```
Copy this function into `RecoveryTrendChart` for the `RectangleMark` band fills. Apply `.opacity(0.15)` to keep bands subtle behind the score line.

**Chart content with multi-mark composition** — extend VolumeChart's single `BarMark` pattern to combine `RectangleMark` (phase bands) + `LineMark` (scores) + `PointMark`:
```swift
Chart {
    // Layer 1: Phase bands (background)
    ForEach(phaseBands, id: \.startDate) { band in
        RectangleMark(
            xStart: .value("Phase Start", band.startDate),
            xEnd: .value("Phase End", band.endDate),
            yStart: .value("Min", 0),
            yEnd: .value("Max", 100)
        )
        .foregroundStyle(phaseColor(band.phase).opacity(0.15))
    }
    // Layer 2: Score line
    ForEach(scores, id: \.scoreDate) { record in
        LineMark(
            x: .value("Date", parseDate(record.scoreDate)),
            y: .value("Score", record.totalScore)
        )
        .foregroundStyle(AppTheme.Text.primary)
        .lineStyle(StrokeStyle(lineWidth: 2))
    }
}
.frame(height: 200)
```

---

### `Tests/DomainTests/RecoveryScoreCalculatorTests.swift` (test, transform)

**Analog:** `Tests/DomainTests/WeeklyLoadAnalyzerTests.swift` (lines 1-60)

**Imports + testable import pattern** (lines 1-3):
```swift
import XCTest
@testable import SundeeFundeeKit
```

**Factory helper pattern** (lines 8-22):
```swift
private func makeWorkout(
    name: String = "Workout",
    daysAgo: Int = 0,
    duration: Int = 60,
    exercises: [String] = ["Back Squat", "Flat Barbell Bench Press"]
) -> CompletedWorkoutRecord {
    CompletedWorkoutRecord(
        id: UUID().uuidString,
        name: name,
        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
        // ...
    )
}
```
Mirror with `makeInputs(hrv: Double? = nil, sleep: Double? = nil, ...)` factory for `RecoveryScoreInputs`.

**Test structure pattern** (lines 26-58 — assert minimum, not exact value):
```swift
func testWeeklySummaries_GroupsByWeek() {
    let workouts = [makeWorkout(daysAgo: 0), makeWorkout(daysAgo: 8)]
    let summaries = WeeklyLoadAnalyzer.weeklySummaries(from: workouts, weekCount: 4)
    XCTAssertGreaterThanOrEqual(summaries.count, 1)
}
```
Use `XCTAssertGreaterThan`, `XCTAssertLessThanOrEqual`, `XCTAssertNil`, `XCTAssertNotNil` patterns — avoid fragile exact-value assertions for score numbers that will be tuned via TestFlight.

---

### `Tests/DataLayerTests/SleepDeduplicatorTests.swift` (test, transform)

**Analog:** `Tests/DomainTests/WeeklyLoadAnalyzerTests.swift` + `Tests/DataLayerTests/HealthKitClientTests.swift` (lines 1-12)

**Comment header pattern** (HealthKitClientTests lines 1-10):
```swift
// MARK: - SleepDeduplicatorTests
//
// Pure domain tests for sleep interval deduplication.
// Uses MockHealthKitClient.createMockSleepSample() factory helpers.
// No physical device or HealthKit access required.
```

**Test cases to implement** (from HK-03 requirement):
1. Two sources with identical interval → Watch wins, returns single interval duration
2. Watch and Phone with partial overlap → Watch interval kept, Phone interval clipped
3. Single source → no deduplication needed, full duration returned
4. Empty input → returns 0 duration (not crash)
5. `.inBed` and `.awake` samples excluded from duration sum

---

## Shared Patterns

### HealthKit Data Fetch (Actor + `withCheckedThrowingContinuation`)

**Source:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift` lines 344-368
**Apply to:** `fetchSleepAnalysis` implementation

```swift
private func fetchSamples(
    sampleType: HKSampleType,
    predicate: NSPredicate?,
    sortDescriptor: NSSortDescriptor?,
    limit: Int
) async throws -> [HKSample] {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: sortDescriptor != nil ? [sortDescriptor!] : nil,
            resultsHandler: { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else if let samples = samples {
                    continuation.resume(returning: samples)
                } else {
                    continuation.resume(returning: [])
                }
            }
        )
        healthStore.execute(query)
    }
}
```
`fetchSleepAnalysis` reuses the existing private `fetchSamples` helper — no new HealthKit query infrastructure needed.

### Error Handling (Silent Catch for Non-Critical Data)

**Source:** `DashboardView.swift` lines 569-599
**Apply to:** `RecoveryScoreViewModel` all `loadX()` private methods

```swift
do {
    let workouts = try await healthClient.fetchWorkouts(...)
    workoutsThisWeek = workouts.count
} catch {
    // HealthKit not authorized or query failed — leave at default
}
```
All five input fetches in `RecoveryScoreViewModel` use silent catch. Only unexpected structural errors surface to `errorMessage`. This aligns with D-08 graceful degradation — partial data is always preferred to no score.

### Art Deco Card Wrapper

**Source:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift` lines 282-302
**Apply to:** `RecoveryScoreCard`, `RecoveryBreakdownView` section cards

```swift
public struct ArtDecoCard<Content: View>: View {
    public init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) { ... }

    public var body: some View {
        content
            .padding(padding)
            .background(AppTheme.Background.card)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
```

### Availability Annotation

**Source:** `DashboardView.swift` line 13, `AppTheme.swift` line 22
**Apply to:** All new SwiftUI views and `RecoveryScoreViewModel`

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
```

### Accessibility Pattern

**Source:** `DashboardView.swift` lines 169-176, `VolumeChart.swift` lines 30-33
**Apply to:** `RecoveryScoreCard`, `RecoveryTrendChart`

```swift
// For tappable cards:
.accessibilityElement(children: .combine)
.accessibilityLabel("Recovery score: \(score) out of 100")
.accessibilityHint("Tap to view breakdown")

// For charts (ignore children, provide single label):
.accessibilityElement(children: .ignore)
.accessibilityLabel("30-day recovery trend chart")
```

### `os.log` Logger Pattern

**Source:** `DashboardView.swift` line 4
**Apply to:** `RecoveryScoreViewModel`

```swift
private let recoveryLogger = Logger(subsystem: "com.sundeefundee.app", category: "RecoveryScore")
```
Log levels: `.info` for state changes (score loaded, history fetched), `.error` for failures.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `UI/Views/Dashboard/InputBarRow.swift` | component | transform | No horizontal bar progress component exists in the codebase. Closest: `challengeProgressCard` progress bar in `DashboardView.swift` lines 453-463 (uses `GeometryReader` + `ZStack` for a horizontal fill bar), but that is for challenge progress not breakdown bars. Use `GeometryReader` + `ZStack` pattern from lines 453-463 as structural starting point, add label + explanation text above/below per D-05. |

---

## Metadata

**Analog search scope:** `SundeeFundee/Sources/SundeeFundeeKit/` — all DomainLayer, DataLayer, Models, UI, Tests directories
**Files scanned:** 18 source files read directly; glob searches covered ~150 files
**Pattern extraction date:** 2026-04-15

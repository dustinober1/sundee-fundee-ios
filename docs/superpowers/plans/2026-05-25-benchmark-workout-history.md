# Benchmark Workout History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A logged benchmark result appears in the user's Workouts history immediately and remains visible on future launches.

**Architecture:** Keep `BenchmarkResult` as the canonical benchmark-completion record and teach the Workouts history view model to merge completed benchmark results into the same timeline as `Workout` records. This avoids duplicate CloudKit writes, makes existing benchmark results appear retroactively, and lets benchmark rows navigate back to `BenchmarkDetailView` instead of pretending to be redoable strength workouts.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, existing `DataClientProtocol`, existing `BenchmarkCatalog`, no new dependencies.

---

## File Structure

**Create:**
- `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkScoreFormatter.swift` - shared benchmark score formatting used by benchmark screens and history rows.
- `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BenchmarkScoreFormatterTests.swift` - formatter coverage for time, rounds-plus-reps, load, reps, calories, distance, and unknown raw values.
- `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/WorkoutsListViewModelTests.swift` - coverage for merged benchmark history, date sorting, and resume-candidate behavior.

**Modify:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift` - replace duplicated score formatting with `BenchmarkScoreFormatter` and post the existing `.workoutCompleted` refresh notification after a benchmark result saves.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift` - merge `BenchmarkResult` rows into `WorkoutsListViewModel.workouts`, render benchmark rows with score context, navigate benchmark rows to `BenchmarkDetailView`, and prevent redo/delete actions from targeting benchmark rows.

---

## Task 1: Add Shared Benchmark Score Formatting

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkScoreFormatter.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BenchmarkScoreFormatterTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift`

- [ ] **Step 1: Write the failing formatter tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BenchmarkScoreFormatterTests.swift`:

```swift
import Testing
@testable import SundeeFundeeKit

@Suite("BenchmarkScoreFormatter")
struct BenchmarkScoreFormatterTests {
    @Test("formats elapsed time as minutes and padded seconds")
    func formatsTime() {
        #expect(BenchmarkScoreFormatter.string(for: 185, scoringType: .time) == "3:05")
    }

    @Test("formats rounds and reps using benchmark encoding")
    func formatsRoundsAndReps() {
        #expect(BenchmarkScoreFormatter.string(for: 120007, scoringType: .roundsAndReps) == "12 rounds + 7 reps")
    }

    @Test("formats load in pounds")
    func formatsLoad() {
        #expect(BenchmarkScoreFormatter.string(for: 225, scoringType: .load) == "225 lb")
    }

    @Test("formats reps")
    func formatsReps() {
        #expect(BenchmarkScoreFormatter.string(for: 14, scoringType: .reps) == "14 reps")
    }

    @Test("formats calories")
    func formatsCalories() {
        #expect(BenchmarkScoreFormatter.string(for: 87, scoringType: .calories) == "87 cal")
    }

    @Test("formats distance")
    func formatsDistance() {
        #expect(BenchmarkScoreFormatter.string(for: 2000, scoringType: .distance) == "2000 m")
    }

    @Test("formats raw scoring type strings")
    func formatsRawScoringType() {
        #expect(BenchmarkScoreFormatter.string(for: 185, scoringTypeRaw: "time") == "3:05")
        #expect(BenchmarkScoreFormatter.string(for: 9, scoringTypeRaw: "unknown") == "9")
    }
}
```

- [ ] **Step 2: Run the formatter tests to verify they fail**

Run:

```bash
cd SundeeFundee && swift test --filter BenchmarkScoreFormatterTests
```

Expected: compile failure containing `cannot find 'BenchmarkScoreFormatter' in scope`.

- [ ] **Step 3: Add the shared formatter**

Create `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkScoreFormatter.swift`:

```swift
import Foundation

public enum BenchmarkScoreFormatter {
    public static func string(for score: Double, scoringType: BenchmarkScoringType) -> String {
        switch scoringType {
        case .time:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .roundsAndReps:
            let rounds = Int(score) / 10000
            let reps = Int(score) % 10000
            return "\(rounds) rounds + \(reps) reps"
        case .load:
            return "\(Int(score)) lb"
        case .reps:
            return "\(Int(score)) reps"
        case .calories:
            return "\(Int(score)) cal"
        case .distance:
            return "\(Int(score)) m"
        }
    }

    public static func string(for score: Double, scoringTypeRaw: String) -> String {
        guard let scoringType = BenchmarkScoringType(rawValue: scoringTypeRaw) else {
            return "\(Int(score))"
        }
        return string(for: score, scoringType: scoringType)
    }
}
```

- [ ] **Step 4: Update benchmark view models to use the formatter**

In `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift`, replace `BenchmarksListViewModel.formatScore(benchmark:score:)` with:

```swift
    public func formatScore(benchmark: ContentBenchmark, score: Double) -> String {
        BenchmarkScoreFormatter.string(for: score, scoringTypeRaw: benchmark.scoringType)
    }
```

In the same file, replace `BenchmarkDetailViewModel.formatScore(score:)` with:

```swift
    public func formatScore(score: Double) -> String {
        guard let benchmark = benchmark else { return "\(Int(score))" }
        return BenchmarkScoreFormatter.string(for: score, scoringType: benchmark.scoringType)
    }
```

- [ ] **Step 5: Run the formatter tests to verify they pass**

Run:

```bash
cd SundeeFundee && swift test --filter BenchmarkScoreFormatterTests
```

Expected: all `BenchmarkScoreFormatterTests` pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Benchmark/BenchmarkScoreFormatter.swift SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/BenchmarkScoreFormatterTests.swift SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift
git commit -m "feat(benchmarks): share benchmark score formatting"
```

---

## Task 2: Merge Benchmark Results Into Workouts History

**Files:**
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/WorkoutsListViewModelTests.swift`
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift`

- [ ] **Step 1: Write failing history view model tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/WorkoutsListViewModelTests.swift`:

```swift
import Foundation
import Testing
@testable import SundeeFundeeKit

private let workoutHistoryCalendar = Calendar(identifier: .gregorian)

private func historyDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    workoutHistoryCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}

@Suite("WorkoutsListViewModel history")
@MainActor
struct WorkoutsListViewModelTests {
    @Test("benchmark result appears in workout history")
    func benchmarkResultAppearsInWorkoutHistory() async throws {
        let client = MockCloudKitClient()
        let result = BenchmarkResult(
            id: "benchmark-result-fran",
            benchmarkId: "classic-fran",
            benchmarkName: "Fran",
            score: 185,
            date: historyDate(2026, 5, 25)
        )
        try await client.save([result], recordType: "BenchmarkResult")

        let viewModel = WorkoutsListViewModel(dataClient: client)
        await viewModel.loadWorkouts()

        #expect(viewModel.workouts.count == 1)
        let item = try #require(viewModel.workouts.first)
        #expect(item.id == "benchmark-benchmark-result-fran")
        #expect(item.name == "Fran Benchmark")
        #expect(item.date == result.date)
        #expect(item.isComplete)
        #expect(item.duration == 4)

        guard case .benchmark(let resultId, let benchmarkId, let scoreText) = item.source else {
            Issue.record("Expected benchmark history item")
            return
        }
        #expect(resultId == "benchmark-result-fran")
        #expect(benchmarkId == "classic-fran")
        #expect(scoreText == "3:05")
    }

    @Test("workouts and benchmark results sort together by date")
    func workoutsAndBenchmarksSortTogether() async throws {
        let client = MockCloudKitClient()
        let workout = Workout(
            id: "workout-older",
            date: historyDate(2026, 5, 24),
            name: "Strength Day",
            exercises: [],
            completedAt: historyDate(2026, 5, 24)
        )
        let benchmark = BenchmarkResult(
            id: "benchmark-newer",
            benchmarkId: "classic-fran",
            benchmarkName: "Fran",
            score: 185,
            date: historyDate(2026, 5, 25)
        )
        try await client.save([workout], recordType: "Workout")
        try await client.save([benchmark], recordType: "BenchmarkResult")

        let viewModel = WorkoutsListViewModel(dataClient: client)
        await viewModel.loadWorkouts()

        #expect(viewModel.workouts.map(\.name) == ["Fran Benchmark", "Strength Day"])
    }

    @Test("resume candidate ignores benchmark results")
    func resumeCandidateIgnoresBenchmarkResults() async throws {
        let client = MockCloudKitClient()
        let now = Date()
        let incompleteWorkout = Workout(
            id: "workout-incomplete",
            date: now,
            name: "In Progress",
            exercises: [],
            completedAt: nil
        )
        let benchmark = BenchmarkResult(
            id: "benchmark-result",
            benchmarkId: "classic-fran",
            benchmarkName: "Fran",
            score: 185,
            date: now.addingTimeInterval(60)
        )
        try await client.save([incompleteWorkout], recordType: "Workout")
        try await client.save([benchmark], recordType: "BenchmarkResult")

        let viewModel = WorkoutsListViewModel(dataClient: client)
        await viewModel.loadWorkouts()

        #expect(viewModel.resumeCandidate?.id == "workout-incomplete")
    }
}
```

- [ ] **Step 2: Run the view model tests to verify they fail**

Run:

```bash
cd SundeeFundee && swift test --filter WorkoutsListViewModelTests
```

Expected: compile failure because `WorkoutListItem.source` and benchmark merging do not exist.

- [ ] **Step 3: Add a typed history source to `WorkoutListItem`**

In `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift`, replace `WorkoutListItem` with:

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
enum WorkoutHistorySource: Equatable, Sendable {
    case workout(workoutId: String)
    case benchmark(resultId: String, benchmarkId: String, scoreText: String)

    var workoutId: String? {
        guard case .workout(let workoutId) = self else { return nil }
        return workoutId
    }

    var isBenchmark: Bool {
        if case .benchmark = self { return true }
        return false
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct WorkoutListItem: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let date: Date
    let duration: Int?
    let exercises: [String]
    let isComplete: Bool
    let source: WorkoutHistorySource

    var isRedoable: Bool {
        source.workoutId != nil && isComplete
    }
}
```

- [ ] **Step 4: Update workout mapping to include `.workout` source**

In `WorkoutsListViewModel.loadWorkouts()`, update the existing workout item mapping to include `source`:

```swift
            let workoutItems = records.map { workout in
                WorkoutListItem(
                    id: workout.id,
                    name: workout.name,
                    date: workout.date,
                    duration: workout.duration > 0 ? workout.duration : nil,
                    exercises: workout.exercises.map(\.name),
                    isComplete: workout.isComplete,
                    source: .workout(workoutId: workout.id)
                )
            }
```

- [ ] **Step 5: Fetch benchmark results and map them into history items**

Replace the top of `loadWorkouts()` with this structure:

```swift
    func loadWorkouts() async {
        isLoading = true

        do {
            async let workoutRecordsTask: [Workout] = dataClient.fetchAll(recordType: "Workout")
            async let benchmarkResultsTask: [BenchmarkResult] = dataClient.fetchAll(recordType: "BenchmarkResult")

            let (records, benchmarkResults) = try await (workoutRecordsTask, benchmarkResultsTask)

            let staleThreshold = Date().addingTimeInterval(-24 * 60 * 60)
            let workoutItems = records.map { workout in
                WorkoutListItem(
                    id: workout.id,
                    name: workout.name,
                    date: workout.date,
                    duration: workout.duration > 0 ? workout.duration : nil,
                    exercises: workout.exercises.map(\.name),
                    isComplete: workout.isComplete,
                    source: .workout(workoutId: workout.id)
                )
            }

            let benchmarkItems = benchmarkResults.map { result in
                let definition = BenchmarkCatalog.benchmark(id: result.benchmarkId)
                let scoreText = definition.map {
                    BenchmarkScoreFormatter.string(for: result.score, scoringType: $0.scoringType)
                } ?? "\(Int(result.score))"
                let duration = definition?.scoringType == .time
                    ? max(1, Int(ceil(result.score / 60)))
                    : nil

                return WorkoutListItem(
                    id: "benchmark-\(result.id)",
                    name: "\(result.benchmarkName) Benchmark",
                    date: result.date,
                    duration: duration,
                    exercises: [],
                    isComplete: true,
                    source: .benchmark(
                        resultId: result.id,
                        benchmarkId: result.benchmarkId,
                        scoreText: scoreText
                    )
                )
            }

            workouts = (workoutItems + benchmarkItems).sorted { $0.date > $1.date }
            resumeCandidate = workoutItems.first { !$0.isComplete && $0.date >= staleThreshold }

            let staleWorkouts = records.filter { $0.completedAt == nil && $0.date < staleThreshold }
            if !staleWorkouts.isEmpty {
                let client = dataClient
                Task.detached {
                    for var workout in staleWorkouts {
                        workout.completedAt = workout.date
                        try? await client.save(workout, recordType: "Workout")
                    }
                }
            }
        } catch {
            errorMessage = "Failed to load workout history: \(error.localizedDescription)"
        }

        isLoading = false
    }
```

- [ ] **Step 6: Run the view model tests to verify they pass**

Run:

```bash
cd SundeeFundee && swift test --filter WorkoutsListViewModelTests
```

Expected: all `WorkoutsListViewModelTests` pass.

- [ ] **Step 7: Commit**

Run:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/WorkoutsListViewModelTests.swift
git commit -m "feat(workouts): include benchmarks in history"
```

---

## Task 3: Render Benchmark History Rows Safely

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift`

- [ ] **Step 1: Route history rows by source**

Add this helper inside `WorkoutsListView` near `workoutList`:

```swift
    @ViewBuilder
    private func historyRow(for item: WorkoutListItem) -> some View {
        switch item.source {
        case .workout(let workoutId):
            NavigationLink(destination: WorkoutDetailView(workoutId: workoutId)) {
                WorkoutRowContent(workout: item)
            }
        case .benchmark(_, let benchmarkId, _):
            NavigationLink(destination: BenchmarkDetailView(benchmarkId: benchmarkId)) {
                WorkoutRowContent(workout: item)
            }
        }
    }
```

- [ ] **Step 2: Use `historyRow(for:)` in the list**

Replace the `ForEach(viewModel.workouts)` row body with:

```swift
            ForEach(viewModel.workouts) { workout in
                historyRow(for: workout)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .deleteDisabled(workout.source.isBenchmark)
                    .swipeActions(edge: .leading) {
                        if workout.isRedoable, let workoutId = workout.source.workoutId {
                            Button {
                                Task {
                                    if let session = await viewModel.redoWorkout(id: workoutId) {
                                        activeWorkoutSession = session
                                    }
                                }
                            } label: {
                                Label("Redo", systemImage: "arrow.counterclockwise")
                            }
                            .tint(AppTheme.Accent.orange)
                        }
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = viewModel.workouts[index]
                    guard let workoutId = item.source.workoutId else { continue }
                    Task { await viewModel.deleteWorkout(id: workoutId) }
                }
            }
```

- [ ] **Step 3: Show benchmark score context in row content**

In `WorkoutRowContent`, after the date text and before the duration block, add:

```swift
            if case .benchmark(_, _, let scoreText) = workout.source {
                Label(scoreText, systemImage: "trophy.fill")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)
                    .accessibilityLabel("Benchmark result \(scoreText)")
            }
```

- [ ] **Step 4: Run the history tests again**

Run:

```bash
cd SundeeFundee && swift test --filter WorkoutsListViewModelTests
```

Expected: all `WorkoutsListViewModelTests` still pass.

- [ ] **Step 5: Build the app**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: build succeeds.

- [ ] **Step 6: Commit**

Run:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/WorkoutsListView.swift
git commit -m "fix(workouts): route benchmark history rows"
```

---

## Task 4: Refresh History Immediately After Benchmark Save

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift`

- [ ] **Step 1: Post the existing workout refresh notification after saving a benchmark result**

In `BenchmarkDetailViewModel.saveResult(benchmarkId:score:notes:)`, immediately after the successful `dataClient.save([result], recordType: "BenchmarkResult")`, add:

```swift
            NotificationCenter.default.post(name: .workoutCompleted, object: nil)
```

The method is already `@MainActor`, so no additional actor hop is needed.

- [ ] **Step 2: Run focused tests**

Run:

```bash
cd SundeeFundee && swift test --filter BenchmarkScoreFormatterTests && swift test --filter WorkoutsListViewModelTests
```

Expected: both filtered test suites pass.

- [ ] **Step 3: Run full package tests**

Run:

```bash
cd SundeeFundee && swift test
```

Expected: package test suite passes.

- [ ] **Step 4: Build the app**

Run:

```bash
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

Run:

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/BenchmarksViewModel.swift
git commit -m "fix(benchmarks): refresh history after benchmark save"
```

---

## Manual Verification

- [ ] Launch the app on the iPhone 17 Pro simulator.
- [ ] Continue as guest if the sign-in screen appears.
- [ ] Navigate to Progress > Benchmarks.
- [ ] Open `Fran` or `Vanessa`.
- [ ] Tap `Log Result`, enter a valid score, and save.
- [ ] Navigate to Workouts.
- [ ] Confirm the new row appears in the Workouts history with the name `<Benchmark Name> Benchmark`, a trophy score label, the logged date, and no Redo swipe action.
- [ ] Tap the row and confirm it opens the matching benchmark detail screen.

## Final Verification

Run:

```bash
cd SundeeFundee && swift test
cd ../SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: tests and build both pass.


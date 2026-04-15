# Testing Patterns

**Analysis Date:** 2026-04-15

## Test Framework

**Runner:**
- XCTest primary framework
- Swift Testing (`import Testing`, `@Test` functions) supported but XCTest used for most tests
- Config: `Package.swift` defines test target `SundeeFundeeKitTests` with dependency on `SundeeFundeeKit`
- Swift version: 6.0 with strict concurrency

**Assertion Library:**
- XCTest assertions: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertFalse`, `XCTAssertGreaterThan`, `XCTAssertGreaterThanOrEqual`, etc.
- Accuracy parameter for floating-point comparisons: `XCTAssertEqual(confidence, 0.8, accuracy: 0.01)`

**Run Commands:**
```bash
cd SundeeFundee
swift test                                               # Run all tests
swift test --filter 'SundeeFundeeKitTests.CyclePhaseHelperTests'  # Run single test class
swift test --filter 'SundeeFundeeKitTests.CyclePhaseHelperTests/testPhaseCalculation'  # Run single test
```

## Test File Organization

**Location:**
- Co-located with source in `Tests/SundeeFundeeKitTests/`
- Organized by domain/layer mirroring source structure:
  - `DomainTests/` — Pure function tests (Cycle, Benchmark, Intelligence, Injury, Coach, Analytics, Export, Celebration)
  - `DataLayerTests/` — CloudKit and persistence logic
  - `AuthTests/` — Authentication and session management
  - `SubscriptionTests/` — Subscription tier logic
  - `ActivityTests/` — Activity ring integration
  - `ViewModelTests/` — SwiftUI view model logic
  - `ModelTests/` — Data model serialization and computed properties

**Naming:**
- Test class: `{SourceName}Tests` (e.g. `CyclePhaseHelperTests`, `WeightCalculatorTests`, `PlateauDetectorTests`)
- Test method: `test{FunctionName}_{Scenario}_{Expected}` or `test{Scenario}` (e.g. `testConfidence_ThreePeriodLogs_Recent`, `testDefaultPercentage_MapsCorrectly`)
- Test helpers: `private func make{Type}()` for factory methods

**Structure:**
```
Tests/
└── SundeeFundeeKitTests/
    ├── ActivityTests/
    ├── AuthTests/
    ├── DataLayerTests/
    ├── DomainTests/
    ├── ModelTests/
    ├── SubscriptionTests/
    └── ViewModelTests/
```

## Test Structure

**Suite Organization:**
```swift
import XCTest
@testable import SundeeFundeeKit

final class CyclePhaseHelperTests: XCTestCase {
    
    // MARK: - convertToPeriodLogs
    
    func testConvertToPeriodLogs_EmptySamples() {
        let logs = CyclePhaseHelper.convertToPeriodLogs([])
        XCTAssertTrue(logs.isEmpty)
    }
    
    // MARK: - calculateConfidence
    
    func testConfidence_OnePeriodLog_Recent() { ... }
}
```

**Patterns:**
- Test class extends `XCTestCase`
- Section markers `// MARK: -` group tests by function/behavior
- One assertion focus per test
- Setup/teardown not typically used (tests are stateless)
- Private helpers `makeX()` for test data creation

## Mocking

**Framework:** None — manual mocks using protocol conformance

**Patterns:**
```swift
// Mock test helper factory
private func makeInjury(
    location: String,
    name: String = "Test Injury",
    recoveryPhase: RecoveryPhase = .rehab
) -> Injury {
    Injury(
        id: UUID().uuidString,
        locationIds: location,
        name: name,
        recoveryPhase: recoveryPhase,
        dateCreated: Date(),
        phaseUpdated: Date()
    )
}

// Usage in test
func testIsContraindicated_KneeInjury_Squat() {
    let injuries = [makeInjury(location: "knee_left")]
    XCTAssertTrue(InjuryAdaptationEngine.isContraindicated(
        exerciseName: "Back Squat",
        exerciseCategory: nil,
        injuries: injuries
    ))
}
```

**Data Layer Mocks:**
- `MockCloudKitClient` — in-memory CloudKit simulation (`DataLayer/Mocks/`)
- `MockHealthKitClient` — in-memory HealthKit simulation
- Implement `DataClientProtocol` and `HealthClientProtocol` respectively
- Used for integration tests that don't require actual iCloud

**What to Mock:**
- External I/O: CloudKit, HealthKit, network (use mock clients)
- Not typical for unit tests of pure functions (domain layer)

**What NOT to Mock:**
- Pure functions — test directly
- Enums and value types — instantiate with test data
- Protocol implementations — use mocks for protocol-dependent code

## Fixtures and Factories

**Test Data:**
```swift
// From PlateauDetectorTests
private func makeRecord(
    exercise: String = "Back Squat",
    weight: Double,
    daysAgo: Int = 0
) -> OneRepMaxRecord {
    OneRepMaxRecord(
        id: UUID().uuidString,
        exerciseName: exercise,
        weight: weight,
        unit: .lbs,
        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    )
}

private func makeWorkout(
    exerciseName: String,
    sets: Int,
    reps: Int,
    weight: Double,
    daysAgo: Int
) -> Workout {
    let exerciseSets = (0..<sets).map { _ in
        ExerciseSet(
            reps: reps,
            prescribedWeight: weight,
            type: .fixed,
            completedWeight: weight,
            actualReps: reps,
            isComplete: true
        )
    }
    let exercise = Exercise(
        id: UUID().uuidString,
        name: exerciseName,
        category: .compound,
        bodyweight: 0,
        targetSets: exerciseSets
    )
    return Workout(
        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
        name: "Workout",
        exercises: [exercise],
        completedAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    )
}

// Helper for date construction
private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
}
```

**Location:**
- Defined as private methods in test classes
- One factory per test type (not shared files)
- Organized after `// MARK: - Helpers` section

## Coverage

**Requirements:** No explicit coverage target enforced

**Test Categories:**
- **Domain Tests** (DomainLayer): Pure function tests covering calculations, adaptations, detection logic
  - Examples: `CycleCalculationsTests`, `WeightCalculatorTests`, `InjuryAdaptationEngineTests`, `PlateauDetectorTests`
  - Generally high coverage (most domain logic has tests)
- **Model Tests** (Models): Serialization, initialization, computed properties
  - Examples: `WorkoutTests`, `ExerciseTests`
- **Data Layer Tests** (DataLayer): Mock client implementations, CloudKit schema logic
  - Examples: `MockCloudKitClient`, `MockHealthKitClient`
- **Auth Tests** (Auth): Sign-in flow, session validation
  - Examples: `AppleAuthClientTests`
- **Activity Tests** (Activity): Activity ring integration
  - Examples: `LiveWorkoutActivityStateTests`
- **ViewModel Tests** (ViewModels): State changes, side effects (when data layer is mocked)

## Test Types

**Unit Tests:**
- Scope: Single function or behavior in isolation
- Approach: Pure function tests with factory helpers, no external I/O
- Example: `CyclePhaseHelperTests.testConfidence_OnePeriodLog_Recent()` tests confidence calculation with specific inputs
- Most tests in codebase are unit tests

**Integration Tests:**
- Scope: Multiple domain layer components working together
- Approach: Not separate files, integrated into existing test classes
- Example: `CycleCalculationsTests.testCycleStatus_MultipleLogs_PicksMostRecentRelevant()` tests cycle status logic across multiple period logs
- No dedicated integration test directory

**E2E Tests:**
- Framework: Not used in Swift Package
- Note: XCTest UI automation exists in Xcode project (`SundeeFundeeApp/`) for SwiftUI views, but not in Package tests

## Common Patterns

**Asserting Calculations:**
```swift
func testCalculatePrescribedWeight_WithMultipliers() {
    // 300lb max, 5 reps (80%), medium energy (1.0), normal cycle (1.0)
    // Expected: 300 * 0.80 * 1.0 * 1.0 = 240 lbs
    let result = calculatePrescribedWeight(
        max: 300,
        reps: 5,
        energyMultiplier: 1.0,
        cycleMultiplier: 1.0
    )
    XCTAssertEqual(result, 240, accuracy: 0.1)
}
```

**Asserting State Changes:**
```swift
func testWorkoutTotalVolume() {
    let workout = Workout(
        id: "workout-002",
        date: Date(),
        name: "Volume Day",
        exercises: [...]
    )
    
    // 5 reps × 185 lbs × 2 sets = 1850 lbs total volume
    XCTAssertEqual(workout.totalVolume, 1850)
}
```

**Testing with Reference Dates:**
```swift
func testCycleStatus_Day10_Follicular() {
    let start = makeDate(2024, 1, 1)
    let ref = makeDate(2024, 1, 10)
    let logs = [PeriodLog(startDate: start)]
    let result = calculateCycleStatus(
        periodLogs: logs,
        settings: defaultSettings,
        referenceDate: ref
    )
    XCTAssertNotNil(result)
    XCTAssertEqual(result!.currentPhase, .follicular)
}
```

**Testing Boundaries:**
```swift
func testConfidence_ManyPeriodLogs_Recent() {
    let lastStart = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
    let confidence = CyclePhaseHelper.calculateConfidence(
        periodLogCount: 6,
        lastPeriodStart: lastStart
    )
    // 6+ logs = 0.9 base, recent = 1.0 multiplier
    XCTAssertEqual(confidence, 0.9, accuracy: 0.01)
}
```

**Testing Collections:**
```swift
func testWorkoutInitialization() {
    let workout = Workout(...)
    XCTAssertEqual(workout.id, "workout-001")
    XCTAssertEqual(workout.exercises.count, 1)
    XCTAssertEqual(workout.duration, 45)
}
```

**Testing Enum Discrimination:**
```swift
// ExerciseType is discriminated union
let fixed = ExerciseType.fixed
let range = ExerciseType.range(min: 5, max: 8)
let text = ExerciseType.text("As needed")

switch range {
case .range(let min, let max):
    XCTAssertEqual(min, 5)
    XCTAssertEqual(max, 8)
default:
    XCTFail("Expected range type")
}
```

## Test Count and Distribution

**Total:** 36 test files across 7 directories

**By Category:**
- `DomainTests/`: ~20 files (core business logic)
- `ModelTests/`: ~3 files (data model tests)
- `DataLayerTests/`: Minimal (mocks tested implicitly)
- `AuthTests/`: ~1-2 files (auth flow)
- `ActivityTests/`: ~1 file (activity integration)
- `ViewModelTests/`: Minimal or 0 (SwiftUI views tested in Xcode project UI automation)
- `SubscriptionTests/`: Minimal or 0 (subscription logic not heavily tested in package)

---

*Testing analysis: 2026-04-15*

# Testing Patterns

**Analysis Date:** 2025-03-14

## Test Framework

**Runner:**
- Swift Testing (native iOS 17+, replaces XCTest)
- Config: Built into Xcode, no external configuration file
- Uses `@Suite` and `@Test` macros

**Assertion Library:**
- Native Swift Testing `#expect()` macro (replaces `XCTAssertEqual`)

**Run Commands:**
```bash
# Run all tests (enforces 100% line coverage)
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests

# Run a single test class
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/BusinessLogicTests
```

## Test File Organization

**Location:**
- Co-located with source: `SundeeFundeTests/` directory at repo root
- 46 test files for 140 source files

**Naming:**
- Suffix `Tests`: `BusinessLogicTests.swift`, `AIWorkoutTests.swift`
- Suffix `CoverageTests` for wave-based coverage: `ViewModelCoverageTests.swift`, `AuthOnboardingCoverageWave5Tests.swift`
- Test files grouped by function: `RepositoryCoverageTests.swift`, `DomainCoverageTests.swift`, `ViewModelCoverageTests.swift`

**Structure:**
```
SundeeFundeTests/
├── BusinessLogicTests.swift
├── AIWorkoutTests.swift
├── AuthOnboardingViewCoverageTests.swift
├── AuthOnboardingCoverageWave3Tests.swift
├── AuthOnboardingCoverageWave5Tests.swift
├── BarbellTestHelpers.swift  # Shared fixtures
├── ViewModelCoverageTests.swift
├── RepositoryCoverageTests.swift
└── DomainCoverageTests.swift
```

## Test Structure

**Suite Organization:**
```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("WeightCalculations")
struct WeightCalculationsTests {

    @Test func roundToNearestFive() {
        #expect(WeightCalculations.roundToNearestFive(102.0) == 100.0)
        #expect(WeightCalculations.roundToNearestFive(103.0) == 105.0)
    }
}
```

**Patterns:**
- Setup: In `@Suite` struct, no `setUp()` / `tearDown()` lifecycle — computed properties or helper functions
- Teardown: None needed; in-memory test database auto-cleaned
- Assertion: `#expect()` macro (replaces `XCTAssert*`)
- Test discovery: `@Test` macro on each test function

**Swift Testing Specifics:**
- Suites are `struct` types (not classes)
- Tests are static functions decorated with `@Test`
- `#expect()` takes condition + optional message: `#expect(value == 5, "value should be 5")`
- No return type requirements
- Swift Testing runner partitions show "Executed 0 tests" per partition — look for aggregate "Executed N tests" line (noted in CLAUDE.md)

## Mocking

**Framework:** Manual mock implementations; no mocking library (Mockito, OCMock, etc.)

**Patterns:**
```swift
private final class FakeProgramRepository: ProgramRepository, @unchecked Sendable {
    private let programs: [Program]
    private let fetchProgramsError: Error?

    init(
        programs: [Program] = [],
        fetchProgramsError: Error? = nil
    ) {
        self.programs = programs
        self.fetchProgramsError = fetchProgramsError
    }

    func fetchPrograms() async throws -> [Program] {
        if let fetchProgramsError { throw fetchProgramsError }
        return programs
    }

    func fetchProgram(id: String) async throws -> Program? {
        programs.first { $0.id == id }
    }
}
```

**Patterns Observed:**

1. **Fake implementations** for simple stubs:
   ```swift
   final class MockBarbellRepository: BarbellRepository {
       private var presets: [BarbellPresetDTO] = []

       func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
           presets.filter { $0.userID == userID }
       }
   }
   ```

2. **Error-throwing stubs** for negative tests:
   ```swift
   private enum FakeCoverageError: Error {
       case expectedFailure
   }

   private struct ThrowingBenchmarkDefinitionRepository: BenchmarkDefinitionRepository {
       func fetchAll() throws -> [BenchmarkDefinition] {
           throw FakeCoverageError.expectedFailure
       }
   }
   ```

3. **Test doubles** using `@unchecked Sendable` to bypass strict concurrency:
   ```swift
   private final class FakeProgramRepository: ProgramRepository, @unchecked Sendable { ... }
   ```

**What to Mock:**
- Repository implementations (replace with `FakeRepository`)
- External service calls (replace with `FakeGeminiService`)
- Health data providers (replace with `MockHealthKitRepository`)

**What NOT to Mock:**
- Domain logic (pure Swift, fully unit testable without mocks)
- SwiftData models (use in-memory test container)
- Value types (enums, structs — use directly)

## Fixtures and Factories

**Test Data:**
```swift
// Factory functions create test objects
func makeBarbellTestExercise(
    name: String = "Back Squat",
    sets: ExerciseValue = .fixed(3),
    reps: ExerciseValue = .fixed(5),
    percent1RM: Double? = nil,
    restMinutes: Double? = 2
) -> ProgramExercise {
    ProgramExercise(
        exercise: name,
        variant: nil,
        sets: sets,
        reps: reps,
        percent1RM: percent1RM,
        restMinutes: restMinutes,
        notes: nil
    )
}

func makeBarbellTestSession(id: String = "s1") -> ProgramSession {
    ProgramSession(
        sessionID: id,
        sessionName: "Session \(id)",
        sessionType: "strength",
        focus: "Lower",
        exercises: [makeBarbellTestExercise()]
    )
}
```

**Location:**
- `BarbellTestHelpers.swift` contains shared factories
- Factories named `make*` prefix
- Parameterized with sensible defaults for common cases

**SwiftData Test Containers:**
```swift
@MainActor
private func makeContainer() throws -> ModelContainer {
    let schema = Schema(AppSchemaV10.models)
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [config])
}

// Usage in tests
@Test
@MainActor
func userRepositorySaveFetchDelete() throws {
    let container = try makeContainer()
    let repository = SwiftDataUserRepository(context: container.mainContext)
    // ... test code ...
}
```

## Coverage

**Requirements:**
- **100% line coverage enforced in CI** (GitHub Actions parses `xccov` output)
- All new public methods require test coverage
- Domain logic must have unit test coverage in corresponding `*CoverageTests.swift` file

**View Coverage:**
- Views tested for critical paths, not all branches
- Static helper methods tested: `DashboardViewModel.findTodayWOD()`, `EMOMTimerView.currentMinute()`
- State transitions verified through `@Test` assertions

## Test Types

**Unit Tests:**
- **Scope:** Single function or method
- **Approach:** Pure Swift domain logic (no mocks needed)
- **Example:** `WeightCalculations.roundToNearestFive(102.0) == 100.0`
- **Location:** `BusinessLogicTests.swift`, `DomainCoverageTests.swift`

```swift
@Suite("WeightCalculations")
struct WeightCalculationsTests {
    @Test func roundToNearestFive() {
        #expect(WeightCalculations.roundToNearestFive(102.0) == 100.0)
    }
}
```

**Integration Tests:**
- **Scope:** ViewModels + Repositories + SwiftData
- **Approach:** In-memory test container + fake repositories
- **Example:** `ViewModelCoverageTests.swift` tests `DashboardViewModel.load()` with test data
- **Location:** `ViewModelCoverageTests.swift`, `RepositoryCoverageTests.swift`

```swift
@Test
@MainActor
func userRepositorySaveFetchDelete() throws {
    let container = try makeContainer()
    let repository = SwiftDataUserRepository(context: container.mainContext)
    try repository.save(user)
    #expect(try repository.fetchCurrentUser()?.id == user.id)
}
```

**E2E Tests:**
- **Status:** Not used — SwiftUI smoke tests exist (`SwiftUISmokeTestsA.swift`, `SwiftUISmokeTestsB.swift`)
- **Purpose:** Basic rendering verification, not full user flows
- **Framework:** None (basic SwiftUI view instantiation)

## Common Patterns

**Async Testing:**
```swift
@Test
@MainActor
func loadPrograms() async {
    let viewModel = DashboardViewModel(
        programRepo: FakeProgramRepository(programs: [testProgram])
    )
    await viewModel.load(modelContext: container.mainContext)
    #expect(viewModel.activeProgram != nil)
}
```

**Error Testing:**
```swift
@Test
func fetchProgramsThrowsError() async throws {
    let repo = FakeProgramRepository(
        fetchProgramsError: FakeCoverageError.expectedFailure
    )

    await #expect(throws: FakeCoverageError.self) {
        try await repo.fetchPrograms()
    }
}
```

## Wave-Based Coverage Pattern

Coverage organized into "waves" (multi-file test groups):
- `AuthOnboardingViewCoverageTests.swift` — Auth UI
- `AuthOnboardingCoverageWave3Tests.swift` — Auth flow part 3
- `AuthOnboardingCoverageWave5Tests.swift` — Auth flow part 5
- `ModelRepoObservabilityCoverageWave4Tests.swift` — Model + Repo tests part 4

This allows splitting massive test files across logical groupings while maintaining code review manageable.

## Coverage Testing Assertions

**Pattern Example from `DomainCoverageTests.swift`:**
```swift
@Suite("WeightCalculations Additional")
struct WeightCalculationsAdditionalTests {

    @Test func wasSetSuccessfulCoversWeightAndRepBranches() {
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 95, prescribedWeight: nil) == true)
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 4, prescribedReps: 5, actualWeight: 100, prescribedWeight: 100) == false)
    }

    @Test func detectPlateauCoversEdgeCasesAndHappyPaths() {
        #expect(WeightCalculations.detectPlateau(weights: []) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 100]) == true)
    }
}
```

Tests group edge cases + happy paths to ensure full decision tree coverage.

## Default Parameter Value Updates

**Critical Rule:** When changing default parameter values, update all test call sites to pass the value explicitly.

Tests that omit the parameter will silently use the new default and may break without warning.

**Example:**
```swift
// If signature changes:
func makeExercise(restMinutes: Double = 3) -> Exercise  // Changed from 2

// Update ALL test calls:
makeExercise(restMinutes: 2)  // Explicit, not relying on default
```

---

*Testing analysis: 2025-03-14*

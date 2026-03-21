# Testing Patterns

**Analysis Date:** 2026-03-21

## Test Framework

**Runner:**
- Apple Testing framework (not XCTest)
- Uses `@Suite` and `@Test` attributes (Swift 6.0+)
- Config: `project.yml` specifies test target `SundeeFundeTests`

**Assertion Library:**
- Native Swift Testing assertions: `#expect(condition)`, `#expect(actual == expected)`

**Run Commands:**
```bash
xcodebuild test -scheme SundeeFundee  # Run all tests
xcodebuild test -scheme SundeeFundee -only-testing SundeeFundeTests/BarbellDefaultsTests  # Run specific suite
```

## Test File Organization

**Location:**
- Co-located with main source: test files in `SundeeFundeTests/` directory (separate bundle)
- Test target configured in `project.yml` scheme

**Naming:**
- `{SubjectName}Tests.swift` convention: `BarbellDefaultsTests.swift`, `SubscriptionServiceTests.swift`
- Suite name matches subject: `@Suite("BarbellDefaults")`, `@Suite("SubscriptionTier")`

**Structure:**
```
SundeeFundeTests/
├── AIWorkoutTests.swift
├── AuthOnboardingCoverageTests.swift
├── BarbellDefaultsTests.swift
├── DomainCoverageTests.swift
├── SubscriptionServiceTests.swift
└── [43 more test files]
```

## Test Structure

**Suite Organization:**
```swift
import Testing
import Foundation
@testable import SundeeFundee

@Suite("BarbellDefaults")
struct BarbellDefaultsTests {

    @Test func builtInPresetsHasFourEntries() {
        let presets = BarbellDefaults.builtInPresets
        #expect(presets.count == 4)
    }

    @Test func standardPresetIs45Lb() {
        let standard = BarbellDefaults.builtInPresets.first { $0.name == "Standard" }
        #expect(standard != nil)
        let expectedKg = 45.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(standard!.weightKg - expectedKg) < 0.01)
    }
}
```

**Patterns:**
- Test suites are structs marked with `@Suite(name)`
- Each test is a method marked with `@Test`
- Setup: Tests create fixtures inline (no setUp/tearDown methods)
- Assertions: Single `#expect()` per test or multiple related assertions
- Helper methods: Create factories/builders within test suite for repeated setup

## Mocking

**Framework:** None detected; Domain layer tested without mocks

**Patterns:**
- Domain layer (pure calculations) tested directly without mocking
- Service tests use dependency injection to pass mock dependencies
- Example from `SubscriptionServiceTests.swift`:
  ```swift
  @Test @MainActor func defaultsToFree() {
      Self.resetUserDefaults()
      let service = SubscriptionService()
      #expect(service.currentTier == .free)
  }
  ```

**What to Mock:**
- UserDefaults access: reset in test setup
- External services: Pass mock implementations via constructor
- Time-dependent functions: Inject reference dates

**What NOT to Mock:**
- Domain logic (pure calculations): Test directly with real values
- Data structures: Create actual instances with test data
- Enums and value types: Use actual instances

## Fixtures and Factories

**Test Data:**
- Inline factory functions in test suites:
  ```swift
  private func makeSettings(
      cycleDays: Int = 28,
      periodDays: Int = 5,
      lutealDays: Int = 14
  ) -> CycleSettings {
      CycleSettings(
          id: UUID().uuidString,
          userID: "u1",
          averageCycleLengthDays: cycleDays,
          averagePeriodLengthDays: periodDays,
          lutealPhaseLengthDays: lutealDays
      )
  }
  ```

**Location:**
- Factories defined as private methods in test suite struct
- Helper types in `SundeeFundeTests/` (e.g., `BarbellTestHelpers.swift`)
- JSON fixtures in `src/domain/__fixtures__/` directory for domain tests:
  - `cycle-adaptation.json`
  - `cycle-calculations.json`
  - `weight-calculations.json`
  - `injury-adaptation.json`

## Coverage

**Requirements:** Not enforced via configuration; 43 test files with 1000+ tests suggest comprehensive coverage

**View Coverage:**
- `SwiftUISmokeTestsA.swift`, `SwiftUISmokeTestsB.swift` for UI smoke tests
- `DashboardViewCoverageTests.swift`, `FeatureViewsCoverageTests.swift` for feature views

**Model Coverage:**
- `BenchmarkModelTests.swift`, `BarbellRepositoryCoverageTests.swift`

**View Coverage:**
```bash
# No explicit coverage reporting command found
# Coverage likely tracked via Xcode's built-in code coverage
```

## Test Types

**Unit Tests:**
- Domain calculations: `CycleCalculationsAdditionalTests`, `BarbellDefaultsTests`
- Service logic: `SubscriptionServiceTests`, `GeminiWorkoutServiceTests`
- Repository operations: `BenchmarkRepositoryTests`, `WODRepositoryTests`
- Scope: Single type/function, pure logic without side effects
- Approach: Direct calls with assertions

**Integration Tests:**
- ViewModel tests: `ReadinessSurveyViewModelTests`, `WODExecutionViewModelTests`
- Repository integration: `BarbellRepositoryCoverageTests` (with SwiftData)
- Service interaction tests: Domain + Repository coordination
- Scope: Multiple components interacting
- Approach: Setup dependencies, verify state changes and outputs

**E2E Tests:**
- Not explicitly labeled, but smoke tests simulate user flows
- `SwiftUISmokeTestsA.swift`, `SwiftUISmokeTestsB.swift` verify UI initialization
- `UICriticalFlowTests.swift` tests critical user paths
- Not automated; relies on manual testing for full app flows

## Common Patterns

**Async Testing:**
- Tests marked with `@MainActor` when testing main-thread code
- Example:
  ```swift
  @Test @MainActor func defaultsToFree() {
      // Test runs on main thread
  }
  ```
- Async functions not heavily tested; domain layer is synchronous

**Error Testing:**
```swift
// Testing error behavior with Result type
@Test func tierFromProductID() {
    #expect(SubscriptionTier.from(productID: "com.sundeefundee.unknown") == .free)
}
```

**Boundary Testing:**
```swift
@Test func detectsOvulationAndLutealPhases() {
    let settings = makeSettings()

    let ovulation = CycleCalculations.calculateCycleStatus(
        periodLogs: [makePeriodLog(startOffset: -12)],
        settings: settings,
        referenceDate: referenceDate
    )
    #expect(ovulation?.currentPhase == .ovulation)
}
```

**Enum and Value Type Testing:**
```swift
@Test func caseInsensitiveMatching() {
    #expect(BarbellDefaults.suggestedPresetName(for: "barbell curl", gender: .male) == "EZ Curl")
    #expect(BarbellDefaults.suggestedPresetName(for: "BENCH PRESS", gender: .female) == "Women's")
}
```

## Test Organization Best Practices

**As Observed:**
1. One suite per file, named after the subject
2. Tests grouped logically with descriptive names
3. Helper methods for setup (factories)
4. Reset shared state (UserDefaults) before tests marked `.serialized`
5. Fixtures stored as JSON for domain test data
6. No global setup/teardown; inline initialization preferred
7. Assertions focus on behavior, not implementation

**Coverage Goals:**
- Domain layer: Comprehensive coverage of pure logic
- Services: Happy path and error conditions
- ViewModels: State initialization and updates
- Views: Smoke tests for initialization without crashes

---

*Testing analysis: 2026-03-21*

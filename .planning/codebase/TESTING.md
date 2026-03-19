# Testing Patterns

**Analysis Date:** 2026-03-18

> This documents the **legacy Swift/SwiftUI codebase** test suite in `SundeeFundeTests/`. The active React Native rewrite has its own Jest-based tests.

## Test Framework

**Runner:**
- Swift Testing (new `@Suite`/`@Test` macro API) — primary framework
- XCTest (`XCTestCase` subclasses) — secondary framework, used for ViewModel and smoke tests
- Both frameworks coexist in the same test target

**Assertion Library:**
- Swift Testing: `#expect(...)` macro
- XCTest: `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil`, `XCTAssertNotNil`
- Swift Testing failure recording: `Issue.record("message")` (equivalent to `XCTFail`)

**Run Commands:**
```bash
# Via Xcode: Product > Test (⌘U)
# Via CLI:
xcodebuild test -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Test File Organization

**Location:**
- Separate `SundeeFundeTests/` directory (not co-located with source)
- Flat directory structure — all 46 test files in one folder, no subdirectories

**Naming:**
- Domain logic: `<Domain>Tests.swift` — e.g., `BusinessLogicTests.swift`, `WODTests.swift`
- Repository tests: `<Domain>RepositoryTests.swift` — e.g., `RepositoryCoverageTests.swift`, `WODRepositoryTests.swift`
- ViewModel tests: `<Feature>ViewModelTests.swift` — e.g., `WODExecutionViewModelTests.swift`, `ReadinessSurveyViewModelTests.swift`
- Coverage waves: `<Area>CoverageTests.swift`, `<Area>CoverageWave<N>Tests.swift` — used to group broad coverage expansions
- Smoke tests: `SwiftUISmokeTestsA.swift`, `SwiftUISmokeTestsB.swift`
- Shared helpers: `BarbellTestHelpers.swift`

## Test Structure

**Swift Testing suite organization:**
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

    @Test func detectPlateauTrue() {
        #expect(WeightCalculations.detectPlateau(weights: [80, 80, 82]) == true)
    }
}
```

**XCTest suite organization:**
```swift
import XCTest
import SwiftData
@testable import SundeeFundee

@MainActor
final class WODExecutionViewModelTests: XCTestCase {

    // MARK: - Setup helpers

    private func makeWOD(exercises: [ProgramExercise] = []) -> WOD { ... }
    private func makeExercise(...) -> ProgramExercise { ... }
    private func makeTestStore() throws -> (container: ModelContainer, context: ModelContext) {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return (container, ModelContext(container))
    }

    // MARK: - Initialization

    func testInitializeSetsCreatesCorrectSetCount() {
        let exercises = [makeExercise(sets: .fixed(4))]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))
        XCTAssertEqual(vm.exerciseSets[0]?.count, 4)
    }
}
```

**Patterns:**
- `@MainActor` on the test class (not individual methods) when testing `@Observable @MainActor` ViewModels
- `// MARK: - <Section>` to group related tests within a file
- Private helper methods (`makeXxx(...)`) at the top of the file for fixture construction
- XCTest classes are always `final class`

## Mocking

**Protocol mocking:**
Manual mock implementations conforming to repository protocols:
```swift
final class MockBarbellRepository: BarbellRepository {
    private var presets: [BarbellPresetDTO] = []
    private var mappings: [ExerciseBarMappingDTO] = []

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        presets.filter { $0.userID == userID }.sorted { $0.sortOrder < $1.sortOrder }
    }
    // ... all protocol methods implemented with in-memory state
}
```

**Network mocking via URLProtocol:**
```swift
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override func startLoading() {
        guard let handler = Self.requestHandler else { ... }
        let (response, data) = try handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

// Usage: configure URLSession with mock protocol
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)

MockURLProtocol.requestHandler = { _ in
    let response = HTTPURLResponse(url: ..., statusCode: 200, ...)!
    return (response, Data(json.utf8))
}
```

**Dependency injection mocking:**
`AuthService.Dependencies` uses closure-based injection. Tests provide custom closures:
```swift
let service = AuthService(dependencies: .init(
    saveAppleUserID: { _ in },
    loadAppleUserID: { "stored-user" },
    deleteAppleUserID: { },
    credentialStateForUserID: { _ in .authorized },
    makeUUID: { "test-uuid" }
))
```

**Inline anonymous mock repos (Swift Testing):**
```swift
private final class InMemoryProgramRepository: ProgramRepository, @unchecked Sendable {
    let programs: [Program]
    func fetchPrograms() async throws -> [Program] { programs }
    func fetchProgram(id: String) async throws -> Program? { programs.first { $0.id == id } }
}
```

**What to Mock:**
- Repository protocol implementations (to avoid SwiftData in pure logic tests)
- URLSession (via `MockURLProtocol`) for network service tests
- System dependencies in `Dependencies` structs (keychain, UUID generation)
- `UserDefaults` (injected fresh instance per test via `UserDefaults(suiteName:)`)

**What NOT to Mock:**
- Domain logic (tested directly — no mocking needed)
- SwiftData `ModelContext` (use in-memory store instead)

## Fixtures and Factories

**Shared test helpers file:**
`SundeeFundeTests/BarbellTestHelpers.swift` — shared `make*` functions usable across test files:
```swift
func makeBarbellTestExercise(name: String = "Back Squat", ...) -> ProgramExercise { ... }
func makeBarbellTestSession(id: String = "s1") -> ProgramSession { ... }
func makeBarbellTestProgram(id: String = "p1", weeks: [ProgramWeek]) -> Program { ... }

@MainActor
func makeBarbellTestVM(barbellRepo: BarbellRepository? = nil, ...) -> WorkoutExecutionViewModel { ... }
```

**In-memory SwiftData container (standard pattern):**
```swift
private func makeTestStore() throws -> (container: ModelContainer, context: ModelContext) {
    let schema = Schema(AppSchemaV10.models)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    return (container, ModelContext(container))
}
```

**Fixed date anchor for ordering tests:**
```swift
private static let baseTime = Date(timeIntervalSince1970: 1_700_000_000)
private func date(_ seconds: TimeInterval) -> Date { Self.baseTime.addingTimeInterval(seconds) }
```

**Isolated UserDefaults per test:**
```swift
private func freshDefaults() -> UserDefaults {
    let name = "test-survey-vm-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}
```

**Location:**
- Shared helpers: `SundeeFundeTests/BarbellTestHelpers.swift`
- Per-file helpers: `private func make<Type>(...)` defined at the top of each test file

## Coverage

**Requirements:** No enforced threshold detected — no `.xccoverage` or CI coverage gate.

**Schema used in tests:** `AppSchemaV10.models` is the standard schema used for in-memory containers (not always the latest V12 — note this potential staleness issue).

## Test Types

**Unit Tests (Domain logic):**
- Location: `BusinessLogicTests.swift`, `DomainCoverageTests.swift`, `WODTemplateTypeTests.swift`
- Scope: Pure functions in `SundeeFundee/Domain/` — `WeightCalculations`, `CycleCalculations`, `InjuryAdaptationEngine`, `EpleyFormula`
- No mocking required — direct instantiation and assertion

**Unit Tests (ViewModel):**
- Location: `WODExecutionViewModelTests.swift`, `ReadinessSurveyViewModelTests.swift`, `ViewModelCoverageTests.swift`, `AIWorkoutViewModelTests.swift`
- Use in-memory SwiftData containers or injected mock repos
- `@MainActor` on class for Observable VM testing

**Integration Tests (Repository):**
- Location: `RepositoryCoverageTests.swift`, `WODRepositoryTests.swift`, `BenchmarkRepositoryTests.swift`, `BarbellRepositoryCoverageTests.swift`
- Use in-memory `ModelContainer` with full schema
- Test full CRUD lifecycle including sort order and predicate behavior

**Network Integration Tests:**
- Location: `GeminiWorkoutServiceTests.swift`
- Use `MockURLProtocol` injected into `URLSession` — tests HTTP method, headers, body, error codes
- `@Suite(.serialized)` to prevent concurrent handler mutation

**SwiftUI Smoke Tests:**
- Location: `SwiftUISmokeTestsA.swift`, `SwiftUISmokeTestsB.swift`
- Instantiate Views via `UIHostingController` and trigger layout
- Verify no crash on render; do not assert UI element content
- `host<Content: View>(_ view: Content, triggerAppearance: Bool)` helper pattern

**Coverage Wave Tests:**
- `AuthOnboardingViewCoverageTests.swift`, `AuthOnboardingCoverageWave3Tests.swift`, `AuthOnboardingCoverageWave5Tests.swift`, etc.
- Target specific code paths for coverage; grouped by feature area and wave number

## Common Patterns

**Async Testing (Swift Testing):**
```swift
@Test("Falls back to offline on network error")
func fallsBackToOfflineOnNetworkError() async {
    FallbackMockURLProtocol.requestHandler = { _ in
        throw URLError(.notConnectedToInternet)
    }
    let workout = await SwiftDataAIWorkoutService.generateWithFallback(...)
    #expect(workout.coachingSummary.contains("offline"))
}
```

**Async Testing (XCTest):**
```swift
func testRestoreSession() async throws {
    let state = await service.restoreSession(modelContext: context)
    XCTAssertEqual(state, .authenticated(userID: "test-id"))
}
```

**Error/Throw Testing (Swift Testing):**
```swift
await #expect(throws: GeminiServiceError.httpError(statusCode: 500)) {
    try await service.generate(from: makeContext())
}

// For any error:
await #expect(throws: (any Error).self) {
    try await service.generate(from: makeContext())
}
```

**Expected failure recording (Swift Testing):**
```swift
do {
    _ = try Program(record: record)
    Issue.record("Expected missing fields error")
} catch ProgramDecodingError.missingFields {
    // expected — test passes
}
```

**Toggling boolean state:**
```swift
vm.toggleSetCompleted(exerciseIndex: 0, setIndex: 0)
XCTAssertTrue(vm.exerciseSets[0]![0].isCompleted)
XCTAssertTrue(vm.showRestTimer)
```

**Testing enum raw value bridging (SwiftData models):**
```swift
let pr = ConditioningPR(...)
#expect(pr.scoringType == .reps)
#expect(pr.scoringTypeRaw == "reps")
pr.scoringType = .time
#expect(pr.scoringTypeRaw == "time")
```

---

*Testing analysis: 2026-03-18*

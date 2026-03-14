# Coding Conventions

**Analysis Date:** 2025-03-14

## Naming Patterns

**Files:**
- Pascal case for View files: `DashboardView.swift`, `DashboardViewModel.swift`
- Pascal case for Model files: `User.swift`, `Program.swift`
- Pascal case for all types and classes: `CloudKitProgramRepository.swift`, `WeightCalculations.swift`
- Protocol files named for protocol: `RepositoryProtocols.swift`, `ProgramRepository.swift`
- Enum files named for enum: `CyclePhase.swift` (inside `Domain/`)

**Functions:**
- Camel case with verb-first pattern: `fetchPrograms()`, `savePreset()`, `calculateCycleStatus()`
- Static helper functions on Views use descriptive names: `currentMinute()`, `exerciseIndex()`, `timeWithinInterval()`
- Private helper functions prefixed with `_` or lowercase verb: `makeContainer()`, `makeProgramRecord()`
- Boolean predicates: `isAtLastSession`, `hasRecentLog()`, `isPersonalRecord()`

**Variables:**
- Camel case for all variables: `activeEnrollment`, `currentCyclePhase`, `oneRepMaxes`
- Collection variables plural: `recentWorkouts`, `activeInjuries`, `oneRepMaxes`, `allPrograms`
- Private properties prefixed with underscore: `_viewModel`, `_isLoading`
- Computed properties use same naming as stored properties: `experienceLevel` computed property accesses `experienceLevelRaw`

**Types:**
- Pascal case for all custom types: `CycleStatusResult`, `PhaseBoundary`, `PhaseRecommendation`
- Enum cases: lowercase with underscores for multi-word: `.full_body`, `.lower_body`, `.prefer_not_to_say`
- Protocol names describe capability: `ProgramRepository`, `UserRepository`, `BarbellRepository`
- Result wrapper types: `CycleStatusResult`, `PhaseRecommendation` (compound noun structure)

**Test Files:**
- Suffix with `Tests` or `CoverageTests`: `BusinessLogicTests.swift`, `ViewModelCoverageTests.swift`
- Suite names match what they test: `@Suite("WeightCalculations")`, `@Suite("EMOMTimerView Static Helpers")`
- Test function names start with what they test: `roundToNearestFive()`, `calculateTargetWeight()`, `userRepositorySaveFetchDelete()`

## Code Style

**Formatting:**
- No external formatter configured — Xcode default formatting applied
- 4-space indentation
- Line breaks: logical breaks for readability, not strict column limit
- Blank lines between logical sections
- MARK comments used extensively to organize code

**Linting:**
- No linter configured (no `.swiftlint.yml`, `swiftformat`, or `biome.json`)
- Code style enforced via code review and testing

**Import Organization:**
```swift
// Order observed in codebase:
import SwiftUI
import SwiftData
import Foundation
import CloudKit
@testable import SundeeFundee  // Test files only
```

Import groups:
1. SwiftUI (UI framework)
2. SwiftData (database)
3. Foundation (base library)
4. CloudKit (specific services)
5. Custom modules (@testable, specific packages)

## Error Handling

**Patterns:**
- Repository methods throw errors: `func fetchPrograms() async throws -> [Program]`
- ViewModels and services use graceful degradation: `(try? await programRepo.fetchPrograms()) ?? []`
- Never use `try!` in production code (enforced in CLAUDE.md)
- Failing repository calls default to empty collections: `?? []`, `?? [:]`, `?? nil`
- SwiftData context save wrapped with `try?`: `try? modelContext.save()`

**Pattern Example:**
```swift
// Repository throws
func fetchPrograms() async throws -> [Program]

// ViewModel gracefully handles error
let allPrograms = (try? await programRepo.fetchPrograms()) ?? []
```

**Errors in views:**
- Button actions ignore errors: `try? workoutRepo.save(skipped)`
- Critical failures handled with optional coalescing: `(try? userRepo.fetchCurrentUser())?.id ?? ""`
- No error presentation to user for repository failures (silent fallback)

## Logging

**Framework:** `print()` and `NSLog()` only — no dedicated logging framework

**When to Log:**
- Domain logic generally does NOT log (pure Swift, zero dependencies)
- Repository implementations may log failures via print (minimal usage observed)
- ViewModels do not log
- Services (e.g., `AuthService`) may use print for debugging

**Pattern:**
```swift
// Minimal logging observed, mostly commented out debug code
```

## Comments

**When to Comment:**
- Complex algorithms: See `CycleCalculations.swift` for phase boundary calculations
- Non-obvious business logic: See `CloudKitProgramRepository` fallback behavior
- Important constraints: See `User.swift` comment "Enums must be stored as raw strings"

**JSDoc/TSDoc:**
- Triple-slash documentation on key public functions: `/// Top-level auth state that drives routing.`
- Mark comments organize code sections: `// MARK: - Component Name`
- Inline comments rare; code is self-documenting via naming

**Mark Organization Pattern:**
```swift
// MARK: - Enums (stored as raw strings in SwiftData)
enum Gender: String, Codable { ... }

// MARK: - User
@Model final class User { ... }

// MARK: - Subviews
var body: some View { ... }
```

## Function Design

**Size:** Functions typically 10-40 lines; longer functions broken into private helpers

**Parameters:**
- Parameters passed explicitly rather than via stored properties when possible
- Dependency injection used heavily: `init(programRepo: any ProgramRepository = CloudKitProgramRepository())`
- Optional parameters with defaults for testability: `referenceDate: Date = .now`

**Return Values:**
- Functions return optional types rather than throwing on "not found": `fetchProgram(id:) -> Program?`
- Async functions throw on errors: `async throws -> [Program]`
- Void methods modify state via stored properties

**Example:**
```swift
// Dependency injection with default
init(
    programRepo: any ProgramRepository = CloudKitProgramRepository(),
    readinessRepo: (any ReadinessRepository)? = nil,
    wodRepo: any WODRepository = CloudKitWODRepository()
) { ... }

// Optional return + graceful default
let allPrograms = (try? await programRepo.fetchPrograms()) ?? []
```

## Module Design

**Exports:**
- Public types in root of `Domain/`, `Models/`, `Features/`, `Repositories/`
- Private implementation details use `private`, `fileprivate`
- Protocol definitions in separate files: `RepositoryProtocols.swift`

**Barrel Files:**
- Not used; each file exports a single primary type
- Test files import directly: `@testable import SundeeFundee`

## Observable & MainActor

**@Observable Pattern:**
- All ViewModels decorated: `@MainActor @Observable final class DashboardViewModel`
- State properties are mutable: `var activeEnrollment: EnrolledProgram?`
- Repository dependencies stored as private: `private let programRepo: any ProgramRepository`

**@MainActor:**
- Enforced on all ViewModels and AppState
- Test helpers marked `@MainActor` when creating containers or ViewModels
- UI updates via state mutation: `activeProgram = program`

**Example:**
```swift
@MainActor
@Observable
final class DashboardViewModel {
    var activeEnrollment: EnrolledProgram?
    private let programRepo: any ProgramRepository

    init(programRepo: any ProgramRepository = CloudKitProgramRepository()) {
        self.programRepo = programRepo
    }
}
```

## Enum Storage in SwiftData

**Critical Pattern:**
- All enum properties stored as raw String values (CloudKit requirement)
- Computed properties provide typed accessors
- Raw property names suffixed with `Raw`: `experienceLevelRaw: String`

**Example from `User.swift`:**
```swift
// Storage
var experienceLevelRaw: String
var primaryGoalRaw: String
var genderRaw: String

// Typed accessor
var experienceLevel: ExperienceLevel {
    get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner }
    set { experienceLevelRaw = newValue.rawValue }
}

// Usage in init
init(experienceLevel: ExperienceLevel, ...) {
    self.experienceLevelRaw = experienceLevel.rawValue
}
```

## Custom Codable

**Rule:** If you implement `init(from decoder:)`, you must also implement `encode(to:)`.

This is enforced in code review to prevent silent loss of Encodable capability when customizing Decodable.

---

*Convention analysis: 2025-03-14*

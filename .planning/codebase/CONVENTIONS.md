# Coding Conventions

**Analysis Date:** 2026-03-18

> This documents the **legacy Swift/SwiftUI codebase** in `SundeeFundee/`. The active React Native rewrite lives in `.claude/worktrees/` and has separate conventions.

## Naming Patterns

**Files:**
- Views: `<Feature>View.swift` — e.g., `WorkoutExecutionView.swift`, `DashboardView.swift`
- ViewModels: `<Feature>ViewModel.swift` — one-to-one with Views
- Repositories (concrete): `SwiftData<Domain>Repository.swift` — e.g., `SwiftDataCycleRepository.swift`
- Repository protocols: all in a single file `RepositoryProtocols.swift`
- Schema versions: `AppSchemaV<N>.swift` (e.g., `AppSchemaV12.swift`)
- Helpers/shared files: named by purpose, e.g., `BarbellTestHelpers.swift`

**Types (structs, classes, enums):**
- PascalCase for all: `WorkoutExecutionViewModel`, `SetExecutionState`, `BarbellPresetDTO`
- Domain enums are value types: `WeightCalculations`, `EpleyFormula`, `PlateCalculation` — implemented as caseless `enum` acting as namespaces
- DTO suffix for data transfer structs: `BarbellPresetDTO`, `ExerciseBarMappingDTO`

**Functions and Properties:**
- camelCase: `finishWorkout(modelContext:userID:)`, `fetchActiveCycles()`, `toggleSetCompleted(exerciseName:setIndex:)`
- Boolean properties: named with `is`/`has`/`show` prefix: `isSaving`, `isFinished`, `showRestTimer`, `hasRequiredOnboardingAnswers`
- Factory functions in test helpers: `make<Type>(...)` pattern — `makeExercise(...)`, `makeWOD(...)`, `makeBarbellTestVM(...)`

**Variables:**
- camelCase: `exerciseSets`, `barbellWeightKg`, `plateCalcWeightKg`
- Enum raw values stored as `<propertyName>Raw` pattern on `@Model` classes (CloudKit/SwiftData requirement):
  ```swift
  var experienceLevelRaw: String
  var experienceLevel: ExperienceLevel {
      get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner }
      set { experienceLevelRaw = newValue.rawValue }
  }
  ```

## Code Style

**Formatting:**
- No explicit Prettier/SwiftFormat config detected; follows Xcode default formatting
- 4-space indentation (Swift standard)
- Trailing commas not used in multi-line init calls

**Access Control:**
- `private` for implementation details within a type
- `private var` for repo/context dependencies in ViewModels
- `private static` for class-level helpers and UserDefaults keys: `private static let dismissedTransitionsKey = "dismissedPhaseTransitions"`
- `static` for pure computation functions in domain enums

## Architecture Patterns

**ViewModels:**
- All `@MainActor @Observable final class <Name>ViewModel`
- No `@Published` — uses `@Observable` macro (Swift 5.9+/iOS 17+)
- ViewModels own all mutable state and expose mutating methods
- Dependencies injected via `init` parameters with defaults: `barbellRepo: BarbellRepository? = nil`

**Repository Protocol Pattern:**
- Each domain has a protocol in `RepositoryProtocols.swift` (e.g., `WorkoutRepository`, `CycleRepository`)
- Concrete implementations: `SwiftData<Domain>Repository` wrapping a `ModelContext`
- Async protocols use `async throws` (e.g., `ProgramRepository`, `WODRepository`, `AIWorkoutServiceProtocol`)
- Sync protocols use `throws` (e.g., `WorkoutRepository`, `CycleRepository`, `LiftRepository`)
- `Sendable` conformance on protocols used in async contexts

**Domain Layer:**
- Pure Swift enums with static functions — no state, no dependencies
- Example pattern:
  ```swift
  enum WeightCalculations {
      static func calculateTargetWeight(oneRepMax: Double, percentage: Double) -> Double {
          roundToNearestFive(oneRepMax * percentage)
      }
  }
  ```
- Domain types in `SundeeFundee/Domain/` — no SwiftUI, no SwiftData imports

**Dependency Injection for System Services:**
- `Dependencies` nested struct with closure-based injection (see `AuthService.Dependencies`)
- `.live` static property provides production dependencies
- Test overrides substitute closures at init time

## SwiftData Conventions

- `@Model final class` for all persistent models
- Enum properties on `@Model` stored as raw `String` fields (CloudKit/SwiftData requirement)
- Computed property bridging pattern:
  ```swift
  var genderRaw: String  // stored
  var gender: Gender {   // computed bridging property
      get { Gender(rawValue: genderRaw) ?? .preferNotToSay }
      set { genderRaw = newValue.rawValue }
  }
  ```
- Schema versioned via `AppSchemaV<N>` enums implementing `VersionedSchema`
- Migration plan in `AppSchemaMigrationPlan.swift`
- `isStoredInMemoryOnly: true, cloudKitDatabase: .none` for test containers

## Error Handling

**Patterns:**
- Repository methods declare `throws` and use `try` internally
- Call sites use `try?` to silently discard errors and provide fallbacks:
  ```swift
  barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
  ```
- `try? ctx.save()` pattern for context saves in ViewModels
- Async network errors use `throws` with typed error enums: `GeminiServiceError.httpError(statusCode:)`
- Auth uses `Result<Success, Error>` in completion handlers

**Error Types:**
- Enums conforming to `LocalizedError` with `errorDescription`: `AuthError`, `GeminiServiceError`, `ProgramDecodingError`

## Import Organization

**Order:**
1. `Foundation`
2. `SwiftData` / `SwiftUI` (when needed)
3. `AuthenticationServices`, `CloudKit`, `HealthKit` (system frameworks)
4. `@testable import SundeeFundee` (test files only)

No `#if` conditional imports observed.

## Comments and Documentation

**MARK sections** — used consistently to organize file sections:
```swift
// MARK: - SetExecutionState
// MARK: - Setup
// MARK: - Set mutations
// MARK: - Rest timer
// MARK: - Completion
// MARK: - Helpers
```

**DocComments:**
- Triple-slash `///` for public/internal functions and types: `/// Returns the next (week, day) in the program, or the current position if at the end.`
- Inline `//` for non-obvious logic: `// Auto-start rest timer when a set is completed`
- No JSDoc-style `@param`/`@return` annotations

**Protocol conformance comments:**
- Used to group delegate conformances: `// MARK: - Delegate`

## Theme/UI Conventions

**Design tokens in `SundeeFundee/Theme/AppTheme.swift`:**
```swift
AppTheme.Color.navy        // #0D1A40
AppTheme.Color.cream       // #F4F0DF
AppTheme.Color.orange      // #F2731A
AppTheme.Colors.accentOrange  // semantic alias (preferred in Views)
AppTheme.Spacing.md        // 16pt
AppTheme.Radius.md         // 12pt
AppTheme.Font.heading(24)  // .system(.serif)
```
- Always use `AppTheme` tokens — never hardcode colors or font sizes in Views
- Semantic aliases (`AppTheme.Colors.*`) preferred over raw token names in feature Views

## Function Design

**Size:** ViewModels have larger functions (e.g., `finishWorkout`) that orchestrate multiple repository calls; domain functions are small and focused.

**Parameters:** Use labeled parameters; provide defaults for optional dependencies. Long parameter lists are split across lines with trailing comma style.

**Return Values:**
- Pure functions return values directly
- ViewModels mutate `@Observable` properties as side effects
- Async state transitions return `AuthState` enum values

---

*Convention analysis: 2026-03-18*

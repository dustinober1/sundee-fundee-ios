# Coding Conventions

**Analysis Date:** 2026-04-15

## Naming Patterns

**Files:**
- PascalCase for source files (e.g. `AppTheme.swift`, `CloudKitClient.swift`, `CyclePhaseHelper.swift`)
- Test files use same name as source with `Tests` suffix (e.g. `CyclePhaseHelperTests.swift`)
- Grouped by feature/domain in subdirectories (e.g. `DomainLayer/Cycle/`, `UI/ViewModels/`, `DataLayer/Actors/`)

**Functions:**
- camelCase for all functions (e.g. `signInWithApple()`, `calculateConfidence()`, `fetchUserNameFromCloudKit()`)
- Public functions documented with markdown comments
- Prefixes: `is` for booleans (e.g. `isAuthenticated`, `isComplete`, `isGuest`)
- Prefixes: `get`/`calculate` for computed values (e.g. `getRegressions()`, `calculateCycleStatus()`)

**Variables:**
- camelCase for variables and properties
- `@Published` for SwiftUI observable properties (view models)
- `@MainActor` annotation for view models
- Private properties with `private let` or `private var`
- Public properties explicitly marked `public`
- Trailing closure properties: `private var restTimerCancellable: AnyCancellable?`

**Types:**
- PascalCase for all types: enums, structs, classes, protocols
- Swift enums preferred over stringly-typed dictionaries (e.g. `ExerciseType` enum instead of string constants)
- Discriminated enums for flexible types: `enum ExerciseType { case fixed, amrap, range(min: Int, max: Int), text(String) }`
- Protocol names end with "Protocol" (e.g. `DataClientProtocol`, `HealthClientProtocol`, `ContentClientProtocol`)
- Model record types for CloudKit have "Record" suffix (e.g. `UserSettingsRecord`, `EnrolledProgramRecord`)
- Error enums have "Error" suffix (e.g. `AuthError`, `DataError`, `HealthError`)

**Excluded identifier names:**
- Single-letter: `id`, `db`, `ui`, `vm`, `x`, `y`, `z`, `i`, `j`, `k` (minimum 2 chars, with exceptions)
- Minimum type name length: 3 characters

## Code Style

**Formatting:**
- SwiftLint configured with `.swiftlint.yml` — 45 opt-in rules enabled
- Key disabled rules: `trailing_whitespace`, `line_length`, `function_body_length`, `type_body_length`, `file_length`, `nesting`
- Swift 6 strict concurrency: `SWIFT_STRICT_CONCURRENCY: complete`

**Linting:**
- SwiftLint enforces: `force_unwrapping`, `implicitly_unwrapped_optional`, `missing_docs`, `weak_delegate`, `yoda_condition`
- Enabled traits: `sorted_imports`, `toggle_bool`, `trailing_closure`, `type_contents_order`
- Run: `swiftlint --config .swiftlint.yml`

**Concurrency:**
- Swift 6 strict concurrency enforced throughout
- `@unchecked Sendable` for non-Sendable types (documented when used, e.g. CloudKitClient)
- Retroactive Sendable conformances for Foundation types with `@retroactive @unchecked Sendable` (e.g. `NSPredicate`, `NSSortDescriptor`)
- `async`/`await` required for all I/O operations
- `@MainActor` for view models and SwiftUI operations
- `actor` for thread-safe clients (e.g. `CloudKitClient`, `HealthKitClient`, `LocalDataClient`)

## Import Organization

**Order:**
1. Foundation imports (`import Foundation`, `import CloudKit`, `import os.log`)
2. Conditional imports (`#if canImport(UIKit)`, `#if os(...)`)
3. Custom module imports (`import SundeeFundeeKit`)
4. Preconcurrency imports for known non-Sendable types (`@preconcurrency import Foundation`)

**Path Aliases:**
- No path aliases configured — uses full module paths

**Organization:**
- Single import per line
- Sorted alphabetically within sections (SwiftLint rule `sorted_imports` enabled)
- Example:
  ```swift
  import CloudKit
  import Foundation
  import os.log
  
  @preconcurrency import Foundation
  ```

## Error Handling

**Patterns:**
- Discriminated error enums for each domain (e.g. `AuthError`, `DataError`, `HealthError`, `SyncQueueError`)
- All errors conform to `Error`, `LocalizedError`, `Sendable`, and `Equatable`
- Each error case includes:
  - `errorDescription: String?` — User-facing error message
  - `recoverySuggestion: String?` — Next steps for user
  - Equatable conformance with manual `==` implementation for cases with associated values
- Example from `AuthError`:
  ```swift
  public enum AuthError: Error, LocalizedError, Sendable, Equatable {
      case cancelled
      case authorizationFailed(underlying: Error?)
      case noPresentationContext
      case credentialStateCheckFailed(underlying: Error?)
      case invalidIdentityToken
      case missingUserInfo(field: String)
      case notAvailable
  }
  ```

**Resilience:**
- Data layer clients (`CloudKitClient`, `LocalDataClient`) skip individual records that fail to decode
- Failures logged as warnings, entire query does not fail on one corrupt record
- Boolean field decoding: custom `init(from:)` tries `Bool` first, falls back to `Int` (CloudKit stores as Int64)
- Backwards-compatible decoding: when renaming fields, try new key first, fall back to legacy key with `try?`

## Logging

**Framework:** `os.log` with `Logger` (imported from `os.log`)

**Patterns:**
- Per-file logger: `private let authLogger = Logger(subsystem: "com.sundeefundee.app", category: "AppleAuth")`
- Log subsystem: `"com.sundeefundee.app"`
- Categories match domain/module: `"CloudKit"`, `"Dashboard"`, `"ScreenshotSeeder"`, `"AppleAuth"`
- Levels used: `.info`, `.error`
- Emoji prefixes for visual scanning:
  - ✅ for success: `ckLogger.info("✅ FETCH \(recordType): \(results.count) records")`
  - ❌ for error: `ckLogger.error("❌ FETCH \(recordType): \(error.localizedDescription)")`
  - 📊 for dashboard: `dashLogger.info("📊 Challenge: fetched \(workouts.count) workouts")`
- Only log in UI/presentation layer and data layer (not domain layer)
- Domain layer functions are pure and log nothing

## Comments

**When to Comment:**
- `// MARK: -` sections to organize logical groups within types (required by SwiftLint rule `type_contents_order`)
- Section structure for files:
  ```swift
  // MARK: - TypeName
  
  // Description of the type
  public enum TypeName { ... }
  
  // MARK: - Methods
  
  func method() { ... }
  ```
- Example section markers: `// MARK: - Published Properties`, `// MARK: - Initialization`, `// MARK: - Public Methods`, `// MARK: - Private: Timers`

**Documentation Comments:**
- Top-of-file comments explain purpose and design decisions (e.g. `AppTheme.swift` explains Art Deco design system and WCAG contrast ratios)
- Type-level `///` comments before public types
- Method-level `///` comments for public methods with parameters, returns, and throws
- Example:
  ```swift
  /// Fetches records of the specified type matching the given predicate.
  ///
  /// - Parameters:
  ///   - recordType: The CloudKit record type identifier.
  ///   - predicate: The predicate to filter records.
  /// - Returns: An array of decoded model objects.
  /// - Throws: `DataError` if the fetch operation fails.
  public func fetch<T>(...) async throws -> [T] { ... }
  ```

**Architecture Comments:**
- Complex algorithms include inline explanations: e.g. cycle phase boundaries with day calculations
- CloudKit-specific comments for non-obvious patterns (e.g. date encoding, nested array serialization)
- Example: `// CloudKit stores Bool as Int64 (0/1); custom decode tries Bool first, falls back to Int`

## Function Design

**Size:** 
- No strict line limit enforced (`line_length` disabled)
- Functions broken down by feature/responsibility
- Large functions documented with section markers (`// MARK:`)

**Parameters:**
- Explicit parameters; no default parameters in public APIs unless documented
- Example: `init(id: String = UUID().uuidString, ...)` only when UUID default is intentional

**Return Values:**
- Optionals used for "no result" cases (not empty arrays)
- Result types preferred over throwing (not enforced, context-dependent)
- Computed properties return synchronously; async operations return Task or use `async`/`await`

## Module Design

**Exports:**
- Public types explicitly marked with `public` keyword
- Private/internal structure hidden from module consumers
- Example: `public struct CycleSettings: Codable, Sendable` vs. internal helpers

**Barrel Files:**
- Not used — each file is standalone
- Imports explicit: `import SundeeFundeeKit` imports only public types
- Domain layer files are pure (no framework imports except Foundation)

## Data Models

**Codable & Sendable:**
- All data models conform to `Codable` and `Sendable`
- Example: `public struct CycleSettings: Codable, Sendable`
- Required for CloudKit serialization and strict concurrency

**Identifiable:**
- Models with unique identity conform to `Identifiable`
- Example: `public struct ExerciseSet: Equatable, Codable, Identifiable, Sendable`

**CloudKit-Specific:**
- Field naming: avoid `createdAt`, `modifiedAt`, `startDate`, `endDate` (collide with CloudKit system fields)
- Use alternatives: `dateCreated`, `challengeStartDate`
- Date encoding: `JSONEncoder` with `.iso8601` produces strings; CloudKit stores as STRING
- Boolean fields: custom `init(from:)` handles both Bool and Int64 decoding

---

*Convention analysis: 2026-04-15*

# Coding Conventions

**Analysis Date:** 2026-03-21

## Naming Patterns

**Files:**
- Standard Swift naming: `FileName.swift` using PascalCase
- View files: `SettingsView.swift`, `AIWorkoutView.swift`
- ViewModel files: `SettingsViewModel.swift`, `WODExecutionViewModel.swift`
- Repository files: `SwiftDataUserRepository.swift`, `FirebaseAIWorkoutService.swift`
- Protocol files: `RepositoryProtocols.swift`
- Test files: `BarbellDefaultsTests.swift`, `SubscriptionServiceTests.swift`

**Functions:**
- Use camelCase: `calculateCycleStatus()`, `fetchWorkouts()`, `saveProfile()`
- Prefix getter/computed properties with appropriate descriptors: `displayName`, `isPremium`, `currentTier`
- Use descriptive verb-noun patterns: `resolveAfterAppleSignIn()`, `migrateGuestRecords()`, `updateProgress()`

**Variables:**
- Use camelCase for instance and local variables: `displayName`, `modelContext`, `currentUser`
- Raw value storage for enums uses `Raw` suffix: `experienceLevelRaw`, `primaryGoalRaw`, `genderRaw`, `subscriptionTierRaw`, `scoringTypeRaw`
- Private variables use underscore prefix only when needed for clarity or convention

**Types:**
- Enums use camelCase: `ExperienceLevel`, `PrimaryGoal`, `Gender`, `CyclePhase`
- Raw values for enums stored as strings: `.preferNotToSay`, `.weight_loss`, `.preferNotToSay`
- Result/DTO types: `CycleStatusResult`, `AppleSignInCredential`, `WorkoutGenerationContext`
- Error types: `AuthError`, `GeminiServiceError`, `AIWorkoutServiceError`, `RepositoryError`

## Code Style

**Formatting:**
- No explicit formatter detected (likely Xcode default formatting)
- Standard Swift formatting conventions followed
- Line breaks for readability, with MARK sections organizing logical groups
- Indentation: 4 spaces (Swift standard)

**Linting:**
- No explicit linter configuration detected
- Code follows Swift compiler standards and warnings

## Import Organization

**Order:**
1. SwiftUI/Foundation imports: `import SwiftUI`, `import Foundation`
2. Framework imports: `import SwiftData`, `import AuthenticationServices`, `import CloudKit`
3. Package/third-party imports: None detected in main codebase
4. Test imports: `import Testing` (for test suites)
5. Testable imports: `@testable import SundeeFundee` (in test files)

**Path Aliases:**
- No custom path aliases detected
- Direct target imports used: `import SundeeFundee`

## Error Handling

**Patterns:**
- Use domain-specific error enums: `enum GeminiServiceError: Error, Equatable`
- Error enums conform to `Error` and often `LocalizedError` for user-facing messages
- Error types include associated values for context: `case httpError(statusCode: Int)`, `case signInFailed(underlyingError: Error)`
- Try-catch blocks used sparingly; prefer `try?` for non-critical operations (see `AppState.swift`: `try? modelContext.save()`)
- Async functions use `throws` keyword to propagate errors
- Recovery handled with Result type: `Result<AppleSignInCredential, Error>`
- Print statements for logging failures when needed: `print("[AuthService] Guest migration failed, will retry: \(error)")`

## Logging

**Framework:** Console and print statements (no centralized logging framework)

**Patterns:**
- Prefix log messages with component name: `[AuthService]`, `[GeminiService]`
- Use print for errors and important state changes
- No structured logging observed; simple string interpolation used
- Async operations checked for cancellation: `try Task.checkCancellation()`

## Comments

**When to Comment:**
- Use `///` doc comments for public functions and types
- MARK sections for large files organizing related code: `// MARK: - Public`, `// MARK: - Private`, `// MARK: - Delegate`
- Inline comments for non-obvious logic (e.g., `// Migration succeeded — clear pending flag`)
- FIX comments with issue numbers: `// (FIX-02)`, `// (FIX-03)` reference specific issues being addressed

**JSDoc/TSDoc:**
- Not used in this Swift codebase
- Documentation uses standard Swift doc comments with `///`:
  ```swift
  /// Handles Sign in with Apple and session restoration.
  ///
  /// This service is injected into the environment via AppState and called
  /// from SignInView. On success it writes the user ID to the keychain and
  /// updates AppState accordingly.
  ```

## Function Design

**Size:** No explicit length limit observed; functions are generally focused:
- Service functions: 10-30 lines average
- Complex calculations in domain layer: 40-80 lines
- Tests: typically 2-10 lines (one assertion focus per test)

**Parameters:**
- Named parameters used consistently
- Default values for optional parameters: `referenceDate: Date = .now`
- Dependency injection via initializer: `init(dependencies: Dependencies = .live)`

**Return Values:**
- Use optional returns for potentially-missing data: `-> User?`
- Use Result type for operations with errors: `Result<AppleSignInCredential, Error>`
- Void for side-effect operations
- Dedicated result structs for complex data: `CycleStatusResult` containing multiple related values

## Module Design

**Exports:**
- No public/private modifiers observed; implicitly internal within app module
- Test files marked with `@testable import SundeeFundee` for access
- Protocols defined in `Repositories/Protocols/` for interface contracts

**Barrel Files:**
- Not used; each file contains one primary type
- Test suites use `@Suite` and `@Test` attributes for organization within files

## Actor Isolation

**@MainActor Pattern:**
- Services and ViewModels marked `@MainActor` when managing UI state
- 41 uses of `@MainActor` throughout codebase for thread safety
- Example: `@MainActor final class AuthService: NSObject, ObservableObject`
- Observable state holders use `@Observable @MainActor` pattern

**Sendable Protocol:**
- Used for thread-safe types: `final class GeminiWorkoutService: Sendable`

## Dependency Injection

**Pattern:** Constructor-based dependency injection with nested `Dependencies` struct:
```swift
struct Dependencies {
    let saveAppleUserID: (String) -> Void
    let loadAppleUserID: () -> String?
    // ... other dependencies
    static let live = Dependencies(/* production implementations */)
}

init(dependencies: Dependencies = .live) {
    self.dependencies = dependencies
}
```

---

*Convention analysis: 2026-03-21*

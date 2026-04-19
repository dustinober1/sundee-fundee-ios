# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a native iOS app for cycle-aware strength training. Built with SwiftUI and Swift 6 (strict concurrency), using CloudKit for persistence, StoreKit 2 for subscriptions, and HealthKit for health data. The app uses an Art Deco design theme (cream/navy/orange).

**Archive:** The retired web app code is preserved in `sundee-fundee-archive-2026-04-08.zip` at the repository root. See `MIGRATION.md` for details.

## Commands

### Build
```bash
cd SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Test
```bash
cd SundeeFundee
swift test
```

### Run a Single Test
```bash
cd SundeeFundee
swift test --filter 'SundeeFundeeKitTests.CyclePhaseHelperTests'
swift test --filter 'SundeeFundeeKitTests.CyclePhaseHelperTests/testPhaseCalculation'
```

### Lint
```bash
swiftlint --config .swiftlint.yml
```

### Release (Fastlane)
```bash
cd SundeeFundeeApp
bundle exec fastlane release    # increment build, archive, upload to ASC
bundle exec fastlane list       # see all available lanes
```

### Generate Xcode Project (if needed)
```bash
cd SundeeFundeeApp
xcodegen generate
```

## Architecture

```
SundeeFundeeApp/ (Xcode project — app entry point)
    ↓ imports
SundeeFundee/ (Swift Package — SundeeFundeeKit)
    ├── DomainLayer/     Pure business logic (zero dependencies)
    ├── DataLayer/       Protocol-based persistence (CloudKit, Local, Mock)
    ├── UI/              SwiftUI views, view models, theme
    ├── Auth/            Apple Sign-In + Keychain session
    ├── Subscription/    StoreKit 2 subscription management
    ├── Models/          Shared data models (Codable)
    ├── Calculations/    Weight calculations, cycle math
    ├── Activity/        Activity ring integration
    └── Screenshot/      Screenshot seeding utilities
```

### Key Directories

- **`SundeeFundee/`** — Swift Package (`SundeeFundeeKit`)
  - **`Sources/SundeeFundeeKit/DomainLayer/`** — Pure business logic: cycle calculations, injury models, benchmark catalog, AI workout types, program templates, coach logic, intelligence features. Zero framework dependencies.
  - **`Sources/SundeeFundeeKit/DataLayer/`** — Abstract persistence via `DataClientProtocol`. Implementations: `CloudKitClient` (signed-in users), `LocalDataClient` (guest mode), `MockCloudKitClient`/`MockHealthKitClient` (testing). Factory: `DataClientFactory.shared.client`.
  - **`Sources/SundeeFundeeKit/UI/`** — SwiftUI views and view models organized by feature: App entry, Auth, Benchmark, Cycle, Dashboard, Maxes, Programs, Settings, Workout.
  - **`Sources/SundeeFundeeKit/Auth/`** — Apple Sign-In authentication, Keychain session storage.
  - **`Sources/SundeeFundeeKit/Subscription/`** — StoreKit 2 subscription tiers and management.
- **`SundeeFundeeApp/`** — Xcode project
  - **`SundeeFundee/App.swift`** — App entry point, `@StateObject` instances for `AuthViewModel` and `ThemeViewModel`.

### Auth

- Apple Sign-In only (no Firebase); session stored in Keychain; user data saved to CloudKit
- Guest mode: `authViewModel.continueAsGuest()` sets `isGuest = true`, `userID = "guest_local"`, skips CloudKit
- Gate CloudKit writes with `!authViewModel.isGuest`
- **Name only on first sign-in** — `fullName` is nil on subsequent sign-ins (including after account deletion). Persist `givenName` to CloudKit as the source of truth for session restore. Use `givenName` (first name) for display, not `displayName` (full formatted name).

### Data Layer

- **`DataClientProtocol`** — Async protocol for fetch/save/delete with generic `Codable & Sendable` types
- **`DataClientFactory.shared.client`** — Thread-safe singleton for client switching
- **`CloudKitClient`** — Actor-based CloudKit implementation for signed-in users
- **`LocalDataClient`** — Local storage for guest users
- **`SyncQueue`** — Queues mutations offline, replays when connectivity returns

#### CloudKit Schema Rules
- **Date encoding** — `JSONEncoder` with `.iso8601` produces strings. CloudKit stores dates as STRING (not TIMESTAMP) when auto-created. Do NOT name model fields `createdAt`, `modifiedAt`, `startDate`, or `endDate` — these collide with CloudKit system TIMESTAMP fields. Use alternative names (e.g. `dateCreated`, `challengeStartDate`).
- **New record types** need a `recordName` QUERYABLE index added in CloudKit Dashboard (Development → Indexes), then deployed to Production. Without this, `fetchAll` throws `DataError.schemaNotDeployed`.
- **Bool fields** — CloudKit stores `Bool` as `Int64` (0/1). Models with Bool fields need a custom `init(from:)` that tries `Bool` first, falls back to `Int`. See `EnrolledProgramRecord` and `UserSettingsRecord` for examples.
- **Nested arrays/structs** — CloudKit does not support `[Any]` arrays. The `CloudKitClient.convertToCKRecordValue` serializes arrays of dicts as typed `[String]` arrays (each element JSON-encoded) or falls back to a single JSON string. When adding new models with nested struct arrays, verify the data round-trips by checking CloudKit Dashboard > Records.
- **Backwards-compatible decoding** — When renaming fields, add a custom `init(from:)` that tries the new key first, falls back to the legacy key. See `Challenge` model for an example with `dateCreated`/`createdAt` fallback. Always use `try?` with a default for fields that may be missing from old records.
- **Decode resilience** — Both `CloudKitClient` and `LocalDataClient` skip individual records that fail to decode (logged as warnings) rather than failing the entire query. This prevents one corrupt record from breaking all data loading.

### Subscriptions

**The app is free with no in-app purchases or subscriptions.** All features are available to all users. Do not introduce paywalls, purchase flows, or subscription gating.

### App Store Submission

- **NEVER submit the app for App Store review unless explicitly told to by the user.** This includes building, uploading, or submitting. Always stop and ask first.

### Domain Layer

Pure Swift business logic mirroring the original web app's domain layer:
- `AIWorkout/` — AI workout types and generation helpers
- `Benchmark/` — Catalog, models, readiness
- `Challenge/` — Challenge models, tracking, lifetime deduplication
- `Cycle/` — Cycle calculations, adaptation policy, calendar, settings
- `Exercise/` — Exercise definitions, categories, muscle groups
- `Injury/` — Body location, adaptation engine, injury models, support
- `Program/` — Program template generator
- `Coach/` — Coach context, memory models, deterministic and on-device coach services
- `Intelligence/` — Plateau detector, schedule reshuffler, substitution ranker, weekly load analyzer
- `Analytics/` — Chart data aggregation
- `Export/` — Data export service
- `Celebration/` — Celebration events

## Coding Conventions

- **Swift 6 strict concurrency** — `SWIFT_STRICT_CONCURRENCY: complete`
- **Const structs for enums** — use Swift enums, not stringly-typed dictionaries
- **Discriminated enums** for flexible types (e.g., `ExerciseValue` with cases: `fixed`, `amrap`, `range`, `text`)
- **Multiplier-based adaptation** — cycle phase, recovery phase, and energy level compose multiplicatively on base weights
- **Domain functions are pure** — no side effects, no framework imports. Accept data, return data.
- **Actor-based data clients** — `CloudKitClient` is an actor for thread safety
- **SourceKit false positives** — "Cannot find type in scope" for cross-module types (KeychainHelper, DataClientFactory, etc.) are SourceKit noise; trust `xcodebuild` results only.
- **Benchmark `roundsAndReps` scoring** encodes as `rounds * 10000 + reps`. Higher is better. Decode: `rounds = value / 10000`, `reps = value % 10000`.
- **Art Deco theme tokens** via `AppTheme.*` — cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`
- **Fonts**: Playfair Display (headings), Inter (body), JetBrains Mono (numbers)

### Testing

- **Framework:** XCTest and Swift Testing (`import Testing`, `@Test` functions)
- **Location:** `SundeeFundee/Tests/SundeeFundeeKitTests/` — subdirs: `DomainTests/`, `DataLayerTests/`, `AuthTests/`, `SubscriptionTests/`, `ActivityTests/`, `ViewModelTests/`, `ModelTests/`
- **Pattern:** Pure function unit tests with factory helpers (`makeDate()`, `makeWorkout()`, `makeExercise()`)
- **Access:** `@testable import SundeeFundeeKit`

### Bundled Content & Program Templates

- **`ContentClientProtocol`** — Protocol for fetching exercises, programs, benchmarks. Implementations: `BundledContentProvider` (hardcoded fallback), `MockContentClient` (testing).
- **`ProgramTemplate` enum** — Cases: `firstMargarita`, `strength`, `hypertrophy`, `fullBody`, `linear`, `dup`, `block`. Each has `TemplateDefaults` (duration, sessions/week).
- **Adding a new program:** Define program data → add case to `ProgramTemplate` → wire into `ProgramTemplateGenerator` → add display name in `BundledContentProvider` → add to UI list in Programs view.

### Build Configuration

- **`SundeeFundeeApp/project.yml`** — XcodeGen config: iOS 18+, Swift 6, app target + `SundeeFundeeWidgetsExtension` + test target
- **`SundeeFundee/Package.swift`** — Swift Package 6.0, single `SundeeFundeeKit` library, zero external dependencies
- **`.swiftlint.yml`** — 45 opt-in rules, Swift 6 strict concurrency compatible

## App Store Requirements

- **Privacy Manifest** (`PrivacyInfo.xcprivacy`) — declares API usage and collected data types
- **UIRequiredDeviceCapabilities** must be `arm64`, not `armv7`
- **Code signing:** `CODE_SIGN_STYLE = Automatic` — don't hardcode
- **App icon:** Single 1024x1024 universal icon
- **Screenshot dimensions:** iPhone 6.5" = 1284x2778, iPad 12.9" = 2048x2732
- **Free apps** must include Privacy Policy link in description

## iOS UI Automation (mobile-mcp)

### Simulator
- Build + install: `xcodebuild ... -destination 'platform=iOS Simulator,id=<UDID>' build` then `xcrun simctl install <UDID> <path-to>.app`
- SwiftUI `Toggle` (AXSwitch) doesn't respond to `tap` by label — use coordinates
- Tab bar items may not expose individual children — use coordinate taps
- Guest mode requires completing onboarding before reaching main screens
- HealthKit permission dialog uses system (not app) coordinate space — screenshot visual coords differ from `list_elements` coords; tap visually or dismiss via background tap
- iPad `.sheet`/form-sheet **coordinates shift when the keyboard shows/hides** — always re-`list_elements` after keyboard visibility changes, never reuse stale coords
- Disabled buttons (e.g. from `.disabled(!viewModel.canCreate)`) still appear in the accessibility tree and accept taps silently — reduce `.opacity` to make disabled state visible, and check for disable modifiers before debugging "unresponsive" buttons
- Keyboard dismiss: tap the "Hide keyboard" button in the bottom-right of the iPad keyboard (around real coords `(957, 1324)` on iPad Pro 13")

### Physical device
- Requires `go-ios` (`npm i -g go-ios`) + `sudo ios tunnel start` running in the background for iOS 17+
- Requires WebDriverAgent signed + installed on the device (clone `appium/WebDriverAgent`, sign in Xcode with team `87VVCMCW3F`, Product → Test once to deploy the runner, trust the dev cert in iPad Settings)
- Without WDA the mobile-mcp tools see the device but `list_elements_on_screen` / `click_on_screen_at_coordinates` fail with "Port forwarding to WebDriverAgent is not running"

## Research

Use the Gemini MCP (`mcp__gemini-cli__ask-gemini`) for all internet research — API lookups, documentation questions, troubleshooting errors, Apple guidelines, etc. Prefer Gemini over web search tools.

## Git Workflow

- **Auto-commit as you go** — commit each file immediately after editing it; don't wait until the entire task is done
- **Commit each file separately** — stage and commit one file at a time
- **Commit message format:** `type(scope): description`
- **Main branch:** `main`

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Sundee Fundee v2**

Sundee Fundee is a cycle-aware strength training iOS app built with SwiftUI, CloudKit, and HealthKit. v2 adds three major features: a daily Recovery Score that aggregates biometric and training data, intelligent deload detection with active recovery programming, and a social layer for sharing workouts with friends — all built on the existing Apple ecosystem.

**Core Value:** Users always know whether today is a push day or a rest day — the recovery score is the single source of truth for training readiness.

### Constraints

- **Platform**: iOS 18+, SwiftUI only, Swift 6 strict concurrency
- **Backend**: CloudKit only — no external services or servers
- **Dependencies**: Zero external package dependencies (keep it that way)
- **Design**: Art Deco theme tokens via `AppTheme.*`
- **Privacy**: HealthKit sleep/HRV requires user authorization; handle denial gracefully
- **Social**: CloudKit sharing has limits on zone sharing — research capacity during planning
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Swift 6 (strict concurrency mode: `SWIFT_STRICT_CONCURRENCY: complete`) - All app logic, domain layer, data layer, UI
- Objective-C - Minimal system-level integration where Swift bridges aren't sufficient
- Ruby - Fastlane build automation (via Gemfile)
## Runtime
- iOS 18.0 minimum deployment target
- macOS 15.0 (watchOS 11.0 support via Swift Package)
- Xcode 16.0+
- Swift Package Manager (SPM) 6.0
- Lockfile: `SundeeFundee/Package.resolved` (tracks Swift package versions)
- Ruby Bundler (Fastlane dependencies via `Gemfile.lock`)
## Frameworks
- SwiftUI 6 - Native UI framework, views and layout
- Swift Testing + XCTest - Testing framework (see `TESTING.md` for patterns)
- CloudKit - Persistent data storage for signed-in users (private database scope)
- HealthKit - Health data integration (read/write workouts and cycle data)
- AuthenticationServices - Apple Sign-In authentication
- ActivityKit - Live workout activity ring integration
- StoreKit 2 - Subscription management (free tier; no purchases currently)
- XcodeGen - Project generation from YAML config (`SundeeFundeeApp/project.yml`)
- SwiftLint 0.45+ - Code linting with 45 opt-in rules (config: `.swiftlint.yml`)
- Fastlane - Build automation and App Store submission (config: `SundeeFundeeApp/fastlane/`)
- Charts framework (Apple's SwiftUI charting) - Volume, strength progression, cycle correlation visualizations
- Foundation - Core utilities, JSON encoding/decoding
- Combine - Reactive programming (older views; being phased toward async/await)
- Security - Keychain access for session tokens
- Network - Network connectivity monitoring in `DataLayer/SyncQueue/NetworkMonitor.swift`
- os.log - Structured logging throughout codebase
- UniformTypeIdentifiers - File type declarations
- UIKit - Limited use; minimal iOS-specific integration
## Key Dependencies
- CloudKit (Apple framework) - User data persistence, requires iCloud container `iCloud.com.sundeefundee.app`
- HealthKit (Apple framework) - Cycle and workout data, requires `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` entitlements
- AuthenticationServices (Apple framework) - Sign in with Apple, requires `com.apple.developer.applesignin` entitlement
- ActivityKit (Apple framework) - Live activity support for active workout tracking
- Network (Apple framework) - Real-time connectivity detection via `NWPathMonitor`
- `SundeeFundee/Package.swift` has `dependencies: []` - zero external package dependencies
- All persistent storage via CloudKit or local SQLite-like (LocalDataClient mock)
- All authentication via Apple native APIs (no Firebase, Auth0, or third-party auth)
- All networking via CloudKit and HealthKit APIs (no HTTP clients, API SDKs, or backends)
## Configuration
- `.env.local` file (not read by build system; for development reference only)
- CloudKit container identifier: `iCloud.com.sundeefundee.app` (configured in entitlements)
- App Group identifier: `group.com.sundeefundee.shared` (for widget extension data sharing)
- `SundeeFundeeApp/project.yml` - XcodeGen configuration with deployment targets, signing, entitlements
- `Info.plist` (via `GENERATE_INFOPLIST_FILE: false`) - Manually maintained, includes privacy descriptions
- `SundeeFundee.entitlements` - Declares CloudKit container, HealthKit, Apple Sign-In, app group
- `.swiftlint.yml` - 45 opt-in rules, disables line_length/file_length/nesting for domain logic
- Marketing version: `CFBundleShortVersionString` (set via `$(MARKETING_VERSION)` in build settings)
- Build number: `CFBundleVersion` (set via `$(CURRENT_PROJECT_VERSION)`)
- Managed via `agvtool` commands or Fastlane `release` lane
## Platform Requirements
- Xcode 16.0+ (Swift 6 support required)
- iOS Simulator or physical iOS device (iPhone/iPad)
- macOS 13+ to run Xcode and build tools
- Ruby 3.0+ for Fastlane (via Bundler)
- Deployment: Apple App Store (via Fastlane + App Store Connect)
- Signing: Automatic code signing via Xcode team ID `87VVCMCW3F`
- Apple Developer account with team access (App Store Connect team `128606738`)
## Subscription & Monetization
- Free tier - Limited features, 5 tracked lifts, 1 injury profile
- Plus tier ($2.99/mo) - Unlimited tracking, advanced charts, AI workout builder
- Pro tier ($4.99/mo) - Coach memory, adaptive programming, plateau detection
- Currently all tiers are free (no paywalls or purchase flows enabled)
- Ready for in-app purchase integration when needed
- See `SundeeFundee/Sources/SundeeFundeeKit/Subscription/` for models
## Data Storage Architecture
- Container: `iCloud.com.sundeefundee.app`
- Database scope: Private
- Record types defined in `SundeeFundeeApp/cloudkit-schema.json`
- Records: BenchmarkDefinition, BenchmarkResult, Celebration, Challenge, CyclePhaseInfo, EnrolledProgram, Exercise, Injury, OneRepMaxRecord, Program, UserSettings, Workout
- Encoding: ISO8601 dates (CloudKit stores as STRING, not TIMESTAMP)
- `LocalDataClient` for guest users with no iCloud
- `SyncQueue` queues mutations offline, replays when connectivity returns
- Keychain via `KeychainHelper` - Apple Sign-In tokens and user IDs
## Privacy & Security
- Declares: Health data (read), Fitness data (read), User ID, Name, Email (all for app functionality, no tracking)
- UserDefaults API access for state persistence
- `com.apple.developer.applesignin` - Sign in with Apple
- `com.apple.developer.healthkit` - Health data access (empty required capabilities)
- `com.apple.developer.icloud-services` - CloudKit access
- `com.apple.developer.icloud-container-identifiers` - Private CloudKit container
- `CODE_SIGN_STYLE = Automatic` - Xcode-managed signing (no manual provisioning)
## Build & Release Pipeline
- `Appfile` - Bundle ID `com.sundeefundee.app`, Apple ID `dustinober@me.com`, team IDs
- `Fastfile` - Release lane definition
- `Deliverfile` - App Store Connect metadata sync
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- PascalCase for source files (e.g. `AppTheme.swift`, `CloudKitClient.swift`, `CyclePhaseHelper.swift`)
- Test files use same name as source with `Tests` suffix (e.g. `CyclePhaseHelperTests.swift`)
- Grouped by feature/domain in subdirectories (e.g. `DomainLayer/Cycle/`, `UI/ViewModels/`, `DataLayer/Actors/`)
- camelCase for all functions (e.g. `signInWithApple()`, `calculateConfidence()`, `fetchUserNameFromCloudKit()`)
- Public functions documented with markdown comments
- Prefixes: `is` for booleans (e.g. `isAuthenticated`, `isComplete`, `isGuest`)
- Prefixes: `get`/`calculate` for computed values (e.g. `getRegressions()`, `calculateCycleStatus()`)
- camelCase for variables and properties
- `@Published` for SwiftUI observable properties (view models)
- `@MainActor` annotation for view models
- Private properties with `private let` or `private var`
- Public properties explicitly marked `public`
- Trailing closure properties: `private var restTimerCancellable: AnyCancellable?`
- PascalCase for all types: enums, structs, classes, protocols
- Swift enums preferred over stringly-typed dictionaries (e.g. `ExerciseType` enum instead of string constants)
- Discriminated enums for flexible types: `enum ExerciseType { case fixed, amrap, range(min: Int, max: Int), text(String) }`
- Protocol names end with "Protocol" (e.g. `DataClientProtocol`, `HealthClientProtocol`, `ContentClientProtocol`)
- Model record types for CloudKit have "Record" suffix (e.g. `UserSettingsRecord`, `EnrolledProgramRecord`)
- Error enums have "Error" suffix (e.g. `AuthError`, `DataError`, `HealthError`)
- Single-letter: `id`, `db`, `ui`, `vm`, `x`, `y`, `z`, `i`, `j`, `k` (minimum 2 chars, with exceptions)
- Minimum type name length: 3 characters
## Code Style
- SwiftLint configured with `.swiftlint.yml` — 45 opt-in rules enabled
- Key disabled rules: `trailing_whitespace`, `line_length`, `function_body_length`, `type_body_length`, `file_length`, `nesting`
- Swift 6 strict concurrency: `SWIFT_STRICT_CONCURRENCY: complete`
- SwiftLint enforces: `force_unwrapping`, `implicitly_unwrapped_optional`, `missing_docs`, `weak_delegate`, `yoda_condition`
- Enabled traits: `sorted_imports`, `toggle_bool`, `trailing_closure`, `type_contents_order`
- Run: `swiftlint --config .swiftlint.yml`
- Swift 6 strict concurrency enforced throughout
- `@unchecked Sendable` for non-Sendable types (documented when used, e.g. CloudKitClient)
- Retroactive Sendable conformances for Foundation types with `@retroactive @unchecked Sendable` (e.g. `NSPredicate`, `NSSortDescriptor`)
- `async`/`await` required for all I/O operations
- `@MainActor` for view models and SwiftUI operations
- `actor` for thread-safe clients (e.g. `CloudKitClient`, `HealthKitClient`, `LocalDataClient`)
## Import Organization
- No path aliases configured — uses full module paths
- Single import per line
- Sorted alphabetically within sections (SwiftLint rule `sorted_imports` enabled)
- Example:
## Error Handling
- Discriminated error enums for each domain (e.g. `AuthError`, `DataError`, `HealthError`, `SyncQueueError`)
- All errors conform to `Error`, `LocalizedError`, `Sendable`, and `Equatable`
- Each error case includes:
- Example from `AuthError`:
- Data layer clients (`CloudKitClient`, `LocalDataClient`) skip individual records that fail to decode
- Failures logged as warnings, entire query does not fail on one corrupt record
- Boolean field decoding: custom `init(from:)` tries `Bool` first, falls back to `Int` (CloudKit stores as Int64)
- Backwards-compatible decoding: when renaming fields, try new key first, fall back to legacy key with `try?`
## Logging
- Per-file logger: `private let authLogger = Logger(subsystem: "com.sundeefundee.app", category: "AppleAuth")`
- Log subsystem: `"com.sundeefundee.app"`
- Categories match domain/module: `"CloudKit"`, `"Dashboard"`, `"ScreenshotSeeder"`, `"AppleAuth"`
- Levels used: `.info`, `.error`
- Emoji prefixes for visual scanning:
- Only log in UI/presentation layer and data layer (not domain layer)
- Domain layer functions are pure and log nothing
## Comments
- `// MARK: -` sections to organize logical groups within types (required by SwiftLint rule `type_contents_order`)
- Section structure for files:
- Example section markers: `// MARK: - Published Properties`, `// MARK: - Initialization`, `// MARK: - Public Methods`, `// MARK: - Private: Timers`
- Top-of-file comments explain purpose and design decisions (e.g. `AppTheme.swift` explains Art Deco design system and WCAG contrast ratios)
- Type-level `///` comments before public types
- Method-level `///` comments for public methods with parameters, returns, and throws
- Example:
- Complex algorithms include inline explanations: e.g. cycle phase boundaries with day calculations
- CloudKit-specific comments for non-obvious patterns (e.g. date encoding, nested array serialization)
- Example: `// CloudKit stores Bool as Int64 (0/1); custom decode tries Bool first, falls back to Int`
## Function Design
- No strict line limit enforced (`line_length` disabled)
- Functions broken down by feature/responsibility
- Large functions documented with section markers (`// MARK:`)
- Explicit parameters; no default parameters in public APIs unless documented
- Example: `init(id: String = UUID().uuidString, ...)` only when UUID default is intentional
- Optionals used for "no result" cases (not empty arrays)
- Result types preferred over throwing (not enforced, context-dependent)
- Computed properties return synchronously; async operations return Task or use `async`/`await`
## Module Design
- Public types explicitly marked with `public` keyword
- Private/internal structure hidden from module consumers
- Example: `public struct CycleSettings: Codable, Sendable` vs. internal helpers
- Not used — each file is standalone
- Imports explicit: `import SundeeFundeeKit` imports only public types
- Domain layer files are pure (no framework imports except Foundation)
## Data Models
- All data models conform to `Codable` and `Sendable`
- Example: `public struct CycleSettings: Codable, Sendable`
- Required for CloudKit serialization and strict concurrency
- Models with unique identity conform to `Identifiable`
- Example: `public struct ExerciseSet: Equatable, Codable, Identifiable, Sendable`
- Field naming: avoid `createdAt`, `modifiedAt`, `startDate`, `endDate` (collide with CloudKit system fields)
- Use alternatives: `dateCreated`, `challengeStartDate`
- Date encoding: `JSONEncoder` with `.iso8601` produces strings; CloudKit stores as STRING
- Boolean fields: custom `init(from:)` handles both Bool and Int64 decoding
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Pure domain layer with zero framework dependencies
- Protocol-based data layer enabling client switching (CloudKit for signed-in, LocalDataClient for guests)
- Actor-based concurrency for thread-safe data clients
- Swift 6 strict concurrency throughout
- Environment-based dependency injection for ViewModels
- Tab-based navigation with feature-specific views
## Layers
- Purpose: Pure business logic mirroring the original web app's domain layer
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`
- Contains: Cycle calculations, benchmarks, challenges, exercises, injury models, program templates, coach logic, analytics, celebration events, AI workout generation, intelligence features (plateau detection, schedule reshuffling, substitution ranking, weekly load analysis), export logic
- Depends on: Nothing (zero framework imports)
- Used by: DataLayer, ViewModels, UI layer
- Purpose: Abstract persistence via protocols; implementations handle CloudKit (signed-in users), local storage (guests), mock implementations (testing)
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/`
- Contains:
- Depends on: DomainLayer types (for Codable models)
- Used by: ViewModels, AuthViewModel
- Purpose: Apple Sign-In authentication and Keychain session storage
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Auth/`
- Contains: `AppleAuthClient` (Sign in with Apple flow), `AppleAuthClientProtocol` (interface), `AuthError` (localized errors), `AppleAuthResult` (credential result), `KeychainHelper` (Keychain read/write)
- Depends on: Foundation, SwiftUI, AuthenticationServices
- Used by: `AuthViewModel`
- Purpose: StoreKit 2 subscription management
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Subscription/`
- Contains: Subscription models and StoreKit 2 integration
- Depends on: StoreKit
- Used by: ViewModels, Settings UI
- **Note:** App is free with all features unlocked; no paywalls or purchase flows
- Purpose: Live activity integration for workout sessions
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Activity/`
- Contains: `LiveWorkoutActivityManager`, `LiveWorkoutActivityAttributes`
- Depends on: ActivityKit, SwiftUI
- Used by: `ActiveWorkoutSessionViewModel`
- Purpose: SwiftUI views, view models, and design system
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/`
- Contains:
- Depends on: SwiftUI, DomainLayer, DataLayer, AuthLayer
- Used by: Xcode app target (`SundeeFundeeApp/SundeeFundee/App.swift`)
- Purpose: Shared Codable data models for persistence and cross-module communication
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Models/`
- Contains: `Challenge.swift`, `Exercise.swift`, `Workout.swift`
- Depends on: Foundation (Codable)
- Used by: DomainLayer, DataLayer, ViewModels
## Data Flow
## Key Abstractions
- Purpose: Generic async protocol for persistent data operations
- Examples: `CloudKitClient`, `LocalDataClient`, `MockCloudKitClient`
- Pattern: Generic `fetchAll<T: Codable & Sendable>()`, `fetch<T>(recordID:)`, `save<T>(record:)`, `delete(recordID:)`, `deleteAll<T>()`
- Returns: Async throws for error handling
- Purpose: Authenticate via Apple Sign-In
- Examples: `AppleAuthClient` (production), mock for testing
- Pattern: `signIn(scopes:) async throws -> AppleAuthResult`, `getCredentialState(forUserID:)`, `revokeToken()`
- Purpose: Fetch bundled content (exercises, benchmarks, programs)
- Examples: `BundledContentProvider` (hardcoded fallback)
- Pattern: Read-only access to reference data
- Purpose: Read HealthKit data (activity rings, step count, etc.)
- Examples: `HealthKitClient` (production), `MockHealthKitClient` (testing)
- Pattern: Async query methods
- Purpose: Observable cached cycle phase state
- Pattern: `@StateObject` in views; `@EnvironmentObject` passed down
- Exposes: `currentPhase`, `isSharkWeek`, `refresh()` method
- Purpose: Bind UI to data, manage state, coordinate data operations
- Examples: `AuthViewModel` (@MainActor singleton in App.swift), `DashboardViewModel` (@StateObject in views)
- Pattern: `@Published` properties for binding, async `loadData()` methods, error handling via `@Published errorMessage`
## Entry Points
- Location: `SundeeFundeeApp/SundeeFundee/App.swift`
- Triggers: App launch
- Responsibilities: 
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`
- Triggers: After successful authentication
- Responsibilities:
- Examples: `DashboardView`, `WorkoutsListView`, `ActiveWorkoutView`, `BenchmarksListView`, `SettingsView`
- Pattern: Create feature-specific `@StateObject viewModel`, environment inject `AuthViewModel` and shared state (e.g., `CyclePhaseCache`)
- Lifecycle: `.task { await viewModel.loadData() }` on appear, `.refreshable { }` for pull-to-refresh, `.onReceive()` for notifications
## Error Handling
- Cases: `cancelled`, `authorizationFailed`, `noPresentationContext`, `credentialStateCheckFailed`, `invalidIdentityToken`, `missingUserInfo`, `notAvailable`
- Displayed in: `AuthViewModel.errorMessage` (@Published) → Alert in UI
- Example: User cancels sign-in → `AuthError.cancelled` → "Sign in was cancelled" + "Try signing in again when ready"
- Cases: `recordNotFound`, `networkError`, `permissionDenied`, `invalidData`, `schemaNotDeployed`
- Handling: ViewModels catch and set `@Published errorMessage` or `isLoading`
- Example: Offline operation → `DataError.networkError` → SyncQueue enqueues mutation → replays on connectivity
- Both `CloudKitClient.fetchAll()` and `LocalDataClient.fetchAll()` skip individual records that fail to decode
- Logged as warnings; entire query does NOT fail
- Allows app to function even if one corrupted record exists
## Cross-Cutting Concerns
- Framework: `os.log` with `Logger` (subsystem: "com.sundeefundee.app", categories per feature)
- Examples: `DashboardView` (category: "Dashboard"), `App.swift` (category: "AppStartup")
- Level: `.info()` for state changes, `.error()` for failures, `.debug()` for tracing
- Domain functions validate inputs and return errors
- Views validate user input before passing to ViewModels
- Example: Workout weight must be > 0; UI prevents saving if invalid
- Gated by `authViewModel.isAuthenticated` check in App.swift
- CloudKit writes guarded: `if !authViewModel.isGuest`
- Session restored from Keychain on app launch
- Swift 6 strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY: complete`)
- Data clients are `actor`-based for thread safety
- ViewModels marked `@MainActor` for UI updates
- All async operations use `async/await`
- UI state: `@State` for local view state, `@StateObject` for per-view ViewModels
- App state: `@EnvironmentObject` for shared objects (`AuthViewModel`, `CyclePhaseCache`)
- Persistence: DataLayer (CloudKit or local) via `DataClientFactory.shared.client`
- Centralized in `AppTheme` enum with color, spacing, typography tokens
- Colors: Cream background, Navy/white text, Gold/orange accents (WCAG AA/AAA compliant)
- Applied via `.artDecoBackground()` modifier on root WindowGroup
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| asc-app-create-ui | Create an App Store Connect app via iris API using web session from Blitz | `.claude/skills/asc-app-create-ui/SKILL.md` |
| asc-aso-audit | Run an offline ASO audit on canonical App Store metadata under `./metadata` and surface keyword gaps using Astro MCP. Use after pulling metadata with `asc metadata pull`. | `.claude/skills/asc-aso-audit/SKILL.md` |
| asc-build-lifecycle | Track build processing, find latest builds, and clean up old builds with asc. Use when managing build retention or waiting on processing. | `.claude/skills/asc-build-lifecycle/SKILL.md` |
| asc-cli-usage | Guidance for using asc cli in this repo (flags, output formats, pagination, auth, and discovery). Use when asked to run or design asc commands or interact with App Store Connect via the CLI. | `.claude/skills/asc-cli-usage/SKILL.md` |
| asc-crash-triage | Triage TestFlight crashes, beta feedback, and performance diagnostics using asc. Use when the user asks about TF crashes, TestFlight crash reports, beta tester feedback, app hangs, disk writes, launch diagnostics, or wants a crash summary for a build or app. | `.claude/skills/asc-crash-triage/SKILL.md` |
| asc-iap-attach | Attach in-app purchases and subscriptions to an app version for App Store review. Use when the user has IAPs or subscriptions in "Ready to Submit" state that need to be included with a first-time version submission. Works for both first-time and subsequent submissions. | `.claude/skills/asc-iap-attach/SKILL.md` |
| asc-id-resolver | Resolve App Store Connect IDs (apps, builds, versions, groups, testers) from human-friendly names using asc. Use when commands require IDs. | `.claude/skills/asc-id-resolver/SKILL.md` |
| asc-localize-metadata | Automatically translate and sync App Store metadata (description, keywords, what's new, subtitle) to multiple languages using LLM translation and asc CLI. Use when asked to localize an app's App Store listing, translate app descriptions, or add new languages to App Store Connect. | `.claude/skills/asc-localize-metadata/SKILL.md` |
| asc-metadata-sync | Sync and validate App Store metadata and localizations with asc, including legacy metadata format migration. Use when updating metadata or translations. | `.claude/skills/asc-metadata-sync/SKILL.md` |
| asc-notarization | Archive, export, and notarize macOS apps using xcodebuild and asc. Use when you need to prepare a macOS app for distribution outside the App Store with Developer ID signing and Apple notarization. | `.claude/skills/asc-notarization/SKILL.md` |
| asc-ppp-pricing | Set territory-specific pricing for subscriptions and in-app purchases using current asc setup, pricing summary, price import, and price schedule commands. Use when adjusting prices by country or implementing localized PPP strategies. | `.claude/skills/asc-ppp-pricing/SKILL.md` |
| asc-privacy-nutrition-labels | Set up App Store privacy nutrition labels (data collection declarations) for an app. Use when the user needs to declare what data their app collects, how it's used, and whether it's linked to the user. Handles both "no data collected" and full data collection declarations. | `.claude/skills/asc-privacy-nutrition-labels/SKILL.md` |
| asc-release-flow | Determine whether an app is ready to submit, then drive the App Store release flow with asc, including first-time submission fixes for availability, in-app purchases, subscriptions, Game Center, and App Privacy. | `.claude/skills/asc-release-flow/SKILL.md` |
| asc-revenuecat-catalog-sync | Reconcile App Store Connect subscriptions and in-app purchases with RevenueCat products, entitlements, offerings, and packages using asc and RevenueCat MCP. Use when setting up or syncing subscription catalogs across ASC and RevenueCat. | `.claude/skills/asc-revenuecat-catalog-sync/SKILL.md` |
| asc-screenshot-resize | Resize and validate App Store screenshots for all device classes using macOS sips. Use when preparing or fixing screenshots for App Store Connect submission. | `.claude/skills/asc-screenshot-resize/SKILL.md` |
| asc-shots-pipeline | Orchestrate iOS screenshot automation with xcodebuild/simctl for build-run, AXe for UI actions, JSON settings and plan files, Koubou-based framing (`asc screenshots frame`), and screenshot upload (`asc screenshots upload`). Use when users ask for automated screenshot capture, AXe-driven simulator flows, frame composition, or screenshot-to-upload pipelines. | `.claude/skills/asc-shots-pipeline/SKILL.md` |
| asc-signing-setup | Set up bundle IDs, capabilities, signing certificates, provisioning profiles, and encrypted signing sync with the asc cli. Use when onboarding a new app, rotating signing assets, or sharing them across a team. | `.claude/skills/asc-signing-setup/SKILL.md` |
| asc-submission-health | Preflight App Store submissions, submit builds, and monitor review status with asc. Use when shipping or troubleshooting review submissions. | `.claude/skills/asc-submission-health/SKILL.md` |
| asc-subscription-localization | Bulk-localize subscription and in-app purchase display names across all App Store locales using asc. Use when you want to fill in subscription/IAP names for every language without clicking through App Store Connect manually. | `.claude/skills/asc-subscription-localization/SKILL.md` |
| asc-team-key-create | Create a new App Store Connect Team API Key with Admin permissions, download the one-time .p8 private key, and store it in ~/.blitz. Use when the user needs a new ASC API key for CLI auth, CI/CD, or external tooling. | `.claude/skills/asc-team-key-create/SKILL.md` |
| asc-testflight-orchestration | Orchestrate TestFlight distribution, groups, testers, and What to Test notes using asc. Use when rolling out betas. | `.claude/skills/asc-testflight-orchestration/SKILL.md` |
| asc-wall-submit | Submit or update a Wall of Apps entry in the App-Store-Connect-CLI repository using `asc apps wall submit`. Use when the user says "submit to wall of apps", "add my app to the wall", or "wall-of-apps". | `.claude/skills/asc-wall-submit/SKILL.md` |
| asc-whats-new-writer | Generate engaging, localized App Store release notes (What's New) from git log, bullet points, or free text using canonical metadata under `./metadata`. Optionally pairs with promotional text updates. | `.claude/skills/asc-whats-new-writer/SKILL.md` |
| asc-workflow | Define, validate, and run repo-local multi-step automations with `asc workflow` and `.asc/workflow.json`. Use when migrating from lane tools, wiring CI pipelines, or orchestrating repeatable `asc` + shell release flows with hooks, conditionals, and sub-workflows. | `.claude/skills/asc-workflow/SKILL.md` |
| asc-xcode-build | Build, archive, export, and manage Xcode version/build numbers with asc and xcodebuild before uploading to App Store Connect. Use when you need to create an IPA or PKG for upload. | `.claude/skills/asc-xcode-build/SKILL.md` |
| cloudkit-validate | Validate Swift models against CloudKit schema rules — checks date encoding, Bool fields, reserved names, nested arrays, and backwards-compatible decoding. | `.claude/skills/cloudkit-validate/SKILL.md` |
<!-- GSD:skills-end -->


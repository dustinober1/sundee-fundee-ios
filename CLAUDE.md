# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a native iOS strength training app with hormonal-cycle-aware training recommendations. Swift 6 + SwiftUI, targeting iOS 17.0+.

## Commands

### Setup
```bash
# Regenerate Xcode project after modifying project.yml
xcodegen generate
```

### Build
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Test
```bash
# Run all tests (CI enforces 100% line coverage)
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

### Deploy
```bash
bundle exec fastlane beta     # Build + upload to TestFlight
bundle exec fastlane tests    # Run tests with coverage report
```

## Architecture

```
SwiftUI Views
    ↓
@Observable ViewModels (@MainActor)
    ↓
Repository Protocols (testable, Sendable)
    ↓
SwiftData ←→ CloudKit (Private DB for users, Public DB for programs)
    ↓
Domain/ (pure Swift, zero dependencies, 100% tested)
```

### Key Directories

- **`App/`** — Entry point, `AppState` (auth routing), `ModelContainer` setup, schema migrations (V1→V7), debug seed data
- **`Auth/`** — Sign in with Apple, `KeychainHelper`, guest mode
- **`Domain/`** — All business logic: weight calculations, cycle phase adaptation, injury modification engine, benchmark catalog. No framework dependencies — fully unit tested.
- **`Models/`** — 14 SwiftData `@Model` types. **Enums must be stored as raw strings** (CloudKit requirement); typed accessors are computed properties.
- **`Repositories/`** — Protocol-based data access layer with SwiftData implementations. `ProgramRepository` fetches from CloudKit Public DB with bundled `programs.json` fallback.
- **`Features/`** — One subdirectory per tab: Dashboard, Programs, Workouts, Cycle, Maxes, Settings + Shell (tab bar)
- **`Theme/`** — Art Deco design tokens: cream/navy/orange palette

### Auth & Routing

`AppState` controls the root navigation state machine:
- `loading` → `signIn` → `onboarding` → `mainTab`
- `.authenticated` mode: full CloudKit sync enabled
- `.guest` mode: local SwiftData only, no CloudKit

### SwiftData / CloudKit Constraints

- Enum properties on `@Model` types **must be stored as `String` raw values** — CloudKit does not support Swift enums directly.
- Release entitlements enable CloudKit + Sign in with Apple; Debug entitlements are empty (supports Personal Team signing without paid capabilities).

### Programs

Programs are delivered via two channels:
1. Bundled `Resources/Programs/programs.json` (always available)
2. CloudKit Public DB (admin-seeded, for remote updates)

### Testing

- **100% line coverage is enforced** in CI (GitHub Actions parses `xccov` output).
- `Domain/` code is tested in isolation via pure Swift unit tests — no mocking needed.
- ViewModels, Repositories, Auth/Onboarding flows, and critical UI paths each have dedicated test wave files.
- When adding new `Domain/` types or public methods, add coverage in the corresponding `*CoverageTests.swift` file.

### Project Generation

The Xcode project is generated from `project.yml` via XcodeGen. **Never edit `.xcodeproj` directly** — modify `project.yml` and run `xcodegen generate`.

### Coding Conventions

- **Never use `try!`** in production code — always use `(try? ...) ?? defaultValue` for repository calls. SwiftData context errors should degrade gracefully, not crash.
- **Disable buttons for invalid input** rather than silently failing on save. Follow the pattern in `AddCustomBenchmarkSheet` (`.disabled(condition)`).
- **Thread `userID`** from `AppState` through all data-writing operations. Use `appState.currentUserID ?? ""` at the call site; never hardcode empty strings in ViewModels or Repositories.
- **Static helper methods** on Views are the preferred pattern for testability — actions, formatters, and computed state are extracted as `static func` so they can be unit tested without hosting the view.
- **Phase transition dismissals** are persisted to `UserDefaults` under the key `dismissedPhaseTransitions` (keyed by injury ID → suggested phase raw value). Clear on phase change.

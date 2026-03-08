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
TestFlight builds are deployed via **Xcode Cloud** (manual trigger only):
- In Xcode: Product → Xcode Cloud → Start Build
- Xcode Cloud handles signing, building, and uploading to TestFlight automatically

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

- **`App/`** — Entry point, `AppState` (auth routing), `ModelContainer` setup, schema migrations (V1→V8), debug seed data
- **`Auth/`** — Sign in with Apple, `KeychainHelper`, guest mode
- **`Domain/`** — All business logic: weight calculations, cycle phase adaptation, injury modification engine, benchmark catalog, pain trend analysis, rehab session generation, phase transition advice. No framework dependencies — fully unit tested.
- **`Models/`** — 18 SwiftData `@Model` types. **Enums must be stored as raw strings** (CloudKit requirement); typed accessors are computed properties.
- **`Repositories/`** — Protocol-based data access layer with SwiftData implementations. `ProgramRepository` fetches from CloudKit Public DB with bundled `programs.json` fallback.
- **`Features/`** — One subdirectory per tab: Dashboard, Programs, Workouts, Cycle, Maxes, Benchmarks, Settings + Shell (tab bar). `Shared/` contains reusable components (e.g., `SpicyRatingView`).
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

WODs (Workouts of the Day) are delivered via bundled `Resources/WODs/wods.json`, matched by date.

### WOD Admin Dashboard

A Next.js web dashboard at `wod-dashboard/` writes WODs to CloudKit Public DB via CloudKit JS SDK. Run locally with `cd wod-dashboard && npm run dev`. AI workout generation proxies through the Cloudflare Worker (see below).

### Cloudflare Worker Proxy

`workout-proxy.sundeefundee.workers.dev/generate-workout` proxies Gemini API calls. Uses native Gemini format (`contents`, `systemInstruction`, `generationConfig`), NOT OpenAI-compatible format.

### Submodule: SundeeFundeeShared

`SundeeFundee/Packages/SundeeFundeeShared/` is a git submodule. To commit changes: first `cd` into the submodule and commit there, then `git add SundeeFundee/Packages/SundeeFundeeShared` in the main repo.

### Testing

- **100% line coverage is enforced** in CI (GitHub Actions parses `xccov` output).
- `Domain/` code is tested in isolation via pure Swift unit tests — no mocking needed.
- ViewModels, Repositories, Auth/Onboarding flows, and critical UI paths each have dedicated test wave files.
- When adding new `Domain/` types or public methods, add coverage in the corresponding `*CoverageTests.swift` file.
- When changing default parameter values, update all test call sites to pass the value explicitly — tests that omit the parameter will silently use the new default and may break.
- **Never ignore pre-existing failures.** If test runs, builds, or CI surface issues that predate your changes, investigate and resolve them — do not dismiss them as "pre-existing." Every identified problem is your responsibility to address.

### Project Generation

The Xcode project is generated from `project.yml` via XcodeGen. **Never edit `.xcodeproj` directly** — modify `project.yml` and run `xcodegen generate`.

### Coding Conventions

- **Custom `init(from decoder:)` requires `encode(to:)`** — Adding a custom Decodable init prevents auto-synthesis of Encodable. Always add both when customizing Codable.
- **CloudKit Public DB writes require user auth** — API token alone only allows reads. Use CloudKit JS SDK with Apple ID sign-in for writes.
- **SourceKit diagnostics are often false positives** — Always verify with `xcodebuild build` before acting on "Cannot find type" or "No such module" SourceKit errors.

- **Benchmark `roundsAndReps` scoring** encodes as `rounds * 10000 + reps` in a single `Double`. Higher is better. Decode: `rounds = Int(value) / 10000`, `reps = Int(value) % 10000`.
- **Never use `try!`** in production code — always use `(try? ...) ?? defaultValue` for repository calls. SwiftData context errors should degrade gracefully, not crash.
- **Disable buttons for invalid input** rather than silently failing on save. Follow the pattern in `AddCustomBenchmarkSheet` (`.disabled(condition)`).
- **Thread `userID`** from `AppState` through all data-writing operations. Use `appState.currentUserID ?? ""` at the call site; never hardcode empty strings in ViewModels or Repositories.
- **Static helper methods** on Views are the preferred pattern for testability — actions, formatters, and computed state are extracted as `static func` so they can be unit tested without hosting the view.
- **Phase transition dismissals** are persisted to `UserDefaults` under the key `dismissedPhaseTransitions` (keyed by injury ID → suggested phase raw value). Clear on phase change.

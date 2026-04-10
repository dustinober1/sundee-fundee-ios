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

### Subscriptions

StoreKit 2 with three tiers:
- **Free** — 5 lifts, 1 injury, 30-day history, limited AI
- **Sundee Plus** — unlimited lifts/injuries/history, daily AI, custom benchmarks, pain trends
- **Sundee Premium** — unlimited all, 10 AI/day, rehab sessions, AI coach memory, plateau detection

### Domain Layer

Pure Swift business logic mirroring the original web app's domain layer:
- `Cycle/` — Cycle calculations, adaptation policy, calendar, settings
- `Injury/` — Body location, adaptation engine, injury models, support
- `Benchmark/` — Catalog, models, readiness
- `AIWorkout/` — AI workout types and generation helpers
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
- **Location:** `SundeeFundee/Tests/SundeeFundeeKitTests/`
- **Pattern:** Pure function unit tests with factory helpers (`makeDate()`, `makeWorkout()`, `makeExercise()`)
- **Access:** `@testable import SundeeFundeeKit`

## App Store Requirements

- **Privacy Manifest** (`PrivacyInfo.xcprivacy`) — declares API usage and collected data types
- **UIRequiredDeviceCapabilities** must be `arm64`, not `armv7`
- **Code signing:** `CODE_SIGN_STYLE = Automatic` — don't hardcode
- **App icon:** Single 1024x1024 universal icon
- **Screenshot dimensions:** iPhone 6.5" = 1284x2778, iPad 12.9" = 2048x2732
- **Subscription apps** must include Terms of Use + Privacy Policy links in description

## iOS Simulator UI Automation

- SwiftUI `Toggle` (AXSwitch) doesn't respond to `tap` by label — use coordinates
- Tab bar items may not expose individual children — use coordinate taps
- Guest mode requires completing onboarding before reaching main screens

## Git Workflow

- **Auto-commit as you go** — commit each file immediately after editing it; don't wait until the entire task is done
- **Commit each file separately** — stage and commit one file at a time
- **Commit message format:** `type(scope): description`
- **Main branch:** `main`

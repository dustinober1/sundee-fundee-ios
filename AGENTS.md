# AGENTS.md

Guidance for Codex working in this repo.

## Project

**Sundee Fundee** — native iOS app for cycle-aware strength training. SwiftUI, Swift 6 (strict concurrency), CloudKit, HealthKit, Apple Sign-In. Art Deco theme (cream/navy/orange).

**v2 scope:** daily Recovery Score, deload detection with active-recovery programming, social sharing layer. All features free; no paywalls.

**Constraints:** iOS 18+, CloudKit-only backend, zero external package dependencies, `AppTheme.*` tokens only, HealthKit denial handled gracefully.

## Commands

```bash
# Build
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test (all / filtered)
cd SundeeFundee && swift test
cd SundeeFundee && swift test --filter 'SundeeFundeeKitTests.CyclePhaseHelperTests/testPhaseCalculation'

# Lint
swiftlint --config .swiftlint.yml

# Release
cd SundeeFundeeApp && bundle exec fastlane release

# Regenerate Xcode project
cd SundeeFundeeApp && xcodegen generate
```

## Architecture

```
SundeeFundeeApp/ (Xcode project — app entry)
    ↓ imports
SundeeFundee/ (Swift Package — SundeeFundeeKit)
    ├── DomainLayer/   pure business logic, zero framework deps
    ├── DataLayer/     DataClientProtocol + CloudKit/Local/Mock impls
    ├── UI/            SwiftUI views, view models, theme
    ├── Auth/          Apple Sign-In + Keychain
    ├── Models/        shared Codable models
    ├── Activity/      live activity (workout rings)
    └── Screenshot/    screenshot seeding
```

- `DataClientFactory.shared.client` — thread-safe client switching (CloudKit for signed-in, `LocalDataClient` for guest).
- `CloudKitClient` is an actor. ViewModels are `@MainActor`.
- `SyncQueue` queues mutations offline; **currently dormant** — not wired into `DataClientFactory`.

## CloudKit schema rules

- **Reserved field names**: do NOT use `createdAt`, `modifiedAt`, `startDate`, `endDate` — they collide with CloudKit system TIMESTAMP fields. Use `dateCreated`, `challengeStartDate`, etc.
- **Dates** encode as ISO8601 STRING via `JSONEncoder`, not TIMESTAMP.
- **Bool fields** decode as `Int64` in CloudKit. Custom `init(from:)` must try `Bool` first, fall back to `Int` (see `EnrolledProgramRecord`, `UserSettingsRecord`).
- **New record types** need a `recordName` QUERYABLE index in CloudKit Dashboard (Development → Indexes) and deploy to Production, or `fetchAll` throws `DataError.schemaNotDeployed`.
- **Nested arrays of structs**: `CloudKitClient.convertToCKRecordValue` serializes as typed `[String]` (JSON-encoded) or single JSON string. Verify round-trips in CloudKit Dashboard.
- **Backwards-compatible decode**: on field rename, try new key first, fall back to legacy via `try?`. See `Challenge` (`dateCreated`/`createdAt`).
- **Decode resilience**: clients skip individual undecodable records and increment `DiagnosticsService.shared.decodeFailureCount` (MainActor singleton, surfaced in Settings when > 0).
- The `cloudkit-validate` skill checks all of the above against model files.

## Auth

- Apple Sign-In only. Session in Keychain, user data in CloudKit.
- Guest mode: `continueAsGuest()` sets `isGuest = true`, `userID = "guest_local"`. Gate CloudKit writes with `!authViewModel.isGuest`.
- **Name only on first sign-in** — `fullName` is nil on subsequent sign-ins (incl. after account deletion). Persist `givenName` to CloudKit as source of truth. Display `givenName`, not `displayName`.
- `GuestDataMigrator` runs inside `signInWithApple` BEFORE the factory swap; source cleared only after every destination save succeeds.

## Monetization & App Store

- App is **free with all features unlocked**. Do not add paywalls, purchase flows, or paid access gates.
- **NEVER submit the app for App Store review unless explicitly told to.** Includes building-for-upload, uploading, submitting. Stop and ask first.

## Coding conventions

- Swift 6 strict concurrency throughout; `@MainActor` view models, `actor` data clients, `async`/`await` for all I/O.
- Pure domain layer — no framework imports beyond Foundation, no logging.
- Swift enums over stringly-typed constants. Discriminated enums for flexible types.
- **Theme**: `AppTheme.*` tokens only. Never hardcode `Color.red/.orange/.green`; use `AppTheme.Semantic.*`, `AppTheme.Accent.*`, `AppTheme.Recovery.*`. Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (numbers).
- **Dynamic Type for icons**: use semantic sizes (`.font(.title3)`, `.font(.system(.largeTitle))`). Avoid new `.font(.system(size: N))` unless intentional.
- **Haptics**: use `HapticFeedback` helper (`UI/Theme/HapticFeedback.swift`). `.light()` set complete, `.medium()` tier milestone, `.success()` PR/challenge/share, `.warning()` failed save. MainActor-isolated — from an actor, `Task { @MainActor in ... }`.
- **User-facing errors**: never display `error.localizedDescription` directly. Wrap with actionable copy; keep raw error in logs.
- **Benchmark `roundsAndReps` encoding**: `rounds * 10000 + reps`. Higher is better.
- **Multiplier-based adaptation**: cycle phase × recovery phase × energy level compose multiplicatively on base weights.
- **SourceKit false positives**: "Cannot find type in scope" across modules (KeychainHelper, DataClientFactory, etc.) is noise — trust `xcodebuild` only.

## Testing

- XCTest and Swift Testing (`import Testing`, `@Test`).
- `SundeeFundee/Tests/SundeeFundeeKitTests/` — subdirs by layer (`DomainTests/`, `DataLayerTests/`, etc.).
- Pure-function unit tests with `makeDate()`, `makeWorkout()`, `makeExercise()` factory helpers.

## iOS UI automation (mobile-mcp, simulator)

- SwiftUI `Toggle` (AXSwitch) and tab bar items often ignore tap-by-label — use coordinates.
- HealthKit permission dialog is in system coord space — differs from app `list_elements`.
- iPad sheets/form-sheets: **coordinates shift when keyboard shows/hides** — re-`list_elements` after keyboard changes. iPad Pro 13" keyboard-hide button ≈ `(957, 1324)`.
- Disabled buttons still appear in accessibility tree and accept silent taps; reduce `.opacity` to make state visible.
- Guest mode requires completing onboarding before main screens.

## Research

Use Gemini MCP (`mcp__gemini-cli__ask-gemini`) for internet research (APIs, docs, Apple guidelines). Prefer over web search tools.

## Git workflow

- Auto-commit per file as you go; one file per commit. Format: `type(scope): description`. Main branch: `main`.
- **Delegate routine git to a Haiku subagent** (`Agent` tool, `subagent_type: "general-purpose"`, `model: "haiku"`). Give it: exact files to stage, commit message (or facts to write one), branch. Haiku handles staging, committing, pushing, status/diff, non-conflict rebases. Keeps git noise out of main context.
- **Do not delegate** destructive/irreversible ops (force push, `reset --hard`, branch deletion, history rewrite, non-trivial merge conflict resolution). Main model + explicit user confirmation.
- Haiku subagent prompt should specify: never `git add .` / `-A`, never amend, never force-push, stop and report on unexpected state.

## Project skills

Project-local skills live in `.Codex/skills/`. Notable:
- `cloudkit-validate` — validates Swift models against the CloudKit schema rules above.
- `asc-*` family — App Store Connect workflows (submission, metadata, TestFlight, screenshots, signing, pricing, etc.). Discover via `ls .Codex/skills/` when an ASC task comes up.

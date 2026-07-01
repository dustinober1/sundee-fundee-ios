# Sundee Fundee Kit

Shared Swift package for the Sundee Fundee iOS app: cycle-aware strength training, recovery guidance, progress tracking, sharing, widgets, and App Intents.

## Repository Shape

```text
SundeeFundee/                  # Swift package: SundeeFundeeKit
├── Sources/SundeeFundeeKit/
│   ├── DomainLayer/           # Pure training, cycle, recovery, privacy, growth, and support logic
│   ├── DataLayer/             # DataClientProtocol plus CloudKit, local, mock, diagnostics, sync, StoreKit
│   ├── UI/                    # SwiftUI views, view models, app shell helpers, theme, share UI
│   ├── Auth/                  # Apple Sign-In and Keychain helpers
│   ├── Models/                # Shared Codable models and CloudKit record types
│   ├── Activity/              # Live Activity support
│   ├── Intents/               # App Intents and App Shortcuts
│   └── Screenshot/            # Screenshot seed data
├── Tests/SundeeFundeeKitTests/
└── Package.swift

SundeeFundeeApp/               # Xcode app project
├── SundeeFundee/              # @main app target, assets, plist, entitlements
├── SundeeFundeeWidgets/       # Widget extension
├── StoreKit/                  # Local StoreKit configuration
└── fastlane/                  # Release metadata and screenshot automation
```

The app target imports `SundeeFundeeKit`; most product code lives in the package so it can be tested with SwiftPM.

## Requirements

- Xcode 17 or newer
- Swift 6
- iOS 18 or newer
- macOS 15 or newer

The project uses Apple frameworks only. Do not add external package dependencies.

## Common Commands

Run package tests:

```bash
cd SundeeFundee
swift test
```

Run a focused package test:

```bash
cd SundeeFundee
swift test --filter SundeeFundeeKitTests.CyclePhaseHelperTests/testPhaseCalculation
```

Build the app and widget extension:

```bash
cd SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Regenerate the Xcode project after editing `project.yml`:

```bash
cd SundeeFundeeApp
xcodegen generate
```

## Architecture Notes

- `DataClientFactory.shared.client` selects CloudKit for signed-in users and local storage for guest mode.
- `CloudKitClient` is an actor; SwiftUI view models are `@MainActor`.
- Domain services should stay deterministic and framework-light.
- UI must use `AppTheme.*` tokens and handle HealthKit denial gracefully.
- CloudKit record dates are encoded as ISO8601 strings, and new record types need a queryable `recordName` index before production use.

## Release Status

The current release plan and item matrix live in:

- `docs/superpowers/plans/2026-06-30-next-release-20-phase-plan.md`
- `docs/superpowers/plans/2026-06-30-next-release-20-matrix.md`

Copyright (c) 2026 Sundee Fundee. All rights reserved.

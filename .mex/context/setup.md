---
name: setup
description: Dev environment setup and commands. Load when setting up the project for the first time or when environment issues arise.
triggers:
  - "setup"
  - "install"
  - "environment"
  - "getting started"
  - "how do I run"
  - "local development"
edges:
  - target: context/stack.md
    condition: when specific technology versions or library details are needed
  - target: context/architecture.md
    condition: when understanding how components connect during setup
  - target: patterns/debug-build-failures.md
    condition: when build or test commands fail
last_updated: 2026-04-11
---

# Setup

## Prerequisites

- Xcode 16.0+ (Swift 6.0)
- iOS 18.0+ Simulator or device
- Node.js (for Teenybase backend, if working on remote content)

## First-time Setup

1. Clone the repo
2. Open `SundeeFundeeApp/SundeeFundee.xcodeproj` in Xcode (or generate it first — see below)
3. Select the `SundeeFundee` scheme and an iOS Simulator (e.g., iPhone 17 Pro)
4. Build and run (Cmd+R)

If the `.xcodeproj` is missing or out of date:
```bash
cd SundeeFundeeApp
xcodegen generate
```

For the Teenybase backend (optional, only for remote content work):
```bash
cd SundeeFundeeApp/backend
npm install
```

## Environment Variables

No environment variables required for the iOS app. CloudKit configuration is handled via entitlements and the container identifier `iCloud.com.sundeefundee.app`.

For the Teenybase backend:
- Cloudflare Wrangler credentials (for deployment only)
- Local development uses `.local-persist/` for D1 SQLite emulation

## Common Commands

- **Build (CLI):**
  ```bash
  cd SundeeFundeeApp
  xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
  ```
- **Test (Swift Package):**
  ```bash
  cd SundeeFundee
  swift test
  ```
- **Generate Xcode project:**
  ```bash
  cd SundeeFundeeApp
  xcodegen generate
  ```
- **Run backend locally:**
  ```bash
  cd SundeeFundeeApp/backend
  npx wrangler dev
  ```

## Common Issues

**"Cannot find type in scope" errors in SourceKit:**
These are SourceKit false positives for cross-module types (KeychainHelper, DataClientFactory, etc.). Trust `xcodebuild` results only — if `xcodebuild build` succeeds, the code is correct. Do not add unnecessary imports or type aliases to silence SourceKit.

**SwiftUI Toggle (AXSwitch) not responding to tap in UI tests:**
SwiftUI `Toggle` doesn't respond to `tap` by accessibility label in the simulator. Use coordinate-based taps instead.

**Tab bar items not individually accessible in UI tests:**
Tab bar may not expose individual children as accessibility elements. Use coordinate taps to navigate between tabs.

**XcodeGen project out of date after adding files:**
If new files aren't showing up in Xcode, re-run `xcodegen generate` in the `SundeeFundeeApp/` directory. The `project.yml` must include new targets or file groups.

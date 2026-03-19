# Technology Stack

**Analysis Date:** 2026-03-18

> **Note:** This document covers the legacy Swift/SwiftUI codebase at the repo root. The active React Native + Expo rewrite lives in the same repo but is documented separately. This Swift codebase is archived but remains the production app.

## Languages

**Primary:**
- Swift 6.0 - All application code (`SundeeFundee/`)
- TypeScript 5.9.3 - WOD admin dashboard (`wod-dashboard/`)

**Secondary:**
- Bash - CI scripts (`ci_scripts/ci_post_clone.sh`, `ci_scripts/ci_pre_xcodebuild.sh`)
- Python 3 - CI coverage enforcement script (inline in `.github/workflows/ios-ci.yml`)
- Ruby - Fastlane tooling (`Gemfile`, `fastlane/Fastfile`)

## Runtime

**Environment:**
- iOS 17.0+ (iPhone only, portrait orientation)
- Xcode 16.0
- Swift Concurrency (async/await, `Sendable`, actors) throughout

**Package Manager:**
- Swift Package Manager (SPM) — no `Package.resolved` committed; resolved at build time
- npm — for `wod-dashboard/` only
- Bundler (Ruby) — for Fastlane

## Frameworks

**Core:**
- SwiftUI — all UI (`import SwiftUI` throughout `SundeeFundee/`)
- SwiftData — local persistence with CloudKit sync (`import SwiftData`)
- Foundation — standard library utilities

**Apple System Frameworks:**
- AuthenticationServices — Sign in with Apple (`SundeeFundee/Auth/AuthService.swift`)
- CloudKit — iCloud private and public database (`SundeeFundee/Repositories/CloudKit/`)
- HealthKit — sleep, HRV, resting heart rate reads (`SundeeFundee/Repositories/HealthKit/`)
- StoreKit 2 — in-app subscriptions (`SundeeFundee/Services/SubscriptionService.swift`)
- MetricKit — performance/crash diagnostics (`SundeeFundee/Observability/MetricsService.swift`)
- Security — Keychain storage (`SundeeFundee/Auth/KeychainHelper.swift`)
- Charts — data visualization (`import Charts` in feature views)

**Testing:**
- XCTest — unit test framework (`SundeeFundeTests/`)

**Build/Dev:**
- XcodeGen 16.0 — generates `SundeeFundee.xcodeproj` from `project.yml` (never commit the `.xcodeproj` directly; regenerate with `xcodegen generate`)
- Fastlane — CI/CD lane runner (`fastlane/Fastfile`)

**WOD Dashboard (wod-dashboard/):**
- Next.js 16.1.6 with React 19.2.3
- Tailwind CSS 4
- tsl-apple-cloudkit 0.2.34 — CloudKit JS SDK for writing WODs from admin dashboard
- Jest 30 / ts-jest 29 — dashboard testing

## Key Dependencies

**Critical:**
- SwiftData (Apple, built-in) — primary local data store; 22-model schema at v12 (`SundeeFundee/App/AppSchemaV12.swift`); versioned migration plan in `AppSchemaMigrationPlan.swift`
- CloudKit (Apple, built-in) — private database sync via SwiftData; public database for shared workout templates
- StoreKit 2 (Apple, built-in) — subscription management; no third-party purchase SDK
- `SundeeFundeeShared` (private SPM package) — `github.com/dustinober1/sundee-fundee-shared`; cloned at CI time into `SundeeFundee/Packages/SundeeFundeeShared/`; provides shared domain types

**Infrastructure:**
- `tsl-apple-cloudkit` `^0.2.34` — CloudKit JS SDK used by `wod-dashboard/` to write WODs to Firestore (note: dashboard currently still uses CloudKit; Firestore migration planned per CLAUDE.md)

## Configuration

**Environment:**
- No `.env` files in Swift app — secrets passed via GitHub Secrets at CI time
- Subscription tiers cached in `UserDefaults` under key `com.sundeefundee.subscription.tier`
- Auth (Apple user ID) stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- CloudKit container: `iCloud.com.sundeefundee.app`
- Gemini proxy URL hardcoded in source: `https://workout-proxy.sundeefundee.workers.dev/generate-workout`

**Required CI/CD secrets (GitHub Secrets):**
- `PAT_TOKEN` — GitHub PAT for private shared package checkout
- `MATCH_GIT_URL`, `MATCH_PASSWORD` — Fastlane Match cert repo
- `APPLE_ID`, `APPLE_TEAM_ID` — App Store Connect credentials
- `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_CONTENT` — ASC API key

**Build:**
- `project.yml` — XcodeGen source of truth; generates `SundeeFundee.xcodeproj`
- `SundeeFundee/Resources/SundeeFundee.entitlements` — production (Sign in with Apple, HealthKit, CloudKit)
- `SundeeFundee/Resources/SundeeFundee.Debug.entitlements` — debug (empty; no CloudKit in dev)
- `SundeeFundee/Resources/SundeeFundee.storekit` — StoreKit sandbox config; 2 products: `com.sundeefundee.plusmonthly` ($4.99/mo) and `com.sundeefundee.pro.monthly` ($9.99/mo)
- `SundeeFundee/Resources/PrivacyInfo.xcprivacy` — Apple privacy manifest (UserDefaults, health/fitness, user content, user ID, purchase history)

## Platform Requirements

**Development:**
- Xcode 16.0
- XcodeGen installed (`brew install xcodegen`) — must run `xcodegen generate` before building
- Private SPM package cloned into `SundeeFundee/Packages/SundeeFundeeShared/`
- iOS Simulator (iPhone 17 Pro used in CI)

**Production:**
- App Store distribution via Fastlane Match + TestFlight (`fastlane beta` lane)
- Xcode Cloud also configured (see `ci_scripts/`) for alternative CI path
- App Store Connect team: `87VVCMCW3F`
- Bundle ID: `com.sundeefundee.app`
- Marketing version: 1.2.0

---

*Stack analysis: 2026-03-18*

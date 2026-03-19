# External Integrations

**Analysis Date:** 2026-03-18

> **Note:** This covers the legacy Swift/SwiftUI codebase at the repo root, which remains the production iOS app.

## APIs & External Services

**AI Workout Generation:**
- Gemini AI (via Cloudflare Worker proxy) — generates personalized workouts from user context
  - Client: Native `URLSession` — no SDK, raw HTTP POST
  - Endpoint: `https://workout-proxy.sundeefundee.workers.dev/generate-workout`
  - Model: `gemini-3.1-flash-lite-preview`
  - Format: Gemini native (`contents`, `systemInstruction`, `generationConfig`) — NOT OpenAI-compatible
  - Implementation: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`
  - Request builder: `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift`
  - Response parser: `SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift`
  - Timeout: 15 seconds; offline fallback via `OfflineWorkoutGenerator`
  - Auth: None (proxy handles key; no token from client)

## Data Storage

**Databases:**
- SwiftData + CloudKit Private Database — primary user data store
  - Container: `iCloud.com.sundeefundee.app`
  - Client: `SwiftData.ModelContainer` / `ModelContext`
  - Schema: 22 models at v12 (`SundeeFundee/App/AppSchemaV12.swift`)
  - Migration plan: `SundeeFundee/App/AppSchemaMigrationPlan.swift` (tracks v1–v12)
  - Container setup: `SundeeFundee/App/AppModelContainer.swift`
  - Fallback tiers: CloudKit (if entitlements) → local persistent → in-memory
  - Dev/debug: local persistent store only (no CloudKit entitlements in Debug)

- CloudKit Public Database — crowdsourced shared workout templates
  - Container: `iCloud.com.sundeefundee.app`
  - Record type: `SharedWorkoutTemplate`
  - Client: `CKContainer` / `CKDatabase` directly (not via SwiftData)
  - Implementation: `SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift`
  - Contributions are anonymized (userID stripped via `strippedForSharing()`)
  - Local cache: `SharedWorkoutTemplateRecord` SwiftData model

**File Storage:**
- Local filesystem only — `ApplicationSupportDirectory/default.store` (SwiftData SQLite)
- Bundled resources: programs JSON at `SundeeFundee/Resources/Programs/`, WODs JSON at `SundeeFundee/Resources/WODs/`

**Caching:**
- `UserDefaults` — subscription tier persistence (`com.sundeefundee.subscription.tier`)
- SwiftData in-memory fallback for tests and previews
- CloudKit shared workout templates cached as `SharedWorkoutTemplateRecord` models

## Authentication & Identity

**Auth Provider:**
- Sign in with Apple (Apple AuthenticationServices)
  - Implementation: `SundeeFundee/Auth/AuthService.swift`
  - Credential storage: Keychain (`SundeeFundee/Auth/KeychainHelper.swift`)
  - Keychain service: `com.sundeefundee.app`, account key: `appleUserID`
  - Accessibility: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  - Session restoration: checks `ASAuthorizationAppleIDProvider.credentialState` on launch
  - User record: `User` SwiftData model linked by `appleUserID` string
  - Onboarding gate: `AuthState.needsOnboarding` for new users; `AuthState.authenticated` for returning users
  - Entitlement: `com.apple.developer.applesignin` = `["Default"]`

**Guest/Anonymous mode:**
- Not present — app requires Sign in with Apple

## Monitoring & Observability

**Performance Monitoring:**
- MetricKit (Apple, built-in) — CPU and memory metrics
  - Implementation: `SundeeFundee/Observability/MetricsService.swift`
  - Logs to Xcode Organizer; debug-only console output
  - Subscribes to `MXMetricPayload` and `MXDiagnosticPayload`
  - Started in `SundeeFundeeApp.init()`

**Error Tracking:**
- None — no third-party crash SDK (Crashlytics, Sentry, etc.) integrated
- MetricKit diagnostics provide crash/hang counts via Xcode Organizer only

**Logs:**
- `print()` statements throughout services and repositories (no structured logging framework)
- MetricKit crash diagnostics surfaced via Xcode Organizer in production

## In-App Purchases & Subscriptions

**Provider:** Apple StoreKit 2 (no RevenueCat in this legacy codebase)
- Implementation: `SundeeFundee/Services/SubscriptionService.swift`
- Tiers: Free, Plus (`com.sundeefundee.plusmonthly` $4.99/mo), Pro (`com.sundeefundee.pro.monthly` $9.99/mo)
- Both subscriptions in group `sundee-fundee-premium` with 2-week free trial
- Transaction observation: `Transaction.updates` async sequence
- Restore: `AppStore.sync()`
- StoreKit config file: `SundeeFundee/Resources/SundeeFundee.storekit`

## Health Data

**Provider:** Apple HealthKit
- Entitlements: `com.apple.developer.healthkit` + `com.apple.developer.healthkit.background-delivery`
- Implementation: `SundeeFundee/Repositories/HealthKit/HealthKitReadinessRepository.swift`
- Read types: sleep analysis, HRV SDNN, resting heart rate
- Write types: workout data (write usage description in Info.plist; write permission declared but HealthKit store write not shown in current repo)
- Usage: computes readiness score for training adaptation
- Privacy manifest: `NSPrivacyCollectedDataTypeHealthAndFitness` declared in `PrivacyInfo.xcprivacy`

## CI/CD & Deployment

**CI — GitHub Actions:**
- Workflow: `.github/workflows/ios-ci.yml` (in worktree; canonical path at repo root `.github/`)
- Triggers: push to `main`, pull requests
- Runner: `macos-15`
- Steps: checkout private shared package → install XcodeGen → generate project → build → test → enforce 100% line coverage
- Coverage enforcement: `xcrun xccov` + Python script; requires 100% line coverage on `SundeeFundee.app` target

**CI — Xcode Cloud (alternate):**
- Scripts: `ci_scripts/ci_post_clone.sh`, `ci_scripts/ci_pre_xcodebuild.sh`
- Installs XcodeGen, clones `sundee-fundee-shared` private package, generates Xcode project

**Deployment:**
- TestFlight/App Store: Fastlane `beta` lane (`fastlane/Fastfile`)
- Code signing: Fastlane Match (`appstore` cert type, private Git repo via `MATCH_GIT_URL`)
- Build number: auto-incremented from latest TestFlight build
- Distribution method: `app-store`

## WOD Admin Dashboard (`wod-dashboard/`)

**Stack:** Next.js 16 + React 19 + TypeScript + Tailwind CSS 4
**Purpose:** Admin interface for writing WODs (Workout of the Day) to backend
**Backend connection:** `tsl-apple-cloudkit` 0.2.34 — CloudKit JS SDK
**Note:** Dashboard uses CloudKit; migration to Firestore is planned per project roadmap but not yet implemented

## Webhooks & Callbacks

**Incoming:**
- None — no webhook endpoints in this native iOS app

**Outgoing:**
- None — all API calls are client-initiated (Gemini proxy, CloudKit)

## Cloudflare Worker Proxy

**URL:** `https://workout-proxy.sundeefundee.workers.dev/generate-workout`
**Purpose:** Proxies Gemini API calls to avoid exposing API key in client
**Auth:** None from client side — proxy handles Gemini API key
**Format:** Gemini native format (`contents`, `systemInstruction`, `generationConfig`)
**Planned replacement:** Firebase Cloud Functions (per project roadmap)

---

*Integration audit: 2026-03-18*

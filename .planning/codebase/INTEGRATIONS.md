# External Integrations

**Analysis Date:** 2025-03-14

## APIs & External Services

**AI Workout Generation:**
- Google Gemini API (via Cloudflare Worker proxy)
  - SDK/Client: `GeminiWorkoutService` (`SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`)
  - Endpoint: `https://workout-proxy.sundeefundee.workers.dev/generate-workout`
  - Model: `gemini-3.1-flash-lite-preview`
  - Format: Native Gemini JSON format (contents, systemInstruction, generationConfig)
  - Timeout: 15 seconds default
  - Fallback: OfflineWorkoutGenerator generates workouts locally on any error

**Shared Workouts (Crowdsourced):**
- CloudKit Public Database shared workout contributions
  - Repository: `CloudKitSharedWorkoutRepository` (`SundeeFundee/Repositories/CloudKit/CloudKitSharedWorkoutRepository.swift`)
  - Fire-and-forget contribution from `SwiftDataAIWorkoutService` after user generates a workout

## Data Storage

**Databases:**
- CloudKit Private Database (`iCloud.com.sundeefundee.app`)
  - Client: SwiftData + CloudKit integration
  - Connection: Automatic via ModelContext when entitlements present
  - Content: User-generated data (completed workouts, custom lifts, injuries, pain logs, cycle data, maxes, benchmarks)
  - Sync: Automatic bi-directional with SwiftData

- CloudKit Public Database (`iCloud.com.sundeefundee.app`)
  - Client: CKContainer API + tsl-apple-cloudkit (JS SDK for dashboard writes)
  - Content: Admin-seeded Programs and WODs, crowdsourced shared workouts
  - Access: Read by all users (unauthenticated), write requires dashboard authentication (CloudKit JS SDK with Apple ID)

- Local SwiftData (fallback, no CloudKit)
  - Stored in ApplicationSupport directory
  - Activated during development when entitlements unavailable
  - Can be cleared via AppModelContainer.forceClearStore()

**File Storage:**
- Bundled JSON files (no external storage)
  - `programs.json` - Static program data
  - `wods.json` - Static workout templates

**Caching:**
- In-memory caches in repository classes:
  - `BundledProgramRepository.cache` - Programs cached after first load
  - `BundledWODRepository.cache` - WODs cached after first load
  - No persistent external cache layer

## Authentication & Identity

**Auth Provider:**
- Apple Sign in with Apple
  - Implementation: `AuthService` (`SundeeFundee/Auth/AuthService.swift`)
  - Framework: AuthenticationServices (ASAuthorizationAppleIDProvider, ASAuthorizationController)
  - Requested scopes: Full name, email
  - Credential storage: Keychain (via `KeychainHelper`)
  - Session restoration: Auto-restores from keychain on app launch
  - Guest mode: Available - guest users have local-only SwiftData (no CloudKit)

- Cloudflare Worker auth (WOD dashboard only)
  - Dashboard: `wod-dashboard/` (Next.js)
  - Auth: CloudKit JS SDK with Apple ID sign-in
  - API Token: NEXT_PUBLIC_CLOUDKIT_API_TOKEN (in .env.local, not committed)

## Monitoring & Observability

**Error Tracking:**
- Not detected (no Sentry, Crashlytics, or similar)
- Errors logged via print() statements in production code

**Logs:**
- Console output via print() statements with prefixes like `[SubscriptionService]`, `[AppModelContainer]`, `[AIWorkoutService]`
- No external logging service

## CI/CD & Deployment

**Hosting:**
- Apple App Store (TestFlight for beta, App Store for production)

**CI Pipeline:**
- Xcode Cloud (Apple's native CI/CD)
  - Manual trigger: Xcode → Product → Xcode Cloud → Start Build
  - Automatically handles: Code signing, building, uploading to TestFlight
  - Enforces: 100% line coverage (xccov output parsed in GitHub Actions)

**Build Verification:**
- GitHub Actions (coverage enforcement)
  - Parses xccov output to verify 100% line coverage
  - Triggered on pull requests or commits

## Environment Configuration

**Required env vars (WOD Dashboard):**
- NEXT_PUBLIC_CLOUDKIT_API_TOKEN - CloudKit JS API token (public-safe, for browser SDK)
- NEXT_PUBLIC_CLOUDKIT_ENV - CloudKit environment (production)

**Secrets location:**
- `wod-dashboard/.env.local` - CloudKit API token (NOT committed to git)
- iOS app: No .env files - configuration via Xcode project settings and entitlements

**Build-time configuration:**
- `project.yml` - Deployment target, Swift version, bundleIdPrefix, signing team
- `SundeeFundee.storekit` - StoreKit subscription products and pricing

## Webhooks & Callbacks

**Incoming:**
- Cloudflare Worker → Gemini API (one-way call, no incoming webhooks)

**Outgoing:**
- CloudKit Public DB contributions (SwiftData writes anonymized workout to shared table)
- StoreKit transaction updates (Transaction.updates stream in SubscriptionService)

## Integration Points Summary

**Data Flow:**
```
iOS App (SwiftUI)
  ↓
AuthService (Sign in with Apple) ↔ Keychain
  ↓
SwiftData ModelContext
  ↓
CloudKit (Private DB: user data) + (Public DB: programs, WODs, shared workouts)
  ↓
HealthKit (read-only: sleep, HRV, resting HR)

AI Workout Generation:
  GeminiWorkoutService (iOS)
  ↓
  Cloudflare Worker: workout-proxy.sundeefundee.workers.dev/generate-workout
  ↓
  Google Gemini API (gemini-3.1-flash-lite-preview)

Subscription Management:
  StoreKit 2 (transaction verification)
  ↓
  App Store Connect (product definitions, receipts)

WOD Admin Dashboard (Next.js):
  ↓
  tsl-apple-cloudkit (JS SDK)
  ↓
  CloudKit Public DB (Programs, WODs)
```

---

*Integration audit: 2025-03-14*

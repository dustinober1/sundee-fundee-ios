# External Integrations

**Analysis Date:** 2025-03-21

## APIs & External Services

**AI Workout Generation:**
- Gemini API (Google) - Generates personalized strength training workouts
  - Proxy URL: `https://workout-proxy.sundeefundee.workers.dev/generate-workout`
  - Implementation: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`
  - Request format: Native Gemini format (contents, systemInstruction, generationConfig)
  - Model: `gemini-3.1-flash-lite-preview` (via Cloudflare Worker proxy)
  - Timeout: 15 seconds
  - Fallback: `OfflineWorkoutGenerator` if network fails

**Apple Services:**
- Sign in with Apple - User authentication
  - Implementation: `SundeeFundee/Auth/AuthService.swift`
  - Uses `AuthenticationServices` framework
  - Credentials stored in Keychain
  - Required for account creation and login

- HealthKit - Readiness metrics (sleep, HRV, resting heart rate)
  - Implementation: `SundeeFundee/Repositories/HealthKit/HealthKitReadinessRepository.swift`
  - Read types: Sleep analysis, heart rate variability (SDNN), resting heart rate
  - Background delivery enabled
  - User must grant permission in Settings

- StoreKit 2 - In-app subscription management
  - Implementation: `SundeeFundee/Services/SubscriptionService.swift`
  - Subscription verification via App Store
  - Product IDs: `com.sundeefundee.plusmonthly`, `com.sundeefundee.pro.monthly`
  - No manual backend validation required

## Data Storage

**Databases:**
- **CloudKit (Apple iCloud)**
  - Container: `iCloud.com.sundeefundee.app`
  - Type: Private database (per-user data sync across iOS devices)
  - Models: 15+ SwiftData models synced via CloudKit
  - Location: `SundeeFundee/App/AppModelContainer.swift`
  - Schema versions: V1–V12 (with `AppSchemaMigrationPlan` for version control)
  - Client: SwiftData with CloudKit persistence store

- **SwiftData (Local)**
  - Purpose: Local model persistence (same models as CloudKit when offline)
  - Fallback when CloudKit unavailable
  - Location: `SundeeFundee/Models/`
  - Models include: User, Program, WOD, Benchmark, CompletedWorkout, Cycle, Injury, etc.

- **Keychain (Apple)**
  - Purpose: Secure credential storage
  - Contents: Apple Sign in user ID, guest user ID
  - Implementation: `SundeeFundee/Auth/KeychainHelper.swift`

- **UserDefaults (Apple)**
  - Purpose: App preferences and state flags
  - Usage: Guest migration status, subscription tier, dismissed notifications
  - Examples: `healthkit-readiness-enabled`, `guestMigrationPending`, `com.sundeefundee.subscription.tier`

**File Storage:**
- Bundled JSON resources only (`SundeeFundee/Resources/Programs/`, `SundeeFundee/Resources/WODs/`)
- No external file storage service (S3, GCS, etc.)
- Program and WOD definitions bundled with app binary

**Caching:**
- CloudKit implicit caching (local sync database)
- SwiftData in-memory cache during app session
- HealthKit query results cached by iOS OS

## Authentication & Identity

**Auth Provider:**
- Sign in with Apple (native iOS)
  - Implementation: `SundeeFundee/Auth/AuthService.swift`
  - Credential storage: Keychain
  - No OAuth2 redirect (uses `AuthenticationServices` framework)
  - Generates and stores unique user ID per device

- Guest Mode
  - No authentication required
  - Unique guest user ID generated and stored in UserDefaults
  - Data stored locally, migrated to authenticated account on sign-in

**Sign-in Flow:**
1. User taps "Sign in with Apple" button
2. `ASAuthorizationController` shows Apple sign-in UI
3. Credential received and stored in Keychain
4. User ID used to identify CloudKit private database
5. Subsequent app launches verify credential with Apple

## Monitoring & Observability

**Error Tracking:**
- Not detected in active codebase
- Legacy Swift code had Firestore error logging (see `_legacy-swift/`)

**Logs:**
- SwiftData migration logging: `SundeeFundee/App/AppModelContainer.swift`
- Gemini service HTTP status logging: `SundeeFundee/Repositories/Gemini/GeminiWorkoutService.swift`
- No centralized logging service integrated

**Crash Reporting:**
- Not configured in iOS app
- Legacy code references Firebase Crashlytics (archived)

## CI/CD & Deployment

**Hosting:**
- **iOS**: Apple App Store only
  - Build system: Fastlane + Xcode
  - Signing: Match (certificates from private Git repo)

- **Web (PWA)**: Browser-based, server-agnostic
  - Frontend: Vite + React (static files)
  - Backend: Firebase Firestore + Cloud Functions

- **WOD Dashboard**: Hosted separately (Next.js server)
  - Deployment target: Any Node.js host

**CI Pipeline:**
- GitHub Actions (scripts in `ci_scripts/`)
  - `ci_post_clone.sh` - Post-clone setup
  - `ci_pre_xcodebuild.sh` - Pre-build steps (certificate setup)
  - Fastlane lane `beta` for TestFlight uploads
  - Fastlane lane `tests` for test execution

**Deployment Flow:**
1. Tag repository with `v*` (e.g., `v1.0.0`)
2. GitHub Actions triggers Fastlane `beta` lane
3. Fastlane syncs signing certificates via `match`
4. Fastlane increments build number via App Store API
5. `xcodebuild` creates Release archive
6. Fastlane uploads to TestFlight

## Environment Configuration

**Required env vars (GitHub Secrets):**
- `APPLE_ID` - Apple Developer ID email
- `APPLE_TEAM_ID` - Apple Developer Team ID
- `MATCH_GIT_URL` - Private Git repo URL for code signing certificates
- `MATCH_PASSWORD` - Decryption password for certificates
- `APPLE_KEY_ID` - App Store API key ID
- `APPLE_ISSUER_ID` - App Store API issuer ID
- `APPLE_KEY_CONTENT` - App Store API private key (base64)
- `TESTFLIGHT_NOTES` - Optional: Custom TestFlight build notes

**Secrets location:**
- GitHub Actions Secrets: Used during CI/CD builds
- Keychain: Local user credentials (development)
- CloudKit entitlements: Xcode project settings

**Development Configuration:**
- CloudKit enabled via entitlements: `com.apple.developer.icloud-services`
- HealthKit enabled: `com.apple.developer.healthkit`
- Testing: In-memory SwiftData (no CloudKit required)

## Webhooks & Callbacks

**Incoming:**
- None detected in active codebase
- StoreKit 2 transactions queried directly (no webhooks)

**Outgoing:**
- AI workout generation: POST to Cloudflare Worker proxy
  - URL: `https://workout-proxy.sundeefundee.workers.dev/generate-workout`
  - Body: Encoded `WorkoutGenerationContext` (custom JSON format)
  - Response: `GeneratedWorkout` JSON
  - Timeout: 15 seconds
  - No callback/webhook pattern

## PWA/Dashboard Specific Integrations

**Firebase (PWA only):**
- Package: `firebase` 12.11.0 (in `pwa/package.json`)
- Usage: Authentication, Firestore database
- Not used in native iOS app

**Stripe (PWA only):**
- Package: `@stripe/stripe-js` 8.11.0 (in `pwa/package.json`)
- Purpose: Web payment processing
- Native iOS app uses StoreKit 2 instead

**CloudKit JS (WOD Dashboard):**
- Package: `tsl-apple-cloudkit` 0.2.34 (in `wod-dashboard/package.json`)
- Purpose: Read/write WOD data from dashboard to CloudKit
- Requires CloudKit authentication (Apple ID)

## Data Privacy & Permissions

**Info.plist Permissions:**
- `NSHealthShareUsageDescription` - "Sundee Fundee uses health data to provide cycle-aware training recommendations."
- `NSHealthUpdateUsageDescription` - "Sundee Fundee writes workout data to Apple Health."
- `ITSAppUsesNonExemptEncryption` - false

**StoreKit Configuration:**
- File: `SundeeFundee/Resources/SundeeFundee.storekit`
- Currency: USD
- Storefront: USA
- Subscription groups: `sundee-fundee-premium` (Plus + Pro)
- Family sharing: Not enabled

**Data Consent:**
- AI workout data sharing opt-in: `com.sundeefundee.ai.dataConsent` UserDefault
- Implementation: `SundeeFundee/Features/AIWorkout/` (consent UI before sharing)

---

*Integration audit: 2025-03-21*

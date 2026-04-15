# External Integrations

**Analysis Date:** 2026-04-15

## APIs & External Services

**CloudKit API:**
- Service: Apple CloudKit (private database)
- What it's used for: User data persistence (workouts, cycles, injuries, benchmarks, programs, challenges, settings)
- SDK/Client: Native CloudKit framework + custom `CloudKitClient` actor wrapper
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift`
- Container identifier: `iCloud.com.sundeefundee.app`
- Authentication: Implicit via user's iCloud account (no API key/token needed)

**HealthKit API:**
- Service: Apple HealthKit (read/write health data)
- What it's used for: Reading menstrual cycle phase, writing workout data back to Health app
- SDK/Client: Native HealthKit framework + custom `HealthKitClient` actor wrapper
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/HealthKitClient.swift`
- Auth: Implicit via user permissions granted in Settings > Health > Sundee Fundee
- Entitlements: `com.apple.developer.healthkit` + `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

**Apple Sign-In:**
- Service: Sign in with Apple (authentication)
- What it's used for: User authentication, identity verification, account linking
- SDK/Client: Native AuthenticationServices framework + custom `AppleAuthClient` actor
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Auth/AppleAuthClient.swift`
- Auth: OAuth via user's Apple ID (automatic flow in-app)
- Entitlements: `com.apple.developer.applesignin`

## Data Storage

**Databases:**
- CloudKit (private user database)
  - Connection: `iCloud.com.sundeefundee.app` container, private database scope
  - Client: `CloudKitClient` (actor-based, thread-safe)
  - Query protocol: `DataClientProtocol` (generic Codable fetch/save/delete)
  - Schema defined in: `SundeeFundeeApp/cloudkit-schema.json`
  - Record types: BenchmarkDefinition, BenchmarkResult, Celebration, Challenge, CyclePhaseInfo, EnrolledProgram, Exercise, Injury, OneRepMaxRecord, Program, UserSettings, Workout

**File Storage:**
- Local filesystem only (no remote file storage)
- Guest mode uses `LocalDataClient` with in-memory or file-based cache
- Export feature generates JSON/CSV exports for local download (no cloud backup)

**Caching:**
- `CyclePhaseCache` - In-memory cache of computed cycle phase (invalidates on new data)
- `SyncQueue` - Local queue for offline mutations (replayed when network returns)
- No third-party cache layer (Redis, Memcached, etc.)

## Authentication & Identity

**Auth Provider:** Apple Sign-In only (no Firebase, Auth0, or custom backend)
- Implementation: `AppleAuthClient` actor handles OAuth flow
- Session storage: Keychain via `KeychainHelper`
- User ID: Apple's unique user identifier (persisted in Keychain)
- Email & name: Requested on first sign-in, then cached in CloudKit as `UserSettings`
- Guest mode: Bypass authentication, set `isGuest = true`, use `LocalDataClient` instead of CloudKit

**Session Management:**
- Location: `SundeeFundee/Sources/SundeeFundeeKit/Auth/KeychainHelper.swift`
- Stores: User ID, authentication token (if needed)
- Persistence: Device Keychain (secure, encrypted by OS)
- Expiration: Managed by Apple's Sign-in service; app checks credential state on launch

## Health Data Integration

**HealthKit Permissions:**
- Read: Menstrual cycle phase (for cycle-aware training adaptation)
- Write: Workout data (saved back to user's Health app for continuity with other fitness apps)
- User grants via Settings > Health > Sundee Fundee after sign-in
- No automatic background sync (reads/writes happen during app use only)

**Data Types:**
- HKCategoryTypeIdentifier.menstrualCycle - Read only
- HKWorkoutTypeIdentifier - Write only (active workout activity)

## Monitoring & Observability

**Error Tracking:** None (no Sentry, Crashlytics, or external error service)
- Errors logged locally via `os.log` subsystem: `com.sundeefundee.app`
- Categories: "CloudKit", "AppleAuth", "HealthKit", "DataLayer", "Coach"

**Logs:** 
- Framework: Apple's `os.log` (structured logging)
- Subsystems and categories per module
- Example: `Logger(subsystem: "com.sundeefundee.app", category: "CloudKit")`
- Accessible via Xcode Console during development, device logs for production

**Analytics:** None (no Google Analytics, Mixpanel, or user tracking)
- Privacy-first: no user behavior tracking or telemetry
- Privacy manifest declares no tracking (`NSPrivacyTracking: false`)

## CI/CD & Deployment

**Hosting:** Apple App Store (iOS)
- Bundle ID: `com.sundeefundee.app`
- Team ID: `87VVCMCW3F` (Developer Portal)
- ITC Team ID: `128606738` (App Store Connect)

**CI Pipeline:** Fastlane (no external CI service like GitHub Actions)
- Manual trigger: `cd SundeeFundeeApp && bundle exec fastlane release`
- Steps: Increment build number → Archive → Export → Upload to App Store Connect
- Configuration: `SundeeFundeeApp/fastlane/Appfile`, `Fastfile`, `Deliverfile`

**App Store Submission:**
- Tool: Fastlane + App Store Connect API
- Metadata: Managed in `SundeeFundeeApp/fastlane/metadata/` (synced via `deliver`)
- Screenshots: Managed in `SundeeFundeeApp/fastlane/screenshots/`
- Binary: IPA built by Xcode, uploaded via Fastlane altool or App Store Connect API

## Environment Configuration

**Required env vars:**
- None for production app (all credentials are implicit)
- CloudKit container identifier is hardcoded: `iCloud.com.sundeefundee.app`
- App group identifier is hardcoded: `group.com.sundeefundee.shared` (for widget extension)

**Development env vars (optional, for reference):**
- `.env.local` file exists but is not read by build system
- Used for documentation of deployment URLs, team IDs, etc.

**Secrets location:**
- Apple certificates: Managed via Xcode (automatic signing)
- Sign-in with Apple: Keys managed via App Store Connect (implicit)
- HealthKit: Permissions managed via Settings
- CloudKit: Credentials via user's iCloud account
- No API keys, credentials, or secrets are stored in code or `.env` files

## Webhooks & Callbacks

**Incoming:** None
- No webhook endpoints or external service callbacks

**Outgoing:** None
- App does not send webhooks or notify external services
- CloudKit subscriptions available but not currently used

## App Store Connect Integration

**Metadata Sync:**
- Tool: Fastlane `deliver` action
- Download: `bundle exec fastlane deliver download_metadata`
- Upload: `bundle exec fastlane deliver` (pushes metadata + screenshots)
- Location: `SundeeFundeeApp/fastlane/metadata/`

**Distribution Certificate:**
- Required for App Store export (Apple Distribution certificate)
- Managed via Xcode Accounts > Manage Certificates
- Automatic signing enabled (`CODE_SIGN_STYLE = Automatic`)

**Privacy Policy & Terms:**
- Privacy Policy: Required link in app description (not enforced by app)
- App Tracking Transparency: Not needed (app declares no tracking)

## Network Monitoring

**Connectivity Detection:**
- Framework: Network.framework (`NWPathMonitor`)
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/NetworkMonitor.swift`
- Purpose: Detect when connectivity returns to replay offline mutations
- Triggers: Cellular, WiFi, or other network changes

**Offline Sync:**
- Queue: `SyncQueue` - Local persistence of mutations while offline
- Replay: Automatic when connectivity restored
- Mechanism: Store mutations as JSON, deserialize and retry on network return

## Data Export

**User Data Export:**
- Service: Custom `DataExportService` (domain layer)
- Format: JSON or CSV
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/Export/DataExportService.swift`
- Includes: Workouts, cycles, programs, challenges, settings, benchmark results
- No external service - all processing local, downloads to device

---

*Integration audit: 2026-04-15*

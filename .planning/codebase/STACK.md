# Technology Stack

**Analysis Date:** 2026-04-15

## Languages

**Primary:**
- Swift 6 (strict concurrency mode: `SWIFT_STRICT_CONCURRENCY: complete`) - All app logic, domain layer, data layer, UI
- Objective-C - Minimal system-level integration where Swift bridges aren't sufficient

**Secondary:**
- Ruby - Fastlane build automation (via Gemfile)

## Runtime

**Environment:**
- iOS 18.0 minimum deployment target
- macOS 15.0 (watchOS 11.0 support via Swift Package)
- Xcode 16.0+

**Package Manager:**
- Swift Package Manager (SPM) 6.0
- Lockfile: `SundeeFundee/Package.resolved` (tracks Swift package versions)
- Ruby Bundler (Fastlane dependencies via `Gemfile.lock`)

## Frameworks

**Core:**
- SwiftUI 6 - Native UI framework, views and layout
- Swift Testing + XCTest - Testing framework (see `TESTING.md` for patterns)
- CloudKit - Persistent data storage for signed-in users (private database scope)
- HealthKit - Health data integration (read/write workouts and cycle data)
- AuthenticationServices - Apple Sign-In authentication
- ActivityKit - Live workout activity ring integration
- StoreKit 2 - Subscription management (free tier; no purchases currently)

**Build/Dev:**
- XcodeGen - Project generation from YAML config (`SundeeFundeeApp/project.yml`)
- SwiftLint 0.45+ - Code linting with 45 opt-in rules (config: `.swiftlint.yml`)
- Fastlane - Build automation and App Store submission (config: `SundeeFundeeApp/fastlane/`)

**Charts & Analytics:**
- Charts framework (Apple's SwiftUI charting) - Volume, strength progression, cycle correlation visualizations

**System Frameworks:**
- Foundation - Core utilities, JSON encoding/decoding
- Combine - Reactive programming (older views; being phased toward async/await)
- Security - Keychain access for session tokens
- Network - Network connectivity monitoring in `DataLayer/SyncQueue/NetworkMonitor.swift`
- os.log - Structured logging throughout codebase
- UniformTypeIdentifiers - File type declarations
- UIKit - Limited use; minimal iOS-specific integration

## Key Dependencies

**Critical (included via imports):**
- CloudKit (Apple framework) - User data persistence, requires iCloud container `iCloud.com.sundeefundee.app`
- HealthKit (Apple framework) - Cycle and workout data, requires `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` entitlements
- AuthenticationServices (Apple framework) - Sign in with Apple, requires `com.apple.developer.applesignin` entitlement
- ActivityKit (Apple framework) - Live activity support for active workout tracking
- Network (Apple framework) - Real-time connectivity detection via `NWPathMonitor`

**No external third-party dependencies:**
- `SundeeFundee/Package.swift` has `dependencies: []` - zero external package dependencies
- All persistent storage via CloudKit or local SQLite-like (LocalDataClient mock)
- All authentication via Apple native APIs (no Firebase, Auth0, or third-party auth)
- All networking via CloudKit and HealthKit APIs (no HTTP clients, API SDKs, or backends)

## Configuration

**Environment:**
- `.env.local` file (not read by build system; for development reference only)
- CloudKit container identifier: `iCloud.com.sundeefundee.app` (configured in entitlements)
- App Group identifier: `group.com.sundeefundee.shared` (for widget extension data sharing)

**Build:**
- `SundeeFundeeApp/project.yml` - XcodeGen configuration with deployment targets, signing, entitlements
- `Info.plist` (via `GENERATE_INFOPLIST_FILE: false`) - Manually maintained, includes privacy descriptions
- `SundeeFundee.entitlements` - Declares CloudKit container, HealthKit, Apple Sign-In, app group
- `.swiftlint.yml` - 45 opt-in rules, disables line_length/file_length/nesting for domain logic

**Versioning:**
- Marketing version: `CFBundleShortVersionString` (set via `$(MARKETING_VERSION)` in build settings)
- Build number: `CFBundleVersion` (set via `$(CURRENT_PROJECT_VERSION)`)
- Managed via `agvtool` commands or Fastlane `release` lane

## Platform Requirements

**Development:**
- Xcode 16.0+ (Swift 6 support required)
- iOS Simulator or physical iOS device (iPhone/iPad)
- macOS 13+ to run Xcode and build tools
- Ruby 3.0+ for Fastlane (via Bundler)

**Production:**
- Deployment: Apple App Store (via Fastlane + App Store Connect)
- Signing: Automatic code signing via Xcode team ID `87VVCMCW3F`
- Apple Developer account with team access (App Store Connect team `128606738`)

## Subscription & Monetization

**Approach:** Free app with optional subscription tiers (no enforcement yet)
- Free tier - Limited features, 5 tracked lifts, 1 injury profile
- Plus tier ($2.99/mo) - Unlimited tracking, advanced charts, AI workout builder
- Pro tier ($4.99/mo) - Coach memory, adaptive programming, plateau detection

**Framework:** StoreKit 2 (via `SubscriptionClientProtocol` and `FreeSubscriptionClient`)
- Currently all tiers are free (no paywalls or purchase flows enabled)
- Ready for in-app purchase integration when needed
- See `SundeeFundee/Sources/SundeeFundeeKit/Subscription/` for models

## Data Storage Architecture

**Primary:** CloudKit (for authenticated users)
- Container: `iCloud.com.sundeefundee.app`
- Database scope: Private
- Record types defined in `SundeeFundeeApp/cloudkit-schema.json`
- Records: BenchmarkDefinition, BenchmarkResult, Celebration, Challenge, CyclePhaseInfo, EnrolledProgram, Exercise, Injury, OneRepMaxRecord, Program, UserSettings, Workout
- Encoding: ISO8601 dates (CloudKit stores as STRING, not TIMESTAMP)

**Secondary:** Local storage (guest mode, offline sync queue)
- `LocalDataClient` for guest users with no iCloud
- `SyncQueue` queues mutations offline, replays when connectivity returns

**Session Storage:**
- Keychain via `KeychainHelper` - Apple Sign-In tokens and user IDs

## Privacy & Security

**Privacy Manifest:** `SundeeFundeeApp/SundeeFundee/PrivacyInfo.xcprivacy`
- Declares: Health data (read), Fitness data (read), User ID, Name, Email (all for app functionality, no tracking)
- UserDefaults API access for state persistence

**Security Entitlements:**
- `com.apple.developer.applesignin` - Sign in with Apple
- `com.apple.developer.healthkit` - Health data access (empty required capabilities)
- `com.apple.developer.icloud-services` - CloudKit access
- `com.apple.developer.icloud-container-identifiers` - Private CloudKit container
- `CODE_SIGN_STYLE = Automatic` - Xcode-managed signing (no manual provisioning)

## Build & Release Pipeline

**Build Tool:** XcodeBuild (via Fastlane or manual commands)
```bash
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Linting:** SwiftLint
```bash
swiftlint --config .swiftlint.yml
```

**Release:** Fastlane (`SundeeFundeeApp/fastlane/`)
```bash
cd SundeeFundeeApp
bundle exec fastlane release  # Increment build, archive, upload to ASC
```

**Fastlane Config:**
- `Appfile` - Bundle ID `com.sundeefundee.app`, Apple ID `dustinober@me.com`, team IDs
- `Fastfile` - Release lane definition
- `Deliverfile` - App Store Connect metadata sync

---

*Stack analysis: 2026-04-15*

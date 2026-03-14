# Technology Stack

**Analysis Date:** 2025-03-14

## Languages

**Primary:**
- Swift 6.0 - iOS app, all business logic and UI
- TypeScript 5.9.3 - WOD dashboard (Next.js), CloudKit admin interface

**Secondary:**
- JSON - Data bundling (programs.json, wods.json)
- XML - Configuration (plist files, entitlements)

## Runtime

**Environment:**
- iOS 17.0+ (minimum deployment target)
- Node.js (implied by Next.js 16.1.6)

**Package Managers:**
- CocoaPods - Implied via Xcode project structure (none explicitly listed)
- npm - Used for WOD dashboard (`wod-dashboard/package.json`)
- Lockfile: Swift Package Index (no Podfile detected); npm package-lock.json expected for dashboard

## Frameworks

**Core iOS:**
- SwiftUI - UI framework for all views
- SwiftData - Local data persistence and CloudKit sync
- CloudKit - iCloud sync (Private DB for user data, Public DB for programs/WODs)
- StoreKit 2 - App Store subscription payments (in-app purchases)

**Authentication & Security:**
- AuthenticationServices - Sign in with Apple (ASAuthorizationController, ASAuthorizationAppleIDProvider)
- KeychainHelper (custom wrapper) - Secure credential storage

**Health & Wellness:**
- HealthKit - Read sleep (HKCategoryType.sleepAnalysis), HRV (heartRateVariabilitySDNN), resting heart rate

**Testing:**
- Swift Testing (native Xcode testing framework)
- Xcode unit test target (`SundeeFundeTests`)

**Web Dashboard:**
- Next.js 16.1.6 - React framework for WOD/Program admin dashboard
- React 19.2.3 - UI components
- React DOM 19.2.3 - DOM rendering
- TailwindCSS 4 - Styling (via @tailwindcss/postcss)

## Key Dependencies

**Critical:**
- SwiftData - Manages 18 @Model types, handles migration from V1→V12, CloudKit sync
- CloudKit - Dual database: Private DB (`iCloud.com.sundeefundee.app` private) for user data, Public DB for admin-seeded Programs and WODs
- StoreKit 2 - Validates purchases, manages subscription entitlements, handles transaction verification

**Infrastructure:**
- Cloudflare Worker (external) - `workout-proxy.sundeefundee.workers.dev/generate-workout` proxies Gemini API
- Google Gemini API (via Cloudflare Worker) - `gemini-3.1-flash-lite-preview` model for AI workout generation
- Apple Health - Data read-only integration (HealthKit framework)

**Web Dashboard:**
- tsl-apple-cloudkit (^0.2.34) - CloudKit JS SDK for browser-based admin writes to Public DB
- ESLint 9 - Linting for dashboard code
- Jest 30.2.0 - Testing for dashboard
- ts-jest 29.4.6 - TypeScript + Jest integration

## Configuration

**Environment:**
- Xcode Cloud - CI/CD pipeline (manual trigger via Xcode: Product → Xcode Cloud → Start Build)
- XcodeGen - Project generation from `project.yml` (never edit .xcodeproj directly)
- App Entitlements:
  - **Release** (`SundeeFundee.entitlements`): Sign in with Apple, HealthKit, CloudKit (iCloud.com.sundeefundee.app)
  - **Debug** (`SundeeFundee.Debug.entitlements`): Empty (supports Personal Team signing)

**Build:**
- `project.yml` - Defines targets, dependencies, deployment target (iOS 17.0), signing settings
- `SundeeFundee.storekit` - StoreKit configuration file (subscription products, pricing, trial periods)
- Info.plist - App metadata, HealthKit usage descriptions, UI requirements

**Data Files:**
- `Resources/Programs/programs.json` - Bundled fallback programs (loaded via BundledProgramRepository)
- `Resources/WODs/wods.json` - Bundled WODs (loaded via BundledWODRepository)

## Platform Requirements

**Development:**
- macOS (for Xcode)
- Xcode 16.0 or later
- Apple Developer account (for CloudKit, HealthKit, Sign in with Apple entitlements)
- iPhone 17 Pro simulator or compatible device (iOS 17.0+)

**Production:**
- Apple App Store - App distribution via TestFlight and App Store Connect
- CloudKit infrastructure - iCloud account for users (private database sync)
- StoreKit 2 configured in App Store Connect with subscription products:
  - `com.sundeefundee.plusmonthly` (Plus tier, $4.99/month, 1 AI workout/day)
  - `com.sundeefundee.pro.monthly` (Pro tier, $9.99/month, 3 AI workouts/day)
- Cloudflare Workers - For Gemini API proxy

---

*Stack analysis: 2025-03-14*

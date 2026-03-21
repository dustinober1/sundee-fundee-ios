# Technology Stack

**Analysis Date:** 2025-03-21

## Languages

**Primary:**
- Swift 6.0 - All app source code (`SundeeFundee/`)
- TypeScript/JavaScript - WOD admin dashboard (`wod-dashboard/`) and PWA (`pwa/`)

**Build System:**
- Ruby (Fastlane scripts, `fastlane/`)

## Runtime

**Environment:**
- iOS 17.0+ (iPhone only, portrait orientation)
- Xcode 16.0
- Swift 6.0 with strict concurrency

**Package Manager:**
- Swift Package Manager (SPM) - No external Swift packages currently in use
- Lockfile: Not applicable (SPM uses Package.resolved)

## Frameworks

**Core (iOS):**
- SwiftUI - All UI implementation
- SwiftData - Local persistent storage with CloudKit synchronization (`SundeeFundee/App/`)
- Foundation - Standard library

**Data & Sync:**
- CloudKit - iCloud private database for data persistence and sync across devices
  - Container: `iCloud.com.sundeefundee.app`
  - Entitlements: `com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services`

**Health & Fitness:**
- HealthKit - Reading sleep analysis, heart rate variability (SDNN), resting heart rate
  - Location: `SundeeFundee/Repositories/HealthKit/HealthKitReadinessRepository.swift`
  - Permissions: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

**Subscriptions & Monetization:**
- StoreKit 2 (native Apple in-app purchases)
  - Configuration: `SundeeFundee/Resources/SundeeFundee.storekit`
  - Product IDs: `com.sundeefundee.plusmonthly`, `com.sundeefundee.pro.monthly`
  - Location: `SundeeFundee/Services/SubscriptionService.swift`

**Authentication:**
- AuthenticationServices (Sign in with Apple)
  - Location: `SundeeFundee/Auth/AuthService.swift`
  - Uses Keychain for secure credential storage: `SundeeFundee/Auth/KeychainHelper.swift`

**Testing:**
- XCTest - Native iOS testing framework
- 27+ test suites in `SundeeFundeTests/`

**Build/CI:**
- XcodeGen - Generates `SundeeFundee.xcodeproj` from `project.yml`
- Fastlane - App Store build automation
  - Configuration: `fastlane/Appfile`, `fastlane/Fastfile`

**Web/Dashboard Stack:**
- Next.js 16.1.6 - WOD admin dashboard (`wod-dashboard/`)
- React 19.2.3 - Web framework
- Vite 8.0.1 - PWA build tool (`pwa/`)
- React Router 7.13.1 - PWA routing
- TypeScript 5.9.3 - Type safety

**Web Testing:**
- Vitest 4.1.0 - Unit testing (`pwa/`)
- Jest 30.2.0 - Dashboard testing (`wod-dashboard/`)
- Testing Library (React) 16.3.2 - Component testing

## Key Dependencies

**Critical (iOS):**
- CloudKit framework - Data synchronization backbone
- HealthKit framework - Readiness metrics from Apple Health
- StoreKit 2 - In-app purchase verification and subscription management

**Critical (Web):**
- Firebase 12.11.0 - Firestore authentication and database for PWA/dashboard (`pwa/`)
- Stripe (`@stripe/stripe-js`) - Payment processing for web checkout
- dnd-kit (`@dnd-kit/core`, `@dnd-kit/sortable`) - Drag-and-drop for web UI

**UI & Data (Web):**
- React Router 7.13.1 - Navigation
- Recharts 3.8.0 - Charts and visualization
- react-day-picker 9.14.0 - Date selection
- date-fns 4.1.0 - Date utilities
- jszip 3.10.1 - ZIP file generation (data export)
- vite-plugin-pwa 1.2.0 - PWA capabilities (web push, offline)

**Dashboard-Specific:**
- tsl-apple-cloudkit 0.2.34 - CloudKit JS SDK for WOD management (`wod-dashboard/`)

## Configuration

**Environment (iOS):**
- Managed via Info.plist: `SundeeFundee/Resources/Info.plist`
- Build configuration: `project.yml` (XcodeGen)
- Development entitlements: `SundeeFundee/Resources/SundeeFundee.Debug.entitlements`
- Release entitlements: `SundeeFundee/Resources/SundeeFundee.entitlements`

**Key Configs Required:**
- `DEVELOPMENT_TEAM` - Apple Developer Team ID (87VVCMCW3F)
- `APPLE_ID` - Apple ID for Fastlane (via GitHub Secrets: `APPLE_ID`)
- `APPLE_TEAM_ID` - Team ID for App Store Connect (via `APPLE_TEAM_ID`)
- `MATCH_GIT_URL` - Private Git repo for code signing certificates (via `MATCH_GIT_URL`)
- `MATCH_PASSWORD` - Password for certificates (via `MATCH_PASSWORD`)
- `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_CONTENT` - App Store API credentials

**Build (iOS):**
- `SundeeFundee.xcodeproj` - Generated from `project.yml` via XcodeGen
- Schemes: Debug (with entitlements), Release (App Store distribution)
- Swift version: 6.0 (strict concurrency enforced)

**Build (Web):**
- `vite.config.ts` - Vite configuration for PWA
- `tsconfig.json` - TypeScript config
- `pwa/` - Vite+React PWA build
- `wod-dashboard/` - Next.js dashboard build

## Platform Requirements

**Development:**
- macOS 12.0+ with Xcode 16.0
- Apple Developer Account (for code signing, CloudKit, HealthKit)
- Ruby 2.7+ (for Fastlane)
- Node.js 18+ (for PWA and dashboard development)
- Git (for certificate management via `match`)

**Production:**
- Deployment: iOS App Store only
- CloudKit private database: iCloud.com.sundeefundee.app
- Web dashboard: Hosted separately (Next.js)
- PWA: Browser-based (Firebase + Stripe backend)

**Infrastructure Dependencies:**
- Apple App Store - iOS distribution
- CloudKit (Apple) - Data sync
- HealthKit (Apple) - Health data integration
- StoreKit 2 (Apple) - In-app purchase verification
- Firebase (Google) - PWA/dashboard backend
- Stripe - PWA payment processing
- Cloudflare Worker - AI workout generation proxy (legacy, being replaced)

---

*Stack analysis: 2025-03-21*

# Stack Research

**Domain:** Native iOS + watchOS strength training app with cycle-aware adaptation
**Researched:** 2026-03-18
**Confidence:** HIGH (Apple-first stack, all technologies are Apple system frameworks or well-established tooling)

---

> **Scope note:** The iOS foundation (Swift 6, SwiftUI, SwiftData, CloudKit, StoreKit 2, HealthKit, XcodeGen, Cloudflare Worker) is already validated in the codebase. This document focuses on what needs to be ADDED (watchOS target, APNs) and what needs to be UPDATED or VERIFIED for 2025/2026 standards. Do not re-architect what already works.

---

## Recommended Stack

### Core Technologies (Existing — Validated)

| Technology | Version | Purpose | Status |
|------------|---------|---------|--------|
| Swift | 6.0 | All application code | Validated — already in use |
| SwiftUI | iOS/watchOS 17+/10+ | All UI on both platforms | Validated — no changes needed |
| SwiftData | iOS/watchOS 17+/10+ | Local persistence, 22-model schema at V12 | Validated — CloudKit activation needed |
| CloudKit | System | Private iCloud sync between devices | Validated — disabled in prod, needs activation |
| StoreKit 2 | System (iOS 17+) | In-app subscriptions | Validated — subscription gating exists |
| HealthKit | System | Sleep, HRV, RHR reads on iOS; workout session on watchOS | Partially validated — watch workout session is NEW |
| AuthenticationServices | System | Sign in with Apple | Validated |
| XcodeGen | 2.x (latest) | Project file generation from project.yml | Validated — watchOS target config needs adding |
| Fastlane + Match | Current (2.x) | CI/CD, code signing, App Store submission | Validated — Xcode 16 compatible |

### New Technologies (Must Add for This Milestone)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| WatchKit + SwiftUI App lifecycle | watchOS 10+ | watchOS app target entry point | watchOS 10 uses SwiftUI App protocol (not WKExtensionDelegate); companion target runs on watch hardware |
| HKWorkoutSession (watchOS) | watchOS 10+ | Active workout session on watch | Required for background workout tracking, heart rate, calories; keeps app alive during workout |
| HKLiveWorkoutBuilder (watchOS) | watchOS 10+ | Real-time metric collection during workout | Automatic collection of heart rate, active calories, distance without manual query setup |
| HealthKit mirroring sessions | iOS 17+ / watchOS 10+ | Bidirectional sync between iPhone and Watch during workout | Replaces WatchConnectivity for workout-specific data; built-in sync without manual serialization |
| UserNotifications (UNUserNotificationCenter) | iOS 17+ | Local + remote push notifications | Rest timer countdowns, daily reminders, WOD alerts; APNs registration flow |
| WidgetKit (watchOS complications) | watchOS 9+ | Watch face complications and Smart Stack widgets | Streak display, next workout, cycle phase glance — WidgetKit replaced ClockKit in watchOS 9 |

### Supporting Libraries (Existing — No Changes Needed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Charts (Apple) | System | Data visualization | Workout history, cycle charts, pain trends |
| MetricKit | System | Performance and crash diagnostics | Already wired in MetricsService.swift |
| Security (Keychain) | System | Auth token persistence | Apple user ID storage |
| `SundeeFundeeShared` | Private SPM | Shared domain types between app and watch target | Must be added as dependency to the watchOS target in project.yml |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| XcodeGen | Generates .xcodeproj from project.yml | Add watchOS target section to project.yml; use `platform: watchOS`, `type: application`, `deploymentTarget: "10.0"` |
| Fastlane Match | Code signing and certificate management | Watch app shares parent bundle ID with `.watchkitapp` suffix; Match handles both automatically |
| Swift Testing (WWDC24) | Modern unit test framework | Use for NEW test suites on watchOS target and new iOS features; run alongside existing XCTest suites — they coexist in Xcode 16 |
| XCTest | Existing unit + UI tests | Keep all 71 existing test suites; do not migrate to Swift Testing mid-milestone |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| HealthKit mirroring sessions (watchOS 10) | WatchConnectivity (WCSession) | WatchConnectivity requires manual serialization of every message; HealthKit mirroring handles workout-specific sync automatically and keeps rest timer in sync across devices. Use WatchConnectivity only for non-workout data (settings, preferences). |
| SwiftUI App protocol (watchOS 10+) | WKExtensionDelegate lifecycle | WKExtensionDelegate is the legacy ClockKit-era pattern. watchOS 7+ supports SwiftUI App protocol. watchOS 10 targets should use `@main struct WatchApp: App` — same pattern as the iOS app. |
| WidgetKit for complications | ClockKit (CLKComplication) | ClockKit is deprecated. Apple migrated to WidgetKit in watchOS 9. New complications must use WidgetKit's accessoryCircular, accessoryRectangular, accessoryCorner, accessoryInline families. |
| Local UserNotifications for rest timer | Third-party push SDKs (OneSignal, etc.) | Rest timer countdown is entirely local — no server needed. UNUserNotificationCenter handles local scheduling. Remote notifications (WOD alerts, streak nudges) go through APNs directly; no third-party intermediary needed for an Apple-only app. |
| XCTest + Swift Testing coexistence | Full migration to Swift Testing | Swift Testing (WWDC24) lacks UI testing and performance testing support as of early 2026. Keep XCTest for UI and perf tests; use Swift Testing for new unit tests only. |
| StoreKit 2 native | RevenueCat | Out of scope per PROJECT.md. Apple-only app has no cross-platform subscription complexity that RevenueCat solves. StoreKit 2's `subscriptionStatusTask` modifier and `Transaction.currentEntitlements(for:)` cover all requirements. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| ClockKit / CLKComplication | Deprecated since watchOS 9; removed path in watchOS 10+ | WidgetKit with accessory widget families |
| WKExtensionDelegate for new watchOS code | Legacy pattern from pre-watchOS 7; creates extension lifecycle complexity | SwiftUI `@main` App protocol on watchOS |
| App Groups for iPhone ↔ Watch data sync | App Group containers cannot be shared across devices (only same-device extensions) | CloudKit sync (already in place) + HealthKit mirroring for active workout data |
| Hardcoded subscription tier in UserDefaults on cold launch | Current known bug — subscription cache loaded without server verification | Use `Transaction.currentEntitlements(for:)` async verification on launch |
| Hardcoded Gemini model name string literal | Current known bug — silent breakage if model is renamed | Config constant or remote config value |
| Empty string userID in guest mode | Current known bug — breaks any keyed persistence | Stable UUID stored in Keychain on first launch |
| `@Attribute(.unique)` on CloudKit-synced models | CloudKit does not support atomic uniqueness constraints across devices — sync silently breaks | Use application-layer deduplication logic |
| Ordered relationships in CloudKit-synced SwiftData models | Not supported by CloudKit; causes sync failures | Use sort descriptors at query time |

---

## Stack Patterns by Variant

**watchOS target (workout logging):**
- Use SwiftUI `@main` App protocol — same pattern as iOS app
- Use `HKWorkoutSession` + `HKLiveWorkoutBuilder` for active workout tracking (keeps app in background during workout)
- Use HealthKit mirroring session for iPhone ↔ Watch sync during active workout
- Use WatchConnectivity (`WCSession`) only for non-workout data: syncing user settings (weight unit, cycle phase) from iPhone to Watch on session activation
- Workout data written to HealthKit on Watch, then CloudKit sync handles persistence to SwiftData on iPhone
- Share `SundeeFundeeShared` SPM package as a dependency in XcodeGen watchOS target sources

**Push notifications (APNs):**
- Local notifications only for rest timer and workout reminders (no server round-trip)
- Remote notifications for WOD-of-the-day alerts (server-initiated via Cloudflare Worker or future Cloud Function)
- APNs auth key (.p8) preferred over certificates — tokens don't expire annually
- Register device token in `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`, store in CloudKit private DB user record for server-side delivery

**StoreKit 2 cold launch fix:**
- Do NOT read UserDefaults subscription tier synchronously on launch
- Await `Transaction.currentEntitlements(for:)` in an async Task on app launch
- Use `.subscriptionStatusTask` modifier in SwiftUI for reactive tier updates

**CloudKit production schema deployment:**
- Development schema ≠ Production schema until explicitly deployed via CloudKit Dashboard
- Must deploy schema to production before App Store submission — sync silently fails otherwise
- SwiftData + CloudKit: all model properties must be Optional or have default values; no `.unique` attributes; lightweight migration only once enabled

**Swift 6 concurrency on watchOS:**
- watchOS 10 app target runs the same Swift 6 strict concurrency checks as iOS
- `@MainActor` annotation required on all UI-update paths
- Consider enabling Swift 6.2's `-default-isolation MainActor` compiler flag to reduce annotation noise on new watchOS code (Swift 6.2 released late 2025)
- `@ModelActor` required for background SwiftData operations to avoid context concurrency violations

---

## Version Compatibility

| Component | Minimum Version | Notes |
|-----------|----------------|-------|
| watchOS target | 10.0 | Matches PROJECT.md constraint; SwiftUI App protocol, HealthKit mirroring, WidgetKit complications all available |
| iOS target | 17.0 | Existing constraint; HealthKit mirroring requires iOS 17+ |
| Xcode | 16.0+ | Required for Swift 6 strict concurrency; Apple mandated iOS 18 SDK builds from April 2025 for new submissions |
| Swift | 6.0 | Already in use; Swift 6.2 available with improved concurrency ergonomics if upgrading compiler |
| SwiftData + CloudKit | iOS 17+ / watchOS 10+ | CloudKit sync available on watchOS 10+ — same modelContainer configuration as iOS |
| WidgetKit (complications) | watchOS 9+ | Safe at watchOS 10 deployment target |
| HKWorkoutSession mirroring | iOS 17+ / watchOS 10+ | Both sides required simultaneously |

---

## APNs Setup Requirements

The existing codebase has no APNs infrastructure. The following must be added:

1. **Entitlements:** Add `aps-environment` (`development` / `production`) to both `.entitlements` files
2. **Capability in project.yml:** Add `pushNotifications: true` under target capabilities for the iOS target
3. **APNs Auth Key:** Generate `.p8` key in Apple Developer portal (Keys section); add `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_AUTH_KEY` to GitHub Secrets
4. **Registration flow:** Call `UIApplication.shared.registerForRemoteNotifications()` after `UNUserNotificationCenter` grants permission
5. **Device token storage:** Store token in CloudKit private DB (`users/{appleUserID}/deviceTokens`) for server-side WOD push delivery
6. **Local notification categories:** Define `UNNotificationCategory` for rest timer (with "Skip" action) and workout reminder (with "Start Now" action)

---

## Sources

- Apple Developer Docs: [Running workout sessions](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions) — HKWorkoutSession + mirroring architecture (HIGH confidence)
- Apple Developer Docs: [Creating independent watchOS apps](https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps/) — SwiftUI App protocol for watchOS (HIGH confidence)
- Apple Developer Docs: [TN3157: Updating your watchOS project for SwiftUI and WidgetKit](https://developer.apple.com/documentation/technotes/tn3157-updating-your-watchos-project-for-swiftui-and-widgetkit) — Migration from WKExtensionDelegate (HIGH confidence)
- Apple Developer Docs: [Sending notification requests to APNs](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns) — APNs setup (HIGH confidence)
- [WWDC25: What's new in StoreKit and In-App Purchase](https://developer.apple.com/videos/play/wwdc2025/241/) — StoreKit 2 current best practices (HIGH confidence)
- [WWDC25: Track workouts with HealthKit on iOS and iPadOS](https://developer.apple.com/videos/play/wwdc2025/322/) — HealthKit workout tracking current guidance (HIGH confidence)
- [Sasquatch Studio: Building a Workout App for Apple Watch (March 2025)](https://sasq.ca/blog/2025/3/2/building-a-workout-app-for-apple-watch) — Mirroring session architecture, critical bug in Apple sample code (MEDIUM confidence — single source but recent and specific)
- [fatbobman.com: Key Considerations Before Using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — CloudKit sync limitations and production gotchas (HIGH confidence — matches official Apple forum reports)
- [fatbobman.com: Fixing CloudKit Sync in Production: Deploying Schema](https://fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login/) — Schema deployment requirement (HIGH confidence)
- [Swift 6.2 Released — Swift.org](https://www.swift.org/blog/swift-6.2-released/) — Approachable concurrency, MainActor default isolation (HIGH confidence)
- [avanderlee.com: Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) — Concurrency ergonomics improvements (MEDIUM confidence — verified blog, cross-references swift.org)
- [XcodeGen ProjectSpec docs](https://yonaskolb.github.io/XcodeGen/Docs/ProjectSpec.html) — watchOS target configuration reference (HIGH confidence)
- [Apple Developer Docs: Transferring data with Watch Connectivity](https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity) — WCSession vs mirroring decision (HIGH confidence)

---

*Stack research for: Sundee Fundee — native iOS + watchOS strength training app*
*Researched: 2026-03-18*

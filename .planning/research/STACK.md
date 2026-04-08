# Technology Stack

**Project:** Sundee Fundee (iOS-only)
**Researched:** 2026-04-08

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift** | 6.0 | Core language | Swift 6 introduces complete concurrency checking, enhanced actor isolation, and improved sendability — critical for apps with heavy async operations (CloudKit sync, HealthKit queries, StoreKit transactions) |
| **SwiftUI** | iOS 18+ | UI framework | Native declarative UI, preview support, perfect for apps with custom design systems (Art Deco theme) |
| **Swift Package Manager** | Built-in | Package management | Modern dependency management, native Xcode integration, supports Swift 6 language mode |
| **Xcode** | 16.2+ | IDE | Latest Xcode required for iOS 18 SDK, Swift 6, and enhanced SwiftUI previews |

### Architecture

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift Package** | - | Code organization | Separates domain logic from app target, enables testing without UI dependencies, supports multiple platforms (iOS, macOS, watchOS) |
| **Actor-based concurrency** | Swift 6 | Data layer isolation | CloudKit, HealthKit, and local data access need thread-safe actors — Swift 6's complete concurrency checking prevents data races |
| **Protocol-oriented design** | - | Dependency injection | Enables mocking for tests, supports factory pattern for production vs. Mock implementations (already used in SundeeFundeeKit) |
| **MVVM** | - | UI architecture | Clear separation of views and view models, fits SwiftUI's reactive patterns, testable view models with mocked dependencies |

### Data & Integration

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **CloudKit** | iOS 18+ | Cloud sync | Native Apple sync, no backend costs, works offline, supports private databases + shared records |
| **StoreKit 2** | iOS 15+ | In-app purchases | Modern async/await API, built-in transaction verification, subscription status handling, easier than StoreKit 1 |
| **HealthKit** | iOS 18+ | Health data | Native integration with Apple Health, workout tracking, period tracking data |
| **Keychain Services** | - | Secure storage | Encrypted storage for auth tokens, user session persistence (already used in SundeeFundeeKit) |
| **WidgetKit** | iOS 18+ | Live Activities | Lock screen workout tracking, interactive widgets (already implemented) |

### Testing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **XCTest** | Built-in | Unit testing | Native testing framework, integrates with Xcode, supports Swift 6 concurrency |
| **Swift Package Manager** | Built-in | Test organization | Separate test targets for domain, data, and UI layers, enables fast test runs without app launch |

### CI/CD

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Xcode Cloud** | 2025+ | Continuous integration | Deep Xcode integration, native TestFlight deployment, automatic crash logs, included with Apple Developer Program (25 free hours/month) |
| **GitHub Actions** (alternative) | Latest | Cross-platform CI | Better for complex workflows, cross-platform needs, or teams already invested in GitHub — but requires macOS runner costs |

### Documentation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **DocC** | Swift 5.6+ | Documentation compiler | Generates HTML docs from code comments, integrates with Xcode, perfect for documenting public package APIs |
| **Markdown** | - | README files | Project documentation, setup instructions, contribution guides |

## Repository Structure

```
sundee-fundee/
├── SundeeFundee/                    # Swift Package (domain + data layer)
│   ├── Package.swift                # Package manifest (Swift 6.0, iOS 18+)
│   ├── Sources/
│   │   └── SundeeFundeeKit/
│   │       ├── DomainLayer/         # Pure business logic (no dependencies)
│   │       ├── DataLayer/           # CloudKit, HealthKit, Local actors
│   │       ├── Models/              # Shared data models
│   │       ├── Auth/                # Apple Sign-In, Keychain
│   │       ├── Subscription/        # StoreKit 2 integration
│   │       ├── Activity/            # Live Activities, WidgetKit
│   │       ├── UI/                  # SwiftUI views, view models, theme
│   │       └── Exports.swift        # Public API surface
│   └── Tests/
│       └── SundeeFundeeKitTests/    # Unit tests (domain, data, view models)
├── SundeeFundeeApp/                 # Xcode project (app target)
│   ├── SundeeFundee.xcodeproj/
│   ├── SundeeFundee/
│   │   ├── App.swift                # App entry point
│   │   ├── Info.plist               # App capabilities, permissions
│   │   ├── entitlements.plist       # CloudKit, HealthKit, Widgets
│   │   └── SundeeFundee.xcdatamodeld # (if using Core Data for caching)
│   └── SundeeFundeeWidgets/         # Widget extension
│       └── LiveWorkoutWidget.swift
├── .planning/                       # Project planning docs
│   ├── PROJECT.md
│   └── research/
│       └── STACK.md                 # This file
├── CLAUDE.md                        # Project instructions for Claude
├── README.md                        # Project overview
└── .gitignore
```

## Platform Support

| Platform | Minimum Version | Why |
|----------|-----------------|-----|
| **iOS** | 18.0 | Latest SwiftUI features, complete Swift 6 concurrency support |
| **macOS** | 15.0 | Optional SundeeFundeeKit target for dashboard/admin tools |
| **watchOS** | 11.0 | Future companion app for workout logging (optional) |

## Development Tools

| Tool | Purpose | Why |
|------|---------|-----|
| **Xcode Previews** | UI development | Fast iteration on SwiftUI views without building full app |
| **Swift Package Manager** | Local development | Edit package code and see changes immediately in Xcode project |
| **Instruments** | Performance profiling | CloudKit sync performance, memory usage, CPU profiling |
| **Console.app** | Log debugging | Unified logging for CloudKit, HealthKit, StoreKit issues |
| **Simulator** | Testing | iOS Simulator for most testing, screenshot generation |

## Installation & Setup

### Prerequisites
```bash
# Xcode 16.2+ from Mac App Store
# Apple Developer Account ($99/year) for:
#   - CloudKit container
#   - StoreKit 2 products
#   - TestFlight distribution
#   - Xcode Cloud CI/CD
```

### Project Setup
```bash
# Clone repository
git clone https://github.com/your-org/sundee-fundee.git
cd sundee-fundee

# Open Xcode project
open SundeeFundeeApp/SundeeFundee.xcodeproj

# Build and run (⌘R)
# Tests run with ⌘U
```

### Swift Package Integration
```bash
# Package is already linked in Xcode project
# To add as dependency in another project:
# File > Add Package Dependencies > Select local SundeeFundee/ directory
```

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **CI/CD** | Xcode Cloud | GitHub Actions | Xcode Cloud is native to Apple ecosystem, free tier included, seamless TestFlight integration. GitHub Actions requires macOS runners ($$$), more setup complexity. |
| **Language Mode** | Swift 6 | Swift 5 | Swift 6's complete concurrency checking prevents data races in CloudKit/HealthKit actors. Swift 5 mode would require manual sendability annotations. |
| **UI Framework** | SwiftUI | UIKit | SwiftUI is native for iOS 18+, better for custom design systems, preview support, and declarative state management. UIKit adds boilerplate and doesn't align with modern Apple platforms. |
| **Sync Architecture** | CloudKit | Firebase / Custom backend | CloudKit is free (no server costs), native offline support, no third-party dependencies. Firebase requires ongoing costs, adds Firebase SDK dependency, and is being retired from this project. |
| **Package Manager** | SwiftPM | CocoaPods / Carthage | SwiftPM is native, built into Xcode, supports Swift 6. CocoaPods is Ruby-dependent, slower, and not first-party. Carthage is deprecated. |
| **Concurrency** | Actors (Swift 6) | Dispatch queues / Manual locking | Actors provide compile-time data race safety, automatic serial execution, and work with Swift 6 concurrency checking. Manual thread safety is error-prone and harder to maintain. |

## Why This Stack is "Standard 2025-2026"

**HIGH confidence** — This aligns with Apple's current direction:

1. **Swift 6 is the current stable release** (2024) with complete concurrency checking as the marquee feature
2. **iOS 18 is the latest platform** (2024) with enhanced SwiftUI and HealthKit APIs
3. **Xcode Cloud is Apple's push** for first-party CI/CD, replacing third-party solutions
4. **StoreKit 2 is the modern API** (iOS 15+) replacing StoreKit 1's completion handler patterns
5. **CloudKit is the default** for Apple-native apps without backend costs
6. **Swift Package Manager is the standard** for code organization and distribution

This stack will remain current through 2026 as Swift 6 adoption matures and iOS 18 adoption grows.

## Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `Package.swift` | Swift Package manifest, targets, platforms | `SundeeFundee/Package.swift` |
| `Info.plist` | App capabilities, permissions (HealthKit, CloudKit) | `SundeeFundeeApp/SundeeFundee/Info.plist` |
| `entitlements.plist` | CloudKit container, HealthKit access, App Groups | `SundeeFundeeApp/SundeeFundee.entitlements` |
| `.xcode.env` | Environment variables for Xcode Cloud builds | `SundeeFundeeApp/.xcode.env` |
| `.gitignore` | Excludes build artifacts, user-specific Xcode files | `.gitignore` |

## Environment Variables

**No runtime environment variables needed** — iOS apps use:
- `Info.plist` for static configuration
- Entitlements for capabilities
- App Store Connect for StoreKit product configuration
- CloudKit Console for schema and permissions

**Xcode Cloud environment variables** (auto-injected):
- `CI_XCODE_CLOUD` — Detects CI environment
- `CI_WORKFLOW_ID` — Current workflow identifier
- `CI_BUILD_NUMBER` — Build number for TestFlight

## Sources

**HIGH confidence** — Official sources:
- [Swift.org Documentation](https://www.swift.org/documentation/) — Swift 6 language features, Package Manager
- [Apple Developer Documentation](https://developer.apple.com/documentation/) — Platform SDKs, frameworks
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/cloud) — CI/CD setup
- [Swift Package Manager](https://www.swift.org/documentation/) — Package structure, targets

**MEDIUM confidence** — Verified with existing codebase:
- Current SundeeFundeeKit Package.swift confirms Swift 6.0 and iOS 18+ targets
- Existing architecture follows protocol-oriented, actor-based patterns
- StoreKit 2, CloudKit, and HealthKit already integrated per SundeeFundeeKit structure

**No LOW confidence findings** — All recommendations based on official Apple documentation or verified existing implementation.

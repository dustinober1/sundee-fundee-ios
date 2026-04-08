# Feature Landscape

**Domain:** iOS-only app repository
**Researched:** 2026-04-08

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **README.md** | First thing developers see; explains what the project is and how to use it | Low | Should include project description, features, requirements, installation steps, basic usage, and license info |
| **.gitignore** | Prevents committing generated files, user-specific settings, and build artifacts | Low | Standard Swift/Xcode gitignore patterns: `*.xcodeproj/`, `DerivedData/`, `*.dSYM`, `.swiftpm/` |
| **LICENSE file** | Legal requirement for open source; clarifies usage rights | Low | MIT or Apache 2.0 are standard for iOS projects. Swift packages typically use Apache 2.0 |
| **Package.swift** | Required for Swift Package Manager (SPM) | Low | Defines dependencies, targets, and products. Even if using Xcode project, SPM is modern standard |
| **CHANGELOG.md** | Tracks version history; users and contributors expect it | Medium | Follow [Keep a Changelog](https://keepachangelog.com/) format: Added, Changed, Deprecated, Removed, Fixed, Security |
| **PrivacyInfo.xcprivacy** | Required by Apple for App Store submission (tracks API usage, data collection) | Medium | MUST declare required reason APIs and third-party SDKs. Apps get rejected without it |
| **Unit tests** | Confidence code works; expected for any serious project | Medium | XCTest framework built into Xcode. Domain layer tests are table stakes |
| **.swift-format** | Consistent code formatting; reduces bike-shedding in PRs | Low | Apple's official formatter. Config file enables team-wide consistency |
| **SwiftLint** | Catches common Swift errors and enforces style guidelines | Low | Community standard. Optional but highly recommended. `.swiftlint.yml` config file |
| **CI/CD pipeline** | Automated testing on every PR; prevents broken main branch | High | Xcode Cloud (native) or GitHub Actions (flexible). At minimum: build + test on every commit |
| **Code signing setup** | Required for iOS deployment (certificates, provisioning profiles) | High | Can use automatic code signing (recommended) or manual. Documentation needed |
| **Contributing guidelines** | Sets expectations for contributors; reduces friction | Low | `CONTRIBUTING.md`: how to set up dev environment, coding standards, PR process |
| **Issue templates** | Structured bug reports and feature requests save time | Low | GitHub issue templates (`.github/ISSUE_TEMPLATE/`) ensure required info upfront |
| **PR templates** | Structured PRs with checklists improve review quality | Low | `.github/pull_request_template.md` ensures description, testing, breaking changes noted |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Swift Package structure** (SundeeFundeeKit) | Clean separation: reusable logic vs app target; easier testing and modular design | High | Swift Package (`Package.swift`) separate from Xcode app target. Enables dependency re-use across targets |
| **Live Activity widget** | Dynamic Island/lock screen integration during workouts; modern iOS feature | High | Requires ActivityKit + Widget extension. Differentiates from static workout apps |
| **StoreKit 2 subscriptions** | Native iOS subscriptions (Free/Plus/Premium tiers); modern, type-safe API | High | StoreKit 2 (Swift concurrency) vs legacy StoreKit 1. Better DX and reliability |
| **CloudKit integration** | Native Apple sync; no backend needed; offline-first architecture | High | Protocol-based architecture (sync queue, offline support). Differentiates from Firebase-dependent apps |
| **HealthKit integration** | Reads/writes health data; integrates with Apple Health ecosystem | Medium | Permissions required in `Info.plist`. Privacy manifest must declare HealthKit usage |
| **comprehensive test coverage** | >90% coverage of domain layer; rare in indie apps | Medium | XCTest for unit tests, XCTAssert for assertions. Tests in `__tests__/` directories |
| **Art Deco design system** | Consistent visual language; cream/navy/orange tokens in `AppTheme.swift` | Medium | Centralized design tokens (`.artDecoBackground()` modifier). Helps with UI consistency |
| **Guest mode** | Try before sign-in; reduces friction for new users | Low | Local-only mode bypasses CloudKit writes. Good for testing and onboarding |
| **Domain-driven design** | Pure business logic separate from UI; testable, framework-agnostic | High | Domain layer has zero dependencies. Enables unit testing without mocks |
| **Architecture documentation** | `.planning/codebase/` explains system structure | Medium | Uncommon for small apps but valuable for maintenance and onboarding |
| **Permissive license** | Apache 2.0 or MIT enables community contributions | Low | Allows commercial use, modification, and distribution. Signals open-for-business |

## Anti-Features

Features to explicitly NOT include.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **CocoaPods** | Deprecated in favor of Swift Package Manager; adds Ruby dependency complexity | Use Swift Package Manager (built into Xcode) |
| **Carthage** | Deprecated; manual binary management is pain | Use Swift Package Manager |
| **Firebase SDK** | Adds Google dependencies; not needed for iOS-only app | Use CloudKit (native Apple) for sync/persistence |
| **web-based docs** | Overkill for single-platform app; maintenance burden | Use inline code documentation (`///` comments) + README |
| **Jazzy docs** | Generated docs are rarely kept in sync | Focus on clear code comments and README |
| **Objective-C bridging** | Unnecessary in Swift-only project | Use pure Swift; leverage Swift concurrency |
| **Storyboard/XIB files** | Hard to merge in git; less programmatic control | Use SwiftUI (or UIKit programmatic layout) |
| **UIKit (unless necessary)** | Verbose; SwiftUI is modern default | SwiftUI for new views. UIKit only if SwiftUI can't handle it |
| **Fastlane** | Overkill for solo dev; Ruby dependency hell | Use Xcode Cloud for CI/CD; `xcodebuild` for simple scripts |
| **AppDelegate lifecycle** | Legacy pattern; SwiftUI apps use `App` protocol | Use `@main` struct conforming to `App` |
| **Info.plist key-value sprawl** | Modern Xcode uses targets settings; direct editing error-prone | Use Xcode target settings (General, Build Settings, Signing) |
| **Manual code signing** | Certificates expire; provisioning profile management pain | Use automatic code signing (Xcode manages it) |
| **Multiple Xcode schemes** | Confusing; stick to shared scheme | One shared scheme per project; use arguments for environment variants |
| **Submodules** | Git submodules are pain points | Use Swift Package Manager for dependencies |
| **Custom shell scripts** | Hard to maintain; brittle | Use Swift scripts or built-in Xcode build phases |
| **`.DS_Store` in git** | macOS metadata file; should be gitignored | Add to `.gitignore` |
| `Package.resolved` **NOT committed** | Breaks reproducible builds; SPM needs pinned versions | Commit `Package.resolved` for dependency reproducibility |

## Feature Dependencies

```
Swift Package Manager (Package.swift)
    → Unit tests (XCTest framework)
    → CI/CD (needs buildable targets)

PrivacyInfo.xcprivacy
    → App Store submission (blocked without it)

Code signing setup
    → CI/CD deployment
    → TestFlight beta testing

SwiftLint
    → PR quality (automated style checks)

Contributing guidelines
    → Issue templates
    → PR templates

Domain layer tests
    → CI/CD (tests run on every commit)
```

## MVP Recommendation

For an iOS-only repo cleanup, prioritize:

**Phase 1 - Essential (Day 1)**
1. README.md - Clear project overview
2. .gitignore - Swift/Xcode standard
3. LICENSE - Apache 2.0 or MIT
4. PrivacyInfo.xcprivacy - App Store requirement
5. Unit tests - XCTest for domain layer
6. .swift-format - Code consistency

**Phase 2 - Quality of Life (Week 1)**
7. CHANGELOG.md - Version history
8. Contributing guidelines (CONTRIBUTING.md)
9. Issue/PR templates - `.github/` templates
10. CI/CD pipeline - Xcode Cloud or GitHub Actions (build + test)
11. SwiftLint - Style enforcement (optional but recommended)

**Phase 3 - Polish (Month 1)**
12. Architecture documentation - `.planning/codebase/`
13. Design system docs - Art Deco theme in code comments
14. Migration guide - If anyone is using old codebase

**Defer:**
- Full API documentation (Jazzy): Overkill for single-developer app
- Performance benchmarks: Nice-to-have, not table stakes
-Localization setup: Only if supporting multiple languages
- Accessibility audit: Important for App Store but can be done later

## Sources

**HIGH Confidence (Official Documentation)**
- [Apple Developer Documentation](https://developer.apple.com/documentation/xcode) - Xcode source control guidelines
- [Swift.org - API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) - Official Swift naming conventions

**MEDIUM Confidence (Verified GitHub Repos)**
- [apple/swift-log](https://github.com/apple/swift-log) - Example of well-structured Swift package: README, LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, Package.swift, .swift-format, .gitignore
- [Alamofire/Alamofire](https://github.com/Alamofire/Alamofire) - Popular iOS library: comprehensive README, migration guides, multiple installation methods
- [Kodeco Swift Style Guide](https://github.com/kodecocodes/swift-style-guide) - Industry-standard Swift conventions: naming, spacing, access control, golden path pattern
- [fastlane Documentation](https://docs.fastlane.tools) - CI/CD automation for iOS (but recommended to avoid for solo projects)

**LOW Confidence (Training Data + General Knowledge)**
- iOS app PrivacyInfo.xcprivacy requirements: Apple requires privacy manifests for App Store, but specific requirements evolve. Official docs should be verified.
- Xcode Cloud vs GitHub Actions: General best practices known, but specific 2026 workflows may have changed.
- SwiftLint configuration: Tool exists and is popular, but rule sets and configuration syntax may vary.

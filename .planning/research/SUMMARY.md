# Project Research Summary

**Project:** Sundee Fundee (iOS-only repo transition)
**Domain:** iOS app repository cleanup (multi-platform → iOS-only)
**Researched:** 2026-04-08
**Confidence:** MEDIUM

## Executive Summary

Sundee Fundee is transitioning from a multi-platform codebase (Next.js web app + Firebase + iOS) to an iOS-only repository. The iOS app is a native Swift/SwiftUI application using CloudKit for persistence, StoreKit 2 for subscriptions, and HealthKit for workout data. The research reveals this is a straightforward repository cleanup project with well-established iOS patterns. The recommended approach is to archive the existing multi-platform state, remove all web/backend directories and configuration, and consolidate around the existing SundeeFundeeKit Swift Package and SundeeFundeeApp Xcode project.

The key risk is cross-reference blindness: iOS code or documentation may reference deleted files through imports, configuration, or documentation. Prevention requires a comprehensive dependency audit before deletion, tagging the pre-cleanup state in git, and updating all documentation in the same commit as deletions. The research indicates this is a low-complexity cleanup with HIGH confidence on the iOS stack (Swift 6, SwiftUI, CloudKit are all standard 2025-2026 technologies) but MEDIUM confidence on repository transition patterns, as authoritative sources on platform retirement were sparse.

## Key Findings

### Recommended Stack

The iOS codebase already follows modern best practices. Swift 6 with complete concurrency checking is the current stable release (2024) and critical for apps with heavy async operations (CloudKit sync, HealthKit queries). SwiftUI + iOS 18 provides native declarative UI with preview support, perfect for apps with custom design systems. Swift Package Manager separates domain logic from app target, enabling independent testing. CloudKit provides native Apple sync with no backend costs, while StoreKit 2 offers modern async/await APIs for subscriptions.

**Core technologies:**
- **Swift 6** — Core language with complete concurrency checking, prevents data races in CloudKit/HealthKit actors
- **SwiftUI (iOS 18+)** — Native declarative UI, preview support, fits custom Art Deco design system
- **Swift Package Manager** — Modern dependency management, separates SundeeFundeeKit from app target
- **CloudKit** — Native Apple sync, no backend costs, offline-first architecture
- **StoreKit 2** — Modern async/await API for subscriptions, better than StoreKit 1
- **XcodeGen** — Generate Xcode project from YAML, avoid merge conflicts in .pbxproj

### Expected Features

**Must have (table stakes):**
- **README.md** — First thing developers see; explains project overview, setup, features
- **.gitignore** — Prevents committing Xcode build artifacts (DerivedData/, *.xcuserstate)
- **LICENSE file** — Apache 2.0 or MIT for open source; clarifies usage rights
- **PrivacyInfo.xcprivacy** — Required by Apple for App Store submission; declares API usage
- **Unit tests (XCTest)** — Confidence code works; expected for any serious iOS project
- **.swift-format** — Consistent code formatting; reduces bike-shedding in PRs

**Should have (competitive):**
- **Swift Package structure (SundeeFundeeKit)** — Clean separation: reusable logic vs app target; easier testing
- **Live Activity widget** — Dynamic Island/lock screen integration during workouts; modern iOS feature
- **StoreKit 2 subscriptions** — Native iOS subscriptions (Free/Plus/Premium tiers); modern, type-safe API
- **CloudKit integration** — Native Apple sync; no backend needed; offline-first architecture
- **HealthKit integration** — Reads/writes health data; integrates with Apple Health ecosystem
- **Domain-driven design** — Pure business logic separate from UI; testable, framework-agnostic

**Defer (v2+):**
- **Full API documentation (Jazzy)** — Overkill for single-developer app; use inline code comments
- **Performance benchmarks** — Nice-to-have, not table stakes
- **Localization setup** — Only if supporting multiple languages

### Architecture Approach

The recommended architecture maintains the existing SundeeFundeeKit (Swift Package) + SundeeFundeeApp (Xcode project) structure. The Swift Package contains pure business logic, domain models, data layer, auth, subscriptions, HealthKit, and CloudKit integration. The Xcode project contains SwiftUI views, view models, app lifecycle, and Live Activities. Data flow is unidirectional: User Interaction → View Model → Domain Layer → Data Layer → CloudKit/HealthKit/Keychain. The domain layer is pure Swift with no framework dependencies.

**Major components:**
1. **SundeeFundeeKit (Swift Package)** — Pure business logic, domain models, data layer, auth, subscriptions; communicates with Xcode targets via local package dependency
2. **SundeeFundeeApp (App Target)** — SwiftUI views, view models, app lifecycle, Live Activities; imports SundeeFundeeKit
3. **SundeeFundeeWidgets (Widget Extension)** — Live Activity widget for workout tracking; imports SundeeFundeeKit
4. **project.yml (XcodeGen)** — Declares local package reference ../SundeeFundee, generates Xcode project

### Critical Pitfalls

**Top 5 pitfalls from research:**

1. **Cross-Reference Blindness** — iOS code or documentation references deleted files through imports, configuration, or docs. Prevention: Before deletion, create comprehensive dependency map by grepping for references to web-app/, firebase/, backend/ in iOS code. Update docs before deleting code. Verify iOS builds independently before committing deletions.

2. **Git History Orphaning** — Large-scale deletion makes git history difficult to navigate. Prevention: Create navigable archive before deletion (zip entire repo, tag pre-cleanup commit). Document archive location in CLAUDE.md. Use detailed commit messages explaining what was deleted and why.

3. **Configuration Drift** — Root-level configs (firebase.json, firestore.indexes.json, wrangler.toml, package.json) remain after cleanup, confusing future contributors. Prevention: Audit all root-level configs before cleanup. Delete platform-specific configs. Update .gitignore to remove web-specific entries and add iOS-specific ignores.

4. **Documentation Staleness** — CLAUDE.md, README, and other docs still reference web app, Firebase, Stripe, and deleted components. Prevention: Audit all documentation before deletion. Update docs in same commit as deletions. Rewrite CLAUDE.md to describe iOS-only architecture. Verify all commands in CLAUDE.md work after cleanup.

5. **Breaking Relative Imports** — Swift files or Package.swift reference code in deleted directories. Prevention: Before deletion, check Swift Package dependencies for local path dependencies. Search for imports outside the Swift Package. Test build before deletion: `xcodebuild -scheme SundeeFundee build`.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Archive & Delete
**Rationale:** Must create permanent archive and dependency audit before any deletions to prevent data loss and build failures. This is the critical foundation phase.
**Delivers:** Archived multi-platform state, cleaned repository with iOS-only directories, updated .gitignore, removed root-level configs
**Addresses:** Table stakes features (README.md, .gitignore, LICENSE, PrivacyInfo.xcprivacy)
**Avoids:** Cross-reference blindness, git history orphaning, configuration drift

### Phase 2: Documentation Updates
**Rationale:** Documentation must reflect iOS-only architecture to prevent confusion for future contributors. Cannot be done until Phase 1 completes because docs reference deleted paths.
**Delivers:** Updated README.md (iOS stack only), rewritten CLAUDE.md (iOS-only context), removed web/Firebase/Stripe references, MIGRATION.md explaining platform transition
**Uses:** Swift Package Manager structure from STACK.md
**Implements:** Architecture documentation approach

### Phase 3: Verification & CI/CD
**Rationale:** Must verify iOS app builds and tests pass after cleanup, then replace Node-based CI with iOS CI. Cannot run CI until Phase 1-2 complete because repo structure changes.
**Delivers:** Verified iOS build, passing unit tests, GitHub Actions workflow for iOS (swift test, xcodebuild test), clean git history with detailed commit messages
**Uses:** XCTest from STACK.md, Xcode build system from ARCHITECTURE.md
**Avoids:** Breaking relative imports, lost context in git commits

### Phase 4: Quality of Life (Optional)
**Rationale:** Polish improvements that enhance developer experience but aren't critical for repo functionality. Can be deferred post-cleanup.
**Delivers:** CHANGELOG.md, CONTRIBUTING.md, issue/PR templates, SwiftLint configuration, architecture documentation in docs/
**Uses:** .swift-format from FEATURES.md, documentation strategy from ARCHITECTURE.md

### Phase Ordering Rationale

- **Phase 1 first** because deletion is destructive and must be done carefully with proper archiving and dependency auditing. Cannot update docs or verify builds until deletion completes.
- **Phase 2 second** because documentation updates depend on Phase 1 completion (docs reference deleted paths). Verification in Phase 3 depends on accurate docs.
- **Phase 3 third** because CI/CD and verification require stable repo structure from Phases 1-2. Cannot test until deletion and doc updates complete.
- **Phase 4 last** because quality-of-life improvements are optional and don't block core functionality. Can be iterated on post-launch.

This ordering follows the dependency graph: Archive → Delete → Update Docs → Verify → Add Polish.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (CI/CD):** Need to research GitHub Actions for macOS runners, TestFlight automation, and iOS-specific CI patterns. Current research identifies this as a gap (LOW confidence on specific workflows).
- **Phase 4 (Quality of Life):** SwiftLint configuration and rule sets may vary. Should validate against Swift 6 language mode.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Archive & Delete):** Standard git operations and file deletion. Well-established patterns. HIGH confidence.
- **Phase 2 (Documentation Updates):** Markdown documentation updates. No specialized knowledge needed. HIGH confidence.
- **Phase 3 (Verification):** XCTest and xcodebuild are standard iOS tools. Official documentation is comprehensive. HIGH confidence.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified with official Apple documentation (Swift 6, SwiftUI, CloudKit, StoreKit 2). All technologies are standard 2025-2026 iOS stack. |
| Features | MEDIUM | Table stakes features based on iOS community standards (apple/swift-log, Alamofire repos). Differentiators are established iOS patterns. Some sources were MEDIUM confidence (GitHub repos vs. official docs). |
| Architecture | HIGH | Current SundeeFundeeKit structure follows Apple's recommended Swift Package patterns. Protocol-oriented design and MVVM are well-documented. XcodeGen is established tool. |
| Pitfalls | LOW-MEDIUM | Specific authoritative sources on repository cleanup and platform transition were sparse. Recommendations based on general software engineering principles, Git best practices, and common patterns. Some pitfalls inferred from first principles rather than verified sources. |

**Overall confidence:** MEDIUM. Stack and architecture are HIGH confidence (aligned with official Apple documentation). Features are MEDIUM confidence (based on established community patterns). Pitfalls are LOW-MEDIUM confidence (lack of specific authoritative sources on platform retirement, though recommendations are sound).

### Gaps to Address

- **CI/CD for iOS:** Research GitHub Actions for macOS runners, TestFlight automation, and iOS-specific CI workflows. Current research identifies this as LOW confidence. Consider Xcode Cloud as alternative (native to Apple ecosystem, free tier included).
- **App Store screenshot automation:** Current Python script workflow should be validated as best practice. Research if Fastlane or Xcode Cloud offers better solution.
- **SwiftLint configuration:** Validate SwiftLint rules against Swift 6 language mode. Some rules may conflict with new concurrency features.
- **Widget extension testing:** How to unit test Live Activity widgets. Not well-documented in current research.
- **CloudKit testing:** Best practices for mocking CloudKit in unit tests. Gap in current research.

## Sources

### Primary (HIGH confidence)
- [Swift.org Documentation](https://www.swift.org/documentation/) — Swift 6 language features, Package Manager, concurrency checking
- [Apple Developer Documentation](https://developer.apple.com/documentation/) — Platform SDKs, frameworks (SwiftUI, CloudKit, HealthKit, StoreKit 2)
- [XcodeGen GitHub](https://github.com/yonaskolb/XcodeGen) — Project specification format, build system
- [swift.org/package-manager](https://swift.org/package-manager/) — Official SPM documentation
- [apple/swift-log GitHub repo](https://github.com/apple/swift-log) — Example of well-structured Swift package (README, LICENSE, CONTRIBUTING.md, .swift-format, .gitignore)

### Secondary (MEDIUM confidence)
- [Alamofire/Alamofire GitHub repo](https://github.com/Alamofire/Alamofire) — Popular iOS library demonstrating comprehensive README, migration guides
- [Kodeco Swift Style Guide](https://github.com/kodecocodes/swift-style-guide) — Industry-standard Swift conventions (naming, spacing, access control)
- WWDC sessions "Protocol-Oriented Programming in Swift" (2015+) — Established patterns for protocol-based design
- [Atlassian Git Tutorial](https://www.atlassian.com/git/tutorials/undoing-changes/git-clean) — Authoritative source on Git commands for cleanup

### Tertiary (LOW confidence)
- Repository management best practices — General software engineering knowledge, not tied to specific sources
- Platform migration common issues — General experience with platform retirement projects
- Specific CI/CD workflows for iOS — Need validation through additional sources
- App Store release automation — Fastlane vs. Xcode Cloud vs. custom scripts (gap identified)

---
*Research completed: 2026-04-08*
*Ready for roadmap: yes*

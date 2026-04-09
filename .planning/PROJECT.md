# Sundee Fundee — Project

## What This Is

Sundee Fundee is a native iOS app for cycle-aware strength training. Built with SwiftUI and Swift 6 (strict concurrency), using CloudKit for persistence, StoreKit 2 for subscriptions, and HealthKit for health data. The app uses an Art Deco design theme (cream/navy/orange).

The repository is now iOS-only — all web app (Next.js PWA), Firebase, and backend code has been archived and removed. Only the Swift Package (SundeeFundeeKit) and Xcode project (SundeeFundeeApp) remain.

## Core Value

A clean, iOS-only repository with updated docs reflecting the native-only direction.

## Requirements

### Validated

- ✓ Archive all non-iOS files into dated zip — v1.0 (sundee-fundee-archive-2026-04-08.zip)
- ✓ Delete all archived files from the repo — v1.0 (web-app, firebase, wod-dashboard, backend, scripts, screenshots, docs, plans, .agents, root configs all removed)
- ✓ Update CLAUDE.md to reflect iOS-only project — v1.0 (no web/Firebase/Stripe/Cloud Functions references)
- ✓ Update README for iOS-only repo — v1.0 (setup instructions, architecture description)
- ✓ Clean up root-level config files — v1.0 (firebase.json, firestore.indexes.json, wrangler.toml, package.json all removed)
- ✓ Update .gitignore to iOS-only patterns — v1.0 (no Node.js/Firebase/web entries)
- ✓ Verify Xcode project builds after cleanup — v1.0 (all tests passing)
- ✓ Create MIGRATION.md documenting transition — v1.0
- ✓ Create CHANGELOG.md in Keep a Changelog format — v1.0
- ✓ Configure SwiftLint with project-specific rules — v1.0 (.swiftlint.yml with Swift 6 rules)
- ✓ iOS app with full feature set — SundeeFundeeKit Swift Package
- ✓ Xcode project builds and runs — SundeeFundeeApp target
- ✓ Apple Sign-In auth with guest mode — Keychain session, CloudKit sync
- ✓ StoreKit 2 subscriptions — Free/Plus/Premium tiers
- ✓ CloudKit data persistence — Protocol-based with offline sync queue

### Active

(No active requirements — milestone v1.0 complete)

### Out of Scope

- New iOS features or improvements — this was cleanup only
- Database migration — CloudKit data is independent of Firestore
- CI/CD pipeline setup — deferred to future work
- App Store submission preparation — out of scope for cleanup

## Context

- Repository is now iOS-only: SundeeFundee/ (Swift Package) + SundeeFundeeApp/ (Xcode project)
- 27,077 lines of Swift code across domain logic, UI, auth, subscriptions, and data layers
- All retired web code archived in sundee-fundee-archive-2026-04-08.zip at repo root
- MIGRATION.md documents the web-to-iOS transition for historical reference
- 60 unit tests passing, Xcode project builds cleanly
- Art Deco design: cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`
- Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (numbers)

## Constraints

- **iOS-only:** Only SundeeFundee/ and SundeeFundeeApp/ directories in repo
- **Archive preserved:** sundee-fundee-archive-2026-04-08.zip at repo root
- **Build integrity:** Xcode project must build after any changes

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Zip + delete (not archive branch) | User wants a clean repo with zip backup, not git history complexity | ✓ Good — simple and effective |
| Keep only iOS-native code | PWA is retired; no other platforms planned | ✓ Good — clean focus |
| Update docs to match new state | Stale web-app docs would be confusing going forward | ✓ Good — all docs updated |
| Move archive ref to CLAUDE.md + MIGRATION.md | Discoverability across both reference docs | ✓ Good — dual reference |

---
*Last updated: 2026-04-08 after v1.0 milestone completion*

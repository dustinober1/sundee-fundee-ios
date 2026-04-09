# Sundee Fundee — Repo Cleanup

## What This Is

Sundee Fundee is a cycle-aware strength training app for iPhone. The PWA (Next.js web app) is being retired in favor of the native iOS app. This project cleans up the repository to contain only the Apple-native codebase — the Swift Package (SundeeFundeeKit) and Xcode project (SundeeFundeeApp) — by archiving all other files into a zip and removing them.

## Core Value

A clean, iOS-only repository with no web app remnants, updated docs reflecting the native-only direction.

## Requirements

### Validated

- ✓ iOS app with full feature set — SundeeFundeeKit Swift Package (domain logic, views, viewmodels, auth, CloudKit, StoreKit 2, HealthKit)
- ✓ Xcode project builds and runs — SundeeFundeeApp target with shared scheme
- ✓ Apple Sign-In auth with guest mode — Keychain session, CloudKit sync, local fallback
- ✓ StoreKit 2 subscriptions — Free/Plus/Premium tiers
- ✓ CloudKit data persistence — Protocol-based architecture with offline sync queue
- ✓ Unit tests — Domain, model, data layer, auth, viewmodel, and activity tests
- ✓ Art Deco theme — Cream/navy/orange design tokens in AppTheme.swift
- ✓ Live Activity widget — Workout tracking via Live Activity
- ✓ Domain logic mirrors web — Cycle calculations, injury adaptation, benchmarks, programs, AI workout, coach, intelligence

### Active

- [ ] Archive all non-iOS files into a zip (web-app/, firebase/, wod-dashboard/, backend/, scripts/, screenshots/, content/, docs/, plans/, .agents/, root config files)
- [ ] Delete all archived files from the repo
- [ ] Update CLAUDE.md to reflect iOS-only project (remove all web app, Firebase, Stripe, Cloud Functions references)
- [ ] Update README (or create one) for the iOS-only repo
- [ ] Clean up root-level config files that are no longer relevant (firebase.json, firestore.indexes.json, wrangler.toml, root package.json, etc.)
- [ ] Update .gitignore to remove web-specific entries and add any needed iOS-only entries
- [ ] Verify the Xcode project still builds after cleanup

### Out of Scope

- New iOS features or improvements — this is cleanup only
- Migration of any web-specific logic to iOS — the iOS app already has its own domain layer
- Database migration — CloudKit data is independent of Firestore
- Keeping the PWA running in any form — it's going away entirely

## Context

- The Sundee Fundee iOS app is complete and ready for App Store release
- The web app (Next.js PWA) served as the initial product but is being retired
- Firebase (Auth, Firestore, Cloud Functions) was the web backend; iOS uses Apple Sign-In + CloudKit
- The repo currently contains both platforms plus shared tooling (scripts, WOD dashboard, etc.)
- The user wants a zip archive of all removed files before deletion (backup)
- Art Deco design: cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`

## Constraints

- **Preserve:** Only `SundeeFundee/` and `SundeeFundeeApp/` directories remain
- **Backup:** All removed files must be zipped first before deletion
- **No data loss:** The zip serves as the archive of all web/Firebase/backend code
- **Build integrity:** Xcode project must still build after cleanup

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Zip + delete (not archive branch) | User wants a clean repo with zip backup, not git history complexity | — Pending |
| Keep only iOS-native code | PWA is retired; no other platforms planned | — Pending |
| Update docs to match new state | Stale web-app docs would be confusing going forward | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-08 after initialization*

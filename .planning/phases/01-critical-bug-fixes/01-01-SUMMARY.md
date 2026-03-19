---
phase: 01-critical-bug-fixes
plan: "01"
subsystem: app-initialization
tags: [swiftdata, migration, subscriptions, storekit]
dependency_graph:
  requires: []
  provides: [stable-local-persistent-store, safe-subscription-init]
  affects: [AppModelContainer, SubscriptionService]
tech_stack:
  added: []
  patterns: [SwiftData migration plan, StoreKit-as-source-of-truth]
key_files:
  created: []
  modified:
    - SundeeFundee/App/AppModelContainer.swift
    - SundeeFundee/Services/SubscriptionService.swift
    - SundeeFundeTests/SubscriptionServiceTests.swift
decisions:
  - "FIX-05: migrationPlan applied to both .cloudKit and .localPersistent store paths — they must be symmetric or migrations silently skip the local path"
  - "FIX-04: init() defaults to .free only; UserDefaults cache read removed — StoreKit loadStatus() is the single verified source of truth"
metrics:
  duration_seconds: 58
  completed_date: "2026-03-19"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
requirements_satisfied:
  - FIX-04
  - FIX-05
---

# Phase 01 Plan 01: App Initialization Bug Fixes Summary

**One-liner:** SwiftData migration plan wired to local persistent store; SubscriptionService init hardened to always default to .free tier with StoreKit as sole verification source.

## What Was Built

Fixed two app initialization correctness bugs affecting cold launch behavior:

1. **FIX-05 (AppModelContainer):** The `.localPersistent` store path in `makeContainer(for:)` was missing the `migrationPlan:` parameter that the `.cloudKit` path already had. Without it, SwiftData silently skips all schema migrations on local store path, which can corrupt or crash the app when the schema version advances.

2. **FIX-04 (SubscriptionService):** The `init()` was reading a cached `SubscriptionTier` raw value from `UserDefaults` and immediately setting `currentTier` before StoreKit verification. This created a window where a user with a cached premium value appeared premium on cold launch before any StoreKit receipt check, even if the subscription had lapsed.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add migrationPlan to localPersistent store path (FIX-05) | 5518a48 |
| 2 | Remove UserDefaults tier cache from SubscriptionService init (FIX-04) | b902dc5 |

## Changes Made

### SundeeFundee/App/AppModelContainer.swift

**Line 96:** Added `migrationPlan: AppSchemaMigrationPlan.self` to the `.localPersistent` case in `makeContainer(for:)`. Now matches the `.cloudKit` case on line 93.

```swift
// Before
return try ModelContainer(for: schema, configurations: [localConfig])

// After
return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
```

### SundeeFundee/Services/SubscriptionService.swift

**init():** Removed `UserDefaults.standard.string(forKey: Self.tierKey)` read. `currentTier` now defaults to `.free` from its property declaration. Only `startObservingTransactions()` is called in `init()`.

```swift
// Before
init() {
    let raw = UserDefaults.standard.string(forKey: Self.tierKey) ?? "free"
    self.currentTier = SubscriptionTier(rawValue: raw) ?? .free
    startObservingTransactions()
}

// After
init() {
    // currentTier starts as .free from property declaration default.
    // StoreKit verification via loadStatus() is the single source of truth.
    startObservingTransactions()
}
```

Note: `UserDefaults.standard.set(tier.rawValue, ...)` write in `setTier(_:)` is retained for analytics/non-gating purposes as specified.

### SundeeFundeTests/SubscriptionServiceTests.swift

Deleted `restoresTierFromUserDefaults` test that validated the now-removed behavior of reading cached tier from UserDefaults on init. The `defaultsToFree`, `isPremiumTrueForPlus`, and `isPremiumTrueForPro` tests are unchanged and continue to validate correct behavior.

## Verification

- `grep -n "migrationPlan" SundeeFundee/App/AppModelContainer.swift | wc -l` → **2** (was 1 before fix)
- `grep -n "UserDefaults" SundeeFundee/Services/SubscriptionService.swift` → only line 141 (write path in `setTier`), NOT in `init()`
- `restoresTierFromUserDefaults` test removed; remaining 3 SubscriptionService tests unaffected

## Deviations from Plan

The plan referenced `_legacy-swift/` paths (e.g., `_legacy-swift/SundeeFundee/App/AppModelContainer.swift`), but the active Swift codebase is at the repo root (`SundeeFundee/App/AppModelContainer.swift`). All changes were applied to the correct root-level paths. The `_legacy-swift/` directory does not exist — those are deleted/staged files in git status from a previous restructure.

No other deviations. Plan executed as written with path correction.

## Self-Check: PASSED

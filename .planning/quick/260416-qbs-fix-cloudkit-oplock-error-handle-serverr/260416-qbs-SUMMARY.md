---
quick_id: 260416-qbs
status: complete
date: 2026-04-16
commits:
  - 0677c4ab
  - 292986a9
---

# Quick Task 260416-qbs — Fix CloudKit oplock error

## Problem

Users on multi-device iCloud accounts were hitting a user-visible alert:

> Failed to save settings: Network error: Error saving record <CKRecordID: ...; recordName=user_settings, zoneID=_defaultZone:__defaultOwner__> to server: client oplock error updating record

Two compounding root causes:

1. **No conflict handling in `CloudKitClient.save()`** — when the server had a newer `recordChangeTag` than our in-memory record, CloudKit rejected the save with `CKError.serverRecordChanged` and we surfaced the raw error to the user.
2. **Race in `SettingsView.saveSettings()`** — four `.onChange` handlers (weightUnit, experienceLevel, primaryGoal, cycleTrackingEnabled) each spawned independent `Task { await viewModel.saveSettings() }` calls. Rapid toggles created parallel in-flight saves racing each other to the server.

## Changes

### Task 1 — CloudKit conflict handling (`0677c4ab`)

**File:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift` (+227/−31)

- Added private helpers: `isServerRecordChangedError`, `perItemErrors`, `extractServerRecords`, `mergeWithServerRecords`, `retryModifyRecords`
- On `CKError.serverRecordChanged` (both per-record and batch-level `CKError.partialFailure` wrapping), extract the server's authoritative record from `CKRecordChangedErrorServerRecordKey` in `userInfo`, re-apply our Codable payload onto it (preserving the server's changeTag), and retry the save exactly once.
- Applied to both `save()` and `saveFromJSON()` — SyncQueue replay is especially prone to stale changeTags after offline periods.
- Existing duplicate-on-insert merge path preserved.
- Bounded: exactly one retry, then throws via existing `mapCKError`.

### Task 2 — SettingsViewModel save serialization (`292986a9`)

**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift` (+45/−12)

- Added `private var saveTask: Task<Void, Never>?` handle on `SettingsViewModel`.
- Rewrote `saveSettings()` as cancel-and-replace with a 150ms coalescing window: rapid toggles across the four controls collapse to a single network write reflecting the final state.
- The `.onChange` handlers at [SettingsView.swift:90-93](../../../SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift) are unchanged — cancellation is internal to the view model.
- Late-cancellation checks avoid clobbering `errorMessage`/`isSaving` after supersession.

## Verification

- `xcodebuild` iPhone 17 Pro simulator: **BUILD SUCCEEDED** (zero new errors, zero new Swift 6 warnings)
- `swift test` full suite: 86 Swift Testing tests pass; XCTest suites pass (DataErrorTests 8/8, MockCloudKitClientUpsertTests 4/4)
- Swift 6 strict concurrency: `CloudKitClient` actor isolation preserved; `@MainActor` preserved on view model.
- CloudKit schema rules (CLAUDE.md) honored — `UserSettingsRecord` Bool-as-Int64 decoder untouched.

## Notes

- Debouncing is belt-and-suspenders. The CloudKit conflict handler is the primary defense — multi-device iCloud races can still occur even with perfectly serialized single-device writes (e.g. iPhone + iPad editing simultaneously).
- Non-duplicate, non-serverRecordChanged per-record failures route through the existing `mapCKError(error, recordID:)` path to preserve the existing `DataError` taxonomy.

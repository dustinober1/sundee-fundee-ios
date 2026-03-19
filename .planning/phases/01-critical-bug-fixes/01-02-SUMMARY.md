---
phase: 01-critical-bug-fixes
plan: 02
subsystem: auth
tags: [fix, sign-out, delete-account, guest-mode, keychain, migration, swiftdata]
dependency_graph:
  requires: []
  provides: [guest-uuid-stable, sign-out-scoped-wipe, delete-account-v12-wipe, guest-to-apple-migration]
  affects: [AppState, AuthService, KeychainHelper, AppAuthCoverageTests]
tech_stack:
  added: []
  patterns: [flag-based-retry, batch-swiftdata-update, keychain-stable-uuid]
key_files:
  created: []
  modified:
    - SundeeFundee/App/AppState.swift
    - SundeeFundee/Auth/KeychainHelper.swift
    - SundeeFundee/Auth/AuthService.swift
    - SundeeFundeTests/AppAuthCoverageTests.swift
decisions:
  - "signOut() uses a scoped model list (workout data only) — User/CycleSettings/BarbellPreset/ExerciseBarMapping and other preference models are preserved"
  - "deleteAccountAndData() uses AppSchemaV12.models for full wipe — removes stale V10 reference"
  - "Guest UUID stored in Keychain via new KeychainHelper.saveGuestUserID/loadGuestUserID/deleteGuestUserID methods"
  - "Batch migration uses flag-based retry: guestMigrationPending set before start, cleared on success, restoreSession retries if flag still set"
  - "AuthService.Dependencies adds loadGuestUserID/deleteGuestUserID with default no-op values to preserve backward-compatibility with all existing test call sites"
metrics:
  duration_minutes: 11
  completed_date: "2026-03-19"
  tasks_completed: 2
  files_modified: 4
requirements: [FIX-02, FIX-03]
---

# Phase 1 Plan 2: Sign-Out/Delete Schema Fix and Guest UUID Migration Summary

**One-liner:** Scoped sign-out wipe (workout data only, preserves preferences), V12 full-wipe for delete-account, and stable Keychain-backed guest UUID with crash-safe batch migration to Apple ID on sign-in.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix sign-out/delete schema + Guest UUID Keychain methods | 57c64cc | AppState.swift, KeychainHelper.swift |
| 2 | Batch guest-to-Apple userID migration + tests | 118e12a | AuthService.swift, AppAuthCoverageTests.swift |

## What Was Built

### Task 1: Schema Fix + Keychain Methods (FIX-02 + FIX-03 foundation)

**KeychainHelper.swift** — Added three guest UUID methods mirroring the existing Apple user ID pattern:
- `saveGuestUserID(_:)` — delete-then-add pattern with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- `loadGuestUserID() -> String?` — query and decode
- `deleteGuestUserID()` — delete

**AppState.swift — signOut():** Replaced stale `AppSchemaV10.models` with a scoped list of 12 workout-data model types. Preferences (`User`, `CycleSettings`, `CycleAdaptationPreferences`, `InjuryProfile`, `PainLog`, `BenchmarkDefinition`, `SharedWorkoutTemplateRecord`, `BarbellPreset`, `ExerciseBarMapping`) survive sign-out. After wiping, calls `signInAsGuest()` to return user to guest mode with a stable UUID.

**AppState.swift — deleteAccountAndData():** Replaced `AppSchemaV10.models` with `AppSchemaV12.models` (full wipe). Added `KeychainHelper.deleteGuestUserID()` alongside existing `deleteAppleUserID()`. Clears `guestMigrationPending` UserDefaults flag.

**AppState.swift — signInAsGuest():** Replaced `currentUserID = nil` with Keychain load-or-generate pattern: loads existing guest UUID if present, otherwise generates `UUID().uuidString`, saves to Keychain, and sets as `currentUserID`.

### Task 2: Batch Migration (FIX-03 completion)

**AuthService.swift — Dependencies:** Added `loadGuestUserID` and `deleteGuestUserID` closure properties with default no-op values, preserving backward compatibility with all 5+ existing test call sites. Live implementation wires to `KeychainHelper`.

**AuthService.swift — migrateGuestRecords():** Private method that:
1. Sets `guestMigrationPending = true` in UserDefaults before starting
2. Fetches all records from 17 model types with `userID` fields
3. Updates each record matching the guest UUID to the Apple user ID
4. Saves context
5. On success: clears flag, deletes guest UUID from Keychain
6. On failure: leaves flag set for retry

**AuthService.swift — resolveAfterAppleSignIn():** Calls `migrateGuestRecords()` before resolving auth state.

**AuthService.swift — restoreSession():** Checks `guestMigrationPending` on app launch; if set and user is authenticated, retries migration.

**AppAuthCoverageTests.swift — New tests:**
- `signOutPreservesPreferencesButWipesWorkoutData` — verifies User/BarbellPreset survive while CompletedWorkout is deleted
- `guestUserIDPersistsAcrossSignInAsGuestCalls` — verifies stable UUID across multiple calls
- `batchMigrationUpdatesGuestRecordsToAppleUserID` — verifies CompletedWorkout and BarbellPreset migrate to Apple ID; pending flag cleared; guest UUID removed from Keychain
- Updated `deleteAccountAndDataClearsStateAndKeychain` — uses V12 schema and verifies BarbellPreset/ExerciseBarMapping are deleted
- Updated `appStateApplyTracksCurrentUserIDAcrossStates` — asserts `currentUserID != nil` after `signInAsGuest()` (was checking `== nil`)

## Deviations from Plan

None — plan executed exactly as written.

## Auth Gates

None.

## Deferred Issues

**Pre-existing test compilation failures in `AIWorkoutTests.swift`** (from a prior plan 01-01 commit):
- `extra argument 'weightUnit' in call` (lines 17, 522, 535)
- `cannot infer contextual base in reference to member 'fullBody'` (line 32)
These errors block `xcodebuild test` for the full suite but do not affect production build. Logged to `.planning/phases/01-critical-bug-fixes/deferred-items.md`. Will be resolved as part of FIX-01 plan completion.

## Verification

- `grep -c "AppSchemaV10" SundeeFundee/App/AppState.swift` → 0 ✓
- `grep -c "guestUserID" SundeeFundee/Auth/KeychainHelper.swift` → 6 ✓
- `grep -c "guestMigrationPending" SundeeFundee/Auth/AuthService.swift` → 5 ✓
- `xcodebuild build` → BUILD SUCCEEDED ✓
- `AppAuthCoverageTests.swift` compiles with zero errors ✓

## Self-Check: PASSED

- `/Users/dustinober/Projects/Sundee-Fundee/SundeeFundee/App/AppState.swift` — FOUND
- `/Users/dustinober/Projects/Sundee-Fundee/SundeeFundee/Auth/KeychainHelper.swift` — FOUND
- `/Users/dustinober/Projects/Sundee-Fundee/SundeeFundee/Auth/AuthService.swift` — FOUND
- `/Users/dustinober/Projects/Sundee-Fundee/SundeeFundeTests/AppAuthCoverageTests.swift` — FOUND
- Commit `57c64cc` — FOUND
- Commit `118e12a` — FOUND

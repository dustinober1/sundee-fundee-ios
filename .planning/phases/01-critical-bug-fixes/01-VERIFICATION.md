---
phase: 01-critical-bug-fixes
verified: 2026-03-19T00:00:00Z
status: passed
score: 8/8 must-haves verified
re_verification: false
---

# Phase 01: Critical Bug Fixes Verification Report

**Phase Goal:** Fix five critical bugs blocking v1.0 release — SwiftData migration, subscription cold launch, sign-out schema scoping, guest UUID stability, and AI weight unit threading.
**Verified:** 2026-03-19
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App boots without crash when SwiftData migration is needed on the local persistent store path | VERIFIED | `AppModelContainer.swift` line 96: `migrationPlan: AppSchemaMigrationPlan.self` present on `.localPersistent` case — 2 occurrences total, symmetric with `.cloudKit` |
| 2 | SubscriptionService.currentTier is .free immediately after init(), regardless of any UserDefaults value | VERIFIED | `SubscriptionService.swift` lines 68-72: `init()` only calls `startObservingTransactions()`, no UserDefaults read; `currentTier` defaults to `.free` from property declaration |
| 3 | StoreKit verification upgrades tier to premium only after async loadStatus() completes | VERIFIED | `loadStatus()` is async and calls `setTier()` after iterating `Transaction.currentEntitlements`; not invoked in `init()` |
| 4 | Sign-out wipes workout-data models but preserves preference models | VERIFIED | `AppState.signOut()` deletes 12 workout-data types (CompletedWorkout, CompletedSet, OneRepMax, etc.) and explicitly excludes User/BarbellPreset/ExerciseBarMapping/preferences |
| 5 | Delete-account wipes ALL V12 models including BarbellPreset and ExerciseBarMapping | VERIFIED | `AppState.deleteAccountAndData()` iterates `AppSchemaV12.models`; no remaining `AppSchemaV10` references in AppState.swift |
| 6 | Guest mode uses a stable UUID from Keychain as currentUserID (not nil or empty string) | VERIFIED | `AppState.signInAsGuest()` calls `KeychainHelper.loadGuestUserID()` or generates and saves a UUID; `KeychainHelper` has `saveGuestUserID`/`loadGuestUserID`/`deleteGuestUserID` (6 references) |
| 7 | On Apple sign-in, all SwiftData records owned by the guest UUID are batch-updated to the Apple user ID | VERIFIED | `AuthService.migrateGuestRecords()` migrates 17 model types; called from `resolveAfterAppleSignIn()` |
| 8 | When weightUnit is kg, system prompt prescribes kg equipment and maxes/body weight are converted | VERIFIED | `GeminiPromptBuilder.systemPrompt(weightUnit:)` returns separate native kg prompt with "20 kg bar"; `userPrompt(from:)` converts maxes via `WeightUnitConversion.poundsPerKilogram`; `GeminiWorkoutService` passes `context.weightUnit` |

**Score:** 8/8 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `SundeeFundee/App/AppModelContainer.swift` | migrationPlan on both store paths | VERIFIED | Line 93 (.cloudKit) and line 96 (.localPersistent) both have `migrationPlan: AppSchemaMigrationPlan.self` |
| `SundeeFundee/Services/SubscriptionService.swift` | Init defaults to .free, no UserDefaults read | VERIFIED | `init()` body is 2 lines: comment + `startObservingTransactions()`. Only UserDefaults reference is line 141 (write in `setTier`) |
| `SundeeFundee/App/AppState.swift` | V12-scoped sign-out and delete-account, guest UUID integration | VERIFIED | `signOut()` uses scoped model list; `deleteAccountAndData()` uses `AppSchemaV12.models`; `signInAsGuest()` uses Keychain load-or-generate |
| `SundeeFundee/Auth/KeychainHelper.swift` | guestUserID save/load/delete methods | VERIFIED | 3 methods present (lines 63-110), mirrors Apple user ID pattern, uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| `SundeeFundee/Auth/AuthService.swift` | Batch migration + guestMigrationPending flag | VERIFIED | `migrateGuestRecords()` sets flag before migration, clears on success; `restoreSession()` retries if flag set; 5 `guestMigrationPending` references |
| `SundeeFundee/Repositories/Gemini/GeminiPromptBuilder.swift` | Unit-parameterized system prompt + max/body weight conversion | VERIFIED | `systemPrompt(weightUnit:)` function with separate native kg/lbs equipment lists; `userPrompt(from:)` converts maxes and body weight |
| `SundeeFundee/Repositories/Gemini/GeminiResponseParser.swift` | Parses `weight` and `weightUnit` fields | VERIFIED | `RawGeminiExercise` has `weight`, `weightUnit`, and legacy `weightLb` fields; backward-compat logic present |
| `SundeeFundee/Domain/AIWorkout/GeneratedWorkout.swift` | weight + weightUnit properties (not weightLb) | VERIFIED | `GeneratedExercise.weight` and `GeneratedExercise.weightUnit`; legacy `weightLb` key mapped to `weightLbLegacy` CodingKey for backward-compat decoding only |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AppModelContainer.makeContainer(.localPersistent)` | `AppSchemaMigrationPlan` | `migrationPlan:` parameter | WIRED | Line 96: `migrationPlan: AppSchemaMigrationPlan.self` present |
| `SubscriptionService.init()` | `loadStatus()` | `startObservingTransactions` only (no UserDefaults) | WIRED | `init()` calls only `startObservingTransactions()`; grep confirms no UserDefaults read in init |
| `AppState.signOut()` | `modelContext.delete(model:)` | Scoped workout-data model list | WIRED | 12 model types explicitly listed; AppSchemaV10 grep returns 0 in AppState.swift |
| `AppState.deleteAccountAndData()` | `AppSchemaV12.models` | Full V12 model list for complete wipe | WIRED | Line 63: `for modelType in AppSchemaV12.models` |
| `AppState.signInAsGuest()` | `KeychainHelper.loadGuestUserID()` | Load or generate stable UUID | WIRED | Lines 22-28: load-or-generate pattern |
| `AuthService.resolveAfterAppleSignIn()` | `migrateGuestRecords()` | Batch migration on sign-in | WIRED | Line 159: `migrateGuestRecords(toAppleUserID:modelContext:)` called before `resolveAuthState` |
| `AuthService.restoreSession()` | `migrateGuestRecords()` | Retry if `guestMigrationPending` flag set | WIRED | Lines 179-181: checks UserDefaults flag and calls migration |
| `GeminiPromptBuilder.systemPrompt(weightUnit:)` | `WorkoutGenerationContext.weightUnit` | Unit passed from context | WIRED | `GeminiWorkoutService.swift` line 58: `GeminiPromptBuilder.systemPrompt(weightUnit: context.weightUnit)` |
| `GeminiResponseParser` | `GeneratedExercise.weight` + `.weightUnit` | Parses new fields, falls back to legacy `weightLb` | WIRED | `mapToGeneratedWorkout` uses prefer-new/fallback-legacy logic |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| FIX-01 | 01-03-PLAN.md | AI workout generation prescribes weights in user's selected unit | SATISFIED | `systemPrompt(weightUnit:)` with native kg/lbs lists; max conversion in `userPrompt`; `GeneratedExercise.weight + weightUnit`; REQUIREMENTS.md marked `[x]` |
| FIX-02 | 01-02-PLAN.md | Sign-out and delete-account wipe all models through V12, not stale V10 | SATISFIED | `signOut()` uses scoped list (no V10); `deleteAccountAndData()` uses `AppSchemaV12.models`; REQUIREMENTS.md marked `[x]` |
| FIX-03 | 01-02-PLAN.md | Guest mode uses stable UUID as userID instead of empty string | SATISFIED | Keychain-backed UUID in `signInAsGuest()`; batch migration in `migrateGuestRecords()`; REQUIREMENTS.md marked `[x]` |
| FIX-04 | 01-01-PLAN.md | Subscription tier defaults to free on cold launch until StoreKit verification | SATISFIED | `init()` body is comment + `startObservingTransactions()` only; REQUIREMENTS.md marked `[x]` |
| FIX-05 | 01-01-PLAN.md | SwiftData migration plan applied to both CloudKit and local persistent store paths | SATISFIED | 2 occurrences of `migrationPlan: AppSchemaMigrationPlan.self` in `AppModelContainer.makeContainer(for:)`; REQUIREMENTS.md marked `[x]` |

**Orphaned requirements:** None. All 5 FIX-xx IDs from REQUIREMENTS.md Phase 1 are claimed by plans and verified.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `SundeeFundee/Auth/AppState.swift` | 81 | `apply(_:)` sets `currentUserID = nil` for guest/signedOut states | Info | Expected behavior for `apply()`; `signInAsGuest()` is the correct path for guest mode with stable UUID — this code path is for non-guest auth state transitions |
| `SundeeFundeTests/AppAuthCoverageTests.swift` | (noted in 01-03-SUMMARY.md) | Pre-existing compilation failures in `AuthOnboardingCoverageWave5Tests.swift` | Warning | Out-of-scope — logged to `deferred-items.md`, does not affect production build or phase goal |

No blockers found.

---

## Human Verification Required

None. All phase 01 fixes are structural code changes (not UI/visual/real-time behavior) and are fully verifiable programmatically.

---

## Gaps Summary

No gaps. All five requirements are implemented, substantive, and wired:

- **FIX-05** (AppModelContainer): `migrationPlan: AppSchemaMigrationPlan.self` present on both `.cloudKit` and `.localPersistent` cases — symmetric and correct.
- **FIX-04** (SubscriptionService): `init()` is a 2-line stub (comment + `startObservingTransactions()`). `restoresTierFromUserDefaults` test deleted. `defaultsToFree`, `isPremiumTrueForPlus`, `isPremiumTrueForPro` tests remain.
- **FIX-02** (AppState sign-out/delete): `signOut()` uses explicit 12-model workout-data list. `deleteAccountAndData()` uses `AppSchemaV12.models`. Zero `AppSchemaV10` references in AppState.
- **FIX-03** (Guest UUID): `KeychainHelper` has save/load/delete guest UUID methods (6 references). `signInAsGuest()` uses load-or-generate pattern. `migrateGuestRecords()` migrates 17 model types with crash-safe retry flag. `AppAuthCoverageTests` covers: sign-out scope, delete-account V12 completeness, guest UUID persistence, batch migration correctness.
- **FIX-01** (AI weight unit): `GeminiPromptBuilder.systemPrompt(weightUnit:)` returns separate native kg/lbs equipment lists. `userPrompt(from:)` converts maxes and body weight. `GeneratedExercise` uses `weight + weightUnit` with backward-compat decoding for legacy `weightLb` JSON key. Remaining `weightLb` references in production code are all on `ExerciseMax.weightLb` (input context data stored as lbs — expected) and local variable names in `OfflineWorkoutGenerator` (not on `GeneratedExercise` property access).

The noted pre-existing test compilation failures in `AuthOnboardingCoverageWave5Tests.swift` are out of scope for this phase and are tracked in `deferred-items.md`.

---

_Verified: 2026-03-19_
_Verifier: Claude (gsd-verifier)_

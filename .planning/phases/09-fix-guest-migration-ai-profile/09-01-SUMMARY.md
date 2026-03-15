---
phase: 09-fix-guest-migration-ai-profile
plan: "01"
subsystem: guest-migration
tags: [migration, auth, firestore, asyncstorage, guest]
dependency_graph:
  requires: []
  provides:
    - full-13-key-guest-migration
    - migration-pending-retry
  affects:
    - useGuestSignIn
    - RootLayout
tech_stack:
  added: []
  patterns:
    - BatchOp[] + commitInChunks() for Firestore batch chunking
    - jest.mock factory inline jest.fn() + import-after-mock for testable mocks
key_files:
  created: []
  modified:
    - SundeeFundeeRN/src/repositories/migration.ts
    - SundeeFundeeRN/src/repositories/__tests__/migration.test.ts
    - SundeeFundeeRN/src/auth/useGuestSignIn.ts
    - SundeeFundeeRN/src/auth/__tests__/useGuestSignIn.test.ts
    - SundeeFundeeRN/app/_layout.tsx
decisions:
  - "[09-01]: migrateGuestDataToFirestore uses static import not dynamic import — dynamic import() fails in Jest CommonJS mode without --experimental-vm-modules; no circular dependency risk since migration.ts does not import from useGuestSignIn.ts"
  - "[09-01]: retryPendingMigration in _layout.tsx uses dynamic import for migration.ts — acceptable here since it is not tested directly and avoids eager-loading Firestore before auth state is known"
  - "[09-01]: jest.mock() factory uses inline jest.fn(), then module is imported after mock declaration — Babel hoisting causes TDZ failure when factory references const variables declared outside it"
metrics:
  duration: 7
  completed_date: "2026-03-15"
  tasks_completed: 2
  files_modified: 5
---

# Phase 9 Plan 01: Guest Migration Expansion Summary

**One-liner:** Full 13-key guest-to-Firestore migration with multi-batch chunking, pending-flag retry, and upgrade() wiring.

## What Was Built

Guest users who upgrade to a permanent account now have all 13 AsyncStorage data types migrated to Firestore. Previously only 4 of 13 types were covered, and the migration was never called from the upgrade path.

### Task 1: Expanded migration.ts

**File:** `SundeeFundeeRN/src/repositories/migration.ts`

- `MIGRATION_KEYS` expanded from 4 to 13 keys
- Replaced direct `batch.set()` calls with a `BatchOp[]` collection pattern
- Added `commitInChunks(db, ops)` that slices ops into chunks of `MAX_BATCH_OPS=499` and commits each chunk sequentially
- Added 9 new switch cases with correct Firestore paths:
  - `exercise-maxes` → `exerciseMaxes/{exerciseId}_{repRange}` (compositeId)
  - `injuries` → `injuries/{id}`
  - `pain_logs` → nested `injuries/{injuryId}/painLogs/{id}`
  - `period_logs` → `periodLogs/{id}`
  - `cycle_settings` → `cycleSettings/settings` (single doc)
  - `benchmark_results` → `benchmarkResults/{id}`
  - `custom_benchmarks` → `customBenchmarks/{id}`
  - `program_enrollment` → `enrollment/active` (single doc)
  - `custom-exercises` → `customExercises/{id}`
- `multiRemove` now clears all 13 `MIGRATION_KEYS` plus `@sundee/migration_pending`
- 13 new tests (19 total): all key types, chunking behavior, clear-only-on-success invariant

**Commit:** 17e1cd2

### Task 2: Migration wiring in useGuestSignIn + _layout.tsx retry

**Files:** `useGuestSignIn.ts`, `__tests__/useGuestSignIn.test.ts`, `app/_layout.tsx`

- `upgrade()` now sets `@sundee/migration_pending` then calls `migrateGuestDataToFirestore(uid)` after `linkWithCredential` succeeds, in a separate try/catch that does NOT re-throw migration errors
- `retryPendingMigration(uid)` added as module-level async function in `_layout.tsx`: checks the pending flag and retries migration for non-anonymous users on each sign-in
- `handleUserSignIn` calls `void retryPendingMigration(user.uid)` for non-anonymous users
- 4 new useGuestSignIn tests: pending flag set before migrate, uid passed correctly, upgrade succeeds when migration throws, no re-throw

**Commit:** 4e377cc

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Static import instead of dynamic import in useGuestSignIn**
- **Found during:** Task 2 GREEN phase
- **Issue:** Plan specified `await import('../repositories/migration')` (dynamic import), but Jest in CommonJS mode throws `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING_FLAG` for dynamic imports without `--experimental-vm-modules`. The migration function was being caught and swallowed silently, making it untestable.
- **Fix:** Changed to static `import { migrateGuestDataToFirestore } from '../repositories/migration'` at the top of the file. No circular dependency exists since `migration.ts` does not import from `useGuestSignIn.ts`.
- **Files modified:** `SundeeFundeeRN/src/auth/useGuestSignIn.ts`
- **Commit:** 4e377cc

**2. [Rule 1 - Bug] jest.mock factory TDZ failure**
- **Found during:** Task 2 test writing
- **Issue:** Test initially captured `mockMigrateGuestDataToFirestore` as a `const` variable then referenced it inside the `jest.mock` factory. Babel hoists `jest.mock` calls to the top of the file, causing the `const` to be in the temporal dead zone when the factory executes.
- **Fix:** Changed factory to use `jest.fn().mockResolvedValue(undefined)` inline, then imported the mocked function via `import { migrateGuestDataToFirestore } from '../../repositories/migration'` after the mock declaration. Cast to `jest.Mock` for test assertions.
- **Files modified:** `SundeeFundeeRN/src/auth/__tests__/useGuestSignIn.test.ts`
- **Commit:** 4e377cc

## Self-Check: PASSED

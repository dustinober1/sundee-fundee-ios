---
phase: 08
plan: 01
subsystem: firestore-access-contract-recovery
tags: [flutter, firestore, repositories, rules, deploy]
depends_on: []
provides:
  - legacy-safe enrollment mutation normalization for mixed-generation documents
  - deterministic active-enrollment lookup across canonical status and legacy isActive rows
  - owner-scoped migration-state rules coverage and deploy parity guardrail
affects:
  - firestore read/write contract for enrollment and migration paths
  - deployment workflow reliability for firestore artifacts
tech-stack:
  added: []
  patterns:
    - "normalize-before-write for strict firestore validation compatibility"
    - "dual-query active enrollment selection (status + legacy isActive)"
    - "deploy app + firestore rules/indexes together"
key-files:
  created:
    - .planning/phases/08-firestore-access-contract-recovery/08-01-SUMMARY.md
  modified:
    - flutter_app/lib/features/repositories/data/firestore_repositories.dart
    - flutter_app/test/features/repositories/data/firestore_enrollment_repository_test.dart
    - flutter_app/test/features/repositories/data/firestore_phase1_smoke_test.dart
    - firestore.rules
    - deploy.sh
    - .planning/phases/08-firestore-access-contract-recovery/08-RESEARCH.md
decisions:
  - "Enrollment mutations now backfill contract fields (id/status/isActive/lastSyncedAt) before update paths to avoid legacy-shape permission failures"
  - "Active enrollment reads merge canonical status-active and legacy isActive streams and select by effective sync time"
  - "Migration state writes at /users/{uid}/migrations/* are explicitly owner-allowed in firestore.rules"
  - "Deploy script now ships firestore rules/indexes with hosting to prevent contract drift"
commits:
  - hash: 0d4503c
    message: "feat(08-01): normalize legacy enrollment contract writes"
  - hash: 9c5bdc3
    message: "fix(08-01): add owner-safe migrations rule coverage"
  - hash: d0e7aa2
    message: "chore(08-01): deploy firestore contracts with app releases"
metrics:
  completed: "2026-02-24"
---

# Phase 8 Plan 01 Summary

## Objective
Recover the Firestore access contract for enrollment/migration paths by aligning repository behavior, rules coverage, and deploy workflow.

## What Was Built

### Task 1: Legacy-safe enrollment repository behavior
- Added normalization-before-write on enrollment mutation paths (`updateEnrollmentProgress`, `markWeekComplete`, `jumpToWeek`, `cancelEnrollment`, `completeEnrollment`) so legacy rows missing modern contract fields are repaired before strict-rule writes.
- Updated `watchActiveEnrollment` to combine canonical status-active rows and legacy `isActive` rows, dedupe by enrollment id, normalize opportunistically, and pick deterministic newest active enrollment.
- Expanded regression coverage with:
  - canonical status-only active-row read test
  - legacy normalization-before-write test
  - smoke test proving legacy rows are normalized during progress updates.

### Task 2: Firestore rules alignment
- Added owner-scoped `/users/{userId}/migrations/{migrationId}` rule coverage for migration orchestrator writes.
- Preserved enrollment write validation and owner-only boundaries.

### Task 3: Deploy drift guardrail
- Updated `deploy.sh` to deploy hosting plus Firestore rules/indexes in one command:
  - `firebase deploy --only firestore,firestore:indexes,hosting`
- Recorded the deploy parity guardrail in phase research notes.

## Verification
Executed successfully:
- `cd flutter_app && flutter test test/features/repositories/data/firestore_enrollment_repository_test.dart test/features/repositories/data/firestore_phase1_smoke_test.dart -r expanded`
- `bash -n deploy.sh`
- `rg -n "firebase deploy --only firestore,firestore:indexes,hosting" deploy.sh`
- `rg -n "match /migrations/|validEnrollmentWrite" firestore.rules`

## Deviations
- None. Plan scope was implemented as specified.

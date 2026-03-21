---
phase: 03-security-hardening
plan: 01
subsystem: firestore-security
tags: [security, firestore, rules, testing]
dependency_graph:
  requires: []
  provides: [firestore-security-rules, rules-test-infrastructure]
  affects: [all-user-data-access, premiumEntitlement-protection]
tech_stack:
  added:
    - "@firebase/rules-unit-testing ^3.0.0 (root devDep)"
    - "jest ^29.0.0 (root devDep)"
    - "ts-jest ^29.0.0 (root devDep)"
  patterns:
    - "Firestore diff().affectedKeys().hasAny() for field-level write blocks"
    - "{nested=**} wildcard for depth-2+ subcollection coverage"
    - "initializeTestEnvironment + withSecurityRulesDisabled for seeding in update tests"
key_files:
  created:
    - firestore.rules
    - firestore.rules.test.ts
    - jest.rules.config.js
    - package.json
  modified: []
decisions:
  - "Separate create/update rules on users/{userId}: create uses !('premiumEntitlement' in request.resource.data), update uses diff().affectedKeys() — resource.data is null on create so the two patterns must be separated"
  - "Root package.json created as dedicated test runner for Firestore rules — rules test runs independently from pwa/ vitest and functions/ jest suites"
  - "19 test cases across 6 describe blocks — comprehensive coverage for SEC-01 (ownership, cross-user denial) and SEC-02 (premiumEntitlement block on create, update, combined)"
metrics:
  duration: "3 minutes"
  completed_date: "2026-03-21"
  tasks_completed: 2
  files_created: 4
---

# Phase 03 Plan 01: Firestore Security Rules Summary

**One-liner:** Firestore security rules with per-user ownership enforcement, premiumEntitlement write block via diff().affectedKeys(), and depth-2 wildcard for painLogs subcollection.

## What Was Built

### Task 1: firestore.rules

Created `firestore.rules` at the repo root, extended from the worktree base with:

1. **SEC-01: Ownership enforcement** — Separate `allow read`, `allow create`, `allow update`, `allow delete` rules on `users/{userId}` all require `request.auth.uid == userId`.

2. **SEC-02: premiumEntitlement field block** — Two patterns to cover both write operations:
   - `allow create`: `!('premiumEntitlement' in request.resource.data)` — blocks creation of user docs with this field
   - `allow update`: `!request.resource.data.diff(resource.data).affectedKeys().hasAny(['premiumEntitlement'])` — blocks any update that touches this field, even alongside other valid fields

3. **Depth-2 wildcard**: Added `match /{subcollection}/{docId}/{nested=**}` covering `injuries/{id}/painLogs/{id}` and any future depth-2+ paths.

4. **Read-only collections**: `programs` and `wods` remain read-only for authenticated users, no-write.

### Task 2: Rules Test Infrastructure

Created:
- `package.json` — Root-level with `@firebase/rules-unit-testing`, `jest`, `ts-jest`, `typescript` devDeps; `npm run test:rules` script
- `jest.rules.config.js` — ts-jest preset, node environment, targets `firestore.rules.test.ts`
- `firestore.rules.test.ts` — 19 test cases across 6 describe blocks

**Test coverage:**

| Describe Block | Tests | Coverage |
|----------------|-------|---------|
| Unauthenticated access | 4 | users, programs, wods all denied |
| Owner access to /users/{uid} | 2 | read and write allowed |
| Cross-user access denial | 2 | read and write denied |
| Depth-1 subcollection access | 4 | own allowed, cross-user denied |
| Read-only collections | 4 | programs and wods (read allowed, write denied) |
| SEC-02: premiumEntitlement field block | 5 | create-with-field denied, create-without-field allowed, update-to-add denied, update-valid-fields allowed, update-combined denied |
| Depth-2 subcollections | 3 | write allowed, read allowed, cross-user denied |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

- [x] `firestore.rules` exists: `[ -f "/Users/dustinober/Projects/Sundee-Fundee/firestore.rules" ]` FOUND
- [x] `firestore.rules.test.ts` exists: FOUND (19 test cases)
- [x] `jest.rules.config.js` exists: FOUND
- [x] `package.json` exists: FOUND with `@firebase/rules-unit-testing` installed
- [x] Commit 885d7b4: feat(03-01): add Firestore security rules
- [x] Commit b6bf1ee: feat(03-01): add rules test infrastructure and comprehensive test suite

## Self-Check: PASSED

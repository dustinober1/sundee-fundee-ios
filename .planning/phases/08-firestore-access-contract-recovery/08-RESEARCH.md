# Phase 08: Firestore Access Contract Recovery - Research

**Researched:** 2026-02-24  
**Domain:** Firestore rules and repository contract alignment for authenticated training flows (Home, Programs, Workout)  
**Confidence:** HIGH

## Summary

Phase 08 should be executed as a contract-recovery effort across three layers:
1. Firestore rules and deploy process
2. Repository read/write/query behavior for enrollment/session paths
3. User-facing recovery behavior on Home, Programs, and Workout surfaces

The highest-risk issue is contract drift, not missing primitives. The app already has robust Firestore-backed repositories and strong unit coverage, but core paths still allow permission-denied failures in realistic UAT conditions:
- the dashboard migration writer targets a subcollection that is not explicitly covered in rules,
- enrollment updates rely on strict write validation and can fail when legacy docs are missing required fields,
- UI lifecycle providers surface backend read failures as terminal screen errors instead of recoverable states.

**Primary recommendation:** lock one canonical Firestore access contract (rules + repository normalization + deploy guardrails), then layer shared retry/recovery UX and workout write resilience on top.

## Locked Context from 08-CONTEXT.md

### Decisions that must be honored
- Authenticated users without active enrollment get explicit empty states with "Start Program" CTA.
- Active enrollment with missing next-session data is treated as valid empty-data state, not hard failure.
- Stale profile enrollment links auto-heal to no-enrollment state.
- Recoverable backend failures render top-banner guidance with retry.
- Retry strategy: auto-retry up to 3 times with short backoff; silent revalidation once on app resume.
- Persistent failures escalate to blocking recovery state.
- Workout writes allow local continuity when transient failures occur, with queued sync and manual retry.

### Implications for planning
- "No data" and "access failure" must be distinct state paths.
- Error UX cannot replace the whole screen with raw exception text.
- Write durability must be explicit for workout start/progress/completion.

## Current Codebase Findings

1. **Dashboard migration writes target `/users/{uid}/migrations/*`, but rules do not explicitly match this subcollection.**
   - Writer path: `legacy_migration_orchestrator.dart` uses `.collection('migrations')`.
   - Rules currently define explicit subcollection matches under `/users/{userId}`, but no `migrations` match.
   - Effect: permission-denied is plausible during dashboard boot flow.

2. **Enrollment writes are strictly validated in rules, while repository progress updates use partial `update(...)` payloads.**
   - `validEnrollmentWrite` requires `id`, `programId`, `startDate`, `currentWeek`, and `currentDay` on final document state.
   - Repository writes like `updateEnrollmentProgress`, `markWeekComplete`, `jumpToWeek` update only partial fields.
   - If legacy enrollment docs are missing required fields (common in long-lived projects), these writes can fail with permission-denied.

3. **Active enrollment lookup is currently tied to `isActive == true` query semantics.**
   - `watchActiveEnrollment` queries `where('isActive', isEqualTo: true)` then filters by status in memory.
   - This is fragile for legacy/status-only rows and can produce false empty states or unstable behavior across mixed document generations.

4. **Core training surfaces still surface lifecycle read errors as terminal UI errors.**
   - `enrollmentLifecycleStateProvider` returns `AsyncError` when active enrollment or latest event streams fail.
   - Home/Programs/Workout screens render raw error text/cards in error branches.
   - This violates the phase context decision for recoverable banner + retry while preserving content skeleton.

5. **Workout completion pipeline is fully serialized remote writes with no durable local queue.**
   - `finishWorkout(...)` writes completed sets, workout record, maxes, and enrollment progress directly to Firestore in sequence.
   - On write failure, user receives failure snackbar and current flow can be interrupted without explicit queued recovery contract.

6. **Deployment guardrails do not currently guarantee rules/index parity with app deploy.**
   - `deploy.sh` deploys hosting only (`firebase deploy --only hosting`).
   - If app code changes ship without corresponding rules/index deploy, UAT can hit permission-denied despite local correctness.

## Targeted Verification Baseline

Executed locally:
- `cd flutter_app && flutter test test/features/repositories/data/firestore_enrollment_repository_test.dart test/features/repositories/data/firestore_workout_repository_test.dart test/features/repositories/data/firestore_phase1_smoke_test.dart -r compact` -> pass
- `cd flutter_app && flutter test test/features/profile/data/firestore_profile_rules_test.dart -r compact` -> pass

Interpretation:
- Current tests validate repository behavior against fake firestore and lightweight rules-file assertions.
- They do not fully cover emulator-backed access control outcomes for mixed legacy document shapes or deploy drift scenarios.

## Standard Stack

No new external product libraries are required for Phase 08.

### Core
| Library/Tool | Version | Purpose | Why standard for this phase |
|---|---|---|---|
| `cloud_firestore` | existing | Authenticated data reads/writes and offline queue | Already the production data boundary |
| `flutter_riverpod` | existing | Async state composition and retry orchestration | Existing pattern for cycle/data providers |
| Firestore Security Rules (`firestore.rules`) | v2 | Server-enforced access contract | Required to prevent client-side bypass |
| Firestore Indexes (`firestore.indexes.json`) | existing | Query compatibility for enrollment/event reads | Required for deterministic query behavior |

### Supporting
| Library/Tool | Purpose | When to use |
|---|---|---|
| `shared_preferences` (already in project) | Durable local queue metadata for pending write replay | Persist pending workout write intents across app restarts if needed |
| Firebase Emulator Suite | Rules + query + write contract verification | Validate permission and rule paths before deploy |

## Architecture Patterns (Recommended)

### Pattern 1: Firestore Contract Normalization at Repository Boundary
- Add explicit normalization/heal steps for legacy enrollment docs before mutating writes.
- Keep rule strictness for owner safety, but make repository writes capable of lifting legacy docs into valid contract shape.

### Pattern 2: Dual-State Access Modeling (Empty vs Failure)
- Introduce typed access status for core surfaces:
  - `available`
  - `valid_empty`
  - `recoverable_failure`
  - `blocking_failure`
- Screens should render valid empty states for missing data and banners for recoverable backend failures.

### Pattern 3: Central Recoverable Error Classifier
- Reuse existing cycle/insights pattern: classify recoverable Firestore errors (`permission-denied`, `unauthenticated`, `unavailable`, `deadline-exceeded`) separately from fatal parse/logic failures.
- Route recoverable failures through retry policy first; do not immediately terminate surface state.

### Pattern 4: Retry Orchestration as Provider Contract
- Implement a shared retry controller:
  - automatic retries up to 3 attempts with short backoff,
  - silent revalidation on app resume,
  - explicit manual retry affordance.

### Pattern 5: Workout Write Resilience with Local Pending Queue
- Keep session continuity by staging local completion/progress payloads.
- Perform background replay until sync succeeds.
- Escalate to blocking modal only for completion finalization that remains unsynced.

## Do Not Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Custom rule interpretation in app | Client-side ACL simulation | Firestore rules + emulator validation | Rules are server authority |
| Ad-hoc retry scattered per screen | Per-widget timers and duplicate logic | Shared provider-based retry policy | Keeps behavior consistent across Home/Programs/Workout |
| "Offline queue" from scratch with new storage tech | New DB layer for this phase | Existing Firestore offline semantics + minimal local pending metadata | Faster, lower risk, aligns with existing stack |

## Common Pitfalls

### Pitfall 1: Subcollection rules assumed from parent
- Firestore rules apply at matched paths; parent rules do not automatically secure/allow nested subcollections unless matched.
- Missing explicit subcollection coverage can produce permission-denied in otherwise valid user flows.

### Pitfall 2: Strict update validation with mixed legacy docs
- `request.resource.data` for `update` represents post-write document state.
- If legacy docs are missing required fields, partial updates can still fail strict validation.

### Pitfall 3: Query/rules mismatch hidden as UI failure
- Firestore rules evaluate query potential result set (all-or-nothing), not per-row filtering.
- Treating these failures as generic UI error text leads to broken-tab UX instead of guided recovery.

### Pitfall 4: Deploying app without rules/indexes
- Shipping new client contracts without deploying matching rules/indexes is a common cause of UAT-only permission failures.

## ACL Traceability (Phase 08)

| Requirement | Key gap observed | Research-backed direction |
|---|---|---|
| ACL-01 Home Next Workout read | Lifecycle read errors bubble as raw error card | Add recoverable state + retry banner and empty-state separation |
| ACL-02 Programs data read | Same lifecycle provider error propagation | Shared access recovery provider + Programs screen integration |
| ACL-03 Workout tab read | Workout landing shows terminal error text | Same recoverable contract and banner/manual retry path |
| ACL-04 Workout start/progress writes | Write pipeline has no durable retry contract; legacy enrollment write risk | Contract normalization + queued write replay + completion gating |
| ACL-05 Recoverable UX | Current raw error text in core surfaces | Top-banner guidance, retry checklist, preserved underlying content |

## Open Questions

1. **What exact UAT stack traces were captured per tab?**
   - We have requirement-level findings and code hotspots, but not full production stack traces by flow.
   - Recommendation: collect and attach per-surface error payloads during first Phase 08 execution cycle.

2. **How many production enrollment docs are legacy/malformed relative to strict rule contract?**
   - Unknown without production snapshot/emulator replay.
   - Recommendation: include a one-time contract audit script or emulator import sample before broad release.

## Sources

### Primary codebase sources
- `firestore.rules`
- `firestore.indexes.json`
- `deploy.sh`
- `flutter_app/lib/features/repositories/data/firestore_repositories.dart`
- `flutter_app/lib/features/programs/providers/enrollment_lifecycle_provider.dart`
- `flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart`
- `flutter_app/lib/features/programs/presentation/programs_screen.dart`
- `flutter_app/lib/features/workouts/presentation/workout_landing_screen.dart`
- `flutter_app/lib/features/workouts/presentation/workout_execution_providers.dart`
- `flutter_app/lib/features/migration/data/legacy_migration_orchestrator.dart`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/08-firestore-access-contract-recovery/08-CONTEXT.md`

### Official Firebase documentation (validated)
- [Structuring Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/rules-structure)
  - Subcollections need explicit matching rules.
- [Writing conditions for Firestore Security Rules](https://firebase.google.com/docs/firestore/security/rules-conditions)
  - `request.resource.data` represents post-write state for partial updates.
- [Securely query data with rules](https://firebase.google.com/docs/firestore/security/rules-query)
  - Rules are not filters; query validation is all-or-nothing against potential result set.
- [Transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions)
  - Batched writes are atomic and execute offline.
- [Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
  - Offline sync is managed by Firestore client; last-write-wins behavior on reconnect.
- [Connect to Firestore emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore)
  - Rule evaluation visibility and test-loop support for contract validation.

## Metadata

**Confidence breakdown:**
- Contract/rules findings: HIGH (code + official docs)
- Recovery UX direction: HIGH (codebase pattern parity with cycle/insights)
- Write resilience approach: MEDIUM-HIGH (codebase fit is strong; final queue persistence depth still a planning choice)

**Research date:** 2026-02-24  
**Valid until:** 2026-03-24 (refresh if Firestore schema/rules change)

## Phase 08 Execution Notes (Contract Parity Guardrail)

- Deploy workflow must ship client + Firestore contract together:
  - `firebase deploy --only firestore,firestore:indexes,hosting`
- Keep this guardrail in future phase execution to avoid UAT-only permission drift.

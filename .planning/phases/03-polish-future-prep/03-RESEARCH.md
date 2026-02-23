# Phase 03: Polish and Future Prep - Research

**Researched:** 2026-02-23  
**Domain:** Flutter + Riverpod + Firestore offline behavior, UI polish, and schema/rules hardening  
**Confidence:** HIGH

## Summary

Phase 03 should be executed as a three-wave hardening pass:

1. Establish a deterministic offline/session/sync contract in auth, repository, and provider layers.
2. Apply major but behavior-safe UI polish across all primary screens, including subtle sync/staleness indicators.
3. Finalize schema/rules/docs and run a broad regression sweep covering both critical paths.

The app already has the right primitives for this phase: Firestore persistence is enabled, key screens already show basic "last synced" text, and workout adaptation can already prompt apply/defer when prescriptions shift. The key missing piece is consistency: sync state is inferred indirectly (not from Firestore metadata), offline session restore is vulnerable to token-refresh failures, and phase-level docs/playbook artifacts do not yet exist.

**Primary recommendation:** implement a shared sync-state contract (metadata + freshness policy) first, then consume it everywhere for polish and offline messaging, then finish with rules/schema and operational documentation.

## Locked Context from 03-CONTEXT.md

### Decisions that must be honored
- Polish all primary screens equally with a heavy visual/interaction pass.
- Keep existing capabilities/flows intact (no net-new product scope).
- Offline mode must support read + act for cycle/program/workout flows, including cycle edits and workout completion.
- If a valid session exists, allow supported offline behavior.
- Queue offline edits/actions and auto-sync on reconnect.
- Use latest-edit-wins behavior.
- Keep sync visibility subtle (small icon/timestamp style).
- Keep stale/offline copy minimal and technical.
- Reconnect success should be quiet (no celebratory toasts).
- Harden both critical paths:
  - cycle update -> program adapts -> workout executes
  - auth restore -> offline use -> reconnect sync
- Deliver developer notes plus an operational playbook.

### Claude discretion areas resolved in this research
- **Stale cutoff policy:** mark data stale when last authoritative sync is older than 24 hours.
- **Indicator placement:** top-of-card status rows on Dashboard/Cycle/Programs, compact header status in workout flows.
- **Motion style:** subtle 120-180ms fades/size transitions for status state changes; no attention-grabbing transitions.

## Current Codebase Findings

1. **Firestore offline persistence is enabled globally, but sync state is not exposed as first-class app state.**
   - `flutter_app/lib/bootstrap.dart` enables `Settings(persistenceEnabled: true)`.
   - Streams in repositories use `.snapshots()` without metadata-aware mapping into UI state.

2. **Offline-valid-session behavior is at risk during auth restore.**
   - `AuthRepository.authStateChanges` calls `_validateAndRefreshSession`.
   - `_validateAndRefreshSession` forces token refresh and signs out on failure.
   - This can reject valid cached sessions while offline, which conflicts with Phase 03 decisions.

3. **Sync indicators exist but are heuristic, not authoritative.**
   - Dashboard/Cycle/Programs show "Last synced" from domain timestamps (for example, latest period start date), not snapshot metadata.
   - There is no unified provider for `fromCache`/`hasPendingWrites` and freshness state.

4. **Cycle/program/workout flows already have robust adaptation primitives.**
   - `adaptedActiveProgramProvider` is reactive to cycle status and preferences.
   - Workout execution has apply/defer prompt for in-progress prescription changes.
   - This is a strong base for the "cycle update -> program adapts -> workout executes" hardening path.

5. **Offline write queue behavior currently relies on Firestore defaults, not explicit app-level contract.**
   - Repository writes use `set/update/delete` directly.
   - There is no shared state model that tells UI whether writes are pending vs synced.
   - There is no explicit, tested policy surface for latest-edit-wins at app layer.

6. **UI polish is partially modernized but inconsistent across primary screens.**
   - Theme tokens and card patterns exist.
   - Screen-level visual language, density, and feedback patterns differ across Dashboard/Cycle/Programs/Workout/Maxes.
   - Phase 03 asks for heavy polish parity across all primary screens.

7. **Rules are broad owner-only, but future-prep schema/rules artifacts are still missing.**
   - `firestore.rules` currently allows owner R/W on user subcollections and public read for program catalogs.
   - This is functional, but there is no Phase 03-level documentation of schema/rules intent for deferred v2 readiness.

8. **Tests are strong in pockets, but phase-wide critical path regression is not yet consolidated.**
   - Good unit/widget coverage exists for cycle adaptation and key screens.
   - Missing cohesive regression command suite for both critical paths and offline/reconnect transitions.

## Success Criteria Gap Check

| Roadmap Success Criterion | Current State | Gap | Phase 03 Requirement |
|---|---|---|---|
| App works offline with cached cycle/program data | Partial (persistence enabled, some fallback) | No unified sync-state contract; auth restore can fail offline | Build metadata+freshness contract; harden offline auth restore and action flows |
| Firebase rules updated for new program fields | Partial (broad owner rules, adaptation fields persisted) | No phase-level future-prep schema/rules artifact and verification path | Add explicit rule/schema hardening plus verification tests |
| Codebase documented and tests cover critical paths | Partial | No operational playbook + broad phase regression suite | Deliver developer notes + playbook + consolidated verification commands |

## Recommended Technical Direction

### 1) Shared Sync State Contract
Define a reusable sync model consumed by all primary screens:
- `isFromCache`
- `hasPendingWrites`
- `lastSyncedAt`
- `freshness` (`fresh`, `aging`, `stale` with stale cutoff at 24h)

Use Firestore metadata where possible and keep copy minimal:
- "Syncing changes..."
- "Offline, showing saved data"
- "Last synced <time>"

### 2) Offline Session Restore Hardening
Change auth restore behavior to preserve valid cached sessions while offline:
- Treat transient network/token refresh failures as non-fatal for offline mode.
- Only invalidate session on explicit auth-invalid signals.
- Keep onboarding/profile stream behavior stable.

### 3) Explicit Latest-Edit-Wins Policy
Use deterministic write timestamps on mutable docs and verify behavior in repository tests:
- preserve existing Firestore queue/replay semantics,
- codify app-level expectation that newest local edit wins on reconnect,
- avoid user-facing conflict dialogs (per locked context).

### 4) Major Screen Polish with Consistent Motion and Status Surfaces
Apply one shared polish checklist across primary screens:
- hierarchy and spacing,
- card and action affordance consistency,
- subtle animated status transitions,
- empty/loading/error/offline states all spec-covered.

### 5) Rules/Schema Future Prep + Documentation
For phase closure, produce:
- rules/schema hardening commit,
- concise developer notes explaining offline/sync contract,
- operator playbook (offline/reconnect troubleshooting + QA checklist).

## Suggested Plan Waves

- **Wave 1:** Offline/session/sync contract foundation.
- **Wave 2:**
  - Critical flow hardening for offline queue + reconnect behavior.
  - Major UI polish pass and subtle sync/stale indicators across primary screens.
- **Wave 3:** Rules/schema future prep, docs/playbook, and broad final regression verification.

## Risks and Mitigations

1. **Risk:** Offline auth restore regression signs users out unexpectedly.
   - **Mitigation:** Add dedicated auth repository tests for offline token refresh failure and cached-session continuity.

2. **Risk:** UI sync indicators become noisy or contradictory.
   - **Mitigation:** Drive all screens from one sync-state model and one display mapping table.

3. **Risk:** Reconnect writes produce confusing state jumps.
   - **Mitigation:** Keep latest-edit-wins deterministic, quiet success, and subtle stale indicators only.

4. **Risk:** Large polish pass regresses accessibility/readability.
   - **Mitigation:** include accessibility smoke and contrast checks in phase verification command.

## Sources

### Codebase (primary)
- `flutter_app/lib/bootstrap.dart`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/lib/features/repositories/data/firestore_repositories.dart`
- `flutter_app/lib/features/cycle/providers.dart`
- `flutter_app/lib/features/programs/providers/adapted_program_provider.dart`
- `flutter_app/lib/features/workouts/presentation/workout_execution_screen.dart`
- `flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart`
- `flutter_app/lib/features/programs/presentation/programs_screen.dart`
- `flutter_app/lib/features/cycle/presentation/cycle_tracking_screen.dart`
- `firestore.rules`

### Existing project docs
- `.planning/phases/03-polish-future-prep/03-CONTEXT.md`
- `.planning/ROADMAP.md`
- `readme.md`

## Metadata

**Research date:** 2026-02-23  
**Valid until:** 2026-03-25 (refresh recommended if Firebase/Auth dependencies or sync architecture changes)

# Project Research Summary

**Project:** Sundee-Fundee (Workout Tracker) — v2.0 Flutter Full Rewrite
**Domain:** Offline-first cross-platform workout tracker migration (Flutter web + Android + iOS)
**Researched:** 2026-02-20
**Confidence:** MEDIUM-HIGH

## Executive Summary

This is a behavior-preserving platform rewrite, not a greenfield build. The recommended strategy is to treat v1.1 as the behavioral source of truth and rebuild in Flutter with a local-first architecture: local DB as authority, explicit sync orchestration, and parity tests that enforce identical outcomes for onboarding, workout logging, recommendations, progress calculations, and sync UX across web, Android, and iOS.

Research aligns on Flutter 3.41 + Dart 3.11 with Riverpod, go_router, Drift for local persistence, and Firebase Hosting for web deployment. The safest build order is: lock parity contracts first, then data/rules, then sync, then feature UI parity, then deploy/cutover hardening. This sequencing addresses the highest-risk failure points early.

Primary risks are offline parity regressions, web storage mismatches, sync conflict corruption during overlap with legacy clients, and Firebase deep-link/refresh failures. Mitigate with explicit cross-platform parity contract tests, early storage spike validation, deterministic conflict policies with telemetry, and CI smoke tests for hosting rewrites and offline behavior.

## Key Findings

### Recommended Stack

Stack recommendations are strong for cross-platform parity delivery: Flutter 3.41.x / Dart 3.11.x, Riverpod for app state, go_router for navigation, Drift for local-first persistence, and Firebase Hosting for web release. The rewrite should preserve domain behavior while replacing runtime/UI implementation.

**Core technologies:**
- **Flutter SDK 3.41.x + Dart 3.11.x:** Cross-platform runtime baseline — current stable and package-compatible.
- **Drift (`^2.31.0` + `drift_flutter`):** Local-first storage authority across web/mobile.
- **Riverpod (`^3.2.1`):** Testable state graph replacing React Context.
- **go_router (`^17.1.0`):** Declarative route and deep-link parity.
- **Firebase Hosting (CLI >=12.1.0):** Supported Flutter web deploy path.
- **Cloud sync backend:** Must be explicitly decided early (STACK.md leans Firestore; ARCHITECTURE.md retains Supabase).

### Expected Features

v2.0 is a parity milestone: users should get the same workflows and logic outcomes across all platforms. Reliability and deterministic behavior matter more than new surface area.

**Must have (table stakes):**
- Full workflow parity: onboarding, programs, workout logging, recommendations, progress, sync UX.
- Offline-first core loop parity on web + Android + iOS.
- Deterministic parity for %1RM/rounding/PR/plateau calculations.
- Cross-platform acceptance tests for critical flows.
- Data continuity/migration plan from v1 behavior.

**Should have (competitive):**
- Shared golden parity fixtures for rules/calculations.
- Improved sync transparency (source + timestamp detail).
- Platform-adaptive chart interactions with invariant datasets.

**Defer (v2+):**
- Social/community features.
- Wearables/live sensors.
- Real-time collaborative conflict tooling.
- Pixel-identical UI across all platforms.

### Architecture Approach

Adopt a layered, repository-first architecture: Flutter presentation -> feature viewmodels/use-cases -> repositories -> local DB + remote datasource + dedicated SyncOrchestrator -> platform/deploy adapters. Local writes are authoritative; cloud sync is async and stateful (queued, retried, conflict-resolved, and surfaced to users).

**Major components:**
1. **Feature UI + Router:** Cross-platform workflows and navigation.
2. **ViewModels + Repositories:** State orchestration and data ownership boundaries.
3. **LocalDataSource (Drift):** Tables, migrations, and performant offline queries.
4. **RemoteDataSource (Supabase/Firestore):** Cloud backup/sync transport.
5. **SyncOrchestrator:** Queue, retry, idempotency, merge policy, sync status.
6. **Hosting/Platform adapters:** Firebase rewrites, lifecycle/background sync triggers.

### Critical Pitfalls

1. **Offline parity regressions** — enforce offline parity contracts and release gates on all 3 platforms.
2. **Wrong web DB assumptions** — run early web/mobile storage spike tests (transactions, restart recovery, quota behavior).
3. **Legacy/new client conflict corruption** — use deterministic conflict policy, idempotent IDs, and conflict telemetry.
4. **Firebase deep-link/refresh 404s** — configure SPA rewrites and validate in CI preview/prod smoke tests.
5. **Stale Flutter web SW assumptions** — own explicit web offline/update strategy; do not rely on deprecated defaults.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Parity Contract + Architecture Decision Lock
**Rationale:** Stops behavior drift and resolves the cloud sync backend split before build-out.
**Delivers:** Parity acceptance matrix, dependency/version lock, explicit sync backend decision (Supabase retain vs Firestore migrate).
**Addresses:** Functional parity, reliability, and testability requirements.
**Avoids:** Offline drift, dependency churn, backend indecision.

### Phase 2: Data Core (Local DB + Rule Engine Port)
**Rationale:** Data/rule correctness is upstream of all user-visible parity.
**Delivers:** Drift schema/migrations, repository interfaces, deterministic calculation/recommendation ports, fixture tests.
**Uses:** Drift, Riverpod, freezed/json_serializable.
**Implements:** LocalDataSource + repository boundaries.

### Phase 3: Sync + Auth Orchestration
**Rationale:** Sync integrity must be proven before parity claims are credible.
**Delivers:** Shared auth lifecycle state machine, queue/retry/conflict handling, sync state UX, dual-client overlap protocol.
**Addresses:** Optional cloud sync parity and error-state parity.
**Avoids:** Data loss/reversion and token-lifecycle stalls.

### Phase 4: Feature Workflow Parity (Vertical Slices)
**Rationale:** With stable data/sync foundations, UI parity can be delivered predictably.
**Delivers:** Onboarding -> Programs -> Workout -> Dashboard/Progress parity, including ergonomic checks.
**Addresses:** Core end-user parity.
**Avoids:** UI-first implementation masking data defects.

### Phase 5: Web Runtime + Hosting/Release Hardening
**Rationale:** Deployment and route/offline behavior are distinct risk surfaces.
**Delivers:** Firebase Hosting rewrites, deep-link reliability, explicit web offline/update validation, CI/CD release pipeline.
**Uses:** Firebase CLI + hosting workflows.
**Avoids:** Production route failures and brittle update behavior.

### Phase 6: Cutover + Stabilization
**Rationale:** Real migration includes overlap between old and new clients.
**Delivers:** Staged rollout, telemetry thresholds, rollback playbook, final parity sign-off.
**Addresses:** Production readiness and trust continuity.
**Avoids:** Silent corruption and hard-to-debug migration incidents.

### Phase Ordering Rationale

- Data and rule parity are dependencies for every feature workflow.
- Sync/auth must stabilize before cross-device parity is credible.
- Hosting hardening should happen before user cutover.
- This order directly de-risks the top identified pitfalls.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** Backend decision analysis (Supabase retain vs Firestore migrate), including migration cost and risk.
- **Phase 2:** Drift web storage mode/durability under target browser/device conditions.
- **Phase 3:** Conflict policy edge cases and auth lifecycle behavior across platforms.
- **Phase 5:** Flutter web offline/update strategy given service-worker changes.

Phases with standard patterns (skip research-phase likely safe):
- **Phase 4:** UI parity implementation once contracts and repositories are fixed.
- **Phase 6:** Staged rollout/monitoring patterns are operationally standard.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Official docs strongly support Flutter/Firebase/Drift baseline; some version details are snapshot-sensitive and backend recommendation is split. |
| Features | MEDIUM-HIGH | Strong parity signal from existing product plus Flutter offline-first guidance; one Firestore offline-default detail explicitly flagged for verification. |
| Architecture | MEDIUM | Robust architecture guidance, but unresolved backend direction introduces meaningful planning uncertainty. |
| Pitfalls | HIGH | Specific, actionable, and phase-mapped pitfalls aligned with known Flutter web/offline/hosting risks. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Sync backend conflict (Supabase vs Firestore):** Resolve in Phase 1 with decision memo, costed migration path, and rollback criteria.
- **Firestore offline platform defaults:** Re-validate in implementation docs/tests before dependency.
- **Web storage durability envelope:** Execute empirical spike for quota/eviction/restart behavior.
- **Dual-client overlap protocol:** Define overlap window and deterministic conflict handling before beta.

## Sources

### Primary (HIGH confidence)
- Flutter official docs: supported platforms, app architecture, offline-first pattern, web deployment, release notes/archive.
- Firebase official docs: Flutter setup, Hosting full config, Flutter hosting integration.
- Drift official docs: web/storage behavior and wasm storage implementations.

### Secondary (MEDIUM confidence)
- Pub package version indexes for FlutterFire, Riverpod, go_router, Drift, fl_chart, connectivity_plus, freezed/json_serializable.
- Existing Sundee-Fundee v1.1 architecture/code/docs as behavioral baseline.

### Tertiary (LOW confidence)
- Firestore platform-specific offline-default behavior details not fully retrieved in this research run; requires implementation-phase validation.

---
*Research completed: 2026-02-20*
*Ready for roadmap: yes*

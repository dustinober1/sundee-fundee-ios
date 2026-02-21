---
phase: 13
plan: 02
title: "Sync Engine + State Machine"
subsystem: sync
tags: [supabase, drift, sync, riverpod, uuid, shared-preferences, offline-queue]
one-liner: "SyncService push/pull/queue/retry engine with UUID bridge + SyncNotifier reactive state machine (disabled/offline/pending/syncing/synced/error)"

dependency-graph:
  requires:
    - "13-01: Drift v4 syncId columns + supabase_flutter + uuid deps"
  provides:
    - "SyncService: push/pull/queue/retry to Supabase via syncId UUID bridge"
    - "SyncNotifier: reactive sync state machine driven by auth + connectivity"
    - "syncProvider: NotifierProvider<SyncNotifier, SyncState>"
  affects:
    - "13-03: Sync UI badge (consumes syncProvider for status display)"
    - "13-04: Workout completion flow (calls syncAfterWorkout)"
    - "13-05: Parity gate tests (test syncProvider state transitions)"

tech-stack:
  added: []
  patterns:
    - "UUID v4 syncId bridge: written to Drift BEFORE Supabase call (idempotent retries)"
    - "FK-ordered push: active_cycles → completed_workouts → completed_sets/PRs/1RMs"
    - "Offline queue via SharedPreferences JSON list (enqueue/dequeue/drain)"
    - "withRetry<T> exponential back-off: 1s, 2s, 4s, max 3 attempts"
    - "Supabase upsert (not insert) for idempotency across all 5 tables"
    - "Riverpod 3.x Notifier with ref.listen for connectivity, stream sub for auth"
    - "_trySetState() swallows StateError on disposed notifier (safe async gaps)"

key-files:
  created:
    - path: "flutter_app/lib/services/sync_service.dart"
      description: "Push/pull/queue/retry sync engine — 594 lines"
    - path: "flutter_app/lib/shared/providers/sync_provider.dart"
      description: "SyncStatus enum, SyncState, SyncNotifier, syncProvider — 301 lines"
  modified: []

decisions:
  - id: D1
    decision: "syncId written to Drift BEFORE Supabase call"
    rationale: "If Supabase call fails, retry reads same syncId from Drift → idempotent upsert"
    alternatives: "Write syncId after success — loses idempotency on retry"
  - id: D2
    decision: "Per-method SyncService factory (_createService) rather than stored instance"
    rationale: "Supabase client may be null when notifier first builds; lazy creation avoids null checks on field"
    alternatives: "Store as field in build() — requires null-safe field type"
  - id: D3
    decision: "_trySetState() helper for all async state assignments"
    rationale: "StateError thrown when notifier disposed mid async-gap; catch once in helper vs every callsite"
    alternatives: "Individual try/catch at each state = assignment"
  - id: D4
    decision: "Offline queue uses SharedPreferences JSON-encoded List<int>"
    rationale: "Matches v1.1 localStorage queue semantics; survives app restart"
    alternatives: "Drift table for queue — adds schema complexity for transient state"

metrics:
  duration: "5 minutes"
  completed: "2026-02-21"
  tasks-completed: 2
  tasks-total: 2
  lines-added: 895
---

# Phase 13 Plan 02: Sync Engine + State Machine Summary

## What Was Built

**SyncService** (`flutter_app/lib/services/sync_service.dart`) — the core sync engine mirroring v1.1's `sync-engine.ts` adapted for Drift + Supabase Flutter. Handles:

- `pushWorkout(int localWorkoutId)` — resolves all syncIds, pushes cycle (FK first), workout, sets, PRs, and lazy ORMs
- `pushCycle(int localCycleId, String userId)` — ensures syncId, upserts to `active_cycles`
- `pullLatest()` — pulls all 5 tables from Supabase, merges into Drift (cloud wins, FK order: cycles → workouts → sets → ORMs → PRs)
- `uploadAllLocalData(String userId)` — pushes all local rows lacking syncId (first-sync after sign-in)
- `enqueue/dequeue/getQueue/drainQueue` — offline retry queue via SharedPreferences
- `withRetry<T>` — exponential back-off (1s, 2s, 4s, max 3 attempts)

**SyncNotifier** (`flutter_app/lib/shared/providers/sync_provider.dart`) — Riverpod 3.x `NotifierProvider` state machine:

- `SyncStatus` enum: `disabled / offline / pending / syncing / synced / error`
- `SyncState` immutable value class with `copyWith`
- `build()` subscribes to `supabase.auth.onAuthStateChange` and `ref.listen(isOnlineProvider)`, seeded from current session
- `syncAfterWorkout(int workoutId)` — push immediately if online+auth, enqueue if offline
- `_onAuthenticated()` — full first-sync: uploadAll → pullLatest → drainQueue
- `pullFromCloud()` — public manual pull
- `_trySetState()` — safe async state setter (swallows `StateError` on dispose)

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `flutter analyze --no-fatal-infos` → clean (0 issues, full project)
- Both files created with all required exports
- `pushWorkout` / `withRetry` / `enqueue` / `Uuid().v4()` / `SyncStatus` / `SyncNotifier` / `syncProvider` / `syncAfterWorkout` / `onAuthStateChange` all present

## Next Phase Readiness

Plan 13-03 (Sync UI badge) can start immediately — `syncProvider` is ready to consume.
Plan 13-04 (workout completion integration) can call `ref.read(syncProvider.notifier).syncAfterWorkout(workoutId)`.

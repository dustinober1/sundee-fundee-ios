---
phase: "03"
plan: "01"
name: "sync-infrastructure"
subsystem: "cloud-sync"
tags: ["supabase", "middleware", "dexie", "offline-first", "rls", "pkce"]

dependency-graph:
  requires:
    - "01-01: recommendation engine (db schema established)"
    - "02-01: dexie tables (completedWorkouts, oneRepMaxes, personalRecords)"
  provides:
    - "Session token refresh on every request (middleware)"
    - "PKCE auth callback route for magic link / OAuth"
    - "Complete sync engine: push, pull, retry, offline queue"
    - "Supabase schema SQL with RLS policies"
  affects:
    - "03-02: sync trigger hooks will import from src/lib/sync"
    - "03-03: sync status UI uses useOnlineStatus"

tech-stack:
  added: []
  patterns:
    - "Singleton Supabase browser client (prevents duplicate connections)"
    - "Offline queue via localStorage with enqueue/dequeue"
    - "withRetry exponential backoff for network resilience"
    - "Duck-typing Date detection for TypeScript strict compatibility"
    - "bulkPut merge strategy (insert-or-replace, no local data loss)"

key-files:
  created:
    - middleware.ts
    - src/app/auth/callback/route.ts
    - src/lib/sync/sync-engine.ts
    - src/lib/sync/sync-transforms.ts
    - src/lib/sync/sync-queue.ts
    - src/lib/sync/index.ts
    - src/hooks/use-online-status.ts
    - supabase/schema.sql
  modified:
    - src/lib/supabase/client.ts

decisions:
  - id: "singleton-supabase-client"
    choice: "Module-level singleton for browser Supabase client"
    rationale: "Prevents multiple GoTrueClient instances warning in React apps"
  - id: "localstorage-offline-queue"
    choice: "localStorage for pending workout IDs"
    rationale: "Survives page refreshes, works without service worker, simple to implement"
  - id: "bulkput-merge-strategy"
    choice: "Dexie bulkPut (insert-or-replace) for pull"
    rationale: "Merges cloud data without deleting local-only records; safe for offline-first"
  - id: "duck-typing-date"
    choice: "'toISOString' in value duck-type guard instead of instanceof Date"
    rationale: "TypeScript strict mode rejects instanceof on unknown; duck-typing is compatible"

metrics:
  duration: "~3 minutes"
  tasks-completed: 3
  completed: "2026-02-19"
---

# Phase 03 Plan 01: Sync Infrastructure Summary

**One-liner:** Supabase middleware + PKCE callback + offline sync engine (push/pull/retry/queue) with Dexie ↔ Supabase camelCase/snake_case transforms and RLS schema.

## What Was Built

### Task 1 — Middleware & Auth Callback
- **`middleware.ts`** (project root): Intercepts every non-static request, refreshes Supabase session tokens via `createServerClient` with cookie handlers. Ensures auth tokens never expire silently across navigation.
- **`src/app/auth/callback/route.ts`**: PKCE code exchange endpoint. Receives `?code=` from magic link or OAuth redirect, calls `exchangeCodeForSession`, then redirects to `/dashboard` (or `?next=` param).

### Task 2 — Sync Engine Module
- **`src/lib/supabase/client.ts`**: Upgraded to singleton pattern — module-level `client` variable prevents multiple `GoTrueClient` instances in the browser.
- **`src/lib/sync/sync-transforms.ts`**: Bidirectional mapping between Dexie (camelCase, Date objects) and Supabase (snake_case, ISO strings). Exports `toSupabaseRows` and `fromSupabaseRows`.
- **`src/lib/sync/sync-queue.ts`**: localStorage-backed queue for offline workout IDs. Exports `enqueueWorkout`, `dequeueWorkout`, `getQueue`, `clearQueue`. Safe to call server-side (returns empty array).
- **`src/lib/sync/sync-engine.ts`**: Core sync logic:
  - `withRetry<T>(fn, maxAttempts, delayMs)`: Generic exponential backoff retry
  - `pushWorkout(workoutId)`: Upserts single workout + its sets to Supabase, dequeues on success
  - `pullLatest()`: Pulls all 5 tables from Supabase and merges into Dexie via `bulkPut`
  - `uploadAllLocalData()`: Batch-uploads entire local Dexie database to Supabase (initial sync)
- **`src/lib/sync/index.ts`**: Barrel re-export of all sync functions
- **`src/hooks/use-online-status.ts`**: `useSyncExternalStore`-based hook that subscribes to `window` online/offline events. Hydration-safe with `getServerSnapshot` returning `true`.

### Task 3 — Supabase Schema
- **`supabase/schema.sql`**: Complete DDL for 5 tables (users, one_rep_maxes, active_cycles, completed_workouts, completed_sets, personal_records). Every table has:
  - RLS enabled
  - Owner-only policy: `user_id = auth.uid()`
  - Performance indexes on user_id + frequently-queried columns

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript strict mode: `instanceof` on `unknown` type fails compilation**

- **Found during:** Build verification
- **Issue:** `Object.entries(r)` returns `unknown` values in strict TypeScript; `instanceof Date` is disallowed on `unknown`
- **Fix:** Added `isDate()` type guard using duck-typing (`'toISOString' in value`) which TypeScript accepts
- **Files modified:** `src/lib/sync/sync-transforms.ts`
- **Commit:** `1dc2f58`

## Verification Results

- `npm run build` ✅ — No TypeScript errors, all 10 routes compiled
- All 9 files exist at expected paths ✅
- sync-engine.ts exports: `pushWorkout`, `pullLatest`, `uploadAllLocalData`, `withRetry` ✅
- Auth callback route appears as `ƒ /auth/callback` (dynamic) in build output ✅
- Middleware proxy shown in build output ✅

## Commits

| Commit | Description |
|--------|-------------|
| `134a512` | feat(03-01): add middleware session refresh and auth callback route |
| `b287f7a` | feat(03-01): add sync engine module and upgrade Supabase client |
| `eb5f352` | feat(03-01): add Supabase schema with RLS policies |
| `1dc2f58` | fix(03-01): use duck-typing instead of instanceof for Date check in sync-transforms |

## Next Phase Readiness

**03-02 (Sync Trigger Hooks)** can now:
- `import { pushWorkout, pullLatest, enqueueWorkout } from '@/lib/sync'`
- `import { useOnlineStatus } from '@/hooks/use-online-status'`
- Wire up `useEffect` to trigger sync on online status change and after workout completion

**Blockers / Concerns for 03-02:**
- Supabase schema must be applied to the actual Supabase project before live sync tests work
- `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` env vars must be set in `.env.local`

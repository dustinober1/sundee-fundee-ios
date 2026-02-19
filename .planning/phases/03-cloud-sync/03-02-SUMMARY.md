---
phase: "03"
plan: "02"
name: "auth-ui-sync"
subsystem: "cloud-sync"
tags: ["supabase", "auth", "magic-link", "oauth", "shadcn", "user-context", "offline-queue"]

dependency-graph:
  requires:
    - "03-01: sync infrastructure (pushWorkout, pullLatest, uploadAllLocalData, withRetry, queue ops)"
    - "02-01: dexie tables (completedWorkouts, oneRepMaxes)"
  provides:
    - "AuthDialog: magic link + Google OAuth sign-in UI"
    - "SyncNudge/SyncNudgeCard: nudge → auth → upload-prompt flow"
    - "UserContext: full auth state (authUser, isAuthenticated, syncStatus, lastSyncedAt, isOnline)"
    - "syncAfterWorkout: auto-push or enqueue on workout completion"
    - "uploadExistingData: bulk upload all local workouts to cloud"
    - "popover shadcn component installed"
    - "SyncStatus includes 'error' for post-retry failure"
  affects:
    - "03-03: sync status UI will consume syncStatus, lastSyncedAt from UserContext"

tech-stack:
  added:
    - "@radix-ui/react-popover (via shadcn popover)"
  patterns:
    - "Null-guarded Supabase browser client (safe SSR prerender without env vars)"
    - "isSyncConfigured flag disables all sync ops gracefully when unconfigured"
    - "onAuthStateChange listener for real-time auth state tracking"
    - "processQueue drains localStorage offline queue on reconnect/auth"
    - "Auto-pull on visibilitychange for fresh data on tab focus"
    - "SyncNudge state machine: nudge → auth → upload-prompt → done"

key-files:
  created:
    - src/components/ui/popover.tsx
    - src/components/auth/auth-dialog.tsx
    - src/components/auth/sync-nudge.tsx
  modified:
    - src/types/user.ts
    - src/contexts/user-context.tsx
    - src/lib/supabase/client.ts
    - middleware.ts
    - src/app/workout/[id]/page.tsx

decisions:
  - id: "null-supabase-client"
    choice: "createClient() returns null when env vars not set"
    rationale: "Prevents @supabase/ssr throw during Next.js static prerender; app works offline-only without config"
  - id: "sync-configured-flag"
    choice: "isSyncConfigured = supabase !== null; gates all sync/auth ops"
    rationale: "Single flag cleanly disables sync when Supabase unconfigured vs checking env vars everywhere"
  - id: "error-status-after-retry"
    choice: "setSyncStatus('error') after withRetry exhaustion"
    rationale: "Distinguishes transient 'pending' (offline, will retry) from terminal 'error' (retried and failed)"

metrics:
  tasks-completed: 4
  deviations: 3
  duration: "~45 minutes"
  completed: "2026-02-19"
---

# Phase 03 Plan 02: Auth UI & Sync Summary

**One-liner:** shadcn popover + magic link/OAuth auth dialog + sync nudge flow + Supabase auth wired into UserContext with auto-queue-drain, auto-pull on focus, and syncAfterWorkout hooked to workout completion.

## What Was Built

### Task 1: shadcn Popover + SyncStatus 'error'
- Installed `@radix-ui/react-popover` via `npx shadcn@latest add popover`
- Added `'error'` to `SyncStatus` union — distinguishes post-retry failure from pending/offline

### Task 2: Auth Components
**`src/components/auth/auth-dialog.tsx`**
- Magic link sign-in via `supabase.auth.signInWithOtp()`
- Google OAuth via `supabase.auth.signInWithOAuth({ provider: 'google' })`
- Email-sent confirmation state (step machine: form → email-sent)
- Error display for auth failures
- PKCE redirect to `/auth/callback`

**`src/components/auth/sync-nudge.tsx`**
- `SyncNudge`: full flow (nudge → auth dialog → upload-prompt → uploading → done)
- `SyncNudgeCard`: compact dashboard card version
- Skips straight to upload-prompt if already authenticated
- "Upload existing data?" is the locked post-auth decision

### Task 3: UserContext Auth Integration
Replaced minimal UserContext with full auth + sync integration:
- `supabase.auth.getUser()` on mount for initial session
- `supabase.auth.onAuthStateChange()` listener for sign-in/out tracking
- `useOnlineStatus()` for connectivity detection
- `processQueue`: drains offline localStorage queue on reconnect/auth
- Auto-sync effect: queue drain + pull on `isOnline && isAuthenticated` change
- Auto-pull on `visibilitychange` to 'visible'
- `syncAfterWorkout(id)`: push if online, enqueue if offline
- `pullFromCloud()`, `uploadExistingData()`, `signOut()` operations
- Context exposes: `authUser`, `isAuthenticated`, `syncStatus`, `lastSyncedAt`, `isOnline`

### Task 4: Wire syncAfterWorkout
- `handleWorkoutComplete` in `src/app/workout/[id]/page.tsx` now calls `syncAfterWorkout(workoutId)` after all sets saved to Dexie

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript strict mode: implicit 'any' in auth callbacks**

- **Found during:** Verification (`npm run build`)
- **Issue:** `supabase.auth.getUser().then(({ data }) => ...)` and `onAuthStateChange((_event, session) => ...)` both trigger TS7031 (implicit any) under strict mode
- **Fix:** Added explicit type annotations `{ data: { user: SupabaseUser | null }; error: unknown }` and `(_event: AuthChangeEvent, session: Session | null)`. Imported `AuthChangeEvent`, `Session` from `@supabase/supabase-js`
- **Files modified:** `src/contexts/user-context.tsx`
- **Commit:** `2981e78`

**2. [Rule 1 - Bug] Supabase browser client throws during Next.js prerender**

- **Found during:** Verification (`npm run build`) — `/_not-found` prerender failed
- **Issue:** `createBrowserClient(undefined, undefined)` throws `@supabase/ssr: Your project's URL and API key are required` when env vars not set at build time. Next.js SSR-renders `UserProvider` (a 'use client' component) for initial HTML of all pages including `/_not-found`
- **Fix:** `createClient()` returns `null` when env vars missing. `UserProvider` checks `isSyncConfigured = supabase !== null` and gates all sync/auth operations. `syncStatus` set to `'disabled'` when unconfigured
- **Files modified:** `src/lib/supabase/client.ts`, `src/contexts/user-context.tsx`
- **Commit:** `2981e78`

**3. [Rule 3 - Blocking] Middleware crashed same way during prerender**

- **Found during:** Same build failure investigation
- **Fix:** Added early-return guard in `middleware.ts` when env vars are not set
- **Files modified:** `middleware.ts`
- **Commit:** `2981e78`

## Must-Haves Status

| Truth | Status |
|-------|--------|
| User can sign in via magic link email | ✅ AuthDialog with signInWithOtp |
| User can sign in via Google OAuth | ✅ AuthDialog with signInWithOAuth |
| User sees 'Upload existing data?' dialog on first sign-in if local workouts exist | ✅ SyncNudge upload-prompt step |
| User sees sync nudge after first completed workout (or on dashboard) | ✅ SyncNudge/SyncNudgeCard components ready |
| Auth state persists across page reloads | ✅ supabase.auth.getUser() on init + onAuthStateChange |
| UserContext exposes authUserId and auth-aware syncStatus | ✅ authUser, isAuthenticated, syncStatus in context |
| Workout completion triggers syncAfterWorkout automatically | ✅ handleWorkoutComplete calls syncAfterWorkout(workoutId) |
| SyncStatus type includes 'error' for post-retry failure state | ✅ Added to types/user.ts |

## Next Phase Readiness

**Ready for 03-03:** Sync status UI can import `syncStatus`, `lastSyncedAt`, `isOnline`, `isAuthenticated`, `signOut` from `useUser()`. All sync infrastructure is in place.

**No blockers.**

# Phase 3: Cloud Sync - Research

**Researched:** 2026-02-19
**Domain:** Supabase SSR + Next.js 16 App Router auth, offline sync, conflict resolution
**Confidence:** HIGH (verified against installed node_modules source + type definitions)

---

## Summary

Phase 3 wires a fully-optional Supabase cloud sync layer on top of the existing Dexie-first architecture. The user never has to sign in; sync is discoverable after the first workout and managed from the Dashboard top bar. Auth uses `@supabase/ssr@0.8.0` (already installed), which forces **PKCE flow** — this requires a middleware file and an auth-callback route that the project does not yet have.

The biggest architectural decision is the **user identity mapping problem**: local Dexie user IDs are device-generated UUIDs that differ across devices; Supabase Auth assigns a different `auth.uid()`. The sync layer must map between them — the recommended approach is to use `auth.uid()` as `user_id` in all Supabase tables while keeping local IDs intact in Dexie, with the sync engine performing the substitution on push and on pull/restore.

The sync engine itself is a plain TypeScript module at `src/lib/sync/`. It is not a background service worker — it is called explicitly at (a) workout completion, (b) app foreground, and (c) reconnect. Offline queuing uses `localStorage` (simplest path — no Service Worker needed for v1).

**Primary recommendation:** Build `src/lib/sync/sync-engine.ts` as the single source of truth for all cloud I/O. Auth state drives whether sync runs. Everything else (UI status, retry, queue) lives around this core module.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@supabase/ssr` | 0.8.0 (installed) | Browser + Server Supabase clients | Official SSR package, replaces deprecated auth-helpers |
| `@supabase/supabase-js` | 2.95.3 (transitive) | Core Supabase client | Bundled with @supabase/ssr |
| `next` | 16.1.6 (installed) | App Router middleware + route handlers | Project constraint |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `shadcn popover` | via `@radix-ui/react-popover` | Sync status popover UI | Popover not yet added to project — add with `npx shadcn@latest add popover` |
| `localStorage` | browser built-in | Offline sync queue persistence | Simpler than IndexedDB queue for v1; survives page refresh |

### Popover component

Popover is NOT yet in `src/components/ui/`. It must be added:

```bash
npx shadcn@latest add popover
```

`@radix-ui/react-popover` is already available (installed via `radix-ui@1.4.3` which re-exports it as `react-popover`).

### Installation needed

```bash
# No new npm packages required — popover comes from shadcn CLI
npx shadcn@latest add popover
```

---

## Architecture Patterns

### Recommended Project Structure

```
src/
├── lib/
│   └── sync/
│       ├── sync-engine.ts        # Core push/pull logic
│       ├── sync-queue.ts         # Offline queue (localStorage)
│       ├── sync-transforms.ts    # Dexie ↔ Supabase row mapping
│       └── index.ts              # Public exports
├── hooks/
│   ├── use-sync.ts               # React hook wrapping sync engine + status
│   └── use-online-status.ts      # navigator.onLine + event listeners
├── app/
│   ├── auth/
│   │   └── callback/
│   │       └── route.ts          # PKCE code exchange (REQUIRED by @supabase/ssr)
│   └── dashboard/
│       └── page.tsx              # Add DashboardHeader with sync indicator
├── components/
│   ├── auth/
│   │   ├── auth-dialog.tsx       # Magic link + Google OAuth sign-in
│   │   └── sync-nudge.tsx        # Post-workout soft prompt
│   └── dashboard/
│       ├── dashboard-header.tsx  # Top bar (avatar, sync status)
│       └── sync-status-popover.tsx
└── middleware.ts                 # Session refresh (REQUIRED by @supabase/ssr)
```

### Pattern 1: Middleware for Session Refresh (REQUIRED)

`@supabase/ssr@0.8.0` with PKCE flow requires a `middleware.ts` at the project root that refreshes the auth token on every request. Without it, the session expires silently and `getUser()` returns null unexpectedly.

```typescript
// middleware.ts  (at project root, NOT in src/)
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // Refresh session — do NOT use getSession() here (security risk)
  await supabase.auth.getUser();

  return supabaseResponse;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

**Source:** Verified against `createServerClient.js` source in installed node_modules — confirms PKCE flow (`flowType: "pkce"`) and cookie-based session persistence.

### Pattern 2: Auth Callback Route (REQUIRED for PKCE)

Magic link and Google OAuth both redirect to this route after authentication. It exchanges the PKCE `code` for a session.

```typescript
// src/app/auth/callback/route.ts
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get('code');
  const next = searchParams.get('next') ?? '/dashboard';

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  // Auth failed — redirect to error state or home
  return NextResponse.redirect(`${origin}/?error=auth_failed`);
}
```

**Source:** Verified `exchangeCodeForSession` method exists in installed `@supabase/auth-js` type definitions.

### Pattern 3: Magic Link + Google OAuth Trigger

```typescript
// In auth-dialog.tsx (client component)
import { createClient } from '@/lib/supabase/client';

const supabase = createClient();

// Magic link
await supabase.auth.signInWithOtp({
  email,
  options: {
    emailRedirectTo: `${window.location.origin}/auth/callback`,
  },
});

// Google OAuth
await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: `${window.location.origin}/auth/callback`,
  },
});
```

**Source:** Verified `signInWithOtp` and `signInWithOAuth` in installed auth-js type definitions.

### Pattern 4: Sync Engine Module

The sync engine is a pure TypeScript module — no React, no hooks. It is called by the hook layer.

```typescript
// src/lib/sync/sync-engine.ts
import { createClient } from '@/lib/supabase/client';
import { db } from '@/lib/db/dexie';
import { toSupabaseRows, fromSupabaseRows } from './sync-transforms';
import { SyncQueue } from './sync-queue';

export type SyncResult = { ok: true } | { ok: false; error: string };

/**
 * Push a completed workout (and its sets) to Supabase.
 * Called immediately after handleWorkoutComplete().
 */
export async function pushWorkout(
  workoutId: string,
  authUserId: string
): Promise<SyncResult> {
  const supabase = createClient();

  const workout = await db.completedWorkouts.get(workoutId);
  if (!workout) return { ok: false, error: 'Workout not found' };

  const sets = await db.completedSets
    .where('workoutId').equals(workoutId).toArray();

  const { error: wErr } = await supabase
    .from('completed_workouts')
    .upsert(toSupabaseRows([workout], authUserId), { onConflict: 'id' });

  if (wErr) return { ok: false, error: wErr.message };

  const { error: sErr } = await supabase
    .from('completed_sets')
    .upsert(toSupabaseRows(sets, authUserId), { onConflict: 'id' });

  if (sErr) return { ok: false, error: sErr.message };

  return { ok: true };
}

/**
 * Pull latest cloud data and merge into local Dexie (last-write-wins by updatedAt).
 */
export async function pullLatest(authUserId: string): Promise<SyncResult> {
  const supabase = createClient();

  // Pull completed workouts
  const { data: cloudWorkouts, error: wErr } = await supabase
    .from('completed_workouts')
    .select('*')
    .eq('user_id', authUserId)
    .order('completed_at', { ascending: false });

  if (wErr) return { ok: false, error: wErr.message };

  // Pull completed sets for those workouts
  const workoutIds = (cloudWorkouts ?? []).map(w => w.id);
  const { data: cloudSets, error: sErr } = workoutIds.length > 0
    ? await supabase.from('completed_sets').select('*').in('workout_id', workoutIds)
    : { data: [], error: null };

  if (sErr) return { ok: false, error: sErr.message };

  // Merge into Dexie (put = upsert semantics in Dexie)
  if (cloudWorkouts?.length) {
    await db.completedWorkouts.bulkPut(fromSupabaseRows(cloudWorkouts));
  }
  if (cloudSets?.length) {
    await db.completedSets.bulkPut(fromSupabaseRows(cloudSets));
  }

  return { ok: true };
}

/**
 * Upload ALL local data to Supabase (used for "upload existing data" on first sign-in).
 */
export async function uploadAllLocalData(authUserId: string): Promise<SyncResult> {
  const supabase = createClient();

  const [workouts, sets, orms, cycles, prs] = await Promise.all([
    db.completedWorkouts.toArray(),
    db.completedSets.toArray(),
    db.oneRepMaxes.toArray(),
    db.activeCycles.toArray(),
    db.personalRecords.toArray(),
  ]);

  // Upsert in dependency order: cycles before workouts, workouts before sets
  const ops = [
    supabase.from('active_cycles').upsert(toSupabaseRows(cycles, authUserId), { onConflict: 'id' }),
    supabase.from('one_rep_maxes').upsert(toSupabaseRows(orms, authUserId), { onConflict: 'id' }),
    supabase.from('completed_workouts').upsert(toSupabaseRows(workouts, authUserId), { onConflict: 'id' }),
    supabase.from('completed_sets').upsert(toSupabaseRows(sets, authUserId), { onConflict: 'id' }),
    supabase.from('personal_records').upsert(toSupabaseRows(prs, authUserId), { onConflict: 'id' }),
  ];

  const results = await Promise.all(ops);
  const firstError = results.find(r => r.error);
  if (firstError?.error) return { ok: false, error: firstError.error.message };

  return { ok: true };
}
```

### Pattern 5: User Identity Mapping (Critical)

Local Dexie user IDs (`user.id`) are device-generated UUIDs that differ per device. Supabase Auth assigns `auth.uid()` as the user identity. These **will not match**.

**Strategy:**
- Supabase tables have `user_id TEXT` column = `auth.uid()` (used for RLS)
- Local Dexie `userId` fields remain as-is — not mutated
- `toSupabaseRows()` substitutes `userId → auth.uid()` during upload
- `fromSupabaseRows()` on restore: create a mapping from `auth.uid()` to local user ID, substituting back

```typescript
// src/lib/sync/sync-transforms.ts

/** Convert Dexie records to Supabase snake_case rows, injecting auth user_id */
export function toSupabaseRows<T extends { id: string; userId?: string }>(
  records: T[],
  authUserId: string
): Record<string, unknown>[] {
  return records.map(r => {
    const row: Record<string, unknown> = {};
    // camelCase → snake_case conversion + inject user_id
    for (const [k, v] of Object.entries(r)) {
      const snakeKey = k.replace(/([A-Z])/g, '_$1').toLowerCase();
      row[snakeKey] = v instanceof Date ? v.toISOString() : v;
    }
    row['user_id'] = authUserId; // always override with auth UID for RLS
    row['updated_at'] = new Date().toISOString(); // for last-write-wins
    return row;
  });
}

/** Convert Supabase rows back to Dexie-compatible camelCase objects */
export function fromSupabaseRows(
  rows: Record<string, unknown>[]
): Record<string, unknown>[] {
  return rows.map(row => {
    const record: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(row)) {
      if (k === 'user_id' || k === 'updated_at') continue; // skip Supabase-only fields
      const camelKey = k.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
      // ISO date strings → Date objects for Dexie
      record[camelKey] = typeof v === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(v)
        ? new Date(v)
        : v;
    }
    return record;
  });
}
```

**Important:** On restore to a fresh device, the `userId` in pulled records will be `auth.uid()` (set during upload). The local Dexie user record's `id` is a new UUID. The sync engine must update pulled workout `userId` fields to match the new local user ID. Simplest approach: after `createUser()` on fresh device, run a post-restore remap in Dexie.

### Pattern 6: Retry with Exponential Backoff

```typescript
// src/lib/sync/sync-engine.ts
export async function withRetry<T>(
  fn: () => Promise<T>,
  maxAttempts = 3,
  delays = [2000, 5000, 10000]
): Promise<T> {
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxAttempts - 1) throw err;
      await new Promise(res => setTimeout(res, delays[attempt]));
    }
  }
  throw new Error('Max retries exceeded');
}

// Usage:
// const result = await withRetry(() => pushWorkout(workoutId, authUserId));
// Silent on attempt 1-2; surface error to user only after attempt 3 throws.
```

### Pattern 7: Offline Detection Hook

```typescript
// src/hooks/use-online-status.ts
'use client';
import { useEffect, useState } from 'react';

export function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(
    typeof navigator !== 'undefined' ? navigator.onLine : true
  );

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return isOnline;
}
```

**Note:** `navigator.onLine` is unreliable on some mobile browsers (can be `true` with no actual connectivity). For v1 this is acceptable — the CONTEXT.md only requires showing an "Offline" indicator and queuing, not verifying actual connectivity. Silent retry after reconnect handles the edge case.

### Pattern 8: Offline Queue

```typescript
// src/lib/sync/sync-queue.ts
const QUEUE_KEY = 'sync_pending_workout_ids';

export function enqueueWorkout(workoutId: string): void {
  const existing = getQueue();
  if (!existing.includes(workoutId)) {
    localStorage.setItem(QUEUE_KEY, JSON.stringify([...existing, workoutId]));
  }
}

export function dequeueWorkout(workoutId: string): void {
  const updated = getQueue().filter(id => id !== workoutId);
  localStorage.setItem(QUEUE_KEY, JSON.stringify(updated));
}

export function getQueue(): string[] {
  try {
    return JSON.parse(localStorage.getItem(QUEUE_KEY) ?? '[]');
  } catch {
    return [];
  }
}
```

### Pattern 9: useSyncStatus Hook (ties it all together)

```typescript
// src/hooks/use-sync.ts
'use client';
import { useEffect, useCallback, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { pushWorkout, pullLatest, withRetry } from '@/lib/sync/sync-engine';
import { getQueue, enqueueWorkout, dequeueWorkout } from '@/lib/sync/sync-queue';
import { useOnlineStatus } from './use-online-status';
import type { SyncStatus } from '@/types/user';

export function useSync() {
  const isOnline = useOnlineStatus();
  const [syncStatus, setSyncStatus] = useState<SyncStatus>('disabled');
  const [lastSyncedAt, setLastSyncedAt] = useState<Date | null>(null);
  const [authUserId, setAuthUserId] = useState<string | null>(null);

  // Resolve auth user on mount
  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getUser().then(({ data }) => {
      setAuthUserId(data.user?.id ?? null);
      setSyncStatus(data.user ? (isOnline ? 'pending' : 'offline') : 'disabled');
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_, session) => {
      setAuthUserId(session?.user.id ?? null);
    });
    return () => listener.subscription.unsubscribe();
  }, []);

  // When coming back online, flush the queue
  useEffect(() => {
    if (!isOnline || !authUserId) return;
    setSyncStatus('syncing');
    const queue = getQueue();
    Promise.all(queue.map(id =>
      withRetry(() => pushWorkout(id, authUserId))
        .then(() => dequeueWorkout(id))
    )).then(() => {
      return withRetry(() => pullLatest(authUserId));
    }).then(() => {
      setSyncStatus('synced');
      setLastSyncedAt(new Date());
    }).catch(() => {
      setSyncStatus('error');
    });
  }, [isOnline, authUserId]);

  const syncAfterWorkout = useCallback(async (workoutId: string) => {
    if (!authUserId) return;
    if (!isOnline) {
      enqueueWorkout(workoutId);
      setSyncStatus('offline');
      return;
    }
    setSyncStatus('syncing');
    try {
      await withRetry(() => pushWorkout(workoutId, authUserId));
      setSyncStatus('synced');
      setLastSyncedAt(new Date());
    } catch {
      setSyncStatus('error');
    }
  }, [authUserId, isOnline]);

  return { syncStatus, lastSyncedAt, syncAfterWorkout, authUserId };
}
```

### Anti-Patterns to Avoid

- **`getSession()` in Server Components:** Use `getUser()` instead. `getSession()` trusts client-provided data without verification — confirmed in `createServerClient.js` source. RLS won't protect you if you use `getSession()` server-side.
- **Creating multiple Supabase browser clients:** `createBrowserClient` is designed to be a singleton. Creating multiple instances causes auth state desync. Use a module-level cache or React context.
- **Calling `supabase.auth` from inside Next.js Server Components to write cookies:** Server Components cannot set cookies (they are read-only). Cookie writes must happen in middleware or Route Handlers only.
- **Syncing static program data:** The `programs` table contains static seed data — do not sync it to Supabase. Only sync user-generated tables: `users`, `oneRepMaxes`, `activeCycles`, `completedWorkouts`, `completedSets`, `personalRecords`.

---

## Supabase Table Schema

The 6 tables to sync. All use `id TEXT PRIMARY KEY` matching Dexie's string UUIDs. All have RLS enabled with policy `user_id = auth.uid()`.

### users

```sql
CREATE TABLE users (
  id           TEXT PRIMARY KEY,           -- local Dexie UUID
  user_id      TEXT NOT NULL DEFAULT auth.uid(), -- Supabase auth UID (RLS column)
  name         TEXT NOT NULL,
  experience_level TEXT NOT NULL,          -- 'beginner' | 'intermediate' | 'advanced'
  primary_goal TEXT NOT NULL,              -- 'strength' | 'hypertrophy' | 'explosiveness'
  created_at   TIMESTAMPTZ NOT NULL,
  synced_at    TIMESTAMPTZ,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_owner" ON users
  FOR ALL USING (user_id = auth.uid());
```

### one_rep_maxes

```sql
CREATE TABLE one_rep_maxes (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL DEFAULT auth.uid(),
  exercise_id TEXT NOT NULL,
  weight      NUMERIC NOT NULL,
  date        TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE one_rep_maxes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orms_owner" ON one_rep_maxes
  FOR ALL USING (user_id = auth.uid());
```

### active_cycles

```sql
CREATE TABLE active_cycles (
  id                  TEXT PRIMARY KEY,
  user_id             TEXT NOT NULL DEFAULT auth.uid(),
  program_id          TEXT NOT NULL,
  cycle_name          TEXT NOT NULL,
  start_date          TIMESTAMPTZ NOT NULL,
  current_week        INTEGER NOT NULL DEFAULT 1,
  current_session_id  TEXT,
  current_phase       TEXT,
  status              TEXT NOT NULL DEFAULT 'active',  -- 'active' | 'completed' | 'paused'
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE active_cycles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cycles_owner" ON active_cycles
  FOR ALL USING (user_id = auth.uid());
```

### completed_workouts

```sql
CREATE TABLE completed_workouts (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL DEFAULT auth.uid(),
  active_cycle_id TEXT NOT NULL,
  program_id      TEXT NOT NULL,
  week            INTEGER NOT NULL,
  day             INTEGER,
  session_id      TEXT,
  completed_at    TIMESTAMPTZ NOT NULL,
  duration        INTEGER,
  notes           TEXT,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE completed_workouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "workouts_owner" ON completed_workouts
  FOR ALL USING (user_id = auth.uid());
```

### completed_sets

```sql
CREATE TABLE completed_sets (
  id                TEXT PRIMARY KEY,
  user_id           TEXT NOT NULL DEFAULT auth.uid(),
  workout_id        TEXT NOT NULL,           -- references completed_workouts(id)
  exercise_id       TEXT NOT NULL,
  set_number        INTEGER NOT NULL,
  prescribed_weight NUMERIC,
  actual_weight     NUMERIC NOT NULL,
  prescribed_reps   INTEGER NOT NULL,
  actual_reps       INTEGER NOT NULL,
  rpe               NUMERIC,
  rest_seconds      INTEGER,
  override_reason   TEXT,
  created_at        TIMESTAMPTZ NOT NULL,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE completed_sets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sets_owner" ON completed_sets
  FOR ALL USING (user_id = auth.uid());
```

### personal_records

```sql
CREATE TABLE personal_records (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL DEFAULT auth.uid(),
  exercise_id TEXT NOT NULL,
  type        TEXT NOT NULL,   -- 'weight' | 'volume'
  value       NUMERIC NOT NULL,
  workout_id  TEXT NOT NULL,
  date        TIMESTAMPTZ NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prs_owner" ON personal_records
  FOR ALL USING (user_id = auth.uid());
```

**Note:** No foreign keys across tables in Supabase v1. The IDs reference each other but without FK constraints — this avoids upsert ordering issues and simplifies the "local deletes don't propagate" requirement.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session token management | Custom cookie/JWT logic | `@supabase/ssr` middleware pattern | Token refresh, PKCE, secure storage already handled |
| Auth state listening | `setInterval` polling for auth changes | `supabase.auth.onAuthStateChange()` | Already fires on magic link confirm, OAuth redirect, sign out |
| Magic link email sending | Custom email service | `supabase.auth.signInWithOtp()` | Supabase handles email templates, rate limiting, token expiry |
| Google OAuth flow | Google SDK or manual PKCE | `supabase.auth.signInWithOAuth({ provider: 'google' })` | Supabase proxies OAuth, handles code exchange |
| Conflict resolution logic | Custom merge algorithms | Timestamp comparison (`completedAt` / `updated_at`) | Last-write-wins is the decided strategy — simple `bulkPut` handles it |
| Network retry logic | Complex state machine | Simple `withRetry()` wrapper with delays array | Three retries with fixed delays is sufficient for v1 |
| Offline queue persistence | Custom IndexedDB store | `localStorage` with JSON array | Queue is tiny (workout IDs only), survives page refresh, no lib needed |

---

## Common Pitfalls

### Pitfall 1: Missing Middleware — Sessions Expire Silently

**What goes wrong:** Without `middleware.ts`, the auth token is not refreshed on navigation. User appears logged in (session exists in cookie) but `getUser()` returns null after token expiry (~1 hour). Sync silently stops working.

**Why it happens:** `@supabase/ssr` uses PKCE flow with cookie-based session persistence. The refresh token exchange must happen in middleware to set the new cookie before the response.

**How to avoid:** Create `middleware.ts` at project root (NOT inside `src/`) with the pattern from Pattern 1 above. This is mandatory.

**Warning signs:** `supabase.auth.getUser()` returning `null` after navigating away and back, or after idle time.

### Pitfall 2: Missing Auth Callback Route — Magic Link 404s

**What goes wrong:** User clicks magic link email, gets a 404. OAuth redirect also fails.

**Why it happens:** Both magic link and Google OAuth redirect to `/auth/callback?code=...`. Without the `route.ts` handler, Next.js returns 404.

**How to avoid:** Create `src/app/auth/callback/route.ts` (Pattern 2) before testing any auth flow.

### Pitfall 3: Dexie User ID ≠ Supabase Auth UID

**What goes wrong:** RLS rejects all inserts because `user_id` in the uploaded row doesn't match `auth.uid()`.

**Why it happens:** Local user records use device-generated UUIDs (`generateId()`). Supabase Auth has its own UUID. These never match.

**How to avoid:** The `toSupabaseRows()` transform always overrides `user_id` with `authUserId` (the auth.uid()). Never attempt to sync the local user ID as the RLS column.

### Pitfall 4: Dates Stored as Strings in Supabase, Expected as Date Objects in Dexie

**What goes wrong:** After pulling from Supabase, `completedAt`, `date`, `startDate` etc. arrive as ISO strings. Dexie typed fields (`Table<CompletedWorkout>`) expect `Date` objects. Sorting by date breaks.

**How to avoid:** `fromSupabaseRows()` converts ISO strings back to `Date` objects using the regex `/^\d{4}-\d{2}-\d{2}T/` detection. Test this explicitly — it handles all date fields generically.

### Pitfall 5: Google OAuth Requires Redirect URI Configuration in Supabase Dashboard

**What goes wrong:** Google OAuth fails with "redirect_uri_mismatch" even when code is correct.

**Why it happens:** Google requires the exact redirect URI to be allowlisted in both the Google Cloud Console AND the Supabase Auth settings (under "URL Configuration").

**How to avoid:** In Supabase Dashboard → Authentication → URL Configuration, add:
- Site URL: `http://localhost:3000` (dev) and production URL
- Redirect URLs: `http://localhost:3000/auth/callback` and `https://yourdomain.com/auth/callback`

In Google Cloud Console → OAuth consent screen → Authorized redirect URIs, add the Supabase callback URL (NOT your app URL — Supabase proxies OAuth).

### Pitfall 6: `bulkPut` on Dexie Fails for Tables with Compound Indexes

**What goes wrong:** `db.table.bulkPut(rows)` throws if rows don't satisfy index constraints.

**Why it happens:** Dexie `bulkPut` validates primary key and some index fields.

**How to avoid:** Ensure `fromSupabaseRows()` correctly maps all non-nullable fields. Test with `bulkPut` in a try/catch and log errors per-table.

### Pitfall 7: Supabase Popover Not in shadcn Components

**What goes wrong:** Planning code for `<Popover>` but it doesn't exist in `src/components/ui/`.

**How to avoid:** Run `npx shadcn@latest add popover` before building the sync status popover. The radix dependency is already installed (`radix-ui` includes `react-popover`).

---

## Code Examples

### Auth State in React (browser client)

```typescript
// Source: installed @supabase/auth-js type definitions + createBrowserClient source
const supabase = createClient(); // from @/lib/supabase/client

// Get current user (always verified server-side)
const { data: { user } } = await supabase.auth.getUser();

// Listen for auth changes
const { data: { subscription } } = supabase.auth.onAuthStateChange(
  (event, session) => {
    // events: SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, USER_UPDATED
    if (event === 'SIGNED_IN') { /* start sync */ }
    if (event === 'SIGNED_OUT') { /* disable sync */ }
  }
);

// Cleanup
subscription.unsubscribe();
```

### Supabase Upsert (bulk upload without duplicates)

```typescript
// Source: verified in @supabase/postgrest-js type definitions
// onConflict: 'id' → PostgreSQL ON CONFLICT (id) DO UPDATE SET ...
const { error } = await supabase
  .from('completed_workouts')
  .upsert(rows, { onConflict: 'id' });
  // rows: array of objects — Supabase accepts up to 1000 rows per call
  // For larger datasets, chunk into batches of 500
```

### Chunked Batch Upsert (for large local histories)

```typescript
async function batchUpsert(
  table: string,
  rows: Record<string, unknown>[],
  chunkSize = 500
) {
  const supabase = createClient();
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    const { error } = await supabase
      .from(table)
      .upsert(chunk, { onConflict: 'id' });
    if (error) throw error;
  }
}
```

### App Foreground Pull Trigger

```typescript
// src/hooks/use-sync.ts — add to useEffect setup
useEffect(() => {
  if (!authUserId) return;

  const handleVisibilityChange = () => {
    if (document.visibilityState === 'visible' && isOnline) {
      // App came to foreground — pull latest
      setSyncStatus('syncing');
      withRetry(() => pullLatest(authUserId))
        .then(() => { setSyncStatus('synced'); setLastSyncedAt(new Date()); })
        .catch(() => setSyncStatus('error'));
    }
  };

  document.addEventListener('visibilitychange', handleVisibilityChange);
  return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
}, [authUserId, isOnline]);
```

### "Upload Existing Data?" Dialog — Supabase Side

```typescript
// After user confirms "yes" in the dialog
async function handleUploadExistingData(authUserId: string) {
  setSyncStatus('syncing');
  try {
    await withRetry(() => uploadAllLocalData(authUserId));
    setSyncStatus('synced');
    setLastSyncedAt(new Date());
  } catch (err) {
    setSyncStatus('error');
    // Show error toast — all 3 retries failed
  }
}
```

### Sync Status Display Logic

```typescript
// SyncStatusPopover uses these mappings
const STATUS_CONFIG: Record<SyncStatus, { icon: string; label: string; color: string }> = {
  synced:   { icon: '✓', label: 'Synced', color: 'text-green-600' },
  syncing:  { icon: '⟳', label: 'Syncing…', color: 'text-blue-500' },
  pending:  { icon: '⏱', label: 'Pending', color: 'text-yellow-500' },
  offline:  { icon: '○', label: 'Offline', color: 'text-muted-foreground' },
  disabled: { icon: '',  label: '',        color: '' },  // don't render
};
```

---

## @supabase/ssr + Next.js App Router Specific Gotchas

### 1. Middleware must be at project root, NOT in `src/`

Next.js looks for `middleware.ts` at the root of the project (same level as `next.config.ts`). The existing server client is at `src/lib/supabase/server.ts` but middleware goes at `/middleware.ts`.

### 2. `getSession()` is insecure server-side — always use `getUser()`

`getSession()` reads the session from the JWT in the cookie without calling Supabase Auth server. An attacker can forge a cookie and bypass RLS. `getUser()` sends the token to Supabase for validation. **Use `getUser()` everywhere server-side.**

### 3. Server Components cannot set auth cookies

The existing `server.ts` has a `try/catch` in `setAll()` that silently swallows errors when called from Server Components. This is intentional — only middleware can reliably write cookies. If you call `signIn()` from a Server Component action, cookies won't be set. **All auth operations must happen in Client Components or Route Handlers.**

### 4. `createBrowserClient` is called on every render — memoize it

```typescript
// src/lib/supabase/client.ts — upgrade to singleton
import { createBrowserClient } from '@supabase/ssr';

let client: ReturnType<typeof createBrowserClient> | null = null;

export function createClient() {
  if (!client) {
    client = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
  }
  return client;
}
```

### 5. App Router Route Handlers (not API Routes) for auth callback

`src/app/auth/callback/route.ts` is a Route Handler (uses `export async function GET`). This is different from old `pages/api/` routes. The `createServerClient` must use the `cookies()` from `next/headers`, which is the existing pattern in `src/lib/supabase/server.ts`.

### 6. `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` must exist in `.env.local`

These env vars are not in the repo yet (not committed to git, no `.env.example`). Both the browser client and server client require them. The build will fail without them. Create `.env.local` before any auth testing.

---

## Open Questions

1. **The local userId → auth.uid() mapping on restore**
   - What we know: `fromSupabaseRows()` produces records with `userId = auth.uid()` after pull
   - What's unclear: On a fresh device restore, the local `user` record has a new UUID. All pulled `completedWorkouts` will have `userId = auth.uid()`. These won't match `user.id`.
   - Recommendation: After restore pull, run a Dexie migration step: `db.completedWorkouts.toCollection().modify({ userId: newLocalUser.id })`. Document this as part of the restore flow.

2. **`completedSets` doesn't have a `user_id` in Dexie — should Supabase have one?**
   - What we know: `CompletedSet` has `workoutId` but no `userId`. RLS on `completed_sets` could use a join to `completed_workouts`.
   - What's unclear: Supabase RLS policies with joins are more complex.
   - Recommendation: Add a `user_id` column to `completed_sets` in Supabase anyway (denormalized but simpler). The `toSupabaseRows()` transform injects it from `authUserId`.

3. **`@supabase/ssr@0.8.0` — is there a breaking change vs 0.7.x?**
   - What we know: This is the installed version. No changelog in node_modules.
   - What's unclear: Whether the `CookieMethodsServer` API changed.
   - Recommendation: The existing `server.ts` uses `getAll/setAll` which matches `CookieMethodsServer` type in installed version — verified safe.

---

## Sources

### Primary (HIGH confidence)
- Installed `@supabase/ssr@0.8.0` source: `node_modules/@supabase/ssr/dist/main/` — confirmed PKCE flow, cookie methods API, createServerClient behavior
- Installed `@supabase/auth-js` type definitions — confirmed `signInWithOtp`, `signInWithOAuth`, `exchangeCodeForSession`, `onAuthStateChange`
- Installed `@supabase/postgrest-js` type definitions — confirmed `upsert(rows[], { onConflict })` API
- Project source: `src/lib/db/dexie.ts` — v4 schema confirmed, all table names and indexes
- Project source: `src/types/workout.ts`, `src/types/user.ts`, `src/types/cycle.ts` — all field names confirmed
- Project source: `src/app/workout/[id]/page.tsx` — confirmed `handleWorkoutComplete` + `saveCompletedWorkout` flow
- Project source: `src/contexts/user-context.tsx` — confirmed `syncStatus` state exists, hardcoded to `'offline'`

### Secondary (MEDIUM confidence)
- Supabase official docs pattern for middleware + auth callback: consistent with what `createServerClient.js` source implements
- `navigator.onLine` + `visibilitychange` pattern: well-established browser API, no library needed

### Tertiary (LOW confidence)
- Google OAuth redirect URI requirement in Supabase Dashboard: known from common community patterns, not directly verified against current Supabase dashboard

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already installed, verified from node_modules source
- Auth patterns: HIGH — verified against installed type definitions and source
- Supabase table schema: HIGH — directly derived from TypeScript types in codebase
- Architecture: HIGH — derived from existing code patterns
- Pitfalls: MEDIUM/HIGH — most verified against source; Google OAuth redirect URI config is MEDIUM

**Research date:** 2026-02-19
**Valid until:** 2026-03-21 (30 days — @supabase/ssr 0.8.0 is installed, stable API)

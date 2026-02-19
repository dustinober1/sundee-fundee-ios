# Phase 03: Cloud Sync - Research

**Researched:** 2026-02-18
**Domain:** Offline-first Data Synchronization
**Confidence:** HIGH

## Summary

This phase implements a robust offline-first synchronization system connecting the existing Dexie.js local database with Supabase. The goal is to ensure user data is securely backed up and available across devices without compromising the snappy, local-first experience. The architecture will rely on a "Local First, Sync Later" pattern where Dexie.js remains the source of truth for the UI, and a background synchronization engine handles replication to Supabase.

The recommended approach avoids complex third-party sync engines (like PowerSync or RxDB) in favor of a lightweight, custom synchronization hook system tailored to the specific data model. This reduces dependency overhead and aligns with the project's existing architecture. We will use a `sync_queue` table in Dexie to track mutations while offline, and a corresponding `deleted_at` soft-delete pattern in Supabase to handle deletions gracefully.

**Primary recommendation:** Implement a custom `useSync` hook and background worker that watches a local `sync_queue` table in Dexie, pushing changes to Supabase and pulling updates via `last_synced_at` timestamps.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Auth Experience:**
  - **Providers:** Google and Email/Password (Social auth preferred for friction-free start).
  - **Entry Point:** Global "Sign In / Sync" button in the header/sidebar, always visible.
  - **Goal:** Frictionless entry to protect data.

- **Sync Behavior:**
  - **Trigger:** Real-time sync on every save (e.g., finishing a workout, updating 1RM).
  - **Offline Handling:** Show a non-intrusive banner ("Offline - Changes queued") when sync fails.
  - **Queue:** Silent background queue that retries when online.

- **Conflict Handling:**
  - **Strategy:** User Choice for genuine conflicts (e.g., modified same workout on two devices).
  - **UI:** A "Conflict List" (likely in settings or a dedicated modal) where users resolve items.
  - **Granularity:** Workout/Object level (resolve the whole session, not individual sets/fields).

- **Data Migration:**
  - **First Sign-in (Empty Cloud):** Merge Local -> Cloud (upload existing local data).
  - **Sign-in (Existing Cloud Data):** Prompt user: "Use Cloud Data (replace local)" or "Merge Local & Cloud".
    - *Correction during discussion:* User initially said "Use Cloud", then clarified "Merge" for empty cloud case. The safe default for non-empty cloud + existing local is to ASK.

### Claude's Discretion
- Specific UI for the conflict resolution list.
- exact retry backoff logic for offline queue.
- Database schema for Supabase (matching Dexie structure).

### Deferred Ideas (OUT OF SCOPE)
- Social feed / Sharing (Phase 5+)
- Push notifications for social interactions.
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **supabase-js** | ^2.39.0 | Auth & Database Client | Official client, robust TypeScript support, isomorphic. |
| **@supabase/ssr** | ^0.1.0 | Next.js Integration | Modern standard for Next.js App Router auth & cookie handling. |
| **dexie** | ^4.0.1 | Local Database | Existing project choice, best-in-class IndexedDB wrapper. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **tanstack/react-query** | * | Data Fetching/State | Optional but good for managing sync state if complex. (Project likely uses useEffect/Context currently). |
| **date-fns** | ^3.0.0 | Date Manipulation | Handling ISO timestamps for sync comparisons. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| **Custom Sync** | **PowerSync** | PowerSync is excellent but adds significant infrastructure complexity (custom docker containers, separate service). Overkill for this specific app scope. |
| **Custom Sync** | **Dexie Cloud** | Paid SaaS service. Locks into Dexie ecosystem completely. User chose Supabase explicitly. |
| **Custom Sync** | **RxDB** | Requires rewriting the entire data layer (RxDB replaces Dexie). Too invasive for this phase. |

**Installation:**
```bash
npm install @supabase/supabase-js @supabase/ssr
```

## Architecture Patterns

### Recommended Sync Architecture: "Queue & Cursor"

1.  **Local Changes (The Queue):**
    -   Create a `sync_queue` table in Dexie: `{ id, table, recordId, action: 'create'|'update'|'delete', data, createdAt }`.
    -   Use Dexie Hooks (`db.table.hook('creating'|'updating'|'deleting')`) to automatically populate this queue whenever data changes.
    -   **Benefit:** Decouples UI from Sync. UI writes to Dexie and succeeds immediately. Sync happens in background.

2.  **Remote Sync (The Cursor):**
    -   Store a `last_synced_at` timestamp in `localStorage` or Dexie `meta` table.
    -   **Pull:** Fetch records from Supabase where `updated_at > last_synced_at`. Upsert into Dexie.
    -   **Push:** Process `sync_queue` items one by one (or batched). On success, remove from queue.

3.  **Deletions (Soft Delete):**
    -   Supabase tables must have `deleted_at` column.
    -   **Local Delete:** Mark as deleted in Dexie? No, actually delete in Dexie but add `delete` action to `sync_queue`.
    -   **Remote Delete:** When processing `delete` action, update Supabase record `deleted_at = NOW()`.
    -   **Pulling Deletes:** If incoming record has `deleted_at`, delete it from Dexie.

### Recommended Project Structure
```
src/
├── lib/
│   ├── supabase/
│   │   ├── client.ts        # Client-side singleton
│   │   ├── server.ts        # Server-side utils (for auth mostly)
│   │   └── types.ts         # Database generated types
│   ├── sync/
│   │   ├── queue.ts         # Dexie queue management
│   │   ├── engine.ts        # The actual sync logic (push/pull)
│   │   └── conflict.ts      # Conflict detection logic
│   └── db/
│       └── hooks.ts         # Dexie hooks to feed the queue
```

### Anti-Patterns to Avoid
-   **Anti-pattern:** "Sync on Mount Only."
    -   **Why:** Users switch devices/tabs. Data gets stale.
    -   **Instead:** Sync on mount, on focus, and on network reconnect.
-   **Anti-pattern:** "Blocking UI for Sync."
    -   **Why:** Destroys the "local-first" feel.
    -   **Instead:** Optimistic UI. Show "Saved" immediately, "Synced" later.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| **Auth Flow** | Custom JWT handling | **Supabase Auth** | Security, session refresh, magic links, social providers are hard to get right. |
| **Network Status** | `window.navigator.onLine` | **`navigator.onLine` + Event Listeners** | Actually, you *do* have to roll a small listener, but don't build a complex polling mechanism. Browser events `online`/`offline` are sufficient. |
| **UUIDs** | `Math.random()` | **`crypto.randomUUID()`** | Collision probability. |

## Common Pitfalls

### Pitfall 1: The "Infinite Sync Loop"
**What goes wrong:** A pull updates Dexie → Dexie hook fires → Adds to Sync Queue → Push to Supabase → Supabase updates `updated_at` → Pull updates Dexie...
**Why it happens:** Failing to distinguish "local user changes" from "sync application changes".
**How to avoid:**
1.  Use `Dexie.on('changes')` with the `transaction.source` check. If source is "sync-engine", ignore.
2.  Or, have the Sync Engine write directly to Dexie bypassing the hook (requires careful implementation).
**Recommendation:** Check `trans.source` in Dexie hooks. Set source to `sync` when applying incoming changes.

### Pitfall 2: Clock Skew
**What goes wrong:** Client clock is wrong. `updated_at` is in the future or past.
**Why it happens:** User manually changes device time.
**How to avoid:** Always rely on Server Time for `last_synced_at`. When a push succeeds, return the server's timestamp.

## Code Examples

### Dexie Hook for Sync Queue
```typescript
// src/lib/db/hooks.ts
import { db } from './dexie';

export function setupSyncHooks() {
  const tablesToSync = ['completedWorkouts', 'oneRepMaxes', 'activeCycles'];

  tablesToSync.forEach(tableName => {
    db.table(tableName).hook('creating', (primKey, obj, trans) => {
      // @ts-ignore - transaction source typing
      if (trans.source === 'sync') return;

      db.syncQueue.add({
        table: tableName,
        action: 'create',
        data: obj,
        createdAt: new Date().toISOString()
      });
    });

    db.table(tableName).hook('updating', (mods, primKey, obj, trans) => {
      // @ts-ignore
      if (trans.source === 'sync') return;

      db.syncQueue.add({
        table: tableName,
        action: 'update',
        data: { id: primKey, ...mods },
        createdAt: new Date().toISOString()
      });
    });

    // ... deleting hook
  });
}
```

### Soft Delete Policy (Supabase RLS)
```sql
-- Enable RLS
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

-- Create Policy
CREATE POLICY "Users can see own active workouts" ON workouts
FOR SELECT
USING (
  auth.uid() = user_id
  AND
  deleted_at IS NULL
);
```

## State of the Art
| Old Approach | Current Approach |
|--------------|------------------|
| **REST API + Polling** | **Realtime Subscriptions / Cursor Sync** |
| **Blocking Save** | **Optimistic UI + Background Sync** |
| **Manual Auth Token Storage** | **HttpOnly Cookies (Supabase SSR)** |

## Open Questions

1.  **Question:** Should we sync *static* program data?
    *   **Recommendation:** No. Programs are defined in code. Only sync *User* data (logs, preferences, active cycles).
2.  **Question:** Handling `users` table sync?
    *   **Recommendation:** The `users` table in Dexie is likely just the local profile. In Supabase, this maps to `public.profiles`. Sync `users` (Dexie) <-> `profiles` (Supabase).

## Sources

### Primary (HIGH confidence)
-   [Context7/Supabase] - Auth & Database patterns
-   [Dexie Docs] - `hook('creating')`, `hook('updating')` patterns
-   [Supabase SSR Docs] - Next.js App Router integration

### Secondary (MEDIUM confidence)
-   [WebSearch] - "Dexie Supabase Offline Sync" patterns confirming Queue + Cursor approach is standard for custom implementations.

## Metadata
**Confidence breakdown:**
-   Standard Stack: HIGH (Supabase + Dexie is a very common combo)
-   Architecture: HIGH (Queue pattern is battle-tested for offline-first)
-   Pitfalls: HIGH (Infinite loop is the #1 issue in bidirectional sync)

**Research date:** 2026-02-18

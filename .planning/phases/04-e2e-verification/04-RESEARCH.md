# Phase 4: E2E Verification - Research

**Researched:** 2026-02-18
**Domain:** Playwright E2E testing — IndexedDB seeding, Supabase mocking, PR celebration
**Confidence:** HIGH (Playwright 1.58 docs, direct codebase inspection)

---

## Summary

Phase 4 requires three Playwright E2E tests against a local-first Next.js app (Dexie IndexedDB, optional Supabase sync). The test infrastructure is already in place: Playwright 1.58 is configured at `playwright.config.ts` with `testDir: ./tests/e2e`, a webServer that auto-starts `npm run dev`, and four existing passing tests that establish conventions.

The three new tests have distinct challenges: (1) the **full workout flow** requires navigating a multi-step UI and capturing a `router.back()` redirect; (2) the **PR celebration test** requires pre-seeding an `oneRepMax` record in IndexedDB so the next lift triggers the `currentMax > 0` guard; (3) the **sync test** requires fake Supabase env vars baked into the dev server build plus `page.route()` network interception to function as a "remote mock."

**Primary recommendation:** Use `page.evaluate()` with raw IndexedDB API for data seeding, `page.route()` for Supabase mocking, and a shared `completeOnboarding()` helper (extract from existing tests). Each test gets an isolated browser context (Playwright default) so no teardown logic is needed.

---

## Standard Stack

### Core (already installed, no additions needed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | 1.58.2 | E2E test runner | Already configured, used by all existing tests |
| Playwright `page.evaluate()` | built-in | Seed IndexedDB from test | Standard Playwright pattern for pre-populating browser storage |
| Playwright `page.route()` | built-in | Mock Supabase REST | Standard Playwright network interception |
| Playwright `page.waitForURL()` | built-in | Detect router.back() navigation | Standard for navigation assertions |

### No new dependencies needed
All required tooling is already installed. Do **not** add `msw`, `nock`, or any other mocking library — `page.route()` handles it natively.

**Installation:** none required

---

## Architecture Patterns

### Recommended Test File Structure
```
tests/e2e/
├── onboarding.spec.ts           # existing
├── back-squat-v2.spec.ts        # existing
├── cycle-logging.spec.ts        # existing
├── view-recommendations.spec.ts # existing
├── helpers/
│   └── onboarding.ts            # NEW: extracted shared helper
├── workout-flow.spec.ts         # NEW: TEST-01
├── pr-celebration.spec.ts       # NEW: TEST-02
└── sync-flow.spec.ts            # NEW: TEST-03
```

### Pattern 1: Shared Onboarding Helper
**What:** Extract `completeOnboarding(page)` — already duplicated in `cycle-logging.spec.ts` and `view-recommendations.spec.ts`.
**When to use:** Every test that needs an authenticated local user in IndexedDB.
**Example:**
```typescript
// tests/e2e/helpers/onboarding.ts
import type { Page } from '@playwright/test';

export async function completeOnboarding(page: Page, name = 'Test User') {
  await page.goto('/onboarding');
  await page.type('input[id="name"]', name, { delay: 50 });
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');
  await page.waitForTimeout(100);
  await page.click('label[for="beginner"]');
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');
  await page.click('button:has-text("Start Training")');
  await expect(page).toHaveURL('/dashboard');
}
```

### Pattern 2: IndexedDB Seeding via page.evaluate()
**What:** Write directly to IndexedDB using the raw API inside the browser context. Dexie schema is at version 4. DB name is `'StrengthApp'`.
**When to use:** TEST-02 — must seed `oneRepMax > 0` before loading the workout page so PR detection fires.
**Example:**
```typescript
// Seed a oneRepMax after onboarding (user already created by onboarding flow)
await page.evaluate(async () => {
  await new Promise<void>((resolve, reject) => {
    const openReq = indexedDB.open('StrengthApp', 4);
    openReq.onsuccess = () => {
      const db = openReq.result;
      // Read userId from users table first
      const readTx = db.transaction(['users'], 'readonly');
      const usersStore = readTx.objectStore('users');
      const getAllReq = usersStore.getAll();
      getAllReq.onsuccess = () => {
        const users = getAllReq.result;
        const userId = users[0]?.id;
        if (!userId) { reject(new Error('No user found')); return; }

        const writeTx = db.transaction(['oneRepMaxes'], 'readwrite');
        const store = writeTx.objectStore('oneRepMaxes');
        store.put({
          id: 'seed-orm-1',
          userId,
          exerciseId: 'back-squat',
          weight: 200,
          date: new Date().toISOString(),
        });
        writeTx.oncomplete = () => resolve();
        writeTx.onerror = () => reject(writeTx.error);
      };
    };
    openReq.onerror = () => reject(openReq.error);
  });
});
```
**Critical detail:** Dexie stores `Date` objects but IndexedDB serializes them. When seeding via raw IndexedDB (bypassing Dexie), store `date` as ISO string — Dexie handles both.

### Pattern 3: Supabase REST Mocking via page.route()
**What:** Intercept Supabase API calls with `page.route()` to simulate successful sync without a real Supabase backend.
**When to use:** TEST-03 — `createClient()` returns null if env vars are absent. Must configure fake env vars AND mock the HTTP endpoints.
**Requires:** Fake `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in the webServer environment so `createClient()` returns a real client pointing at a fake host.
**Example:**
```typescript
// In playwright.config.ts webServer section (for sync test support):
webServer: {
  command: 'npm run dev',
  url: 'http://localhost:3000',
  reuseExistingServer: !process.env.CI,
  env: {
    NEXT_PUBLIC_SUPABASE_URL: 'https://test-project.supabase.co',
    NEXT_PUBLIC_SUPABASE_ANON_KEY: 'test-anon-key',
  },
},

// In sync-flow.spec.ts:
test('workout data appears in remote mock after sync', async ({ page }) => {
  const capturedRequests: unknown[] = [];

  // Mock Supabase auth — return a fake authenticated user
  await page.route('**/auth/v1/user**', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ id: 'user-123', email: 'test@test.com' }),
    });
  });

  // Mock Supabase REST upsert for completed_workouts
  await page.route('**/rest/v1/completed_workouts**', async route => {
    const body = route.request().postDataJSON();
    capturedRequests.push(body);
    await route.fulfill({ status: 200, contentType: 'application/json', body: '[]' });
  });

  // Mock Supabase REST upsert for completed_sets
  await page.route('**/rest/v1/completed_sets**', async route => {
    await route.fulfill({ status: 200, contentType: 'application/json', body: '[]' });
  });

  // Complete a full workout flow...
  // Then assert:
  expect(capturedRequests.length).toBeGreaterThan(0);
});
```

### Pattern 4: Detecting router.back() After Workout Completion
**What:** After "Complete Workout" is clicked, `handleWorkoutComplete` calls `router.back()`. The test must detect this navigation.
**When to use:** TEST-01 — workout completion redirects to the previous page.
**Example:**
```typescript
// Navigate to workout, then wait for URL to change on completion
const previousUrl = page.url();
await page.click('button:has-text("Complete Workout")');
await page.waitForURL(url => url !== previousUrl, { timeout: 5000 });
```

### Pattern 5: TEST-01 Full Workout Flow
**What:** Complete all sets for a session, then complete the workout.
**Key detail:** `handleComplete` fires when all sets are collected; it passes `setDataMap` to `onComplete`. Doesn't require ALL sets to be filled — just clicking the button.
**Example:**
```typescript
// Fill a weight for at least the first set
const firstInput = page.locator('input[type="number"]').first();
await firstInput.fill('135');
// Click the "Complete Workout" button
await page.click('button:has-text("Complete Workout")');
```

### Anti-Patterns to Avoid
- **Don't use `waitForTimeout` as primary assertion strategy** — use `waitForSelector` or `toBeVisible` with timeouts. The existing tests use `waitForTimeout(500)` for IndexedDB; this is acceptable as a brief stabilizer AFTER `waitForLoadState('networkidle')`, but not as the primary wait.
- **Don't run sync tests without fake Supabase env vars** — `createClient()` returns null without them, so `syncAfterWorkout` returns immediately with no network calls.
- **Don't rely on `fullyParallel: true` causing race conditions in sync tests** — each test uses its own browser context with isolated IndexedDB.
- **Don't seed IndexedDB before `page.goto()`** — the DB doesn't exist yet. Seed after first navigation (onboarding creates the DB at version 4).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supabase API mocking | Custom mock server | `page.route()` | Built into Playwright, no external process needed |
| IndexedDB reset between tests | Custom teardown | Rely on Playwright's isolated browser contexts | Each test gets fresh storage by default |
| Test user creation | Custom user factory | `completeOnboarding()` helper | Onboarding already creates a real user in Dexie |
| Network state simulation | Custom offline mode | `page.context().setOffline(true)` | Built into Playwright for offline simulation |
| Wait for async Dexie operations | Polling loops | `page.waitForLoadState('networkidle')` + brief timeout | Established pattern in existing tests |

**Key insight:** Playwright's isolation and `page.route()` mean zero external mock services are needed. All mocking happens in-process via the browser context.

---

## Common Pitfalls

### Pitfall 1: Supabase Env Vars Not Baked into Dev Server
**What goes wrong:** `createClient()` returns null → sync disabled → `syncAfterWorkout` returns immediately → no HTTP calls made → TEST-03 captures nothing.
**Why it happens:** `NEXT_PUBLIC_*` vars are read by Next.js at server startup, not per-request. A running dev server without them will never enable sync even if `page.route()` is set up.
**How to avoid:** Add env vars to `playwright.config.ts` webServer `env:` block. Note: `reuseExistingServer: true` (dev mode) means if a server is already running WITHOUT these vars, the playwright run will reuse it and the vars won't apply. For local reliability, either kill the existing dev server before running sync tests, OR use `reuseExistingServer: false` in the sync test project config.
**Warning signs:** No network requests captured in `capturedRequests`, `syncStatus === 'disabled'` on the page.

### Pitfall 2: IndexedDB Version Mismatch When Seeding
**What goes wrong:** `page.evaluate()` opens IndexedDB at the wrong version → `versionchange` event fires → Dexie panics or upgrade callback runs.
**Why it happens:** Must open at exactly version 4 (current schema). Opening at a lower version triggers the upgrade path.
**How to avoid:** Always use `indexedDB.open('StrengthApp', 4)` in `page.evaluate()`.
**Warning signs:** `IDBVersionChangeEvent` errors in browser console during tests.

### Pitfall 3: PR Check Fires on 1RM Seed but User Not Loaded Yet
**What goes wrong:** `oneRepMaxes` in UserContext is loaded asynchronously. If the workout page loads before `useEffect` populates `oneRepMaxes`, `checkWeightPR` sees an empty array and returns false even with seeded data.
**Why it happens:** UserContext loads `oneRepMaxes` via `getOneRepMaxesByUser` on mount — async. The component renders before data arrives.
**How to avoid:** After seeding and navigating to the workout page, add `page.waitForLoadState('networkidle')` + `page.waitForTimeout(300)` before interacting with set inputs. This lets UserContext's useEffect complete.
**Warning signs:** PR celebration never appears despite correct seeded data.

### Pitfall 4: `router.back()` Navigation After Workout Completion
**What goes wrong:** Test waits for specific URL after completing workout but `router.back()` goes back to whatever was in history (could be `/workout/[id]` again if history is empty in a fresh context).
**Why it happens:** In a fresh browser context with no navigation history, `router.back()` may behave differently (stay on same page or go to `/`).
**How to avoid:** Navigate to `/dashboard` before going to `/workout/[id]`, establishing a history. OR check that the workout page is no longer visible (look for absence of "Complete Workout" button) rather than asserting on a specific URL.
**Warning signs:** `waitForURL` times out.

### Pitfall 5: Test-01 "Complete Workout" Button Not Triggering handleWorkoutComplete
**What goes wrong:** Clicking "Complete Workout" in `WorkoutSessionView` fires `handleComplete` which calls `onComplete({ completed: true, sets })`, but `handleWorkoutComplete` in `page.tsx` requires `data.completed && user`. If no user in context, it returns immediately.
**Why it happens:** User is loaded async from IndexedDB. If the page loads before UserContext resolves, `user` is null.
**How to avoid:** Always complete onboarding before navigating to workout page. Onboarding writes the user to IndexedDB. Add `page.waitForLoadState('networkidle')` after selecting a session before clicking "Complete Workout".
**Warning signs:** Workout completes without router navigation (stays on same page).

---

## Code Examples

### Full TEST-01: Workout Flow
```typescript
// tests/e2e/workout-flow.spec.ts
import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test('user can complete full workout flow', async ({ page }) => {
  // 1. Set up: create user via onboarding
  await completeOnboarding(page, 'Workout Flow User');

  // 2. Navigate to a workout program
  await page.goto('/workout/back-squat-complete-cycle');
  await page.waitForLoadState('networkidle');

  // 3. Select a session
  await page.click('text=Support Session A');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(300); // Allow UserContext to resolve

  // 4. Fill in weight for at least one set
  const firstInput = page.locator('input[type="number"]').first();
  await firstInput.fill('135');

  // 5. Complete the workout
  const previousUrl = page.url();
  await page.click('button:has-text("Complete Workout")');

  // 6. Assert navigation happened (workout saved and router.back() called)
  await page.waitForURL(url => url !== previousUrl, { timeout: 5000 });
});
```

### Full TEST-02: PR Celebration
```typescript
// tests/e2e/pr-celebration.spec.ts
import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test('PR celebration triggers correctly', async ({ page }) => {
  // 1. Create user
  await completeOnboarding(page, 'PR Test User');

  // 2. Seed a prior oneRepMax so currentMax > 0
  await page.evaluate(async () => {
    await new Promise<void>((resolve, reject) => {
      const openReq = indexedDB.open('StrengthApp', 4);
      openReq.onsuccess = () => {
        const db = openReq.result;
        const readTx = db.transaction(['users'], 'readonly');
        readTx.objectStore('users').getAll().onsuccess = (e) => {
          const users = (e.target as IDBRequest).result;
          const userId = users[0]?.id;
          if (!userId) { reject(new Error('No user')); return; }
          const writeTx = db.transaction(['oneRepMaxes'], 'readwrite');
          writeTx.objectStore('oneRepMaxes').put({
            id: 'seed-squat-orm',
            userId,
            exerciseId: 'back-squat',
            weight: 200,
            date: new Date().toISOString(),
          });
          writeTx.oncomplete = () => resolve();
          writeTx.onerror = () => reject(writeTx.error);
        };
      };
      openReq.onerror = () => reject(openReq.error);
    });
  });

  // 3. Navigate to workout and select session
  await page.goto('/workout/back-squat-complete-cycle');
  await page.waitForLoadState('networkidle');
  await page.click('text=Support Session A');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(500); // Wait for UserContext to load oneRepMaxes

  // 4. Enter a weight that beats the 200 lbs 1RM
  const firstInput = page.locator('input[type="number"]').first();
  await firstInput.fill('205');
  await firstInput.press('Tab'); // Trigger onChange

  // 5. Assert PR celebration appears
  await expect(page.locator('text=New PR!')).toBeVisible({ timeout: 3000 });
});
```

### Full TEST-03: Sync to Remote Mock
```typescript
// tests/e2e/sync-flow.spec.ts
import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test('local workout data appears in remote mock after sync', async ({ page }) => {
  const capturedWorkoutBodies: unknown[] = [];

  // Mock Supabase auth endpoint — return fake authenticated user
  await page.route('**/auth/v1/user**', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ id: 'test-user-supabase-id', email: 'test@example.com' }),
    })
  );

  // Mock Supabase REST — capture workout upsert
  await page.route('**/rest/v1/completed_workouts**', async route => {
    capturedWorkoutBodies.push(route.request().postDataJSON());
    await route.fulfill({ status: 201, contentType: 'application/json', body: '[]' });
  });

  // Mock Supabase REST — respond to sets upsert
  await page.route('**/rest/v1/completed_sets**', route =>
    route.fulfill({ status: 201, contentType: 'application/json', body: '[]' })
  );

  // Complete onboarding and a workout
  await completeOnboarding(page, 'Sync Test User');
  await page.goto('/workout/back-squat-complete-cycle');
  await page.waitForLoadState('networkidle');
  await page.click('text=Support Session A');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(300);

  await page.locator('input[type="number"]').first().fill('135');
  await page.click('button:has-text("Complete Workout")');

  // Wait for sync to attempt (syncAfterWorkout is called after save)
  await page.waitForTimeout(1000);

  // Assert the workout was posted to the "remote"
  expect(capturedWorkoutBodies.length).toBeGreaterThan(0);
});
```

### playwright.config.ts update for Supabase env vars
```typescript
// playwright.config.ts — add env to webServer
webServer: {
  command: 'npm run dev',
  url: 'http://localhost:3000',
  reuseExistingServer: !process.env.CI,
  env: {
    NEXT_PUBLIC_SUPABASE_URL: 'https://test-project.supabase.co',
    NEXT_PUBLIC_SUPABASE_ANON_KEY: 'test-anon-key',
  },
},
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mock Service Worker (msw) for API mocking | `page.route()` native Playwright | Playwright 1.11+ | Zero external mock server, works in CI without ports |
| Global test fixtures for DB | Per-test `page.evaluate()` seeding | Playwright 1.x best practice | Full isolation, no shared state |
| `waitForTimeout` as only wait | `waitForLoadState` + optional brief timeout | Current best practice | Flaky test prevention |

**Deprecated/outdated:**
- `page.waitForNavigation()`: Replaced by `page.waitForURL()` in Playwright 1.x — more reliable for SPAs using client-side routing.

---

## Open Questions

1. **Supabase auth mock for onAuthStateChange**
   - What we know: `UserContext` calls `supabase.auth.onAuthStateChange()` on mount. With fake env vars, this connects to `https://test-project.supabase.co/auth/v1/...` websocket or polling.
   - What's unclear: Does the auth state change listener cause test failures/timeouts when it can't connect to the fake host?
   - Recommendation: Add `page.route('**/auth/v1/**', ...)` to catch all auth requests, OR verify behavior during test implementation and add targeted mocks as needed.

2. **Input trigger for PR detection on tab press vs blur**
   - What we know: `handleSetChange` is called in `ExerciseCardV2` via an `onChange` handler on the input.
   - What's unclear: Whether filling via `firstInput.fill('205')` or `page.type()` reliably triggers the React `onChange` handler.
   - Recommendation: Use `page.type()` with delay (as established by existing tests: `page.type(..., { delay: 50 })`) OR use `firstInput.fill()` followed by `firstInput.dispatchEvent('input')` if fill alone doesn't trigger React's synthetic event.

3. **Exercise ID for PR test**
   - What we know: The program uses `back-squat` as a key exercise ID.
   - What's unclear: Whether `Support Session A` has `back-squat` as its first exercise (verified in program data).
   - Recommendation: Inspect the program JSON to confirm the first exercise of Support Session A uses `back-squat` exercise ID, or use a more targeted exercise selector.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `src/hooks/use-pr-detection.ts` — confirmed PR logic (`currentMax > 0` guard)
- Direct codebase inspection: `src/lib/sync/sync-queue.ts` — `QUEUE_KEY = 'sync_pending_workout_ids'`
- Direct codebase inspection: `src/lib/supabase/client.ts` — null guard confirmed
- Direct codebase inspection: `src/contexts/user-context.tsx` — `isSyncConfigured = supabase !== null`
- Direct codebase inspection: `playwright.config.ts` — version 1.58.2, testDir, webServer config
- Direct codebase inspection: `src/lib/db/dexie.ts` — DB name `StrengthApp`, version 4 schema
- Direct codebase inspection: `tests/e2e/*.spec.ts` — existing test patterns and conventions

### Secondary (MEDIUM confidence)
- Playwright 1.58 API: `page.route()`, `page.evaluate()`, `page.waitForURL()` are stable APIs unchanged since 1.x
- IndexedDB raw API with version 4 open: standard browser API, cross-verified with Dexie schema

### Tertiary (LOW confidence)
- `onAuthStateChange` WebSocket behavior with fake host: untested, may require additional route mocking

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Playwright 1.58.2 confirmed installed, no additions needed
- Architecture: HIGH — Codebase directly inspected, test patterns confirmed from existing tests
- Pitfalls: HIGH for env vars / IndexedDB seeding (confirmed from code); MEDIUM for auth mock behavior (untested)
- Code examples: HIGH for TEST-01/02 patterns; MEDIUM for TEST-03 (auth WebSocket behavior unverified)

**Research date:** 2026-02-18
**Valid until:** 2026-03-18 (30 days — stable Playwright API)

# Phase 3: Security Hardening — Research

**Researched:** 2026-03-21
**Domain:** Firestore Security Rules, Content Security Policy, Cloud Function Rate Limiting
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-01 | Firestore security rules enforce per-user ownership on all subcollections | Rules already exist in worktree; need to be placed at repo root and deployed |
| SEC-02 | Firestore rules prevent client-side write to `premiumEntitlement` field | Field-level diff() pattern documented; requires separate rule on users/{userId} write |
| SEC-03 | Content Security Policy headers in firebase.json allowlisting Firebase, Stripe, and Gemini domains | firebase.json headers array format confirmed; specific domains researched per service |
| SEC-04 | Rate limiting on AI workout generation (5 per user per day) | Cloud Function Firestore counter+transaction pattern; no maintained external library for Node 20 |
</phase_requirements>

---

## Summary

This phase has four concrete deliverables: Firestore security rules, a CSP header block in `firebase.json`, a `premiumEntitlement` field write block in the rules, and rate limiting inside the `generateAIWorkout` Cloud Function.

**Critical discovery:** A working `firestore.rules` file and a matching `firestore.rules.test.ts` already exist in the legacy RN worktree at `.claude/worktrees/serene-poincare/SundeeFundeeRN/`. These cover SEC-01 (ownership on all subcollections). They need to be copied to the repo root, extended for SEC-02, and wired into `firebase.json`. The test harness uses `@firebase/rules-unit-testing` + the Firebase Emulator and runs independently from the vitest PWA suite and the Jest Cloud Functions suite.

**SEC-04 implementation decision:** The only maintained rate-limiting library (`firebase-functions-rate-limiter`) was last updated June 2022 and explicitly does not support Node 20 (which this project uses). The correct approach is a hand-rolled Firestore transaction counter inside `generateAIWorkout.ts`. The counter document lives at `users/{uid}/rateLimits/aiWorkout` and stores `{ date: "YYYY-MM-DD", count: N }`. Each call runs a Firestore transaction: read the doc, if the stored date is today and count >= 5 reject, otherwise increment (or reset to 1 with today's date).

**Primary recommendation:** Copy and extend the existing rules, add the CSP block, and embed the rate limit check as the first step inside `generateAIWorkout` (after auth check, before Gemini call).

---

## Current Codebase State (Critical for Planning)

### What Already Exists

**Firestore rules (in worktree, NOT at repo root):**
- `/Users/dustinober/Projects/Sundee-Fundee/.claude/worktrees/serene-poincare/SundeeFundeeRN/firestore.rules`
- Covers: default-deny, `users/{userId}` owner-only, one-level `{subcollection}/{docId}` match, `programs` read-only, `wods` read-only
- Does NOT cover: `premiumEntitlement` field block, deep nested subcollections (e.g., `injuries/{id}/painLogs/{id}`)

**Firestore rules tests (in worktree, NOT at repo root):**
- `/Users/dustinober/Projects/Sundee-Fundee/.claude/worktrees/serene-poincare/SundeeFundeeRN/firestore.rules.test.ts`
- Uses `@firebase/rules-unit-testing` + Firebase Emulator on port 8080
- Missing: `premiumEntitlement` write rejection test, deep subcollection test

**Cloud Functions already implemented:**
- `functions/src/generateAIWorkout.ts` — has auth gating, no rate limiting yet
- Mock infrastructure: `functions/__mocks__/firebase-admin-firestore.ts` — mutable delegation pattern; supports `get`, `set`, `update` handlers. Rate limit check uses `get` then `set` — the mock already supports this without changes.

**firebase.json current state:**
- Has `hosting.headers` array with Cache-Control rules
- NO Content-Security-Policy header yet

### Firestore Data Model (All Subcollections Under `users/{uid}`)

| Subcollection | Depth | Repo File |
|--------------|-------|-----------|
| `workouts/{id}` | 1 | FirestoreWorkoutRepo.ts |
| `injuries/{id}` | 1 | FirestoreInjuryRepo.ts |
| `injuries/{id}/painLogs/{id}` | 2 | FirestoreInjuryRepo.ts |
| `periodLogs/{id}` | 1 | FirestoreCycleRepo.ts |
| `cycleSettings/settings` | 1 | FirestoreCycleRepo.ts |
| `readiness/{id}` | 1 | FirestoreReadinessRepo.ts |
| `benchmarkResults/{id}` | 1 | FirestoreBenchmarkRepo.ts |
| `customBenchmarks/{id}` | 1 | FirestoreBenchmarkRepo.ts |
| `exerciseMaxes/{id}` | 1 | FirestoreExerciseMaxRepo.ts |
| `exercises/{id}` | 1 | FirestoreExerciseRepo.ts |
| `programs/{id}` | 1 | FirestoreProgramRepo.ts (user-specific) |
| `onboardingProfile/profile` | 1 | FirestoreOnboardingProfileRepo.ts |
| `settings/preferences` | 1 | FirestoreSettingsRepo.ts |
| `rateLimits/aiWorkout` | 1 | NEW — rate limit counter (SEC-04) |

**Wildcard depth issue:** The existing rule `match /{subcollection}/{docId}` covers depth-1 subcollections only. `injuries/{id}/painLogs/{id}` is depth-2 and is NOT covered by the current rules. This is a gap that must be fixed.

---

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| Firestore Security Rules | Built-in | Data access control | Platform-native; zero deployment overhead |
| `@firebase/rules-unit-testing` | `^3.0.0` | Emulator-based rules testing | Official Firebase library for rules unit tests |
| Firebase Emulator Suite | Latest | Local test environment for rules | Required by `@firebase/rules-unit-testing` |
| firebase.json `headers` array | Built-in | HTTP response headers via Firebase Hosting | Platform-native; no middleware needed |
| `getFirestore().runTransaction()` | firebase-admin v12 | Atomic rate limit counter | Guarantees no race conditions on concurrent requests |

### Don't Use
| Problem | Don't Use | Use Instead | Why |
|---------|-----------|-------------|-----|
| Rate limiting | `firebase-functions-rate-limiter` npm package | Hand-rolled Firestore transaction | Library is unmaintained, Node 20 unsupported; last updated June 2022 |
| Rate limiting | Redis | Firestore transaction counter | Unnecessary complexity; 5 req/day is low traffic, 1 write/sec Firestore limit is not an issue |
| CSP enforcement | `report-only` mode (long-term) | Enforcement mode | App functionality must be verified before deploying; use report-only only during initial testing |

---

## Architecture Patterns

### SEC-01 + SEC-02: Firestore Security Rules

**Pattern:** Copy existing rules from worktree, extend with depth-2 wildcard and `premiumEntitlement` field block.

**Key rules structure:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }

    match /users/{userId} {
      // SEC-01: owner-only on profile document
      // SEC-02: premiumEntitlement field cannot be written by client
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && !('premiumEntitlement' in request.resource.data);
      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && !request.resource.data.diff(resource.data)
                       .affectedKeys().hasAny(['premiumEntitlement']);
      allow delete: if request.auth != null && request.auth.uid == userId;

      // Depth-1 subcollections (all user data)
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // Depth-2 subcollections (e.g., injuries/{id}/painLogs/{id})
      match /{subcollection}/{docId}/{nested=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Read-only public collections
    match /programs/{programId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    match /wods/{wodId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

**Source:** `diff().affectedKeys().hasAny()` pattern — [Control access to specific fields | Firestore | Google Cloud](https://docs.cloud.google.com/firestore/native/docs/security/rules-fields)

**SEC-02 rationale:** The `premiumEntitlement` field is written ONLY by the `stripeWebhook` Cloud Function via Firebase Admin SDK. Admin SDK bypasses security rules entirely. Blocking client writes via the `diff().affectedKeys().hasAny(['premiumEntitlement'])` pattern ensures no authenticated client can escalate their own subscription status.

**Important:** On a `create` (new document), use `!('premiumEntitlement' in request.resource.data)` since `resource.data` does not exist yet. On `update`, use the `diff()` approach.

### SEC-03: Content Security Policy in firebase.json

**Pattern:** Add a new entry to the `hosting.headers` array in `firebase.json` targeting `**` (all routes).

**Required domains by service:**

| Service | Directive | Domains |
|---------|-----------|---------|
| Firebase Auth | `connect-src` | `https://securetoken.googleapis.com` `https://identitytoolkit.googleapis.com` `https://*.googleapis.com` |
| Firestore | `connect-src` | `https://*.firestore.googleapis.com` `wss://*.firestore.googleapis.com` |
| Firebase Hosting (self) | `default-src` | `'self'` |
| Firebase JS SDK | `connect-src` | `https://*.firebaseio.com` |
| Stripe Checkout (redirect) | `script-src`, `connect-src`, `frame-src` | `https://checkout.stripe.com` |
| Stripe (images) | `img-src` | `https://*.stripe.com` |
| Stripe (telemetry) | `connect-src` | `https://q.stripe.com` `https://r.stripe.com` |
| Gemini (via Cloud Function, not direct browser call) | `connect-src` | `https://us-central1-{project}.cloudfunctions.net` |
| Google Fonts (if used) | `font-src`, `style-src` | `https://fonts.googleapis.com` `https://fonts.gstatic.com` |
| Inline scripts/styles | `script-src`, `style-src` | `'unsafe-inline'` (React/Vite SPA requirement) |

**Note on Gemini:** The PWA calls `generateAIWorkout` via Firebase onCall (goes to `cloudfunctions.net`), NOT directly to Gemini APIs. Gemini is called server-side inside the Cloud Function. So no Gemini API domains are needed in the browser CSP.

**firebase.json additions:**
```json
{
  "source": "**",
  "headers": [
    {
      "key": "Content-Security-Policy",
      "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://checkout.stripe.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https://*.stripe.com; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firestore.googleapis.com https://checkout.stripe.com https://q.stripe.com https://r.stripe.com https://us-central1-sundee-fundee.cloudfunctions.net; frame-src https://checkout.stripe.com; object-src 'none'; base-uri 'self';"
    },
    {
      "key": "X-Frame-Options",
      "value": "SAMEORIGIN"
    },
    {
      "key": "X-Content-Type-Options",
      "value": "nosniff"
    }
  ]
}
```

**Sources:** [Stripe Integration Security Guide](https://docs.stripe.com/security/guide), [Firebase Hosting full-config](https://firebase.google.com/docs/hosting/full-config)

**Confidence note:** The exact Cloud Functions URL format is `https://{region}-{projectId}.cloudfunctions.net`. The project ID is `sundee-fundee` based on existing code. However, Firebase SDK onCall uses `https://us-central1-{projectId}.cloudfunctions.net/{functionName}`. This must be verified after deploy — the exact URL pattern can be discovered from the browser's network tab on first call.

**Testing approach:** Deploy to Firebase Hosting, open browser DevTools → Network/Console. A CSP violation will appear as a console error with the blocked domain. Iterate on the CSP value until no violations appear. This is a manual verification step.

### SEC-04: Rate Limiting in generateAIWorkout

**Pattern:** Firestore transaction counter at `users/{uid}/rateLimits/aiWorkout`.

**Data structure:**
```typescript
interface RateLimitDoc {
  date: string;   // "YYYY-MM-DD" in UTC
  count: number;  // 0–5
}
```

**Algorithm:**
1. Read `users/{uid}/rateLimits/aiWorkout` in a Firestore transaction
2. Get today's UTC date as `YYYY-MM-DD`
3. If doc exists and `doc.date === today` and `doc.count >= 5` → throw `HttpsError('resource-exhausted', ...)`
4. If doc exists and `doc.date === today` → set `{ date: today, count: doc.count + 1 }`
5. If doc doesn't exist or `doc.date !== today` → set `{ date: today, count: 1 }` (reset)
6. After transaction succeeds → call Gemini

**Implementation location:** At the top of `generateAIWorkout`'s handler, after auth check, before input validation and Gemini call.

**Code pattern:**
```typescript
// Source: firebase-admin/firestore runTransaction pattern
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const DAILY_LIMIT = 5;
const today = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD" UTC

const db = getFirestore();
const rateLimitRef = db.collection('users').doc(uid)
  .collection('rateLimits').doc('aiWorkout');

await db.runTransaction(async (tx) => {
  const snap = await tx.get(rateLimitRef);
  const data = snap.data() as { date: string; count: number } | undefined;

  if (data && data.date === today && data.count >= DAILY_LIMIT) {
    throw new HttpsError(
      'resource-exhausted',
      `Daily AI workout limit reached. Try again tomorrow.`
    );
  }

  if (data && data.date === today) {
    tx.update(rateLimitRef, { count: data.count + 1 });
  } else {
    tx.set(rateLimitRef, { date: today, count: 1 });
  }
});
```

**Test approach:** The existing `firebase-admin-firestore.ts` mock supports `get` and `set`/`update` calls. However, it currently does NOT expose a `runTransaction` mock. The mock must be extended to support `runTransaction`, or the rate limiting logic must be extracted into a testable helper function that accepts an injected `db` reference.

**Recommended approach for testability:** Extract `checkAndIncrementRateLimit(uid, db)` as a separate async function in `generateAIWorkout.ts`. Tests call it directly with a mock db, bypassing `runTransaction`. Alternative: extend the Firestore mock to support `runTransaction`.

**Firestore cost:** 1 read + 1 write per AI workout call. At 5 calls/day/user this is negligible.

---

## Common Pitfalls

### Pitfall 1: Subcollection Depth Mismatch
**What goes wrong:** The `match /{subcollection}/{docId}` pattern only covers one level of nesting. `injuries/{id}/painLogs/{id}` is depth-2 and will be DENIED by the default-deny rule even though the user owns it.
**Why it happens:** Firestore rules do not auto-recurse through wildcards.
**How to avoid:** Add a second wildcard match: `match /{subcollection}/{docId}/{nested=**}` under `/users/{userId}`.
**Warning signs:** App works for workouts (depth-1) but crashes when loading pain logs (depth-2).

### Pitfall 2: premiumEntitlement create vs. update Difference
**What goes wrong:** Using only the `diff()` pattern (which requires `resource.data` to exist) on a `create` operation causes a runtime error because `resource` is null for new documents.
**Why it happens:** `resource.data` is the current document state — undefined for creates.
**How to avoid:** Separate `allow create` and `allow update` rules. On create, use `!('premiumEntitlement' in request.resource.data)`. On update, use `diff().affectedKeys()`.

### Pitfall 3: Admin SDK Bypasses Rules (by Design)
**What goes wrong:** Developer tests the `stripeWebhook` function and is confused that it can write `premiumEntitlement` despite the rule blocking it.
**Why it happens:** Firebase Admin SDK always bypasses security rules. This is correct and expected behavior.
**How to avoid:** Understand the layered security model: rules protect client SDK, Admin SDK is trusted server-side code. The test for SEC-02 must use the client SDK via the rules testing library, not Admin SDK.

### Pitfall 4: CSP Blocks Firebase SDK WebSocket
**What goes wrong:** Firestore real-time listeners (if used) require `wss://` WebSocket connections to Firestore endpoints. Missing this from `connect-src` breaks real-time updates silently.
**Why it happens:** WebSocket connections are controlled by `connect-src`, not `default-src`.
**How to avoid:** Include `wss://*.firestore.googleapis.com` in `connect-src`. Also include `wss://*.firebaseio.com` for the Realtime Database if used.

### Pitfall 5: Rate Limit Counter Race Condition Without Transaction
**What goes wrong:** Without `runTransaction`, two concurrent requests from the same user could both read count=4, both write count=5, and both succeed — allowing 6+ requests.
**Why it happens:** Non-transactional reads and writes are not atomic.
**How to avoid:** Always use `runTransaction` for the rate limit check-and-increment. Never split it into separate `get` + `set` calls.

### Pitfall 6: Rate Limit Mock Infrastructure Gap
**What goes wrong:** The existing Firestore mock (`firebase-admin-firestore.ts`) does not expose `runTransaction`. Tests for the rate limit path will fail with "runTransaction is not a function".
**Why it happens:** The mock was built for simple `set`/`get`; transactions weren't needed before.
**How to avoid:** Either extend the mock to expose `runTransaction(callback)` that calls `callback({ get: mockGet, set: mockSet, update: mockUpdate })`, or extract the rate limit logic into a testable pure function.

### Pitfall 7: CSP `unsafe-inline` and Vite/React
**What goes wrong:** Removing `'unsafe-inline'` from `script-src` breaks the React/Vite application because Vite injects inline scripts for module loading.
**Why it happens:** Strict CSP without `'unsafe-inline'` requires nonce-based CSP, which requires server-side rendering to inject nonces per request. Firebase Hosting serves static files.
**How to avoid:** Keep `'unsafe-inline'` in `script-src` and `style-src` for a static SPA on Firebase Hosting. The tradeoff is accepted: this CSP still blocks external script injection, which is the primary XSP vector. The STATE.md already notes this approach.

---

## Code Examples

### Verified Pattern: Field Block in Firestore Rules
```
// Source: https://docs.cloud.google.com/firestore/native/docs/security/rules-fields
// Prevent update from modifying premiumEntitlement
allow update: if request.auth != null
              && request.auth.uid == userId
              && !request.resource.data.diff(resource.data)
                 .affectedKeys().hasAny(['premiumEntitlement']);
```

### Verified Pattern: firebase.json headers array
```json
// Source: https://firebase.google.com/docs/hosting/full-config
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "Content-Security-Policy", "value": "..." }
        ]
      }
    ]
  }
}
```

### Verified Pattern: Firestore Transaction Counter
```typescript
// Source: firebase-admin/firestore SDK (runTransaction)
await db.runTransaction(async (tx) => {
  const snap = await tx.get(rateLimitRef);
  // check and increment pattern...
  tx.set(rateLimitRef, { date: today, count: 1 });
});
```

### Verified Pattern: Rules Testing with @firebase/rules-unit-testing
```typescript
// Source: existing firestore.rules.test.ts in worktree
const testEnv = await initializeTestEnvironment({
  projectId: 'sundee-fundee-test',
  firestore: {
    rules: readFileSync(RULES_PATH, 'utf8'),
    host: 'localhost',
    port: 8080,
  },
});
const aliceDb = testEnv.authenticatedContext('alice-uid').firestore();
await assertFails(aliceDb.collection('users').doc('bob-uid').get());
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| External rate-limit library | Hand-rolled Firestore transaction | Library abandoned; native approach is simpler and Node 20 compatible |
| CSP report-only (initial testing) | CSP enforcement | Start report-only, verify, then switch to enforcement before phase completion |
| Rules without field-level blocks | `diff().affectedKeys()` for field protection | Cleaner than checking each field individually |

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true`).

### Test Frameworks

| Property | Value |
|----------|-------|
| Rules tests | `@firebase/rules-unit-testing` + Firebase Emulator |
| Cloud Functions tests | Jest + ts-jest (existing infrastructure) |
| Rules run command | `firebase emulators:exec --only firestore 'npx jest --testPathPattern=firestore.rules.test.ts'` |
| Functions test run | `cd functions && npm test` |
| Functions test filter | `cd functions && npx jest generateAIWorkout` |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-01 | User A cannot read User B's subcollection | unit (rules) | `firebase emulators:exec --only firestore 'npx jest --testPathPattern=firestore.rules.test.ts'` | Partially — worktree file needs copying and extension |
| SEC-02 | Client write to `premiumEntitlement` is rejected | unit (rules) | Same as SEC-01 | No — new test cases needed |
| SEC-03 | CSP header present in HTTP response | manual smoke | `curl -I https://sundeefundee.web.app/` then check header | N/A — manual verification |
| SEC-04 | 6th AI workout call in same day is rejected | unit (functions) | `cd functions && npx jest generateAIWorkout` | No — rate limit test cases needed |

### Wave 0 Gaps

- [ ] `firestore.rules` — must be created at repo root (copy from worktree + add depth-2 wildcard + `premiumEntitlement` block)
- [ ] `firestore.rules.test.ts` — must be created at repo root (copy from worktree + add SEC-02 and depth-2 subcollection tests)
- [ ] `functions/__mocks__/firebase-admin-firestore.ts` — must be extended to expose `runTransaction` mock
- [ ] `functions/src/__tests__/generateAIWorkout.test.ts` — must be extended with rate limit test cases (5 allowed, 6th rejected, different day resets)
- [ ] Install `@firebase/rules-unit-testing` (not in current `pwa/package.json` or `functions/package.json`):
  ```bash
  npm install --save-dev @firebase/rules-unit-testing
  ```
  (Install at repo root level alongside `firebase.json`, or in a dedicated `test/` package — see note below)

**Note on `@firebase/rules-unit-testing` install location:** The package must be installed where `firestore.rules.test.ts` lives. Since `firestore.rules` and `firestore.rules.test.ts` will live at repo root (alongside `firebase.json`), the test needs either a root `package.json` with Jest configured, or the test can live in the `pwa/` directory (which already has a test runner). The existing worktree puts it at repo root with its own Jest config. Follow the same pattern: root `package.json` + Jest config for rules tests only.

### Sampling Rate

- **Per task commit:** `cd functions && npm test` (Cloud Functions Jest suite)
- **Per wave merge:** `cd functions && npm test` + `firebase emulators:exec --only firestore 'npx jest --testPathPattern=firestore.rules.test.ts'` (requires Firebase Emulator running)
- **Phase gate:** Both suites green + manual CSP verification via curl/browser DevTools

---

## Open Questions

1. **CSP: Exact Firebase onCall URL**
   - What we know: Firebase onCall v2 calls go to `https://{region}-{projectId}.cloudfunctions.net/...`
   - What's unclear: The exact request URL format when called from `firebase/functions` SDK — it may go through a different Firebase domain (e.g., `cloudfunctions.net` vs `firebase.app`)
   - Recommendation: Use `Content-Security-Policy-Report-Only` for the first deploy, check browser DevTools for blocked domains, then finalize enforcement CSP. The STATE.md already flagged this as a known open question.

2. **Firestore rules: `aiWorkout` rateLimits subcollection**
   - What we know: The rate limit counter at `users/{uid}/rateLimits/aiWorkout` is written by Admin SDK (bypasses rules)
   - What's unclear: Should clients be allowed to READ their own rate limit doc? (Not strictly needed but could be useful for UI)
   - Recommendation: The generic `match /{subcollection}/{docId}` rule will allow owner to read this. No special case needed.

3. **SEC-01 rules test infrastructure: root vs. pwa/**
   - What we know: The existing worktree puts `firestore.rules.test.ts` at repo root with a separate `package.json`
   - What's unclear: Whether this project has or needs a root-level `package.json` test runner
   - Recommendation: Check if a root `package.json` exists. If not, put the rules test in `pwa/` pointing to the root rules file via relative path.

---

## Sources

### Primary (HIGH confidence)
- [Control access to specific fields | Firestore | Google Cloud](https://docs.cloud.google.com/firestore/native/docs/security/rules-fields) — `diff().affectedKeys()` pattern for SEC-02
- [Stripe Integration Security Guide](https://docs.stripe.com/security/guide) — CSP directives required for Stripe Checkout
- [Firebase Hosting full-config](https://firebase.google.com/docs/hosting/full-config) — `firebase.json` headers array format
- Existing codebase — `firestore.rules`, `firestore.rules.test.ts` in worktree, all Firestore repo files for subcollection map
- `functions/__mocks__/firebase-admin-firestore.ts` — confirmed mock pattern supports extension

### Secondary (MEDIUM confidence)
- [Firestore Security Rules Examples | Sentinel Stand](https://www.sentinelstand.com/article/firestore-security-rules-examples) — field-level ownership patterns
- [In-depth guide to Firestore Security Rules | Makerkit](https://makerkit.dev/blog/tutorials/in-depth-guide-firestore-security-rules) — `fieldsNotInCreateAction` helper pattern
- Firebase groups thread on CSP domains — Firebase SDK domain requirements

### Tertiary (LOW confidence — flag for manual validation)
- Firebase Auth exact `connect-src` domains: `https://securetoken.googleapis.com`, `https://identitytoolkit.googleapis.com` — sourced from community reports, not official docs. Must be verified via browser DevTools during CSP testing.
- Stripe telemetry domains `q.stripe.com`, `r.stripe.com` — sourced from GitHub issues, not official Stripe docs. Verify via browser DevTools.

---

## Metadata

**Confidence breakdown:**
- Firestore rules (SEC-01, SEC-02): HIGH — existing tested rules file in worktree, field-blocking pattern from official docs
- CSP (SEC-03): MEDIUM — format confirmed, some domains (especially Firebase SDK internals) require browser DevTools verification after deploy
- Rate limiting (SEC-04): HIGH — transaction pattern is standard firebase-admin, no external dependencies, existing mock infrastructure supports extension

**Research date:** 2026-03-21
**Valid until:** 2026-06-21 (Firestore rules API is stable; Stripe CSP domains may change with major Stripe.js versions)

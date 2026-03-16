# Phase 12: Fix Firestore Pain Log Security Rules - Research

**Researched:** 2026-03-15
**Domain:** Firestore Security Rules — nested subcollection access patterns
**Confidence:** HIGH

## Summary

The pain log feature is functionally complete at every layer — domain logic (`pain-trend-analyzer.ts`), repository (`FirestoreInjuryRepo`, `LocalInjuryRepo`), UI (`injuries/[id].tsx`), and visualization (`PainTrendChart`). The blocking gap is that `savePainLog` and `getPainLogs` write and read from a **3-level deep path**: `/users/{uid}/injuries/{injuryId}/painLogs/{logId}`. The existing Firestore security rules only contain a single-wildcard subcollection rule (`/{subcollection}/{docId}`) that covers 1-level subcollections. Firestore wildcard matching is **non-recursive** by default — `{subcollection}/{docId}` does NOT match a 2-level nested path. The fix is a single additional `match` block with a nested wildcard, plus corresponding tests in the existing `firestore.rules.test.ts` file.

INJR-03 (user can log pain levels) and INJR-04 (pain trend analysis receives real data) are both blocked by this rules gap. The UI and domain logic are in place; no code changes are needed there.

**Primary recommendation:** Add a nested `match /injuries/{injuryId}/painLogs/{logId}` block inside `match /users/{userId}` in `firestore.rules`, then add 4-5 targeted tests for the pain log path in `firestore.rules.test.ts`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INJR-03 | User can log pain levels for active injuries | `savePainLog` in `FirestoreInjuryRepo` writes to `/users/{uid}/injuries/{injuryId}/painLogs/{logId}` — path must be allowed by security rules |
| INJR-04 | App analyzes pain trends over time and surfaces insights | `getPainLogs` in `FirestoreInjuryRepo` reads the same path; `analyzeTrend()` in `pain-trend-analyzer.ts` is already wired in `[id].tsx` — real data flows when read is allowed |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Firebase Security Rules Language | rules_version = '2' | Declarative server-side access control | Already in use in `firestore.rules` |
| `@firebase/rules-unit-testing` | ^5.0.0 | Test rules against local Firestore emulator | Already installed as devDependency |
| Firebase Emulator Suite (Firestore) | bundled with firebase-tools | Local rules execution environment | Already referenced in `test:rules` script |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@react-native-firebase/firestore` | ^23.8.8 | Client SDK that hits the secured paths | Already in use — no change needed |

**Installation:** No new packages required. All dependencies are present.

## Architecture Patterns

### Firestore Security Rules — Nested Subcollection Pattern

Firestore's `match` directive uses **path wildcards**, not recursive glob matching. The key distinction:

```
match /{subcollection}/{docId}        // matches exactly 1 level deep
match /{subcollection=**}             // matches ALL levels (recursive wildcard)
```

A specific nested path needs its own explicit `match` block. The canonical pattern for a 2-level subcollection under a user document is:

```javascript
// Source: Firestore security rules documentation
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  // 1-level subcollections: workouts, injuries, readiness, etc.
  match /{subcollection}/{docId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }

  // 2-level nested subcollection: painLogs under an injury
  match /injuries/{injuryId}/painLogs/{logId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

The `userId` binding from the outer `match /users/{userId}` is accessible in all nested `match` blocks. This is the standard pattern.

### Alternative: Recursive Wildcard

An alternative is replacing `/{subcollection}/{docId}` with `/{path=**}` to match all depths:

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  match /{path=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

This works but is less explicit — it grants access to any future nested path without requiring a deliberate rules addition. The explicit nested `match` for `painLogs` is the better choice for this project because it is self-documenting and keeps the rules as an inventory of intentional data paths.

### Recommended Project Structure (no change needed)

```
SundeeFundeeRN/
├── firestore.rules                  # ADD nested painLogs match block
├── firestore.rules.test.ts          # ADD 4-5 pain log path tests
└── app/(app)/injuries/[id].tsx      # Already calls savePainLog/getPainLogs
```

### Anti-Patterns to Avoid

- **Using `allow read, write: if true`** for debugging: wipes security, easy to forget
- **Recursive wildcard without thought**: `/{path=**}` permits future undocumented subcollections — use explicit paths when possible
- **Deploying without running emulator tests**: rules are not validated at deploy time for logic correctness, only syntax

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rules correctness testing | Manual curl/SDK calls against prod | `@firebase/rules-unit-testing` v5 with emulator | Deterministic, isolated, fast, already installed |
| Auth simulation | Real Firebase auth tokens in tests | `testEnv.authenticatedContext(uid)` | `initializeTestEnvironment` handles mock auth headers |

**Key insight:** The `@firebase/rules-unit-testing` package with `assertSucceeds` / `assertFails` is the only safe way to verify rules — production Firestore will silently deny writes without an error in the RN client unless the rejection is caught and logged.

## Common Pitfalls

### Pitfall 1: Single Wildcard Does Not Match Nested Paths

**What goes wrong:** The existing rule `match /{subcollection}/{docId}` looks like it should cover `injuries/{injuryId}` (which it does) but developers assume `painLogs/{logId}` nested beneath that is also covered. It is not — Firestore wildcards match exactly one path segment.

**Why it happens:** Glob-style thinking (where `*` often means "any depth") applied to Firestore's segment-based wildcards.

**How to avoid:** Any path with more than 2 segments below the base `match` requires its own `match` block or a recursive wildcard.

**Warning signs:** `FirestoreInjuryRepo.savePainLog` throws a permission-denied error in production even though `saveInjury` works fine. `getPainLogs` returns an empty result (silently) or throws.

### Pitfall 2: Emulator Needed for `test:rules`

**What goes wrong:** Running `npm run test:rules` without the Firebase emulator running causes the test to hang or fail with a connection error.

**Why it happens:** `firebase emulators:exec` spawns the emulator and shuts it down after — but if the emulator binary is not installed, the command fails.

**How to avoid:** Run `firebase setup:emulators:firestore` once if not already done. Alternatively, `npx firebase emulators:start --only firestore` in a separate terminal, then run `npx jest firestore.rules.test.ts` directly.

**Warning signs:** `ECONNREFUSED` on port 8080 in the test output.

### Pitfall 3: `testEnv.clearFirestore()` Required in `afterEach`

**What goes wrong:** Pain log tests from one test bleed into the next, causing unexpected `assertSucceeds` passes (data already exists).

**Why it happens:** The Firestore emulator persists state across test runs within the same process.

**How to avoid:** `afterEach(async () => { await testEnv.clearFirestore(); })` — already present in the existing `firestore.rules.test.ts`.

### Pitfall 4: Rules Deploy Required After Rule Changes

**What goes wrong:** The fix is verified locally but the production app still gets permission denied.

**Why it happens:** Firestore rules must be explicitly deployed with `firebase deploy --only firestore:rules`.

**How to avoid:** Include deploy step in the plan. The emulator tests verify local rules; deploy pushes them to production.

## Code Examples

### Current Blocking Rule Gap

```javascript
// Source: SundeeFundeeRN/firestore.rules (current state)
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  // This rule covers /users/{uid}/injuries/{id}, /users/{uid}/workouts/{id}, etc.
  // It does NOT cover /users/{uid}/injuries/{id}/painLogs/{id}
  match /{subcollection}/{docId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

### Fixed Rule (what to add)

```javascript
// Add inside match /users/{userId} { ... }
match /injuries/{injuryId}/painLogs/{logId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Test Pattern for Pain Log Path

```typescript
// Source: firestore.rules.test.ts pattern (modeled on existing subcollection tests)
describe('Pain log subcollection — /users/{uid}/injuries/{injuryId}/painLogs/{logId}', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('ALLOW: authenticated user can write their own pain log', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users').doc(ALICE_UID)
        .collection('injuries').doc('injury-1')
        .collection('painLogs').doc('log-1')
        .set({ painLevel: 4, date: '2026-03-15T00:00:00.000Z' })
    );
  });

  test('ALLOW: authenticated user can read their own pain logs', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users').doc(ALICE_UID)
        .collection('injuries').doc('injury-1')
        .collection('painLogs').doc('log-1')
        .get()
    );
  });

  test('DENY: user cannot write another user\'s pain log', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users').doc(BOB_UID)
        .collection('injuries').doc('injury-1')
        .collection('painLogs').doc('log-1')
        .set({ painLevel: 7 })
    );
  });

  test('DENY: user cannot read another user\'s pain logs', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users').doc(BOB_UID)
        .collection('injuries').doc('injury-1')
        .collection('painLogs').doc('log-1')
        .get()
    );
  });

  test('DENY: unauthenticated user cannot write pain logs', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb
        .collection('users').doc(ALICE_UID)
        .collection('injuries').doc('injury-1')
        .collection('painLogs').doc('log-1')
        .set({ painLevel: 3 })
    );
  });
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual rules testing against live Firestore | `@firebase/rules-unit-testing` v5 + emulator | Firebase SDK v9 era | Deterministic, no prod side effects |
| `rules_version = '1'` | `rules_version = '2'` | 2019 | v2 required for collection group queries |

**Deprecated/outdated:**
- `@firebase/rules-unit-testing` v1-v4 API (`firebase.initializeTestApp()`): replaced by `initializeTestEnvironment()` in v5 — the existing test file already uses v5 correctly.

## Open Questions

1. **`orderBy('date', 'desc')` on pain logs requires a Firestore index**
   - What we know: `FirestoreInjuryRepo.getPainLogs` calls `.orderBy('date', 'desc')`. Firestore auto-creates single-field ascending indexes, but `desc` ordering and multi-field queries require explicit index definitions.
   - What's unclear: Whether the emulator enforces the index requirement or silently succeeds. Production Firestore will fail with an index-missing error if the index isn't deployed.
   - Recommendation: Add a `firestore.indexes.json` with an index on `painLogs` collection group for `date` descending, or document that the query ordering should be handled client-side instead. Client-side sorting avoids the index requirement and is acceptable given that pain logs per injury are small in number (< 100 records).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30 via `jest-expo` preset |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Rules test file | `SundeeFundeeRN/firestore.rules.test.ts` (excluded from default Jest run via `testPathIgnorePatterns`) |
| Quick run command | `npm test` (excludes rules tests) |
| Full suite command | `npm run test:rules` (requires Firebase emulator) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INJR-03 | Authenticated user can write pain log to `/users/{uid}/injuries/{injuryId}/painLogs/{logId}` | Rules integration | `npm run test:rules` | ✅ `firestore.rules.test.ts` (tests must be added) |
| INJR-03 | Unauthenticated user cannot write pain logs | Rules integration | `npm run test:rules` | ✅ same file |
| INJR-03 | User cannot write another user's pain logs | Rules integration | `npm run test:rules` | ✅ same file |
| INJR-04 | Authenticated user can read pain logs for trend analysis | Rules integration | `npm run test:rules` | ✅ same file |
| INJR-04 | User cannot read another user's pain logs | Rules integration | `npm run test:rules` | ✅ same file |

### Sampling Rate
- **Per task commit:** `npm test` (unit test suite, no emulator needed)
- **Per wave merge:** `npm run test:rules` (emulator-based rules tests)
- **Phase gate:** All rules tests green before `/gsd:verify-work`

### Wave 0 Gaps
None — the test infrastructure is fully in place. `firestore.rules.test.ts` exists with the correct `initializeTestEnvironment` setup, `afterEach(clearFirestore)`, and `@firebase/rules-unit-testing` v5 is installed. New test cases for the pain log path are additions, not new file scaffolding.

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `SundeeFundeeRN/firestore.rules` — confirmed current rule structure and the missing nested match
- Direct code inspection: `SundeeFundeeRN/src/repositories/FirestoreInjuryRepo.ts` — confirmed the exact 3-level Firestore path being written/read
- Direct code inspection: `SundeeFundeeRN/firestore.rules.test.ts` — confirmed existing test patterns, `@firebase/rules-unit-testing` v5 API usage
- Direct code inspection: `app/(app)/injuries/[id].tsx` — confirmed the UI and domain wiring is complete, pain logging button calls `savePainLog`

### Secondary (MEDIUM confidence)
- Firestore security rules documentation pattern for nested subcollections — wildcard segment behavior is well-established and stable

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already installed, no new dependencies
- Architecture: HIGH — confirmed by direct code inspection of current rules file and the exact path used by `FirestoreInjuryRepo`
- Pitfalls: HIGH — the wildcard non-recursion is a documented Firestore behavior, not speculation

**Research date:** 2026-03-15
**Valid until:** 2026-09-15 (Firestore rules language is stable; no planned breaking changes)

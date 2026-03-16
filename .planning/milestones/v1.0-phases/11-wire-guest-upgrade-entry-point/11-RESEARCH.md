# Phase 11: Wire Guest Upgrade Entry Point - Research

**Researched:** 2026-03-15
**Domain:** Firebase Anonymous Auth account linking, React Native / Expo Router auth flow
**Confidence:** HIGH

## Summary

Phase 11 is a targeted wiring fix, not a feature build. The guest upgrade mechanism — `useGuestSignIn.upgrade(credential)` — is fully implemented, tested, and works correctly. The sole gap is that `sign-in.tsx`'s three auth handlers (`handleAppleSignIn`, `handleGoogleSignIn`, `handleEmailAuth`) call `signInWithCredential` / `signInWithEmailAndPassword` / `createUserWithEmailAndPassword` directly, without first checking whether the current user is anonymous. As a result, guest users who tap "Sign in with Apple", "Sign In with Google", or "Create Account" get a brand-new Firebase account, losing all AsyncStorage workout history, cycle logs, and injury profiles.

The fix is a one-file change to `sign-in.tsx` plus new test cases in `app/(app)/__tests__/sign-in.test.tsx` (a file that does not yet exist). Each handler gains a guard: if `getCurrentUser()?.isAnonymous === true`, call `guest.upgrade(credential)` instead of the normal sign-in path. The data migration (`migrateGuestDataToFirestore`) and pending-flag retry mechanism already handle everything downstream.

AUTH-07 is satisfied the moment this routing branch is reachable. No backend changes, no new libraries, and no repository changes are required.

**Primary recommendation:** Modify the three `handle*` functions in `sign-in.tsx` to detect an anonymous session via `getCurrentUser().isAnonymous` and call `guest.upgrade(credential)`; add a test file covering both the guest-upgrade branch and the normal (non-guest) sign-in branch for each provider.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-07 | User data syncs across devices when authenticated | Achieved by calling `guest.upgrade(credential)` in sign-in.tsx: `linkWithCredential` preserves the Firebase UID so all Firestore writes already keyed to that UID remain intact; `migrateGuestDataToFirestore` moves AsyncStorage data to Firestore in the same call |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@react-native-firebase/auth` | installed (native) | `getCurrentUser()`, `linkWithCredential()` | Already wired into `src/firebase/auth.ts`; used by all auth hooks |
| `firebase/auth` (web) | installed | Web parity — same function signatures | `src/firebase/auth.web.ts` exposes identical API |
| `useGuestSignIn` hook | internal | Exposes `upgrade(credential)` | Phase 9 — fully implemented, 100% tested |
| `expo-apple-authentication` | installed | Produces Apple `identityToken` | Already used by `useAppleSignIn` |
| `@react-native-google-signin/google-signin` | installed | Produces Google `idToken` | Already used by `useGoogleSignIn` |

### No New Dependencies

This phase requires zero new package installs. All libraries are already in the project.

## Architecture Patterns

### The Upgrade Branch Pattern

Each handler in `sign-in.tsx` that produces an `AuthCredential` must check for an existing anonymous session before consuming the credential in the standard sign-in path.

**Pseudocode — every credential-producing handler:**

```
1. Obtain credential (Apple token / Google idToken / email+password)
2. const currentUser = getCurrentUser()
3. if (currentUser?.isAnonymous) {
     await guest.upgrade(credential)
     // onAuthStateChanged fires automatically, navigation handled by SessionProvider
   } else {
     await [normal signInWithCredential / signInWithEmailAndPassword / createUserWithEmailAndPassword]
   }
```

The `guest.upgrade(credential)` call already wraps `linkWithCredential` + `migrateGuestDataToFirestore` + the pending-flag pattern. No additional logic is needed in `sign-in.tsx`.

### Email/password edge case

For `handleEmailAuth`, the upgrade branch only makes sense in **sign-up mode** (`isSignUpMode === true`). A guest signing in with an existing email account has no new credential to produce — the correct behavior is to sign them in normally (which creates a new session, and their guest data is separate). For the upgrade path:

- Sign-up mode (`isSignUpMode === true`): create an `EmailAuthProvider.credential(email, password)` and call `guest.upgrade(credential)`.
- Sign-in mode (`isSignUpMode === false`): the normal `signInWithEmailAndPassword` path; the user already has a permanent account, no upgrade needed.

**EmailAuthProvider for credential creation:**

```typescript
// native (auth.ts)
import { EmailAuthProvider } from '@react-native-firebase/auth';
const credential = EmailAuthProvider.credential(email, password);

// web (auth.web.ts)
import { EmailAuthProvider } from 'firebase/auth';
const credential = EmailAuthProvider.credential(email, password);
```

`EmailAuthProvider.credential` is already exported from `@react-native-firebase/auth` (static on the `auth` module object). The web equivalent is available from `firebase/auth`. Both must be added to the platform auth wrappers (`auth.ts` and `auth.web.ts`) and re-exported from `src/firebase/auth.ts`.

### Recommended Project Structure (no changes needed)

```
src/firebase/
├── auth.ts              # Add: export EmailAuthProvider
├── auth.web.ts          # Add: export EmailAuthProvider (firebase/auth)
src/auth/
├── useGuestSignIn.ts    # No changes — upgrade() is complete
├── useAppleSignIn.ts    # No changes — signIn() returns credential
├── useGoogleSignIn.ts   # No changes — signIn() returns credential
├── useEmailAuth.ts      # No changes — signUp/signIn unchanged
app/
├── sign-in.tsx          # THE change — 3 handlers gain isAnonymous guard
├── (app)/__tests__/
│   └── sign-in.test.tsx # NEW — tests for both upgrade and normal branches
```

### Anti-Patterns to Avoid

- **Calling `guest.upgrade()` in sign-in mode for email:** A returning user with an existing email account cannot link — `linkWithCredential` throws `auth/email-already-in-use`. Only call upgrade in sign-up mode.
- **Re-throwing from the upgrade branch:** `guest.upgrade()` already handles migration failures non-fatally. If `linkWithCredential` itself fails (e.g., `auth/credential-already-in-use`), it rethrows and the existing `setError` in `catch` handles display.
- **Duplicate navigation after upgrade:** `onAuthStateChanged` in `SessionProvider` fires when `linkWithCredential` completes (the user's `isAnonymous` flips to `false`), which triggers the existing `useEffect` redirect in `sign-in.tsx`. Do not add manual `router.replace()` calls in the upgrade path.
- **Passing credential instead of calling existing sign-in hook:** Do not bypass `useAppleSignIn.signIn()` or `useGoogleSignIn.signIn()` to get the credential. Instead, refactor those hooks to return the credential (or expose a `getCredential()` step), OR obtain the credential inside `handleAppleSignIn`/`handleGoogleSignIn` and pass it to `guest.upgrade()`. The simplest path: extract credential creation into a helper and share between upgrade and normal paths.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Account linking | Custom merge logic | `linkWithCredential` (Firebase) | Atomically links anonymous account to permanent provider, preserves UID and all Firestore data |
| Data migration | Inline AsyncStorage-to-Firestore copy | `migrateGuestDataToFirestore()` | Already handles 13 keys, 499-op batch limit, pending flag, retry on next launch |
| Anonymous user detection | Reading from AsyncStorage | `getCurrentUser().isAnonymous` | Firebase Auth provides this synchronously from in-memory state |
| Credential construction | Parsing raw tokens | `AppleAuthProvider.credential()` / `GoogleAuthProvider.credential()` / `EmailAuthProvider.credential()` | Provider objects already exported from `auth.ts` |

**Key insight:** Every hard problem in this phase is already solved. The only gap is a 5-line conditional in each handler.

## Common Pitfalls

### Pitfall 1: `auth/credential-already-in-use` on upgrade

**What goes wrong:** A guest tries to upgrade with an Apple/Google credential that is already linked to an existing Firebase account. `linkWithCredential` throws `auth/credential-already-in-use`.

**Why it happens:** The same Apple ID or Google account was used before on another device; a permanent account already exists.

**How to avoid:** Catch this specific error code. The correct UX is to sign the user into the existing account (using `signInWithCredential`) and — if desired — offer to merge the guest data. For v1, displaying the error "This account already exists. Please sign in normally." is acceptable. Do not silently swallow the error.

**Warning signs:** The error message from `getAuthErrorMessage` for `auth/credential-already-in-use` must be user-friendly; verify `authErrors.ts` handles this code.

### Pitfall 2: `auth/email-already-in-use` for email upgrade

**What goes wrong:** Guest tries to sign up with an email that already has a permanent Firebase account. `linkWithCredential` throws `auth/email-already-in-use`.

**How to avoid:** Same treatment as pitfall 1 — surface the error, suggest the user sign in normally instead. The email sign-in path (non-guest) continues to work; the user's guest data will not be merged in this case.

### Pitfall 3: Credential not accessible from existing hooks

**What goes wrong:** `useAppleSignIn.signIn()` calls `signInWithCredential(credential)` internally and returns the user, but does not expose the credential. To call `guest.upgrade(credential)`, the handler in `sign-in.tsx` needs the credential before it is consumed.

**How to avoid:** Two viable approaches:
1. Inline the Apple/Google credential extraction in `sign-in.tsx` (duplicate the `appleSignInAsync` / `GoogleSignin.signIn` call). This is the simplest change but adds duplication.
2. Refactor `useAppleSignIn` and `useGoogleSignIn` to return an intermediate credential, then have `sign-in.tsx` decide whether to upgrade or sign in normally.

Approach 2 is cleaner and keeps the hooks testable. The planner should choose approach 2 for consistency. The `upgrade` function already accepts `AuthCredential` — the type contract is already defined.

### Pitfall 4: EmailAuthProvider not exported from platform wrappers

**What goes wrong:** `auth.ts` currently exports `AppleAuthProvider` and `GoogleAuthProvider` but not `EmailAuthProvider`. Calling `EmailAuthProvider.credential(email, password)` in `sign-in.tsx` will fail to compile.

**How to avoid:** Add `EmailAuthProvider` export to both `auth.ts` and `auth.web.ts`:

```typescript
// auth.ts (native)
export const EmailAuthProvider = auth.EmailAuthProvider;

// auth.web.ts (web)
export { EmailAuthProvider } from 'firebase/auth';
```

Add `EmailAuthProvider` to the `__mocks__/@react-native-firebase/auth.ts` mock:

```typescript
const EmailAuthProvider = {
  credential: jest.fn().mockReturnValue({ providerId: 'password', token: 'mock-email-token' }),
};
```

### Pitfall 5: Test for `sign-in.tsx` does not yet exist

**What goes wrong:** No tests cover `handleAppleSignIn`, `handleGoogleSignIn`, or `handleEmailAuth`. Adding the upgrade branch without tests leaves the behavior unverified.

**How to avoid:** Create `app/(app)/__tests__/sign-in.test.tsx` (see Validation Architecture). The existing auth hook tests (`useGuestSignIn.test.ts`) already verify the upgrade mechanics; this test file verifies that `sign-in.tsx` routes to `guest.upgrade()` when `isAnonymous` is true.

## Code Examples

Verified patterns from existing codebase:

### Checking anonymous user (from `AuthContext.tsx`)

```typescript
// Source: SundeeFundeeRN/src/auth/AuthContext.tsx:73
isGuest: user?.isAnonymous === true,
```

### Calling upgrade (from `useGuestSignIn.ts`)

```typescript
// Source: SundeeFundeeRN/src/auth/useGuestSignIn.ts:49-83
const upgrade = useCallback(
  async (credential: AuthCredential): Promise<unknown> => {
    // ...
    const currentUser = getCurrentUser();
    const result = await linkWithCredential(currentUser, credential);
    // migration follows...
    return result;
  },
  []
);
```

### Obtaining AuthCredential for Apple (from `useAppleSignIn.ts`)

```typescript
// Source: SundeeFundeeRN/src/auth/useAppleSignIn.ts:34-45
const appleCredential = await appleSignInAsync({ requestedScopes: [...] });
const { identityToken } = appleCredential;
const credential = AppleAuthProvider.credential(identityToken, undefined);
```

### Obtaining AuthCredential for Google (from `useGoogleSignIn.ts`)

```typescript
// Source: SundeeFundeeRN/src/auth/useGoogleSignIn.ts:38-48
const signInResult = await GoogleSignin.signIn();
const idToken = signInResult.data?.idToken;
const credential = GoogleAuthProvider.credential(idToken);
```

### How to construct email credential (EmailAuthProvider — not yet in codebase)

```typescript
// auth.ts (to add)
export const EmailAuthProvider = auth.EmailAuthProvider;
// usage in sign-in.tsx
const credential = EmailAuthProvider.credential(email, password);
await guest.upgrade(credential);
```

### Handler shape after fix (conceptual — sign-in.tsx)

```typescript
async function handleAppleSignIn(): Promise<void> {
  try {
    const credential = await apple.getCredential(); // refactored
    const currentUser = getCurrentUser();
    if (currentUser?.isAnonymous) {
      await guest.upgrade(credential);
    } else {
      await apple.signInWithCredential(credential);
    }
  } catch {
    // error set in hook
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Anonymous accounts separate from permanent accounts | `linkWithCredential` atomically upgrades anonymous UID to permanent | Firebase baseline | Same UID retained — Firestore data needs no migration |
| Migration blocking upgrade | Migration non-blocking with pending-flag retry | Phase 9 (this project) | Upgrade always succeeds even if migration fails |

**Deprecated/outdated:**

- None relevant to this phase.

## Open Questions

1. **Refactor hooks vs. inline credential extraction**
   - What we know: `useAppleSignIn` and `useGoogleSignIn` do not currently return the credential. The upgrade path needs the credential before it is consumed by `signInWithCredential`.
   - What's unclear: Whether to refactor hooks (cleaner) or inline extraction (minimal change).
   - Recommendation: Refactor the hooks to return the credential from a `getCredential()` step; `sign-in.tsx` decides whether to upgrade or sign in. This keeps hooks testable and avoids duplicating platform SDK calls.

2. **UX when `auth/credential-already-in-use`**
   - What we know: Firebase will throw this error if the Apple/Google/email credential is linked to a different existing account.
   - What's unclear: Should the app silently fall back to signing in to the existing account (merging nothing), or present an explicit choice?
   - Recommendation: For v1, display an error message ("This account already exists. Please sign in instead.") and let the user restart. No data merging across accounts.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | jest-expo (Jest 29) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest app/\(app\)/__tests__/sign-in.test.tsx --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-07 | Apple handler calls `guest.upgrade(credential)` when `isAnonymous` is true | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleAppleSignIn.*guest"` | Wave 0 |
| AUTH-07 | Google handler calls `guest.upgrade(credential)` when `isAnonymous` is true | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleGoogleSignIn.*guest"` | Wave 0 |
| AUTH-07 | Email sign-up handler calls `guest.upgrade(credential)` when `isAnonymous` is true | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "handleEmailAuth.*guest.*signup"` | Wave 0 |
| AUTH-07 | Normal sign-in still works when user is NOT anonymous (regression) | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "non-guest"` | Wave 0 |
| AUTH-07 | `auth/credential-already-in-use` error surfaces to UI | unit | `npx jest app/\(app\)/__tests__/sign-in.test.tsx -t "credential-already-in-use"` | Wave 0 |
| AUTH-07 | `EmailAuthProvider` exported from `auth.ts` and `auth.web.ts` | unit (import) | `npx jest src/firebase/__tests__/auth.test.ts` | ❌ Wave 0 (add to existing) |

### Sampling Rate

- **Per task commit:** `cd SundeeFundeeRN && npx jest app/\(app\)/__tests__/sign-in.test.tsx --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `app/(app)/__tests__/sign-in.test.tsx` — covers AUTH-07 (all three upgrade branches + regression)
- [ ] `EmailAuthProvider` mock in `__mocks__/@react-native-firebase/auth.ts` — needed for email upgrade tests

## Sources

### Primary (HIGH confidence)

- Codebase: `SundeeFundeeRN/src/auth/useGuestSignIn.ts` — upgrade() implementation, fully tested
- Codebase: `SundeeFundeeRN/app/sign-in.tsx` — current handler logic, gap location confirmed
- Codebase: `SundeeFundeeRN/src/firebase/auth.ts` — linkWithCredential, getCurrentUser exported
- Codebase: `SundeeFundeeRN/src/firebase/auth.web.ts` — web parity confirmed
- Codebase: `.planning/v1.0-MILESTONE-AUDIT.md` — authoritative gap description for AUTH-07
- Codebase: `SundeeFundeeRN/__mocks__/@react-native-firebase/auth.ts` — mock structure for test authoring

### Secondary (MEDIUM confidence)

- Firebase docs (general): `linkWithCredential` is the standard upgrade path for anonymous accounts — documented behavior aligns with project implementation

### Tertiary (LOW confidence)

- None applicable — entire research domain is the existing codebase, which is directly readable.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all libraries confirmed in package.json / existing imports
- Architecture: HIGH — upgrade() contract confirmed from source + tests; handler pattern derived directly from existing code
- Pitfalls: HIGH — `auth/credential-already-in-use` and `EmailAuthProvider` gaps confirmed from direct code inspection; not hypothetical

**Research date:** 2026-03-15
**Valid until:** Until `sign-in.tsx` or auth hook interfaces change (stable — no external dependencies changing)

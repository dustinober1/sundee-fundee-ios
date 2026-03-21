# Phase 7: Gap Closure — Firestore Deploy + Dashboard Routes - Research

**Researched:** 2026-03-21
**Domain:** Firebase Firestore rules deployment (CI/CD), React Router navigation fixes
**Confidence:** HIGH

## Summary

Phase 7 is a focused gap-closure phase with two completely independent workstreams. The first (SEC-01, SEC-02) is a deployment gap: `firestore.rules` exists, is tested, and has been wired into `firebase.json` since Phase 3 — but `deploy.yml` never added a step to deploy Firestore rules. The Stripe paywall can currently be bypassed by any authenticated user writing `premiumEntitlement: { active: true }` directly via the Firebase Client SDK. The fix is a single YAML step in `deploy.yml` plus an equivalent line in the manual deploy fallback.

The second workstream is a routing typo gap: `Dashboard.tsx` hardcodes `/workout` and `/ai-workout` as Link destinations, but the router defines these routes as `workout-session` and `ai-workout/config` respectively. These have been broken since Phase 5 (UX/routing work). Two line-level changes fix both flows.

Both fixes are low-risk, zero-ambiguity changes against existing verified code. No new dependencies, no architectural decisions, no design work.

**Primary recommendation:** Fix `deploy.yml` and `Dashboard.tsx` in one wave. Write a Vitest test for Dashboard route Links so this class of regression is caught by CI in the future.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-01 | Firestore security rules enforce per-user ownership on all subcollections | Rules exist at `firestore.rules` and are wired in `firebase.json` — only deployment is missing. Add `--only firestore` step to `deploy.yml` and manual deploy script. |
| SEC-02 | Firestore rules prevent client-side write to `premiumEntitlement` field | Same code as SEC-01 — same deployment gap. Same fix. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase-tools | (already via npx) | `firebase deploy --only firestore` | Official Firebase CLI; already used for functions deploy in deploy.yml |
| @firebase/rules-unit-testing | ^3.0.0 | Emulator-based rules tests | Already installed in root package.json; existing test suite at firestore.rules.test.ts |
| react-router | (current) | `<Link to="...">` navigation | Already used throughout the codebase |
| vitest + @testing-library/react | (current in pwa/) | Component tests for Dashboard | Already configured in pwa/vitest.config.ts; pattern established in WorkoutSession.test.tsx, SignIn.test.tsx |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FirebaseExtended/action-hosting-deploy | @v0 | Hosting deploy step | Already handles hosting deploy — Firestore step is additive alongside it |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `npx firebase-tools deploy --only firestore` | `firebase deploy --only firestore` | Global install required; npx pattern already established for functions step in deploy.yml |

**Installation:**
No new packages needed. All dependencies are in place.

## Architecture Patterns

### Recommended Project Structure
No structural changes. All work is modifications to existing files:
```
.github/workflows/deploy.yml      # Add Firestore rules deploy step
pwa/src/routes/Dashboard.tsx      # Fix 2 route paths
pwa/src/routes/Dashboard.test.tsx # New test file (Wave 0 gap)
```

### Pattern 1: Firebase deploy --only firestore
**What:** Deploys `firestore.rules` to production using the service account already available in the workflow.
**When to use:** After any change to `firestore.rules`; runs as part of every production deploy.
**Example:**
```yaml
# Add after the "Deploy Cloud Functions" step in deploy.yml
- name: Deploy Firestore rules
  env:
    SA_KEY: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE }}
  run: |
    echo "$SA_KEY" > /tmp/sa-key.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json
    npx firebase-tools deploy --only firestore --project sundee-fundee
    rm /tmp/sa-key.json
```

### Pattern 2: Dashboard Link path corrections
**What:** Update two `<Link to="...">` paths in `Dashboard.tsx` to match the routes defined in `router.tsx`.
**When to use:** Any time a Link destination must match a `path:` entry in the router config.

| Dashboard.tsx (current) | router.tsx (canonical) | Fix |
|------------------------|------------------------|-----|
| `<Link to="/workout">` | `{ path: 'workout-session', ... }` | Change to `/workout-session` |
| `<Link to="/ai-workout">` | `{ path: 'ai-workout/config', ... }` | Change to `/ai-workout/config` |

### Pattern 3: Dashboard component test (Nyquist)
**What:** Vitest + Testing Library test that renders Dashboard and asserts correct `href` values on navigation links.
**When to use:** Wave 0 before implementing the fix, following TDD RED scaffold convention established in Phase 4.
**Example:**
```tsx
// Source: established pattern in pwa/src/routes/WorkoutSession.test.tsx and SignIn.test.tsx
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router';
import { Dashboard } from './Dashboard';

// Mock dependencies
vi.mock('../auth/AuthContext', () => ({
  useSession: () => ({ user: null, isGuest: true }),
}));
vi.mock('../entitlements/EntitlementContext', () => ({
  useEntitlementContext: () => ({ isPremium: false }),
}));
vi.mock('../repositories/WODRepo', () => ({
  getWODRepo: () => ({ getWODForDate: () => Promise.resolve(null) }),
}));
vi.mock('../repositories/OnboardingProfileRepo', () => ({
  getOnboardingProfileRepo: () => ({ getProfile: () => Promise.resolve(null) }),
}));

test('Start Workout button links to /workout-session', () => {
  render(<MemoryRouter><Dashboard /></MemoryRouter>);
  expect(screen.getByText('Start Workout').closest('a')).toHaveAttribute('href', '/workout-session');
});

test('AI Workout card links to /ai-workout/config', () => {
  render(<MemoryRouter><Dashboard /></MemoryRouter>);
  expect(screen.getByText('AI Workout').closest('a')).toHaveAttribute('href', '/ai-workout/config');
});
```

### Anti-Patterns to Avoid
- **Hardcoded route strings without router cross-reference:** The root cause of both broken flows. Always verify Link destinations against the actual `path:` entries in `router.tsx`.
- **Deploying only `--only hosting` manually:** The existing manual deploy pattern only deploys hosting. Any manual deploy procedure must include Firestore rules.
- **Using `firebase deploy` (all targets) without specifying `--only`:** Risk of unintended side effects to other Firebase services. Use targeted deploys as the codebase already does.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Firestore rules deployment | Custom HTTP call to Firebase Management API | `firebase-tools deploy --only firestore` | Official path; handles rule validation, versioning, rollback |
| Route correctness testing | Manual QA checklist | Vitest + Testing Library `href` assertion | Automated, runs in CI, catches regressions |
| Rules verification in CI | Re-running emulator tests in deploy.yml | Trust the Phase 3 test suite (already passes) | `firestore.rules.test.ts` verifies rule logic; deploy step is about promotion, not re-verification |

**Key insight:** Both gaps are infrastructure/configuration gaps, not code gaps. The implementation is already correct and tested. The work is wiring the deployment.

## Common Pitfalls

### Pitfall 1: Service account credentials not available for Firestore deploy step
**What goes wrong:** The Firestore deploy step runs but fails with auth error because `GOOGLE_APPLICATION_CREDENTIALS` is not set.
**Why it happens:** The hosting deploy step uses the `FirebaseExtended/action-hosting-deploy` action (which consumes the service account internally). The functions and Firestore steps use `npx firebase-tools` directly and need `GOOGLE_APPLICATION_CREDENTIALS` set explicitly.
**How to avoid:** Use the identical credential pattern already established for the functions deploy step — write SA key to `/tmp/sa-key.json`, export env var, deploy, then `rm` the file.
**Warning signs:** CI log shows "Error: Failed to get Firebase project sundee-fundee. Please make sure the project exists and your account has permission to access it."

### Pitfall 2: `firebase deploy --only firestore` vs `--only firestore:rules`
**What goes wrong:** The `--only firestore` target deploys both rules AND indexes. If a `firestore.indexes.json` doesn't exist or is malformed, the deploy fails even though rules are correct.
**Why it happens:** `firebase deploy --only firestore` is a compound target. Using `--only firestore:rules` deploys only the rules file.
**How to avoid:** Check if `firestore.indexes.json` exists at repo root. If it does not exist, use `--only firestore:rules` to avoid index-related failures. If it does exist, `--only firestore` is safe.
**Warning signs:** `Error: cannot determine Cloud Firestore indexes location` or `No project active`.

### Pitfall 3: Dashboard test — SkeletonCard renders before data loads
**What goes wrong:** The `Start Workout` button renders outside the `isLoading` conditional (line 39 of Dashboard.tsx) and is always visible. But the `AI Workout` card is inside the `isLoading ? <SkeletonCard> : <>cards</>` block. Tests that don't wait for the async state will find `AI Workout` absent.
**Why it happens:** `Promise.all([profileFetch, wodFetch]).finally(() => setIsLoading(false))` — loading starts as `true` and the grid with "AI Workout" is hidden until both fetches resolve.
**How to avoid:** In the Dashboard test, resolve the mocked repo promises immediately (return `Promise.resolve(null)`) and use `await screen.findByText('AI Workout')` (async query) rather than `screen.getByText`.
**Warning signs:** Test fails with "Unable to find an element with the text: AI Workout" even though the component is rendered.

### Pitfall 4: Manual deploy fallback not updated
**What goes wrong:** `deploy.yml` is fixed but the manual deploy procedure (referenced in DEPLOY-03) still only deploys hosting.
**Why it happens:** The audit found the manual deploy fallback uses `--only hosting`. There is no `scripts/manual-deploy.sh` — the manual procedure is likely inline instructions or a CI script variant.
**How to avoid:** Document the correct manual deploy command including Firestore rules in the phase VERIFICATION.md. The correct manual command is:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa-key.json
npx firebase-tools deploy --only firestore:rules --project sundee-fundee
```

## Code Examples

Verified patterns from codebase:

### Existing functions deploy step (model for Firestore step)
```yaml
# Source: .github/workflows/deploy.yml (lines 52-59, current)
- name: Deploy Cloud Functions
  env:
    SA_KEY: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_SUNDEE_FUNDEE }}
  run: |
    echo "$SA_KEY" > /tmp/sa-key.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json
    npx firebase-tools deploy --only functions --project sundee-fundee --force
    rm /tmp/sa-key.json
```

### firebase.json firestore block (already wired)
```json
// Source: firebase.json (current)
"firestore": {
  "rules": "firestore.rules"
}
```
The `firebase.json` firestore block already points to `firestore.rules`. No firebase.json changes needed.

### Correct router paths (from router.tsx)
```typescript
// Source: pwa/src/routes/router.tsx lines 88, 107 (current)
{ path: 'workout-session', element: <L><WorkoutSessionScreen /></L> },
{ path: 'ai-workout/config', element: <L><AIWorkoutConfig /></L> },
```

### Broken Dashboard Links (exact lines to fix)
```tsx
// Source: pwa/src/routes/Dashboard.tsx lines 39 and 57 (current — BROKEN)
<Link to="/workout" className={styles.startBtn}>       // line 39 — must be /workout-session
<Link to="/ai-workout" className={styles.card}>        // line 57 — must be /ai-workout/config
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Global `firebase-tools` install | `npx firebase-tools` | Phase 2/3 | No global dependency required in CI |
| Manual rules deployment via Console | `firebase deploy --only firestore` in CI | Phase 7 (this phase) | Rules are deployed atomically with every production deploy |

**Deprecated/outdated:**
- Nothing deprecated in this phase. All tools and patterns are current.

## Open Questions

1. **Does `firestore.indexes.json` need to exist?**
   - What we know: `firebase.json` has a `"firestore": { "rules": "firestore.rules" }` block but no `"indexes"` key. Firebase CLI `--only firestore` deploys both rules and indexes when configured.
   - What's unclear: Whether the absence of an indexes config means `--only firestore` will fail or silently skip indexes.
   - Recommendation: Use `--only firestore:rules` as the targeted deploy target to avoid any index-related ambiguity. This is the safer and more precise option.

2. **Is there an existing manual deploy script?**
   - What we know: DEPLOY-03 is satisfied (per REQUIREMENTS.md) and the audit mentions a manual fallback. No `scripts/manual-deploy.sh` was found at repo root or `pwa/`.
   - What's unclear: Whether the manual procedure is documented inline or is the `deploy.yml` itself run locally.
   - Recommendation: The plan should add a manual deploy command to a comment block in `deploy.yml` or create a `scripts/manual-deploy.sh`. Either is acceptable — document the updated command including Firestore rules.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest (pwa/) + Jest (repo root, rules) |
| Config file | `pwa/vitest.config.ts` (component tests); `jest.rules.config.js` (Firestore rules) |
| Quick run command | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` |
| Full suite command | `cd pwa && npx vitest run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-01 | Firestore rules deployed to production — per-user ownership enforced | smoke (deploy verification) | `grep -q "firestore" .github/workflows/deploy.yml && echo PASS` | ✅ (deploy.yml exists) |
| SEC-02 | Firestore rules deployed to production — premiumEntitlement blocked | smoke (deploy verification) | Same as SEC-01 — same deploy step | ✅ |
| (route) | Dashboard Start Workout links to /workout-session | unit | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` | ❌ Wave 0 gap |
| (route) | Dashboard AI Workout links to /ai-workout/config | unit | `cd pwa && npx vitest run src/routes/Dashboard.test.tsx` | ❌ Wave 0 gap |

### Sampling Rate
- **Per task commit:** `cd pwa && npx vitest run src/routes/Dashboard.test.tsx`
- **Per wave merge:** `cd pwa && npx vitest run`
- **Phase gate:** Full Vitest suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `pwa/src/routes/Dashboard.test.tsx` — covers route link correctness (Start Workout → /workout-session, AI Workout → /ai-workout/config)

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `.github/workflows/deploy.yml` — confirmed missing Firestore deploy step
- Direct file inspection: `pwa/src/routes/Dashboard.tsx` lines 39, 57 — confirmed broken route strings
- Direct file inspection: `pwa/src/routes/router.tsx` lines 88, 107 — confirmed canonical route paths
- Direct file inspection: `firebase.json` — confirmed `firestore.rules` is wired, no deploy needed for config
- Direct file inspection: `firestore.rules` — confirmed rules are correct, verified by Phase 3 tests
- Direct file inspection: `.planning/v1.0-MILESTONE-AUDIT.md` — authoritative gap evidence with exact line numbers

### Secondary (MEDIUM confidence)
- Firebase CLI docs pattern (via existing usage in deploy.yml): `npx firebase-tools deploy --only <target>` is the correct invocation pattern
- Phase 3 STATE.md decisions: "Firestore rules wired into firebase.json firestore block for unified firebase deploy"

### Tertiary (LOW confidence)
- None — all critical claims are directly verified from codebase files.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all tools already in use
- Architecture: HIGH — exact file paths, line numbers, and code verified from source
- Pitfalls: HIGH — root causes identified from actual codebase inspection (credential pattern, SkeletonCard conditional, `--only firestore` vs `--only firestore:rules`)

**Research date:** 2026-03-21
**Valid until:** Stable — these are configuration/routing bugs with exact known fixes. Valid indefinitely until addressed.

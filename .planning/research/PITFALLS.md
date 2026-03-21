# Pitfalls Research

**Domain:** PWA production readiness (Vite 8 + React 19 + Firebase + Stripe)
**Researched:** 2026-03-21
**Confidence:** HIGH — verified against Firebase docs, Stripe docs, vite-plugin-pwa issues, and official guidance

---

## Critical Pitfalls

### Pitfall 1: Firebase Hosting Missing SPA Rewrite Rule

**What goes wrong:**
Firebase Hosting serves static files by default. Without a catch-all rewrite rule, any deep URL refresh (e.g., `/cycle`, `/programs/session`) returns a 404 from Firebase — the React Router never loads. The app appears to work during dev but breaks immediately after first deploy when users bookmark routes or share links.

**Why it happens:**
Developers test their app locally (Vite dev server handles all routes) and the SPA routing works. Firebase Hosting does not apply Vite's dev-server fallback behavior — it needs an explicit `"rewrites"` block in `firebase.json` to route all non-file requests to `index.html`. No `firebase.json` exists in this repo yet.

**How to avoid:**
Create `firebase.json` at the repo root with:
```json
{
  "hosting": {
    "public": "pwa/dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "/sw.js",
        "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
      },
      {
        "source": "**/*.@(js|css|png|jpg|svg|woff2)",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      }
    ]
  }
}
```
The `**` catch-all MUST come last among rewrites. The service worker `sw.js` MUST be served with `no-cache` — if the browser caches the service worker itself, users never receive updates.

**Warning signs:**
- Deep-link routes return 404 after deploy
- Browser back/forward works but manual URL entry fails
- Lighthouse PWA audit flags "start_url not in service worker scope"

**Phase to address:** Infrastructure / CI-CD setup phase (before any other deploy work)

---

### Pitfall 2: Stripe Webhook Raw Body Destroyed by JSON Middleware

**What goes wrong:**
Firebase Cloud Functions v2 uses `express` internally. If `express.json()` middleware (or any body-parsing middleware) runs before the Stripe webhook handler, it parses the raw request body into a JavaScript object. Stripe's `stripe.webhooks.constructEvent()` requires the original raw bytes to verify the HMAC-SHA256 signature — the parsed JSON string never matches. Every webhook call fails with `No signatures found matching the expected signature for payload` and subscriptions are never activated.

**Why it happens:**
Developers copy a Cloud Functions boilerplate that wraps multiple routes in a single `express` app with `app.use(express.json())` at the top. The Stripe webhook route is then added below, and the signature check silently fails in staging (test mode webhooks are often not verified strictly) but blows up in production.

**How to avoid:**
- Use a dedicated Cloud Function (`onRequest`) for the Stripe webhook, separate from other functions — not as a route in a shared Express app.
- Access `req.rawBody` (Firebase Functions v1) or read the raw buffer from the request before any middleware. Firebase Functions automatically populates `req.rawBody` on `onRequest` handlers.
- In Firebase Functions v2 with `@google-cloud/functions-framework`, configure the function to skip body parsing for the webhook route, or use a dedicated `onRequest` handler.
- Store the webhook secret in Firebase environment config (`firebase functions:config:set stripe.webhook_secret="whsec_..."`), not in code.

```typescript
// Correct pattern for Firebase Functions v2
export const stripeWebhook = onRequest({ cors: false }, (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const event = stripe.webhooks.constructEvent(
    req.rawBody,   // raw bytes, not req.body
    sig,
    process.env.STRIPE_WEBHOOK_SECRET!,
  );
  // ...
});
```

**Warning signs:**
- "No signatures found matching" errors in Cloud Functions logs
- Stripe Dashboard shows webhooks delivered with 400/500 responses
- Subscriptions created in Stripe but `premiumEntitlement.active` never set in Firestore
- Test webhooks via Stripe CLI work but live webhooks fail

**Phase to address:** Stripe integration phase (before any live payment testing)

---

### Pitfall 3: Firestore Security Rules Allow Cross-User Data Access

**What goes wrong:**
Rules that only check `request.auth != null` allow any authenticated user to read or write any other user's documents. In a fitness app storing health-sensitive data (cycle phase, injury profiles, pain logs), this is a data breach. An attacker who creates a legitimate account can enumerate all user IDs (often guessable or leakable) and read every user's workout history, injury records, and cycle data.

**Why it happens:**
The default "authenticated users only" template is shipped as an example and developers treat it as sufficient. The check `allow read, write: if request.auth != null` passes security scanners focused on the "any user = open" case but misses the "authenticated but wrong user" case.

**How to avoid:**
Every user-scoped document must enforce ownership:
```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;

  match /workouts/{workoutId} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
  match /painLogs/{logId} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
  // All subcollections must repeat the ownership check — they do NOT inherit
}
```
Run `firebase emulators:start` and use the Firestore emulator's Rules Playground to test cross-user access attempts. Test: can user A read `/users/userB/workouts`? Should return `false`.

**Warning signs:**
- Rules have `allow read, write: if request.auth != null` without `uid` comparison
- Subcollections exist under `/users/{uid}/` but only the parent doc has ownership rules
- No integration tests that sign in as User A and attempt to read User B's data
- Firebase console "Rules Playground" not used during development

**Phase to address:** Security hardening phase (Firestore rules audit)

---

### Pitfall 4: Service Worker Caches Stale App Versions — Users Stuck on Old Code

**What goes wrong:**
The app uses `registerType: 'autoUpdate'` in vite-plugin-pwa, which forces `skipWaiting: true` and `clientsClaim: true`. This means the new service worker activates immediately across all tabs. However, there are two sub-problems:

1. **Lazy-loaded chunks become 404s**: After a deploy, old precache manifests reference hashed chunk filenames that no longer exist. If a user has the old service worker active and navigates to a lazy-loaded route for the first time (e.g., `/ai-workout/config`), the chunk fetch fails with a 404 because the old filename hash doesn't exist on the new deploy. The result is a white screen with a chunk load error.

2. **Service worker file itself gets cached by the browser**: If `sw.js` is served without `Cache-Control: no-cache`, the browser caches it and never checks for updates. Users run stale code indefinitely.

**Why it happens:**
vite-plugin-pwa's precache manifest contains content-hashed filenames. When a new build runs, all hashes change. The old SW still holds references to old files that have been purged from the CDN. The gap between "old SW active, user clicks new route" and "new SW installed" is the danger window.

**How to avoid:**
- Configure Firebase Hosting to serve `sw.js` with `Cache-Control: no-cache` (see Pitfall 1 config above).
- Add a global error boundary that catches chunk load errors and triggers a hard reload:
```typescript
// In router error element or lazy component wrapper
window.addEventListener('unhandledrejection', (e) => {
  if (e.reason?.message?.includes('Failed to fetch dynamically imported module')) {
    window.location.reload();
  }
});
```
- Consider switching from `autoUpdate` to `prompt` strategy for a better UX update flow — show "New version available, tap to update" rather than silently reloading during a workout session.
- The current vite.config.ts `globPatterns` only includes `**/*.{js,css,html,ico,png,svg,woff2}` — ensure `woff` and `json` assets (resources/programs.json, resources/wods.json) are also included if served from the dist directory.

**Warning signs:**
- Console errors "Failed to fetch dynamically imported module" after deploy
- Users report app is broken until they force-refresh
- Lighthouse PWA audit shows stale resources being served
- Service worker update prompts never appear

**Phase to address:** Service worker and offline support phase; also verify in CI after every build

---

### Pitfall 5: Content Security Policy Blocks Firebase and Stripe

**What goes wrong:**
Adding a `Content-Security-Policy` header is a required production hardening step. A poorly-written CSP will silently block:
- Firebase Auth popup flows (`accounts.google.com`, `appleid.apple.com`)
- Firebase SDK scripts loaded from `www.gstatic.com`
- Stripe.js from `js.stripe.com`
- Firebase Analytics from `www.google-analytics.com`
- Firebase Crashlytics / App Check from `firebaselogging.googleapis.com`
- Recharts SVG rendering (inline styles)
- Service worker registration (requires `worker-src` or `script-src`)

The app appears fine in dev (no CSP header locally) and completely broken in production.

**Why it happens:**
CSP is set once in the Hosting headers config and developers test the happy path. Auth providers, payment iframes, and analytics all load from third-party domains that must be explicitly allowlisted. Each omission causes a silent failure — no console error unless DevTools is open.

**How to avoid:**
Minimum viable CSP for this stack in `firebase.json` headers:
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'unsafe-inline' https://js.stripe.com https://www.gstatic.com https://apis.google.com;
  style-src 'self' 'unsafe-inline';
  connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://api.stripe.com wss://*.firebaseio.com https://firestore.googleapis.com https://identitytoolkit.googleapis.com;
  frame-src https://js.stripe.com https://accounts.google.com;
  img-src 'self' data: https:;
  font-src 'self' data:;
  worker-src 'self' blob:;
```
Note: `'unsafe-inline'` in `script-src` is required because Recharts and inline React hydration use inline styles/scripts. Switching to nonce-based CSP requires build tooling changes.

Start in report-only mode (`Content-Security-Policy-Report-Only`) with a reporting endpoint before enforcing, to catch violations without breaking production.

**Warning signs:**
- Google Sign-In popup opens then immediately closes without authenticating
- Stripe checkout redirect fails silently
- Analytics events stop firing after CSP is added
- Browser console shows "Refused to load" errors in production but not dev

**Phase to address:** Security hardening phase (after all integrations are working, add CSP last)

---

### Pitfall 6: PWA Icons Missing or Wrong Format — Install Prompt Never Appears

**What goes wrong:**
The current `vite.config.ts` manifest references `/icons/icon-192.png` and `/icons/icon-512.png`, but the `pwa/public/` directory only contains `favicon.svg` and `icons.svg` — no PNG icons exist. Chrome's installability checker requires actual PNG files at the declared paths. The install prompt never fires. Lighthouse fails the "Installable" PWA check. On iOS Safari, the home screen icon falls back to a screenshot of the page.

Additionally, the manifest declares the 512px icon twice with `purpose: 'maskable'` but the same source image. On Android, maskable icons require 20% safe-zone padding — using a non-padded icon with `purpose: 'maskable'` will crop your logo to an unrecognizable circle.

**Why it happens:**
The Vite PWA plugin generates the manifest JSON but does not generate icon files — those must be provided. Developers declare icons in config without actually placing the files. The disconnect is not caught during development because the install prompt doesn't fire on localhost.

**How to avoid:**
- Generate icons using a tool like `sharp` or `pwa-asset-generator`: one regular 512px PNG (logo fills the safe area) and one maskable 512px PNG (logo centered in the middle 60% of the canvas, with the outer 40% being background color `#0D1A40`).
- Place both at `pwa/public/icons/icon-192.png`, `pwa/public/icons/icon-512.png`, and `pwa/public/icons/icon-512-maskable.png`.
- Update the manifest to reference separate regular and maskable icons:
```javascript
icons: [
  { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
  { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
  { src: '/icons/icon-512-maskable.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
]
```
- Add `apple-touch-icon` at `pwa/public/apple-touch-icon.png` (180px) — iOS Safari ignores the manifest icons and only reads this link tag.

**Warning signs:**
- Chrome DevTools Application tab → Manifest shows icon errors
- Lighthouse audit: "Manifest doesn't have a maskable icon"
- No install prompt appearing on mobile Chrome after visiting the site twice
- iOS home screen shows a screenshot instead of an app icon

**Phase to address:** PWA assets and manifest phase (before any production deploy or Lighthouse audit)

---

### Pitfall 7: Missing Error Boundaries Cause White Screens on Lazy Route Failures

**What goes wrong:**
The router uses `React.lazy()` for every route except Dashboard. If a lazy chunk fails to load (network flap, CDN miss, post-deploy stale cache) or if a component throws during render (bad Firestore data, null dereference), React bubbles the error to the nearest error boundary. Currently there are no error boundaries in the component tree — the error propagates to React's root and the entire app goes blank. The user sees a white screen with no recovery path.

**Why it happens:**
Error boundaries are not required to make the app work in development. React's StrictMode does not enforce them. The `<Suspense>` fallback in `router.tsx` handles loading states but does not catch render errors. Lazy loading errors (failed chunk fetches) are not the same as Suspense loading states — they throw an error that bypasses Suspense.

**How to avoid:**
Add a minimum of two error boundaries:
1. **Root-level** wrapping the entire app in `main.tsx` — catches catastrophic failures with a full-page "Something went wrong, please refresh" message.
2. **Route-level** wrapping each `<L>` (lazy route wrapper) — catches per-route failures and allows the nav/shell to remain functional.

```tsx
// Root error boundary in main.tsx
<ErrorBoundary fallback={<CrashFallback />}>
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>
</ErrorBoundary>
```

React 19 introduced improved error boundary handling with `use client` and `use` hook patterns, but class-based or library-based (`react-error-boundary` package) boundaries remain the standard approach for route-level protection.

**Warning signs:**
- A Firestore document with unexpected `null` values crashes a route with no recovery
- Any unhandled promise rejection in a component renders a blank page
- Chrome DevTools shows React's "The above error occurred in the <Component> component" but users see nothing

**Phase to address:** Error handling and resilience phase (before any user-facing testing)

---

### Pitfall 8: GitHub Actions CI Deploys Without Gating on Test Failures

**What goes wrong:**
A CI workflow that runs `npm run build && firebase deploy` without first running `vitest run` will deploy broken code. Build success does not imply correctness — TypeScript compilation passes even when domain logic is broken. The existing Vitest test suite (domain logic, components) provides real regression protection that is wasted if CI skips it.

A secondary issue: CI workflows that deploy using `FIREBASE_TOKEN` (legacy auth) will break when Firebase deprecates it in favor of Workload Identity Federation (GCP service account keys).

**Why it happens:**
CI pipelines are often written quickly with "make it deploy" as the only goal. Tests are added to the workflow as an afterthought, often after they first fail.

**How to avoid:**
Structure the CI workflow with explicit dependency ordering:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
        working-directory: pwa
      - run: npx vitest run
        working-directory: pwa

  deploy:
    needs: [test]   # deploy only if tests pass
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci && npm run build
        working-directory: pwa
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          # ... all other VITE_ secrets
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: ${{ vars.FIREBASE_PROJECT_ID }}
```

Use `FIREBASE_SERVICE_ACCOUNT` (JSON key from a dedicated deployment service account) rather than the deprecated `FIREBASE_TOKEN`. All `VITE_*` environment variables must be injected at build time — they are not available at runtime since Vite inlines them.

**Warning signs:**
- CI workflow only has a `build` step, no `test` step
- `FIREBASE_TOKEN` used instead of `FIREBASE_SERVICE_ACCOUNT`
- `VITE_STRIPE_PRICE_ID` still shows `price_PLACEHOLDER` in the deployed app (env var not injected)
- Deploy succeeds but app shows auth errors because Firebase project ID is wrong

**Phase to address:** CI/CD pipeline phase (the first infrastructure task)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inlining Firebase config in code | Simpler setup, no env var management | Config leaks in git history; can't rotate keys without code deploy | Never — always use `VITE_` env vars |
| `allow read, write: if true` Firestore rules during development | No auth friction while building | Any internet user can read/write all user data | Only with emulator, never pushed to prod |
| Skipping Stripe webhook signature verification in test mode | Faster local testing | No defense against forged events in prod; grants free premium | Never in production code paths |
| Single `firebase.json` with all hosting + functions config | One file to manage | Functions config in root `firebase.json` can conflict with `pwa/` subdirectory builds | Acceptable if paths are correct |
| `registerType: 'autoUpdate'` without chunk-load error handling | Simpler update flow | Users get white screens after deploy if a lazy chunk fetch fails | Acceptable only if error boundary catches chunk failures |
| No error boundaries while iterating on UI | Faster development cycle | One null dereference blanks the entire app in production | Only in pre-alpha, never at launch |
| Placeholder `price_PLACEHOLDER` Stripe price ID | App builds and tests pass | Stripe checkout fails silently; no subscription revenue | Never in production deploy |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase Hosting + Vite | Deploy the project root instead of `pwa/dist` | Set `"public": "pwa/dist"` in `firebase.json` |
| Firebase Auth + CSP | Forgetting `accounts.google.com` and `appleid.apple.com` in `frame-src` | Allowlist all identity provider domains explicitly |
| Stripe + Cloud Functions | Using `req.body` instead of `req.rawBody` in webhook handler | Access `req.rawBody` directly on Firebase Functions `onRequest` handlers |
| Stripe webhooks | Using test webhook secret with live mode keys | Maintain separate `STRIPE_WEBHOOK_SECRET_TEST` and `STRIPE_WEBHOOK_SECRET_LIVE` env vars |
| Firestore offline persistence + service worker | Initializing Firestore before service worker installs | `initializeFirestore` with `persistentLocalCache` handles this, but verify no race on first paint |
| vite-plugin-pwa + Firebase Hosting | Not setting `Cache-Control: no-cache` on `sw.js` | Add explicit header in `firebase.json` for `/sw.js` |
| GitHub Actions + Vite build | `VITE_` env vars not set in CI = `undefined` inlined | Add all `VITE_*` vars to GitHub repository secrets and inject at build step |
| React Router v7 + Firebase Hosting | Deep links 404 without `"rewrites"` | Add `{ "source": "**", "destination": "/index.html" }` rewrite |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Firestore `onSnapshot` subscriptions not unsubscribed | Memory leak, duplicate Firestore listeners, stale data on tab reuse | Always return the unsubscribe function from `useEffect` | Becomes visible at 5+ pages with real-time listeners |
| `persistentLocalCache` with large datasets | First load takes 2-5s on mobile; IndexedDB queries 20x slower than the deprecated API | Limit Firestore query sizes, use pagination, test on low-end Android | Any collection with 100+ documents |
| Analytics `initAnalytics()` called on every route render | `RootLayout` calls `initAnalytics()` at module load — acceptable, but if moved into a hook called per route it fires multiple times | Keep analytics init at module scope in a single file | Fires duplicate events after any React re-render |
| Recharts SVG rendering large datasets | Cycle charts with 365 data points freeze on mobile | Limit chart data to 90 days by default, paginate or downsample for longer ranges | 200+ data points on low-end devices |
| Firestore reads without security rules caching | Every `onSnapshot` triggers a rules evaluation; complex rules slow cold reads | Keep rules simple; avoid cross-document `get()` calls in rules | High read volume, 1000+ MAU |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Firestore `premiumEntitlement.active` field writable by the client | Users set their own premium status for free | Rules must deny client writes to `premiumEntitlement`; only the Stripe webhook Cloud Function (server-side) should write this field |
| Stripe Price ID hardcoded as `price_PLACEHOLDER` deployed to production | No subscriptions can be created; users see broken checkout | Inject `VITE_STRIPE_PRICE_ID` at build time via GitHub Actions secret |
| Firebase project ID committed to `.env` in version control | Exposes project to unauthorized SDK usage (though API keys are restricted by domain) | Use `.env.local` for local dev, GitHub Secrets for CI; never commit `.env` with real credentials |
| Guest mode user data accessible via Firestore | Anonymous auth UIDs are real UIDs; if rules are wrong, guest data is readable by others | Apply same ownership rules to anonymous users: `request.auth.uid == uid` applies to anonymous UIDs too |
| No rate limiting on AI workout generation Cloud Function | A single user can call `generateWorkout` thousands of times, running up Gemini API costs | Add Firebase App Check and per-UID rate limiting (count calls in Firestore with a TTL timestamp) |
| Stripe webhook endpoint publicly documented | Not a primary risk since signature verification prevents forgery, but worth noting | Signature verification is the protection; keeping the endpoint URL undocumented is defense-in-depth |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No "Add to Home Screen" install prompt | Discoverability is lost; mobile users don't know the app is installable | Implement `beforeinstallprompt` banner for Android; add "Install app" section to Settings on iOS with manual instructions |
| `autoUpdate` service worker silently reloads during an active workout session | User loses in-progress workout data when SW activates mid-session | Detect active workout session state; defer SW activation until user is on a non-critical screen or show a dismissable "Update available" banner |
| Loading spinner with no skeleton UI on first Firestore fetch | Dashboard appears blank for 2-3s on slow connections | Replace spinners with content-shaped skeleton screens on Dashboard, History, and Programs routes |
| Checkout redirects to Stripe then back — no confirmation state | User returns to `/settings?checkout=success` but sees no visual confirmation before the Firestore listener catches up | Show optimistic "Subscription activating..." state on return from checkout; listen for `isPremium` change to confirm |
| PWA installed on iOS shows browser chrome | `apple-mobile-web-app-capable` meta tag must be present AND the user must add via Safari | The meta tag is present in `index.html`; ensure `apple-touch-icon` resolves correctly |

---

## "Looks Done But Isn't" Checklist

- [ ] **Firebase Hosting deploy:** `firebase.json` exists with `"public": "pwa/dist"`, SPA rewrite rule, and `no-cache` header for `sw.js` — verify with `firebase hosting:channel:deploy preview` before first production push
- [ ] **PWA icons:** Actual PNG files exist at `pwa/public/icons/icon-192.png` and `pwa/public/icons/icon-512.png` — `ls pwa/public/icons/` confirms files exist, not just SVG
- [ ] **Stripe webhook secret:** `STRIPE_WEBHOOK_SECRET` env var set in Cloud Functions config and the webhook endpoint is registered in Stripe Dashboard pointing to the deployed function URL — test with `stripe trigger customer.subscription.created`
- [ ] **Firestore security rules deployed:** `firebase.json` includes `"firestore": { "rules": "firestore.rules" }` and rules are deployed with `firebase deploy --only firestore:rules` — not just saved locally
- [ ] **Environment variables in CI:** GitHub Actions secrets include all `VITE_FIREBASE_*`, `VITE_STRIPE_PRICE_ID` — verify by checking the deployed app's network requests don't show `undefined` in Firebase config
- [ ] **Error boundaries present:** Root `<ErrorBoundary>` wraps `<RouterProvider>` in `main.tsx`; route-level boundaries wrap each lazy component — test by temporarily throwing in a component
- [ ] **CSP in report-only mode first:** Verify no CSP violations appear in production logs before switching from `Report-Only` to enforcing — check Firebase Hosting request logs for CSP violation reports
- [ ] **Service worker update handling:** Chunk load errors trigger a reload; users are not silently stuck on stale code — test by deploying a new build while having the old app open in another tab

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SPA rewrite missing, 404s on all deep links | LOW | Add `firebase.json` rewrite rule, redeploy — takes ~5 minutes |
| Stripe webhook broken, subscriptions not activating | MEDIUM | Fix raw body issue, redeploy function, replay failed webhook events from Stripe Dashboard |
| Firestore rules too permissive in production | HIGH | Deploy corrected rules immediately (can hot-deploy without new app build); audit Firestore logs for unauthorized reads |
| Users stuck on stale cached version | MEDIUM | Serve new `sw.js` with `no-cache`, deploy update — users will auto-update on next visit; add "force refresh" notice in-app |
| CSP blocks auth/payments after enforcement | LOW | Revert CSP header to report-only mode, identify blocked domains from violation reports, add to allowlist, re-enable enforcement |
| White screen from missing error boundary | LOW | Add error boundaries, redeploy — no data migration needed |
| PWA icons missing, install prompt fails | LOW | Generate icons, push to `public/icons/`, redeploy hosting — takes ~30 minutes |
| CI deploys broken code because tests not gated | MEDIUM | Add `needs: [test]` to deploy job; if broken code is live, roll back with `firebase hosting:clone` |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Firebase Hosting SPA rewrite missing | Phase 1: Infrastructure and CI/CD | `curl https://yourdomain.com/cycle` returns 200 with `index.html`, not 404 |
| Stripe webhook raw body destroyed | Phase 2: Stripe integration | `stripe trigger customer.subscription.created` in live mode sets Firestore `premiumEntitlement.active = true` |
| Firestore cross-user data access | Phase 3: Security hardening | Firestore emulator test: user A cannot read `/users/userB/workouts`; all subcollections gated |
| Service worker stale chunk 404s | Phase 4: PWA and offline polish | Deploy new build while old app is open in another tab; navigate to a lazy route; no white screen |
| CSP blocking Firebase/Stripe | Phase 3: Security hardening | Run in report-only mode for 24h in staging; zero violations before enforcing |
| PWA icons missing/wrong format | Phase 4: PWA and offline polish | Lighthouse PWA audit passes "Installable" category; maskable icon audit passes |
| Missing error boundaries | Phase 5: Error handling and resilience | Deliberately throw in a lazy route; root shell remains visible with recovery UI |
| CI not gating on test failures | Phase 1: Infrastructure and CI/CD | Break a domain test intentionally; confirm deploy job does not run |

---

## Sources

- [Firebase Hosting full configuration docs](https://firebase.google.com/docs/hosting/full-config) — rewrite rules and headers
- [Stripe webhook signature verification](https://docs.stripe.com/webhooks/signature) — raw body requirement, timing attacks, replay prevention
- [Firebase Firestore security rules: fix insecure rules](https://firebase.google.com/docs/firestore/security/insecure-rules) — cross-user access patterns
- [vite-plugin-pwa: Service Worker Precache guide](https://vite-pwa-org.netlify.app/guide/service-worker-precache.html) — globPatterns gotchas
- [vite-plugin-pwa: Auto update strategy](https://vite-pwa-org.netlify.app/guide/auto-update) — skipWaiting and clientsClaim behavior
- [Lighthouse PWA installable manifest audit](https://developer.chrome.com/docs/lighthouse/pwa/installable-manifest) — required manifest fields
- [Lighthouse maskable icon audit](https://developer.chrome.com/docs/lighthouse/pwa/maskable-icon-audit) — maskable icon requirements
- [MDN: Making PWAs installable](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable) — iOS vs Android install flows
- [BiteSite: Raw body for Stripe webhooks in Firebase Cloud Functions](https://www.bitesite.ca/blog/raw-body-for-stripe-webhooks-using-firebase-cloud-functions) — `req.rawBody` pattern
- [Implementing Stripe Subscriptions with Firebase Cloud Functions 2025](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — current implementation pattern
- [Securing Firebase in Production checklist](https://modernpentest.com/blog/securing-firebase-in-production) — Firestore security audit
- [Firestore IndexedDB persistence: multi-tab issues](https://github.com/firebase/firebase-js-sdk/issues/6511) — stale data mutation in non-leader tabs
- [Webhook Security Best Practices 2025-2026](https://dev.to/digital_trubador/webhook-security-best-practices-for-production-2025-2026-384n) — idempotency, replay prevention

---
*Pitfalls research for: PWA production readiness (Vite 8 + React 19 + Firebase + Stripe)*
*Researched: 2026-03-21*

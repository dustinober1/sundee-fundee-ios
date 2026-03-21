# Architecture Research

**Domain:** PWA production infrastructure — Vite + React + Firebase
**Researched:** 2026-03-21
**Confidence:** HIGH (architecture based on existing codebase audit + official Firebase/Stripe/React docs)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BROWSER (PWA)                                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  React Router (react-router v7) + React 19 Component Tree    │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────────┐   │   │
│  │  │SessionPro-│ │Entitlement│ │  Route    │ │  Error     │   │   │
│  │  │vider      │ │Provider   │ │  Outlets  │ │  Boundary  │   │   │
│  │  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬──────┘   │   │
│  └────────┼─────────────┼─────────────┼─────────────┼───────────┘   │
│           │             │             │             │               │
│  ┌────────▼─────────────▼─────────────▼─────────────▼───────────┐   │
│  │            Repository Layer (Firestore + LocalStorage)         │   │
│  │  FirestoreWorkoutRepo / LocalWorkoutRepo  (dual adapters)     │   │
│  └──────────────────────────────┬────────────────────────────────┘   │
│                                 │                                    │
│  ┌──────────────────────────────▼────────────────────────────────┐   │
│  │         src/domain/  (pure TypeScript, zero deps)             │   │
│  └─────────────────────────────────────────────────────────────  │   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │      Service Worker (vite-plugin-pwa / Workbox)               │   │
│  │   NetworkFirst for Firestore API  |  CacheFirst for assets    │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │ HTTPS / wss
┌─────────────────────▼───────────────────────────────────────────────┐
│                        FIREBASE                                      │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │  Hosting   │  │  Auth     │  │  Firestore   │  │  Functions  │  │
│  │ (CDN+HTTPS)│  │(multi-    │  │(persistent   │  │generateWork-│  │
│  │            │  │provider)  │  │ IndexedDB    │  │out,         │  │
│  │ CSP headers│  │           │  │ offline)     │  │stripeWebhook│  │
│  │ in         │  │           │  │              │  │createCheckout│ │
│  │firebase.json│ │           │  │              │  └──────┬──────┘  │
│  └────────────┘  └───────────┘  └──────────────┘         │         │
└────────────────────────────────────────────────────────── │ ────────┘
                                                            │
                                              ┌─────────────▼────────┐
                                              │       STRIPE          │
                                              │  Checkout Sessions    │
                                              │  Customer Portal      │
                                              │  Webhooks → Function  │
                                              └──────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     CI/CD (GitHub Actions)                           │
│  push to main → [test] → [build] → [deploy to Firebase Hosting]     │
│  PR → [test] → [build] → [preview channel deploy]                   │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| SessionProvider | Firebase Auth state, guest/authenticated mode | AuthContext consumers, repo selection |
| EntitlementProvider | Stripe premium state via Firestore onSnapshot | /users/{uid}.premiumEntitlement.active |
| Error Boundary | Catch React render errors, show fallback UI | Sentry/Firebase Crashlytics (log) |
| Repository Layer | Data access abstraction (Firestore or LocalStorage) | Firestore, IndexedDB |
| src/domain/ | Pure business logic (cycle, injury, workout) | Nothing — pure TypeScript |
| Service Worker | Asset precaching, Firestore API NetworkFirst cache | Browser Cache API, Workbox |
| Firebase Hosting | HTTPS delivery, CSP/security headers, SPA redirect | CDN edge nodes |
| Cloud Functions | AI workout gen (Gemini), Stripe session creation, webhook handler | Gemini API, Stripe API, Firestore |
| GitHub Actions | Build, test, deploy on push/PR | Firebase Hosting deploy action |

## Recommended Project Structure

The PWA already has a strong structure. Production readiness adds infrastructure files alongside it:

```
pwa/
├── src/
│   ├── auth/               # AuthContext, Firebase auth wrappers
│   ├── components/         # Reusable UI (add ErrorBoundary.tsx here)
│   ├── domain/             # Pure TS business logic — unchanged
│   ├── entitlements/       # EntitlementContext, useEntitlements, stripe-checkout
│   ├── firebase/           # app.ts, auth.ts, firestore.ts, analytics.ts
│   ├── repositories/       # Firestore* and Local* dual adapters
│   ├── routes/             # Route components + AppLayout
│   └── main.tsx            # Root — add ErrorBoundary wrapper here
├── public/
│   └── icons/              # icon-192.png, icon-512.png (production quality)
├── vite.config.ts          # Service worker config (already exists)
└── index.html              # SEO meta tags, OG tags added here

functions/
├── src/
│   ├── index.ts            # Export all functions
│   ├── generateWorkout.ts  # Gemini proxy (replace Cloudflare worker)
│   ├── createCheckoutSession.ts   # Stripe Checkout session creator
│   ├── createPortalSession.ts     # Stripe Customer Portal session
│   └── stripeWebhook.ts    # Webhook handler (sets premiumEntitlement)
└── package.json

firebase.json               # Hosting config: rewrite rules, CSP headers
firestore.rules             # Security rules (already solid, verify subcollections)
firestore.indexes.json      # Query indexes for subcollection queries

.github/
└── workflows/
    └── deploy.yml          # CI/CD: test + build + firebase deploy
```

### Structure Rationale

- **functions/src/**: Stripe functions live here alongside `generateWorkout.ts` — they share the same deploy unit and Firebase Admin SDK initialization.
- **firebase.json headers**: CSP is set at the CDN edge via `firebase.json` `headers` config — this is the correct place for a SPA served from Firebase Hosting, not in the Vite build.
- **.github/workflows/**: Single `deploy.yml` handles both PR preview channels and main-branch live deploys using Firebase's official GitHub Action.

## Architectural Patterns

### Pattern 1: Firebase Hosting + GitHub Actions CI/CD

**What:** GitHub Actions workflow triggers on push to `main` and on PRs. Firebase's official GitHub Action (`FirebaseExtended/action-deploy-firebase-hosting`) handles deploy authentication via a service account stored as a GitHub secret.

**When to use:** Every project deploying to Firebase Hosting — this is the official, maintained path.

**Trade-offs:** Preview channels are automatic on PR; live deploys require the `FIREBASE_SERVICE_ACCOUNT` secret. One-time setup cost, then fully automated.

**Example:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Firebase Hosting
on:
  push:
    branches: [main]
  pull_request:

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd pwa && npm ci
      - run: cd pwa && npm run test
      - run: cd pwa && npm run build
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          VITE_FIREBASE_AUTH_DOMAIN: ${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
          VITE_FIREBASE_PROJECT_ID: ${{ secrets.VITE_FIREBASE_PROJECT_ID }}
          VITE_FIREBASE_STORAGE_BUCKET: ${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
          VITE_FIREBASE_MESSAGING_SENDER_ID: ${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
          VITE_FIREBASE_APP_ID: ${{ secrets.VITE_FIREBASE_APP_ID }}
          VITE_STRIPE_PRICE_ID: ${{ secrets.VITE_STRIPE_PRICE_ID }}
      - uses: FirebaseExtended/action-deploy-firebase-hosting@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          channelId: live           # "live" for main, auto-preview for PRs
          projectId: sundee-fundee
```

**Key details:**
- `VITE_*` env vars must be injected at build time (Vite bakes them into the bundle)
- `FIREBASE_SERVICE_ACCOUNT` is a JSON service account key stored as a GitHub secret
- PR builds get automatic preview channel URLs (e.g., `https://sundee-fundee--pr-42-abc123.web.app`)
- `channelId: live` only applies when branch is `main` — use a conditional for this

### Pattern 2: Stripe Webhook Architecture

**What:** Stripe → Cloud Function HTTP endpoint → verify signature → update Firestore. The client never writes to `premiumEntitlement` — only the webhook function does. The client reads it via `onSnapshot` for real-time updates.

**When to use:** Any Stripe subscription integration. The webhook is the source of truth, not the checkout success redirect (which can be skipped if the user closes the tab).

**Trade-offs:** Webhook must be an HTTP function (`onRequest`), not a callable (`onCall`), because Stripe calls it directly. Raw body preservation is required for signature verification — this is a common gotcha with Firebase Functions.

**Example:**
```typescript
// functions/src/stripeWebhook.ts
import * as functions from 'firebase-functions/v2/https';
import Stripe from 'stripe';
import * as admin from 'firebase-admin';

export const stripeWebhook = functions.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

  let event: Stripe.Event;
  try {
    // req.rawBody is preserved by Firebase Functions — required for verification
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    res.status(400).send('Webhook signature verification failed');
    return;
  }

  if (event.type === 'customer.subscription.updated' ||
      event.type === 'customer.subscription.created') {
    const subscription = event.data.object as Stripe.Subscription;
    const uid = subscription.metadata.firebaseUid; // set at checkout creation
    const isActive = subscription.status === 'active';

    await admin.firestore()
      .collection('users').doc(uid)
      .update({ 'premiumEntitlement.active': isActive });
  }

  res.json({ received: true });
});
```

**Firestore document structure for entitlements:**
```
/users/{uid}
  premiumEntitlement: {
    active: boolean,
    stripeCustomerId: string,
    stripeSubscriptionId: string,
    currentPeriodEnd: Timestamp
  }
```

**Firestore rule for entitlement field — only Functions can write it:**
```
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId
    && !('premiumEntitlement' in request.resource.data.diff(resource.data).affectedKeys());
}
```

### Pattern 3: React Error Boundary Placement

**What:** Two-tier error boundary placement — one at the root to catch total failures, one at the route level to allow graceful degradation (a broken dashboard doesn't kill the settings screen).

**When to use:** Production React apps. React 19 adds `onCaughtError` and `onUncaughtError` root options — these complement but don't replace error boundaries.

**Trade-offs:** `react-error-boundary` package provides a declarative `<ErrorBoundary>` with `FallbackComponent`, `onError` callback (for logging), and `resetKeys` (to auto-recover on route change). Building a class-based boundary manually is more work for the same result.

**Example:**
```typescript
// src/components/ErrorBoundary.tsx
import { ErrorBoundary as REB } from 'react-error-boundary';

function GlobalFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert" className="error-screen">
      <h1>Something went wrong</h1>
      <p>The app encountered an unexpected error.</p>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}

// In main.tsx — wrap RouterProvider:
<ErrorBoundary FallbackComponent={GlobalFallback} onError={logToAnalytics}>
  <RouterProvider router={router} />
</ErrorBoundary>

// In route layouts (AppLayout.tsx) — per-route boundaries:
<ErrorBoundary FallbackComponent={RouteFallback} resetKeys={[location.pathname]}>
  <Outlet />
</ErrorBoundary>
```

**Error event handler capture (React 19):**
```typescript
// main.tsx — createRoot options for unhandled errors
createRoot(document.getElementById('root')!, {
  onUncaughtError: (error, errorInfo) => {
    logToFirebase(error, errorInfo);
  },
  onCaughtError: (error, errorInfo) => {
    logToFirebase(error, errorInfo);
  },
}).render(<App />);
```

### Pattern 4: Content Security Policy via firebase.json

**What:** CSP headers are set in `firebase.json` under the `hosting.headers` array. This runs at the CDN edge, before the browser parses HTML — more secure and reliable than meta tags or Vite plugins.

**When to use:** Firebase Hosting deployments. The `firebase.json` headers approach is the correct production pattern.

**Trade-offs:** CSP for Firebase is moderately complex because Firebase SDK requires `connect-src` for multiple googleapis.com domains, and `wss://` for Firestore real-time connections. The service worker also needs `script-src 'self'`. Get this wrong and the app silently breaks in production.

**Example — firebase.json CSP header block:**
```json
{
  "hosting": {
    "public": "pwa/dist",
    "ignore": ["firebase.json", "**/.*"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Content-Security-Policy",
            "value": "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com https://firestore.googleapis.com https://identitytoolkit.googleapis.com https://securetoken.googleapis.com https://api.stripe.com; frame-src https://js.stripe.com https://hooks.stripe.com; worker-src 'self' blob:"
          },
          { "key": "X-Frame-Options", "value": "DENY" },
          { "key": "X-Content-Type-Options", "value": "nosniff" },
          { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
          { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" }
        ]
      },
      {
        "source": "**/*.@(js|css|woff2|png|jpg|svg)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      }
    ]
  }
}
```

**Key CSP domains for Firebase + Stripe:**
- `connect-src` must include: `*.googleapis.com`, `*.firebaseio.com`, `wss://*.firebaseio.com`, `securetoken.googleapis.com`, `api.stripe.com`
- `frame-src` must include: `js.stripe.com`, `hooks.stripe.com` (for Stripe Elements, even redirect-based checkout)
- `worker-src 'self' blob:` is required for the service worker

### Pattern 5: Service Worker Strategy (Workbox via vite-plugin-pwa)

**What:** The existing `vite.config.ts` already has correct strategy choices. The configuration is nearly production-ready with two key fixes needed.

**Existing config is correct:**
- `NetworkFirst` for Firestore API calls — always tries network, falls back to cache. Right for data freshness.
- `CacheFirst` for images — long cache, right for static assets.
- `globPatterns` precaches all JS/CSS/HTML/assets — enables full offline shell.

**What needs to be fixed for production:**
1. `registerType: 'autoUpdate'` is correct for production (silently updates SW).
2. The manifest icon paths reference `/icons/icon-192.png` and `/icons/icon-512.png` but `public/` only contains `favicon.svg` and `icons.svg` — actual PNG icons must exist at build time.
3. Firebase Hosting must not serve stale `sw.js` — add `Cache-Control: no-cache` header for `sw.js` specifically in `firebase.json`.

**firebase.json addition for service worker:**
```json
{
  "source": "/sw.js",
  "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
}
```

### Pattern 6: Firestore Security Rules (Production Lockdown)

**What:** The existing `firestore.rules` in the RN worktree is a strong baseline. The production rules need one addition: prevent client-side writes to `premiumEntitlement` (only the Stripe webhook Cloud Function should set this).

**Current state:** Rules correctly use `allow read, write: if false` as default, with owner-only access to `/users/{uid}` and all subcollections. Programs and WODs are read-only for authenticated users.

**Missing — entitlement write protection:**
```javascript
match /users/{userId} {
  // User can read own doc
  allow read: if request.auth != null && request.auth.uid == userId;

  // User can write own doc, but CANNOT modify premiumEntitlement field
  allow write: if request.auth != null
    && request.auth.uid == userId
    && !request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['premiumEntitlement']);

  // Subcollections: full owner access
  match /{subcollection}/{docId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

**Testing:** Use `firebase emulators:start` with `firestore.rules.test.ts` (already exists in the worktree) before deploying rule changes.

## Data Flow

### Request Flow: Authenticated User Reading Workout Data

```
User navigates to /history
    ↓
React Router → History route component
    ↓
useWorkoutHistory() hook → FirestoreWorkoutRepo.getAll(uid)
    ↓
Firestore SDK → checks IndexedDB offline cache first (persistentLocalCache)
    ↓
[Online] → Firestore read via HTTPS → returns latest docs
[Offline] → returns cached IndexedDB data
    ↓
Firestore security rules evaluate: request.auth.uid == userId ✓
    ↓
Component renders with data
```

### Data Flow: Stripe Subscription Purchase

```
User clicks "Go Premium"
    ↓
redirectToCheckout(uid, priceId) in stripe-checkout.ts
    ↓
httpsCallable('createStripeCheckoutSession') → Cloud Function
    ↓
Cloud Function: creates Stripe Checkout Session with metadata.firebaseUid = uid
    ↓
Returns URL → browser redirects to Stripe-hosted checkout page
    ↓
User completes payment on Stripe
    ↓
Stripe fires webhook → stripeWebhook Cloud Function (HTTP endpoint)
    ↓
Function verifies stripe-signature header (constructEvent)
    ↓
On success: Firestore.update(/users/{uid}, { premiumEntitlement.active: true })
    ↓
useEntitlements() onSnapshot fires in the already-open tab
    ↓
EntitlementContext updates → isPremium = true across app
    ↓
User redirected to /settings?checkout=success (success URL)
```

### Data Flow: GitHub Actions Deploy

```
Developer pushes to main
    ↓
GitHub Actions: checkout → npm ci → npm test → npm run build
  (VITE_* secrets injected as env vars at build time)
    ↓
Vite build: bundles app, generates sw.js, writes dist/
    ↓
FirebaseExtended/action-deploy-firebase-hosting
  (authenticates with FIREBASE_SERVICE_ACCOUNT secret)
    ↓
Firebase CLI: firebase deploy --only hosting
  (uploads dist/ to Firebase CDN, activates new version)
    ↓
Firebase Hosting: propagates to CDN edge nodes globally
    ↓
Service worker on existing client tabs auto-updates (autoUpdate mode)
```

### Key Data Flows Summary

1. **Auth state:** Firebase Auth → `onAuthStateChanged` → `SessionProvider` → all consumers via context
2. **Entitlement state:** Stripe webhook → Firestore `/users/{uid}.premiumEntitlement` → `useEntitlements` onSnapshot → `EntitlementProvider` → `useEntitlementContext()` in components
3. **User data:** Components → Repo layer (Firestore vs Local depending on auth state) → Firestore with offline cache via IndexedDB
4. **AI workout generation:** Component → `httpsCallable('generateWorkout')` → Cloud Function → Gemini API → response
5. **CI/CD:** git push → GitHub Actions → Vite build with secrets → Firebase Hosting deploy

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Current architecture is correct. No changes needed. |
| 1k-10k users | Watch Firestore read costs (onSnapshot per user). Add Firestore indexes for subcollection queries as needed. Cloud Functions cold starts acceptable. |
| 10k-100k users | Enable Firebase App Check to block abuse. Add Firestore composite indexes. Consider Cloud Functions minimum instances to reduce cold starts. Rate-limit AI generation per UID using Firestore counters or Firebase Extensions. |
| 100k+ users | Separate read/write replicas not needed (Firestore scales automatically). Cost becomes primary concern — audit onSnapshot subscriptions vs. one-time reads. |

### Scaling Priorities

1. **First bottleneck:** Firestore read costs from `onSnapshot` — every authenticated user maintains a live connection. At scale, switch history/benchmarks to `getDocs` (one-time fetch) and only keep `onSnapshot` for entitlements and real-time data.
2. **Second bottleneck:** AI generation Cloud Function costs — rate limit by UID (one free generation per day, more for premium) enforced server-side in the function.

## Anti-Patterns

### Anti-Pattern 1: Writing Environment Variables Into Source Files

**What people do:** Hardcode Firebase config or Stripe price IDs directly in source files when they can't figure out how to inject env vars in CI.

**Why it's wrong:** Firebase API keys end up in git history. The existing code correctly uses `import.meta.env.VITE_*` — this works only if the build step receives the values as environment variables. In GitHub Actions, these must be declared as `env:` in the build step using GitHub Secrets.

**Do this instead:** Store all `VITE_*` values as GitHub repository secrets. Pass them as env vars in the GitHub Actions workflow `build` step. Never commit `.env` files.

### Anti-Pattern 2: Using onCall Instead of onRequest for Stripe Webhooks

**What people do:** Implement the Stripe webhook handler as an `onCall` Firebase Function (the same type used for checkout session creation).

**Why it's wrong:** `onCall` functions expect Firebase Auth tokens and a specific JSON payload format. Stripe sends raw HTTP POST requests with a `stripe-signature` header and raw body — `onCall` will reject these. Additionally, `onCall` transforms the request body, destroying the raw body needed for `constructEvent` signature verification.

**Do this instead:** Use `onRequest` for the webhook endpoint. Export the URL from the deployed function and register it in the Stripe dashboard as the webhook endpoint. Use `req.rawBody` (preserved by Firebase Functions runtime) for `constructEvent`.

### Anti-Pattern 3: Setting CSP in Vite index.html Meta Tag

**What people do:** Add `<meta http-equiv="Content-Security-Policy" content="...">` to `index.html` to set CSP.

**Why it's wrong:** Meta-tag CSP does not support `frame-ancestors` (which prevents clickjacking). It also executes after the HTML parser runs, meaning inline scripts can fire before the policy applies. For Stripe's `frame-src` requirements, a header-based CSP is more reliable.

**Do this instead:** Set CSP in `firebase.json` under `hosting.headers`. This runs at the CDN edge before any content is delivered.

### Anti-Pattern 4: Single Top-Level Error Boundary

**What people do:** One global error boundary at the app root that shows a full-page "Something went wrong" screen.

**Why it's wrong:** If the Settings screen crashes, the Dashboard becomes inaccessible too. Users lose all context and cannot navigate away without a full reload.

**Do this instead:** Nest error boundaries at the route/layout level. `AppLayout` wraps `<Outlet>` in an error boundary with `resetKeys={[location.pathname]}` — navigating to a different route auto-clears the error state. The global root boundary is still present as a last resort but individual routes fail independently.

### Anti-Pattern 5: Relying on Checkout Success Redirect for Entitlement

**What people do:** On the Stripe success URL (`/settings?checkout=success`), immediately grant premium access to the user in Firestore.

**Why it's wrong:** The success URL fires in the browser after redirect — a user can close the tab before it loads, or manipulate the URL parameters. The entitlement write from client code would also violate the Firestore security rule that prevents clients from writing to `premiumEntitlement`.

**Do this instead:** The success URL is for UX only (show a "Welcome to Premium!" message, poll briefly). The actual entitlement is set exclusively by the `stripeWebhook` Cloud Function via `constructEvent` signature verification. The `useEntitlements` `onSnapshot` will fire automatically when Firestore is updated by the webhook.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Firebase Auth | `onAuthStateChanged` in `SessionProvider` | Multi-provider: email, Google, Apple, anonymous guest |
| Firestore | `persistentLocalCache` for offline-first; dual Firestore/Local repo adapters | Guest mode uses LocalStorage repos only |
| Firebase Cloud Functions | `httpsCallable` for AI generation and Stripe session creation; `onRequest` for Stripe webhook | Functions must be deployed separately from Hosting |
| Firebase Hosting | Deploy via GitHub Actions; CSP and cache headers in `firebase.json` | SPA rewrite rule required: `"source": "**", "destination": "/index.html"` |
| Stripe | Redirect-based checkout (no Stripe.js Elements needed); webhook for entitlement sync | Price ID from `VITE_STRIPE_PRICE_ID` env var |
| Gemini (via Cloud Function) | Replaces Cloudflare worker; called as `httpsCallable('generateWorkout')` | Gemini API key stored as Firebase Function secret, not in frontend bundle |
| GitHub Actions | `FirebaseExtended/action-deploy-firebase-hosting@v0` | Requires `FIREBASE_SERVICE_ACCOUNT` GitHub secret |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| React Components ↔ Repository Layer | Custom hooks calling repo methods | Repos are selected at the `repositories/index.ts` level based on auth state |
| Repository Layer ↔ src/domain/ | Direct TypeScript imports | Domain layer is purely computational — repos call domain functions, not vice versa |
| SessionProvider ↔ EntitlementProvider | EntitlementProvider reads uid from useSession() | SessionProvider must be the outer wrapper |
| Cloud Functions ↔ Firestore | Firebase Admin SDK (bypasses security rules) | Only Functions should write to premiumEntitlement |
| Service Worker ↔ Firestore SDK | No direct connection — Firestore uses IndexedDB for offline cache, service worker handles HTTP caching for API calls | Do not intercept Firestore WebSocket (wss://) connections in service worker — Firestore manages its own real-time connection |

## Build Order Implications

Production readiness work has these dependencies that drive phase ordering:

1. **Environment variables and secrets first** — nothing else can be deployed without real Firebase keys. GitHub Actions secrets must be configured before CI/CD can work.

2. **firebase.json before deploy** — Firebase Hosting config (rewrites, headers) must exist before the first deploy. CSP headers, cache rules, and SPA redirect rule all live here.

3. **Cloud Functions before Stripe wiring** — `createCheckoutSession`, `createPortalSession`, and `stripeWebhook` must be deployed before Stripe checkout can be tested end-to-end.

4. **Firestore rules before Cloud Functions go live** — entitlement field write protection should be in place before the webhook can write to it.

5. **Error boundaries before Lighthouse audit** — error states are part of PWA quality assessment.

6. **CI/CD pipeline before icons/SEO/polish** — once CI is running, subsequent changes auto-deploy, accelerating all remaining work.

**Suggested build order:**
```
Phase 1: Firebase Hosting + GitHub Actions (deploy infrastructure)
Phase 2: Environment variables + Cloud Functions (Gemini + Stripe)
Phase 3: Stripe checkout end-to-end + Firestore rules hardening
Phase 4: Error boundaries + loading states + CSP headers
Phase 5: PWA quality (icons, offline page, install prompt, Lighthouse)
Phase 6: Test coverage + analytics verification + SEO/meta tags
```

## Sources

- [Deploy to Firebase Hosting via GitHub Actions — Firebase docs](https://firebase.google.com/docs/hosting/github-integration) — MEDIUM confidence (page truncated, content from search results and official GitHub Action marketplace listing)
- [Stripe webhook signature verification — official Stripe docs](https://docs.stripe.com/webhooks#verify-official-libraries) — HIGH confidence
- [Implementing Stripe Subscriptions with Firebase Cloud Functions — Aron Schueler, 2025](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — MEDIUM confidence (community source, verified against official Stripe pattern)
- [React Error Boundary — react.dev](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary) — HIGH confidence
- [react-error-boundary — bvaughn/react-error-boundary](https://github.com/bvaughn/react-error-boundary) — HIGH confidence
- [Firebase Firestore Security Rules — Firebase docs](https://firebase.google.com/docs/firestore/security/get-started) — HIGH confidence
- [Use Firebase in a PWA — Firebase docs](https://firebase.google.com/docs/web/pwa) — HIGH confidence
- [vite-plugin-pwa documentation — vite-pwa-org](https://vite-pwa-org.netlify.app/) — HIGH confidence
- [Existing codebase audit — pwa/vite.config.ts, pwa/src/**, firestore.rules] — HIGH confidence (direct inspection)

---
*Architecture research for: Vite + React + Firebase PWA production infrastructure*
*Researched: 2026-03-21*

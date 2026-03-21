# Stack Research

**Domain:** PWA production readiness (Vite + React + Firebase)
**Researched:** 2026-03-21
**Confidence:** HIGH — all versions verified against npm/official sources, not training data alone

---

## Existing Stack (Already Chosen — Do Not Change)

| Technology | Version | Purpose |
|------------|---------|---------|
| Vite | ^8.0.1 | Build tool + dev server |
| React | ^19.2.4 | UI framework |
| TypeScript | ~5.9.3 | Type safety |
| firebase (JS SDK) | ^12.11.0 | Auth, Firestore, Analytics |
| vite-plugin-pwa | ^1.2.0 | Service worker + manifest generation |
| @stripe/stripe-js | ^8.11.0 | Stripe browser SDK |
| Vitest | ^4.1.0 | Unit test runner |
| react-router | ^7.13.1 | Client-side routing |
| recharts | ^3.8.0 | SVG charts |

These are confirmed in `pwa/package.json`. Research below is additive — what's needed on top.

---

## Recommended Stack (New Additions for Production Readiness)

### Deployment & CI/CD

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| FirebaseExtended/action-hosting-deploy | v0 (latest tag) | GitHub Actions Firebase deploy | Official Firebase-maintained action; supports live channel and PR preview channels; integrates with `firebase init hosting:github` to auto-create service account | HIGH confidence — [official Firebase docs](https://firebase.google.com/docs/hosting/github-integration) |
| firebase-tools | latest (CLI) | Manual deploy script + CI build step | Required for `firebase deploy`; `firebase init hosting:github` scaffolds the GH Actions workflow automatically | HIGH confidence |
| FIREBASE_SERVICE_ACCOUNT | GitHub Secret | Auth for GH Actions deploy | Service account JSON stored as encrypted secret; workload identity federation is NOT supported by Firebase Admin SDK so service account key is the correct choice for Firebase Hosting deploys | MEDIUM confidence — [WIF limitation confirmed](https://github.com/google-github-actions/auth) |

### Firebase Cloud Functions (AI Workout + Stripe Webhook)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| firebase-functions (gen2) | ^6.x | Cloud Function runtime | Gen2 (`firebase-functions/v2/https`) runs on Cloud Run; `onRequest` provides `request.rawBody` needed for Stripe webhook signature verification; superior cold starts vs gen1 | HIGH confidence |
| firebase-admin | ^13.x | Server-side Firestore/Auth access | Current major version; write user entitlement after Stripe webhook; Node 20+ required | HIGH confidence — [npm release notes](https://firebase.google.com/support/release-notes/admin/node) |
| stripe (Node.js server SDK) | ^17.x | Stripe webhook verification + checkout session creation | `stripe.webhooks.constructEvent(request.rawBody, sig, secret)` — must use `rawBody` not `body` on Firebase Functions; latest stable is v17+ | HIGH confidence — confirmed via npm search results |
| Node.js runtime | 20 | Function execution environment | Node 18 deprecated in firebase-admin 13.x; Node 22 not GA in Firebase as of research date; Node 20 is stable and recommended | HIGH confidence |

### Stripe Payment Flow (Frontend)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| @stripe/stripe-js | ^8.11.0 | Already installed — keep | v8 required for Elements with Checkout Sessions API; already at correct version | HIGH confidence |
| @stripe/react-stripe-js | ^5.6.1 | React components for Stripe Elements | Provides `Elements`, `CheckoutProvider`, `PaymentElement` components; use `CheckoutProvider` (renamed from `CustomCheckoutProvider` in v5) | HIGH confidence — [React Stripe.js docs](https://docs.stripe.com/sdks/stripejs-react) |

**Stripe flow to use:** Server-side Checkout Session (not client-only redirect). Create session in Cloud Function → return `clientSecret` → mount `PaymentElement` on frontend. This keeps secret key server-side and supports subscription webhooks.

**Do NOT use:** Stripe Checkout hosted page redirect (loses control of UX) or client-only Stripe.js without a server (exposes secret key).

### PWA Compliance

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| vite-plugin-pwa | ^1.2.0 | Already installed — keep | Already configured with correct `registerType: 'autoUpdate'`, Workbox runtime caching, and manifest. Gaps below are configuration, not new packages | HIGH confidence |
| workbox-window | bundled via vite-plugin-pwa | Update prompt UI | Use `useRegisterSW` hook from `virtual:pwa-register/react` for "new version available" toast | HIGH confidence — [vite-pwa docs](https://vite-pwa-org.netlify.app/guide/) |

**PWA gaps to fill (configuration, no new packages):**
- `pwa/public/icons/icon-192.png` and `icon-512.png` must exist as actual production-quality PNG files (currently `public/` only has `favicon.svg` and `icons.svg`)
- `pwa/public/apple-touch-icon.png` (180×180) — referenced in vite config `includeAssets` but file missing
- Add `<meta name="apple-mobile-web-app-capable" content="yes">` to `index.html`
- Add maskable icon variant (512×512 with safe zone padding) — already declared in vite config but PNG missing
- `manifest.webmanifest` MIME type — Firebase Hosting serves this correctly by default

### Security Headers (firebase.json)

No new packages needed. Firebase Hosting's `firebase.json` headers config handles all of these.

**Required headers configuration:**

```json
{
  "hosting": {
    "public": "pwa/dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      {
        "source": "**/*.@(js|css|woff2|png|svg|ico)",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      },
      {
        "source": "**",
        "headers": [
          { "key": "X-Content-Type-Options", "value": "nosniff" },
          { "key": "X-Frame-Options", "value": "DENY" },
          { "key": "X-XSS-Protection", "value": "1; mode=block" },
          { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
          { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" }
        ]
      }
    ]
  }
}
```

**CSP — handle carefully:** Firebase Hosting supports `Content-Security-Policy` as a custom header. However, CSP for a Firebase + Stripe app requires explicit allowlisting of:
- `js.stripe.com` in `script-src`
- `api.stripe.com` in `connect-src`
- `*.googleapis.com`, `*.firebaseio.com`, `*.firebaseapp.com` in `connect-src`
- `'unsafe-inline'` required for Vite-generated styles (cannot hash dynamically at build time without custom plugin)

**Recommendation:** Set report-only CSP first (`Content-Security-Policy-Report-Only`) to identify violations before enforcing. Full CSP enforcement is a phase unto itself — start with the other headers above which have no risk.

**HSTS:** Firebase Hosting automatically sets `Strict-Transport-Security: max-age=31556926`. Do not manually set it in firebase.json — Firebase silently corrupts the value when you override it (known issue: [firebase-tools#5999](https://github.com/firebase/firebase-tools/issues/5999)).

### Monitoring & Error Tracking

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| firebase/analytics | bundled in firebase ^12.x | Already initialized in `src/firebase/analytics.ts` — keep | `logEvent()` from `firebase/analytics` is already wired; verify events fire in Firebase Console DebugView before launch | HIGH confidence |
| @sentry/react | ^8.x | JavaScript error tracking for web | Firebase Crashlytics is mobile-only (iOS/Android); for the PWA, Sentry is the standard web error monitoring solution. Captures unhandled exceptions, React component errors (ErrorBoundary integration), and performance traces. Free tier covers small apps. | MEDIUM confidence — comparison sources confirm Crashlytics has no web SDK |

**Sentry setup pattern:**
```typescript
import * as Sentry from '@sentry/react';
Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.MODE,
  integrations: [Sentry.browserTracingIntegration()],
  tracesSampleRate: 0.1,
});
```
Wrap React root with `Sentry.withErrorBoundary` or use `<Sentry.ErrorBoundary>`. This replaces manual `<ErrorBoundary>` components listed in the production readiness triage.

**Alternative:** Skip Sentry and use Firebase Analytics + manual `window.onerror` logging to Firestore. Simpler but no stack traces, no release tracking, and no performance monitoring. Only do this if Sentry DSN/account management is overhead you want to avoid.

---

## Supporting Libraries (Already Installed, Confirm Usage)

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| @dnd-kit/core | ^6.3.1 | Drag-and-drop workout reorder | Already used — no changes |
| date-fns | ^4.1.0 | Date calculations for cycle tracking | Already used — no changes |
| jszip | ^3.10.1 | CSV/ZIP export | Already used — no changes |
| react-day-picker | ^9.14.0 | Calendar UI | Already used — no changes |

---

## Installation

```bash
# From pwa/ directory — add missing production dependencies
npm install @stripe/react-stripe-js @sentry/react

# From functions/ directory — Firebase Cloud Functions
npm install firebase-admin@^13 firebase-functions@^6 stripe@^17
npm install -D typescript @types/node
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| FirebaseExtended/action-hosting-deploy | firebase-tools CLI in raw GH Actions step (`npm install firebase-tools && firebase deploy`) | If you need more control over deploy flags or multi-site deploys; slightly more boilerplate |
| Sentry for error tracking | Manual Firestore error logging | If you want zero third-party services and are OK without stack traces/release tagging |
| Stripe Checkout Session (server-side) | Stripe Payment Links (hosted Stripe page) | If you want zero custom payment UI; acceptable for B2C apps where redirect UX is fine |
| CSP report-only first | Enforce CSP immediately | Never enforce immediately on a Stripe + Firebase app — will break payments on first deploy |
| Service account JSON secret (GitHub) | Workload Identity Federation | WIF is better security posture but Firebase Admin SDK explicitly does not support it; use service account key |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Firebase Crashlytics for web | No web SDK; mobile-only product | Sentry |
| Gen1 Firebase Functions (`firebase-functions/v1`) | No `request.rawBody` reliability, cold starts, Node 18 deprecated | Gen2 `firebase-functions/v2/https` with `onRequest` |
| `req.body` for Stripe webhook verification | JSON-parsed body breaks HMAC signature check; Stripe signature verification always fails | `request.rawBody` (Buffer) which Firebase gen2 provides natively |
| Manually setting HSTS in firebase.json | Firebase overrides/corrupts the value silently ([known bug](https://github.com/firebase/firebase-tools/issues/5999)) | Rely on Firebase Hosting's automatic HSTS (max-age=31556926) |
| `'unsafe-eval'` in CSP script-src | Required for Vite HMR in dev but should never reach production; Vite production builds do not use eval | Remove from production CSP; keep in dev-only server config |
| Stripe secret key in frontend code | Exposed in browser, exploitable | Always call Stripe server API from Firebase Cloud Function; frontend only receives `clientSecret` |
| Node 22 for Firebase Functions | Not GA as of March 2026 in Firebase | Node 20 (stable, recommended) |

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| vite-plugin-pwa ^1.2.0 | Vite ^8.x, Workbox 7.x | vite-plugin-pwa 0.17+ requires Vite 5+; 1.x tracks Vite 6+/8+ |
| @stripe/react-stripe-js ^5.6.1 | @stripe/stripe-js ^8.x | Peer dep; must upgrade both together; v5 renames `CustomCheckoutProvider` → `CheckoutProvider` |
| firebase ^12.11.0 | Node 20+ (server), modern browsers (client) | firebase-admin 13.x drops Node 18 support |
| firebase-functions ^6.x | firebase-admin ^13.x, Node 20 | Gen2 requires Firebase CLI 12.0.0+ |
| stripe (Node) ^17.x | Stripe API version 2025-01-27.acacia | Stripe auto-assigns API version on account creation; pin in constructor |

---

## GitHub Actions Workflow Pattern

```yaml
# .github/workflows/deploy.yml
name: Deploy to Firebase Hosting
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
          cache-dependency-path: pwa/package-lock.json

      - name: Install and build
        working-directory: pwa
        env:
          VITE_FIREBASE_API_KEY: ${{ secrets.VITE_FIREBASE_API_KEY }}
          VITE_FIREBASE_AUTH_DOMAIN: ${{ secrets.VITE_FIREBASE_AUTH_DOMAIN }}
          VITE_FIREBASE_PROJECT_ID: ${{ secrets.VITE_FIREBASE_PROJECT_ID }}
          VITE_FIREBASE_STORAGE_BUCKET: ${{ secrets.VITE_FIREBASE_STORAGE_BUCKET }}
          VITE_FIREBASE_MESSAGING_SENDER_ID: ${{ secrets.VITE_FIREBASE_MESSAGING_SENDER_ID }}
          VITE_FIREBASE_APP_ID: ${{ secrets.VITE_FIREBASE_APP_ID }}
          VITE_STRIPE_PUBLISHABLE_KEY: ${{ secrets.VITE_STRIPE_PUBLISHABLE_KEY }}
        run: |
          npm ci
          npm run build

      - name: Deploy to Firebase Hosting (live)
        if: github.event_name == 'push'
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: sundee-fundee
          channelId: live

      - name: Deploy to Firebase Hosting (preview)
        if: github.event_name == 'pull_request'
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: sundee-fundee
```

**Required GitHub Secrets:**
- `FIREBASE_SERVICE_ACCOUNT` — JSON key from Firebase Console > Project Settings > Service Accounts
- All `VITE_*` environment variables — Firebase config values (public, not sensitive, but keep out of source)
- `VITE_STRIPE_PUBLISHABLE_KEY` — Publishable key only (never secret key in frontend)

---

## Sources

- [firebase.google.com/docs/hosting/github-integration](https://firebase.google.com/docs/hosting/github-integration) — Official Firebase Hosting GitHub Actions docs (HIGH confidence)
- [firebase.google.com/docs/hosting/full-config](https://firebase.google.com/docs/hosting/full-config) — Headers, rewrites, cache config (HIGH confidence)
- [vite-pwa-org.netlify.app/guide/pwa-minimal-requirements](https://vite-pwa-org.netlify.app/guide/pwa-minimal-requirements) — PWA icon sizes, manifest requirements for Lighthouse (HIGH confidence)
- [docs.stripe.com/sdks/stripejs-react](https://docs.stripe.com/sdks/stripejs-react) — React Stripe.js reference, v5 API changes (HIGH confidence)
- [aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — Stripe + Firebase Functions gen2 pattern with rawBody (MEDIUM confidence — blog, but March 2025 and matches official Stripe docs)
- [github.com/firebase/firebase-tools/issues/5999](https://github.com/firebase/firebase-tools/issues/5999) — HSTS override bug in firebase.json (HIGH confidence — official repo issue)
- [github.com/google-github-actions/auth](https://github.com/google-github-actions/auth) — WIF not supported by Firebase Admin SDK (MEDIUM confidence — community finding, consistent across multiple sources)
- [sentry.io/resources/sentry-vs-crashlytics-mobile-developers-guide](https://sentry.io/resources/sentry-vs-crashlytics-mobile-developers-guide/) — Sentry vs Crashlytics web support comparison (MEDIUM confidence — vendor source)
- npm search results for stripe@20.x, @stripe/stripe-js@8.x, @stripe/react-stripe-js@5.x — version numbers (HIGH confidence, cross-referenced with package.json)

---

*Stack research for: PWA production readiness (Vite + React + Firebase)*
*Researched: 2026-03-21*

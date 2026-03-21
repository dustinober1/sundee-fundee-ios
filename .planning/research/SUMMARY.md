# Project Research Summary

**Project:** Sundee Fundee PWA — Production Readiness
**Domain:** PWA production infrastructure (Vite 8 + React 19 + Firebase + Stripe)
**Researched:** 2026-03-21
**Confidence:** HIGH

## Executive Summary

The Sundee Fundee PWA is feature-complete with 25+ screens, offline support via Workbox, Firestore sync, cycle tracking, AI workout generation, and a Stripe stub. The gap between "feature-complete" and "production-ready" is entirely infrastructure: no `firebase.json` exists, no CI/CD pipeline exists, PNG icons are missing from disk, the Stripe price ID is a placeholder, and Firestore security rules need hardening. None of these are architectural reworks — they are well-understood deployment and security tasks with documented patterns.

The recommended approach is to ship in six sequentially-dependent phases, starting with the Firebase Hosting config and GitHub Actions pipeline (nothing else can be verified or automated without these), then Cloud Functions for Stripe and AI (required for monetization and to replace the Cloudflare worker), then security hardening (Firestore rules + CSP), then PWA quality (icons, offline fallback, install prompt), then error resilience (error boundaries, loading states), and finally test coverage and analytics confirmation. Each phase unlocks the next — attempting them out of order introduces risk.

The most consequential risks are: Firestore security rules allowing cross-user reads of health-sensitive data (cycle phase, injury profiles, pain logs); the Stripe webhook raw body being destroyed by Express middleware before signature verification; and the service worker caching stale chunk filenames after a deploy, causing white screens on lazy routes. All three have clear, low-cost preventions documented in PITFALLS.md and must be addressed before any real users are onboarded.

## Key Findings

### Recommended Stack

The existing stack is correct and complete for the core app (Vite 8, React 19, TypeScript, Firebase JS SDK v12, vite-plugin-pwa, Stripe.js, Vitest, react-router v7). Two additions are needed for production: `@stripe/react-stripe-js ^5.6.1` (if Elements UI is used; skip if using Stripe Checkout redirect) and optionally `@sentry/react ^8.x` for web error tracking (Firebase Crashlytics is mobile-only). Cloud Functions need `firebase-functions@^6` (gen2), `firebase-admin@^13`, and `stripe@^17` on Node 20. All CI/CD and security headers are configuration, not new packages.

**Core technologies:**
- `firebase-functions/v2/https` (gen2): Cloud Function runtime — `req.rawBody` preservation for Stripe webhook, Cloud Run backend, no cold-start issues vs gen1
- `FirebaseExtended/action-hosting-deploy@v0`: GitHub Actions Firebase deploy — official, maintained, PR preview channels built in
- `@sentry/react ^8.x`: Web error tracking — Crashlytics has no web SDK; Sentry is the standard replacement (optional: error boundary + Firebase Analytics custom events is sufficient for a small team)
- `Node 20`: Cloud Functions runtime — firebase-admin 13.x drops Node 18; Node 22 not GA in Firebase as of research date
- Service account JSON secret (not WIF): Firebase Admin SDK explicitly does not support Workload Identity Federation; service account key is correct

### Expected Features

The feature research classifies all production-readiness items against a feature-complete app going to real users. Every P1 item is infrastructure or security, not new product functionality.

**Must have (table stakes):**
- Firebase Hosting config (`firebase.json`) + CI/CD pipeline — app must be reachable and auto-deploy on push
- Production PNG icons (192px, 512px maskable) — `beforeinstallprompt` will never fire without these; currently only SVGs exist
- Real environment variables (Stripe price ID, Firebase config) — placeholder `price_PLACEHOLDER` in deployed code prevents all revenue
- Firestore security rules audit and lockdown — non-negotiable; health-sensitive data exposed without ownership checks
- React error boundaries (root + route-level) — missing boundaries produce white screens on any render error
- Stripe checkout end-to-end (Cloud Function + webhook + Firestore entitlement) — primary monetization path
- Firebase Cloud Function for AI workouts — consolidates infra, adds auth gating, replaces Cloudflare worker
- Content Security Policy headers — XSS protection; must be configured in `firebase.json`, not meta tags
- Loading skeleton states — blank flash during Firestore fetch on 25+ routes reads as broken
- Custom offline fallback page, 404 page, SEO/OG meta tags — basic trust signals

**Should have (competitive):**
- "Add to Home Screen" install prompt — implement `beforeinstallprompt` on Android; instructional modal for iOS Safari
- Rate limiting on AI generation — per-UID Firestore counter to cap Gemini costs; implement once abuse patterns emerge
- Component test coverage for auth/checkout/workout session — domain tests exist; critical flow UI tests are the gap

**Defer (v2+):**
- Web push notifications — needs user volume to prove retention impact
- Expanded Firestore real-time listeners — current one-time fetches are correct; add `onSnapshot` only where data staleness causes complaints
- A/B testing on onboarding — needs sufficient user volume to be statistically significant

### Architecture Approach

The architecture is already correct and does not need structural changes for production readiness. The six-component production system is: Firebase Hosting (HTTPS + CDN + CSP headers via `firebase.json`), Firebase Auth (`SessionProvider` with multi-provider support), Firestore with `persistentLocalCache` and dual Firestore/LocalStorage repository adapters, Firebase Cloud Functions gen2 (AI workout via Gemini, Stripe checkout session, Stripe webhook), Stripe (redirect-based checkout, webhook-driven entitlement), and GitHub Actions CI/CD (test → build → deploy pipeline). The domain layer (`src/domain/`) is pure TypeScript with zero external dependencies and is not touched in any production readiness phase.

**Major components:**
1. **GitHub Actions CI/CD** — test gate + Vite build with `VITE_*` secrets injected + `FirebaseExtended/action-hosting-deploy@v0`; deploy job gated on test job success
2. **firebase.json** — `"public": "pwa/dist"`, SPA rewrite rule, `no-cache` for `sw.js`, immutable cache for hashed assets, CSP and security headers
3. **Cloud Functions (gen2)** — `generateWorkout` (Gemini, replaces Cloudflare worker), `createCheckoutSession` (creates Stripe session, returns URL), `stripeWebhook` (uses `req.rawBody` + `constructEvent`, writes `premiumEntitlement` to Firestore)
4. **EntitlementProvider** — `onSnapshot` on `/users/{uid}.premiumEntitlement`; only the webhook function writes this field; client-side writes blocked by Firestore rules
5. **Error Boundary (two-tier)** — root boundary in `main.tsx` wrapping `RouterProvider`; route-level boundary in `AppLayout` wrapping `<Outlet>` with `resetKeys={[location.pathname]}`
6. **PWA assets** — `icon-192.png`, `icon-512.png`, `icon-512-maskable.png` (20% safe-zone padding, `#0D1A40` background), `apple-touch-icon.png` (180px)

### Critical Pitfalls

1. **Missing SPA rewrite rule in firebase.json** — every deep-link URL refresh returns a 404 from Firebase Hosting; add `{ "source": "**", "destination": "/index.html" }` rewrite and serve `sw.js` with `Cache-Control: no-cache`
2. **Stripe webhook raw body destroyed by Express middleware** — `stripe.webhooks.constructEvent` requires `req.rawBody`, not the JSON-parsed `req.body`; use a dedicated `onRequest` Cloud Function (not an Express route) to preserve it; all subscriptions fail silently without this
3. **Firestore security rules missing uid ownership check on subcollections** — `allow read, write: if request.auth != null` without `request.auth.uid == uid` comparison allows any authenticated user to read any other user's health data; subcollections do NOT inherit parent rules
4. **Service worker caches stale chunk filenames after deploy** — `autoUpdate` activates the new SW immediately but old lazy-loaded chunk URLs 404; add global `unhandledrejection` handler that force-reloads on `Failed to fetch dynamically imported module` errors
5. **CSP blocks Firebase Auth, Stripe, and Analytics when enforced** — set `Content-Security-Policy-Report-Only` first; allowlist must include `accounts.google.com`, `appleid.apple.com`, `js.stripe.com`, `*.googleapis.com`, `*.firebaseio.com`, `wss://*.firebaseio.com`; `frame-src` for Stripe iframes; only switch to enforcing after 24h of zero violations in staging
6. **PWA icons are SVGs only — install prompt never fires** — Chrome's installability check requires actual PNG files at the declared manifest paths; generate 192px, 512px, and 512px maskable PNGs before any production deploy or Lighthouse audit
7. **premiumEntitlement writable by client** — Firestore rules must deny client writes to this field; only the Stripe webhook Cloud Function (via Admin SDK, which bypasses rules) should set it

## Implications for Roadmap

Based on combined research, the build order has hard dependencies that make the phase sequence non-negotiable. CI/CD unlocks auto-deploys; firebase.json is required for any deploy; Cloud Functions are required for Stripe; Firestore rules must be locked before Cloud Functions write entitlements; error resilience and PWA quality are independent polish tracks that can run last.

### Phase 1: Firebase Hosting + GitHub Actions CI/CD

**Rationale:** Nothing else can be deployed, tested, or iterated on without a working deploy pipeline. This is the absolute prerequisite. CI gating on tests prevents broken code from reaching production.
**Delivers:** Live deployment at production URL, PR preview channels, automated test + build + deploy on every push to main
**Addresses:** Firebase Hosting config (table stakes), CI/CD pipeline (table stakes), environment variables (unblocks Stripe and AI)
**Avoids:** Pitfall 1 (SPA rewrite missing), Pitfall 8 (CI deploys without test gate), `FIREBASE_TOKEN` deprecation (use service account key)

### Phase 2: Firebase Cloud Functions (AI Workout + Stripe Backend)

**Rationale:** Stripe checkout requires a server-side session creator (secret key cannot be in frontend). AI workout generation must move from Cloudflare worker to Firebase Functions to add auth gating. Both functions must be deployed before end-to-end payment testing can happen.
**Delivers:** `generateWorkout` function (auth-gated Gemini proxy), `createCheckoutSession` function, `stripeWebhook` function, `createPortalSession` function
**Uses:** `firebase-functions/v2/https`, `firebase-admin ^13`, `stripe ^17`, Node 20
**Avoids:** Pitfall 2 (raw body destruction — use dedicated `onRequest` with `req.rawBody`)

### Phase 3: Stripe Checkout End-to-End + Firestore Security Hardening

**Rationale:** With Cloud Functions deployed, Stripe checkout can be wired end-to-end. Firestore rules must be locked simultaneously — the webhook writes `premiumEntitlement`, so rules protecting that field must be in place before any live payment testing. These ship together.
**Delivers:** Working Stripe subscription flow (create session → hosted checkout → webhook → Firestore entitlement → `EntitlementProvider` update), production Stripe credentials replacing placeholders, Firestore rules with uid ownership on all subcollections and `premiumEntitlement` write protection
**Implements:** EntitlementProvider architecture, Stripe webhook data flow
**Avoids:** Pitfall 3 (cross-user Firestore access), Pitfall 5 (premiumEntitlement client-writable)

### Phase 4: Security Headers (CSP) + PWA Quality Assets

**Rationale:** CSP must come after all integrations (Firebase Auth, Stripe, AI) are confirmed working, so the allowlist is known. PWA icons are independent but similarly required before Lighthouse audit. Neither requires other phases to be in a specific state — they can ship together.
**Delivers:** `Content-Security-Policy` header enforced in `firebase.json` (report-only first), full security header set (X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy), production PNG icons (192px, 512px, maskable), `apple-touch-icon.png`, Lighthouse PWA "Installable" audit pass
**Avoids:** Pitfall 5 (CSP blocking integrations — report-only first), Pitfall 6 (missing PNG icons blocking install prompt)

### Phase 5: Error Resilience + Loading States + Offline UX

**Rationale:** Error boundaries, skeleton states, and offline fallback are user-facing polish that improve perceived quality but do not unblock other phases. They ship together as a polish pass before any soft launch.
**Delivers:** Root + route-level error boundaries (`react-error-boundary`), shimmer skeleton screens on Dashboard/Programs/History/Cycle/Maxes, custom offline fallback page (`offline.html` via Workbox `navigateFallback`), chunk load error handler (force-reload on stale SW chunks), 404 page
**Avoids:** Pitfall 4 (stale SW chunk 404s), Pitfall 7 (missing error boundaries → white screens)

### Phase 6: SEO, Meta Tags, Analytics Verification + Install Prompt

**Rationale:** Final pre-launch polish. OG tags enable social sharing. Analytics verification confirms event tracking works before the app is in users' hands. The install prompt is a P2 feature but worth shipping before formal launch.
**Delivers:** OG/Twitter meta tags in `index.html`, analytics event verification via Firebase DebugView, `beforeinstallprompt` banner for Android, iOS "Add to Home Screen" instructional modal in Settings, optional rate limiting on AI generation
**Addresses:** SEO (table stakes), analytics verification (table stakes), install prompt (P2 differentiator)

### Phase Ordering Rationale

- Phase 1 before everything: No deploy = no ability to test or validate any subsequent work. GitHub Actions gating on tests protects all future phases.
- Phase 2 before Phase 3: Cloud Functions must be deployed before Stripe checkout can be tested end-to-end. Both Stripe functions ship together.
- Phase 3 simultaneous with Cloud Functions going live: Firestore rules must protect `premiumEntitlement` before the webhook function can write it in production.
- Phase 4 after integrations: CSP allowlist cannot be correct until all third-party integrations (Firebase Auth providers, Stripe, Gemini) are confirmed working.
- Phase 5 independent: Error boundaries and skeleton states have no upstream dependencies; they are pure frontend additions.
- Phase 6 last: Analytics verification requires a working deployed app. Install prompt works best after users can discover the app organically.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Stripe subscription lifecycle (trial periods, cancellation, reactivation, prorations) — the basic webhook pattern is documented but edge cases (failed payments, grace periods) need specific handling decisions
- **Phase 4:** CSP violation reporting endpoint — Firebase Hosting does not provide a built-in violation reporting endpoint; options include a Cloud Function handler or a third-party service like `report-uri.com`

Phases with standard patterns (skip research-phase):
- **Phase 1:** Firebase Hosting + GitHub Actions is fully documented with official tooling; follow STACK.md workflow pattern verbatim
- **Phase 2:** Cloud Functions gen2 pattern is well-documented; `req.rawBody` behavior confirmed in official docs and multiple community sources
- **Phase 5:** React error boundaries and Workbox offline fallback are well-established patterns with no app-specific unknowns
- **Phase 6:** Static meta tag additions are trivial; Firebase Analytics `logEvent` patterns are already wired in the codebase

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions confirmed against npm and official docs; no speculative recommendations; the existing stack requires minimal additions |
| Features | HIGH | Based on direct codebase audit of confirmed gaps (no firebase.json, no PNG icons, placeholder Stripe ID); not inferred |
| Architecture | HIGH | Architecture research was grounded in the actual codebase (`pwa/vite.config.ts`, `firestore.rules`, `src/`); diagrams match the real component structure |
| Pitfalls | HIGH | All critical pitfalls verified against official Firebase docs, Stripe docs, and vite-plugin-pwa issues; not based on training data alone |

**Overall confidence:** HIGH

### Gaps to Address

- **Stripe edge cases (Phase 3):** Research covered the happy path (checkout session → webhook → entitlement). Failed payment handling, subscription cancellation UX, trial-to-paid conversion, and dunning management are not researched. Validate against Stripe docs during Phase 3 planning.
- **WIF for service account (Phase 1):** Workload Identity Federation is the preferred GCP auth method and has better security posture, but Firebase Admin SDK explicitly does not support it as of research date. Confirm this limitation has not changed before finalizing the CI/CD approach — if WIF support was added, it is preferable to a long-lived service account JSON key.
- **Sentry vs Firebase Analytics for error tracking:** Research flagged Sentry as MEDIUM confidence (vendor source). For a small team, the React error boundary + Firebase Analytics `logEvent('error')` approach is simpler and free. Validate this is sufficient before adding a Sentry dependency and account.
- **CSP report-only violation collection:** No reporting endpoint is defined. Before switching from `Content-Security-Policy-Report-Only` to enforcement, a collection mechanism is needed. Resolve during Phase 4 planning.

## Sources

### Primary (HIGH confidence)
- [firebase.google.com/docs/hosting/github-integration](https://firebase.google.com/docs/hosting/github-integration) — Firebase Hosting GitHub Actions official integration
- [firebase.google.com/docs/hosting/full-config](https://firebase.google.com/docs/hosting/full-config) — Headers, rewrites, cache config
- [docs.stripe.com/webhooks/signature](https://docs.stripe.com/webhooks/signature) — Raw body requirement, `constructEvent` pattern
- [docs.stripe.com/sdks/stripejs-react](https://docs.stripe.com/sdks/stripejs-react) — React Stripe.js v5 API
- [firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started) — Security rules ownership patterns
- [vite-pwa-org.netlify.app/guide/](https://vite-pwa-org.netlify.app/guide/) — vite-plugin-pwa autoUpdate, service worker precache
- [developer.chrome.com/docs/lighthouse/pwa/installable-manifest](https://developer.chrome.com/docs/lighthouse/pwa/installable-manifest) — PWA installability criteria
- [react.dev/reference/react/Component](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary) — Error boundary API
- [github.com/bvaughn/react-error-boundary](https://github.com/bvaughn/react-error-boundary) — react-error-boundary library
- [github.com/firebase/firebase-tools/issues/5999](https://github.com/firebase/firebase-tools/issues/5999) — HSTS override bug in firebase.json (do not set manually)

### Secondary (MEDIUM confidence)
- [aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — Stripe + Firebase Functions gen2 `rawBody` pattern; March 2025, matches official Stripe docs
- [bitesite.ca/blog/raw-body-for-stripe-webhooks-using-firebase-cloud-functions](https://www.bitesite.ca/blog/raw-body-for-stripe-webhooks-using-firebase-cloud-functions) — `req.rawBody` on Firebase `onRequest`
- [github.com/google-github-actions/auth](https://github.com/google-github-actions/auth) — WIF not supported by Firebase Admin SDK (community finding, consistent across sources)
- [sentry.io/resources/sentry-vs-crashlytics-mobile-developers-guide](https://sentry.io/resources/sentry-vs-crashlytics-mobile-developers-guide/) — Crashlytics has no web SDK (vendor source)
- [modernpentest.com/blog/securing-firebase-in-production](https://modernpentest.com/blog/securing-firebase-in-production) — Firestore security audit checklist
- Direct codebase audit: `pwa/vite.config.ts`, `pwa/src/`, `firestore.rules`, `pwa/public/` — confirmed actual gaps (HIGH confidence for facts found, source is the repo itself)

---
*Research completed: 2026-03-21*
*Ready for roadmap: yes*

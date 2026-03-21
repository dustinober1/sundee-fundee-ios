# Feature Research

**Domain:** PWA Production Readiness — Vite + React + Firebase (feature-complete app going to real users)
**Researched:** 2026-03-21
**Confidence:** HIGH

---

## Context

The Sundee Fundee PWA is feature-complete (25+ screens, offline support, Firestore sync, Stripe stubbed, AI workout generation, cycle tracking). This research covers what production readiness features are table stakes vs. differentiating before shipping to real users. Existing capabilities are noted to avoid re-researching implemented items.

**Current gaps confirmed from codebase audit:**
- No firebase.json / Firebase Hosting config exists yet
- No GitHub Actions CI/CD workflow present
- Icons in `public/` are placeholder SVGs — no production PNG icons (192px, 512px) confirmed missing
- `index.html` has basic meta tags but no OG/social tags, no description
- No React error boundary components found in `src/`
- No loading/skeleton state components found
- 17 test files total — domain tests only, no auth or critical flow component tests
- No CSP headers configured in firebase.json (file doesn't exist yet)
- `vite.config.ts` has PWA manifest declared but icons not on disk
- Stripe is `@stripe/stripe-js` dependency present but uses placeholder price IDs

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = the app feels broken or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Firebase Hosting deployment pipeline | App must be accessible at a real URL | LOW | Needs `firebase.json`, deploy script, `.firebaserc` — standard Firebase CLI setup |
| GitHub Actions CI/CD | Every production app runs tests before deploy | MEDIUM | Firebase provides a GitHub Actions action; add build + test + deploy workflow |
| Real environment variables | Placeholder Stripe price IDs will cause checkout to fail | LOW | `.env.production` with Firebase config, Stripe price ID, auth domain — never commit secrets |
| Production PWA icons (192px, 512px PNG) | `beforeinstallprompt` will not fire without valid icons on disk | LOW | Currently only SVGs in `public/` — need PNG icons at exact declared sizes or install prompt is permanently broken |
| React error boundaries | Uncaught React render errors show a blank white screen to users | MEDIUM | Add root-level `ErrorBoundary` component and route-level boundaries for graceful recovery |
| Loading / skeleton states on data-fetching routes | Blank flash during Firestore fetch is disorienting; users assume broken | MEDIUM | 25+ routes that fetch data — shimmer skeletons on Dashboard, Programs, History, Cycle, Maxes |
| Firestore security rules audit and lockdown | Open rules are a critical security hole; Firestore will flag and alert | MEDIUM | Current rules unknown — need deny-by-default + `request.auth.uid == userId` per collection |
| Content Security Policy headers | Without CSP, XSS attacks are trivially injectable into the Firebase-hosted app | MEDIUM | Configure in `firebase.json` `headers` block — must allowlist Firebase SDK domains, Stripe, Gemini |
| 404 page for unknown routes | Browser default 404 or blank screen breaks trust; looks unfinished | LOW | Add `<Route path="*">` in router.tsx with a branded "page not found" component |
| SEO / meta tags (og:title, og:description, og:image) | Social share links will show blank previews without OG tags | LOW | Static tags in `index.html` sufficient for a single-page app — og:title, og:description, og:image, twitter:card |
| Lighthouse PWA audit pass | Chrome's install prompt requires passing installability criteria; Lighthouse score is a trust signal | MEDIUM | Need: valid manifest, icons on disk, service worker registered, HTTPS — currently blocked by missing PNG icons |
| Analytics verification | Firebase Analytics events must fire correctly or data is blind in production | LOW | Confirm `logEvent` calls reach Firebase console; test with DebugView before launch |
| Custom offline fallback page | Workbox shows a blank page offline without a custom fallback; users think the app is broken | LOW | Add `offline.html` to `public/`, configure Workbox `navigateFallback` — already using vite-plugin-pwa |

### Differentiators (Competitive Advantage)

Features that set the app apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Add to Home Screen" install prompt | Native-app feel from browser; dramatically increases retention vs. bookmark | MEDIUM | Use `beforeinstallprompt` event on Android; iOS requires a custom "tap Share then Add to Home Screen" instructional modal — Safari does not support the event |
| Stripe checkout end-to-end | Real monetization; without it the app cannot generate revenue | HIGH | Cloud Function for `createCheckoutSession`, webhook for entitlement write-back to Firestore, success/cancel URLs, subscription status in AuthContext |
| Firebase Cloud Function for AI workouts | Replaces Cloudflare worker; consolidates infra; adds auth gating on AI generation | HIGH | Move `generateWorkout` to Firebase Functions with user auth check; use Gemini SDK |
| Rate limiting on AI generation | Prevents runaway Gemini API costs from single abusive users | MEDIUM | Use `firebase-functions-rate-limiter` (Firestore-backed); 5 generations per user per day is sufficient starting limit |
| Component test coverage for critical flows | High-confidence deploys; prevents regressions in auth/checkout/workout session | MEDIUM | Add Vitest + React Testing Library tests for: AuthContext, Stripe checkout trigger, WorkoutSession set logging — domain tests already exist |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full SSR / pre-rendering for SEO | "PWAs have bad SEO" concern | The app is auth-gated — only the landing/sign-in page needs SEO. Adding SSR (Vite SSR, Remix) is a rewrite-level scope change that adds operational complexity for essentially zero user-facing benefit on an authenticated training app | Add static OG/meta tags to `index.html`; use a simple static landing page if SEO matters |
| Sentry for error monitoring | Best-in-class web error tracking | Sentry is a paid service with a free tier that runs out fast; Firebase already has Crashlytics and Analytics for web error logging. For a small team, custom error boundary + `logEvent('error', ...)` to Firebase Analytics is sufficient | React error boundary + Firebase Analytics custom events for error tracking |
| Real-time Firestore listeners on every screen | "Always fresh data" appeal | Firestore real-time listeners on 25+ screens simultaneously will exhaust free-tier quotas and rack up read costs; the app is async fitness logging, not a chat app — data does not need to be real-time everywhere | Use one-time `getDocs` fetches for history/programs; reserve `onSnapshot` for active workout session only |
| In-app update prompt for PWA | "Users always have latest code" | `vite-plugin-pwa` with `registerType: 'autoUpdate'` already handles this silently. Adding a modal "new version available, refresh now?" creates friction and is unnecessary with autoUpdate | Let autoUpdate handle silently; the service worker already does this |
| HSTS preloading | Maximum transport security | HSTS preload requires domain submission to browser preload lists and is essentially irreversible — mistakes can lock users out. Firebase Hosting already serves HTTPS; adding `Strict-Transport-Security` header is sufficient without preload submission | Set `Strict-Transport-Security` header in firebase.json without the `preload` directive |
| Custom Stripe Elements (hosted payment UI) | Branded checkout experience | Stripe Checkout (redirect) is far simpler to implement, PCI-compliant by default, and handles card validation, 3DS, and Apple/Google Pay automatically. Custom Elements require PCI SAQ A-EP compliance and significant UI work | Use Stripe Checkout redirect — simpler, safer, faster to ship |

---

## Feature Dependencies

```
Firebase Hosting config (firebase.json)
    └──required by──> GitHub Actions CI/CD deploy step
    └──required by──> CSP headers (defined in firebase.json)
    └──required by──> Custom offline fallback routing

Production PNG icons (192px, 512px)
    └──required by──> PWA Lighthouse audit pass
    └──required by──> "Add to Home Screen" install prompt (beforeinstallprompt)

Real environment variables
    └──required by──> Stripe checkout end-to-end
    └──required by──> Firebase Cloud Function (AI workouts)
    └──required by──> Analytics verification

Firebase Cloud Functions (AI workout)
    └──required by──> Rate limiting on AI generation
    └──enhanced by──> Real environment variables

Firestore security rules audit
    └──enhances──> Rate limiting (rules can enforce per-user write limits)
    └──required before──> production launch (open rules = immediate security risk)

React error boundaries
    └──enhanced by──> Analytics verification (errors logged to Firebase Analytics)

Stripe checkout end-to-end
    └──requires──> Real environment variables (Stripe price ID, publishable key)
    └──requires──> Firebase Cloud Function (createCheckoutSession)
    └──requires──> Firestore security rules (subscription status write-back)

Component test coverage
    └──enhanced by──> GitHub Actions CI/CD (tests run on every push)
```

### Dependency Notes

- **Production PNG icons require PWA install prompt**: `beforeinstallprompt` is gated on Chrome's installability check. The manifest declares `icon-192.png` and `icon-512.png` but neither file exists on disk. The install prompt will never fire until icons are present.
- **Firebase Hosting config requires CI/CD**: There is no `firebase.json` in the PWA directory. CI/CD cannot deploy until hosting is configured.
- **Stripe requires Cloud Functions**: The current Cloudflare worker proxy handles AI only; Stripe checkout sessions must be created server-side to avoid exposing Stripe secret key. A Firebase Cloud Function is required.
- **Firestore security rules should precede launch**: Currently unknown state. Open/permissive rules expose all user data. This is the highest-risk gap.

---

## MVP Definition

### Launch With (v1)

Minimum required to ship to real users with confidence.

- [ ] Firebase Hosting deployment pipeline — app must be reachable at production URL
- [ ] GitHub Actions CI/CD (build + test + deploy) — prevents broken builds shipping
- [ ] Real environment variables — Stripe and Firebase must use production credentials
- [ ] Production PWA icons (192px, 512px PNG) — required for installability
- [ ] Firestore security rules audit and lockdown — non-negotiable security requirement
- [ ] React error boundaries — prevents blank white screens on runtime errors
- [ ] Content Security Policy headers — XSS protection for a Firebase-hosted app
- [ ] SEO / OG meta tags in index.html — social share links must not show blank previews
- [ ] 404 page — basic trust signal; every production app has one
- [ ] Custom offline fallback page — offline UX should be branded, not blank
- [ ] Lighthouse PWA audit pass — confirms installability and service worker correctness
- [ ] Stripe checkout end-to-end — primary monetization path must work
- [ ] Firebase Cloud Function for AI workouts — consolidates infra, adds auth gating
- [ ] Analytics verification — blind to user behavior without confirmed events
- [ ] Loading / skeleton states on data-fetching routes — perceived performance and polish

### Add After Validation (v1.x)

Features to add once core is working and real users are using the app.

- [ ] "Add to Home Screen" install prompt — measure install rate; add contextual prompt after user completes first workout
- [ ] Rate limiting on AI generation — implement once actual usage data shows abuse patterns or cost trends
- [ ] Component test coverage for auth/checkout/workout session — add incrementally as regressions appear

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Web push notifications — requires notification permission UX; defer until retention data shows this moves the needle
- [ ] Expanded Firestore real-time listeners — only worth the cost if users complain about staleness
- [ ] A/B testing on onboarding flow — needs user volume to be statistically significant

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Firestore security rules audit | HIGH (trust/safety) | MEDIUM | P1 |
| Firebase Hosting + CI/CD | HIGH (ship the app) | LOW | P1 |
| Real environment variables | HIGH (payments work) | LOW | P1 |
| Production PWA icons | HIGH (installability) | LOW | P1 |
| React error boundaries | HIGH (no blank screens) | MEDIUM | P1 |
| Stripe checkout end-to-end | HIGH (monetization) | HIGH | P1 |
| Firebase Cloud Function (AI) | HIGH (consolidate infra) | HIGH | P1 |
| CSP headers | HIGH (XSS protection) | LOW | P1 |
| Loading skeleton states | MEDIUM (perceived perf) | MEDIUM | P1 |
| Offline fallback page | MEDIUM (offline UX) | LOW | P1 |
| 404 page | MEDIUM (trust signal) | LOW | P1 |
| SEO / OG meta tags | MEDIUM (social share) | LOW | P1 |
| Lighthouse audit pass | MEDIUM (installability gate) | MEDIUM | P1 |
| Analytics verification | MEDIUM (visibility) | LOW | P1 |
| "Add to Home Screen" prompt | MEDIUM (retention) | MEDIUM | P2 |
| Rate limiting on AI | MEDIUM (cost control) | MEDIUM | P2 |
| Component test coverage | MEDIUM (confidence) | MEDIUM | P2 |
| Web push notifications | LOW (nice to have) | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Typical Fitness PWA | Strong Production PWA | Our Approach |
|---------|---------------------|----------------------|--------------|
| Deployment | Manual firebase deploy | GitHub Actions + preview channels | GitHub Actions with manual script fallback |
| Error handling | None / white screen | Sentry + error boundaries | React error boundary + Firebase Analytics events |
| Offline | None | Full offline with sync | Already implemented via vite-plugin-pwa + Workbox; needs custom offline fallback page |
| Install prompt | None | Contextual prompt after engagement milestone | Post-first-workout prompt on Android; instructional modal for iOS |
| Payments | None or App Store only | Stripe Checkout with entitlements | Stripe Checkout redirect via Firebase Cloud Function |
| Security | Open Firestore rules | CSP + locked Firestore rules | CSP headers in firebase.json + deny-by-default Firestore rules |
| Icons | Placeholder | Production-quality maskable icons | Need to generate 192px and 512px maskable PNGs |
| Loading UX | Blank flash | Shimmer skeletons | Shimmer skeletons on all data-fetching routes |

---

## Sources

- [PWA Best Practices — MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Best_practices)
- [PWA Installability Criteria — Chrome for Developers](https://developer.chrome.com/docs/lighthouse/pwa/installable-manifest)
- [Making PWAs Installable — MDN](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable)
- [How to Customize the Install Prompt — web.dev](https://web.dev/articles/customize-install)
- [Firebase Hosting GitHub Integration — Firebase Docs](https://firebase.google.com/docs/hosting/github-integration)
- [Firestore Security Rules — Firebase Docs](https://firebase.google.com/docs/firestore/security/get-started)
- [Content Security Policy for Firebase Hosting — firebase.google.com](https://firebase.google.com/docs/hosting/full-config)
- [PWA Security Best Practices 2025 — AppInstitute](https://appinstitute.com/9-pwa-security-practices-for-2025/)
- [SEO for React + Vite Apps — DEV Community](https://dev.to/ali_dz/optimizing-seo-in-a-react-vite-project-the-ultimate-guide-3mbh)
- [Service Worker Caching Strategies — ZeePalm](https://www.zeepalm.com/blog/service-worker-caching-5-offline-fallback-strategies)
- [firebase-functions-rate-limiter — npm](https://www.npmjs.com/package/firebase-functions-rate-limiter)
- [Implementing Stripe + Firebase Cloud Functions (2025) — aronschueler.de](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/)
- [Skeleton Loading in React 19 — Medium/balevdev](https://balevdev.medium.com/skeletons-the-pinnacle-of-loading-states-in-react-19-427cbb5a1f48)
- [Vitest Component Testing — vitest.dev](https://vitest.dev/guide/browser/component-testing)
- [Progressive Web Apps 2026 Performance Guide — Digital Applied](https://www.digitalapplied.com/blog/progressive-web-apps-2026-pwa-performance-guide)

---
*Feature research for: PWA Production Readiness (Sundee Fundee)*
*Researched: 2026-03-21*

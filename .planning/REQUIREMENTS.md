# Requirements: Sundee Fundee PWA — Production Readiness

**Defined:** 2026-03-21
**Core Value:** Users can reliably access Sundee Fundee from any browser, with real payments, real AI workouts, and production-grade reliability

## v1 Requirements

### Deployment

- [x] **DEPLOY-01**: Firebase Hosting configured with `firebase.json`, SPA rewrite rules, and `.firebaserc`
- [x] **DEPLOY-02**: GitHub Actions workflow builds, tests, and deploys to Firebase Hosting on push to main
- [x] **DEPLOY-03**: Manual `firebase deploy` script as CI/CD fallback
- [x] **DEPLOY-04**: Production environment variables for Firebase config, Stripe price ID, and auth domain

### Backend

- [x] **BACK-01**: Firebase Cloud Function generates AI workouts via Gemini SDK with user auth gating
- [x] **BACK-02**: Stripe Checkout session created via Cloud Function with real price ID, success/cancel URLs
- [x] **BACK-03**: Stripe webhook verifies signature via `rawBody`, writes subscription entitlement to Firestore

### Security

- [ ] **SEC-01**: Firestore security rules enforce per-user ownership on all subcollections
- [ ] **SEC-02**: Firestore rules prevent client-side write to `premiumEntitlement` field
- [x] **SEC-03**: Content Security Policy headers in `firebase.json` allowlisting Firebase, Stripe, and Gemini domains
- [x] **SEC-04**: Rate limiting on AI workout generation (5 per user per day)

### PWA

- [ ] **PWA-01**: Production 192px and 512px PNG icons on disk matching manifest declarations
- [ ] **PWA-02**: Lighthouse PWA audit passes installability, accessibility, and performance checks
- [ ] **PWA-03**: Custom branded offline fallback page served by service worker
- [ ] **PWA-04**: "Add to Home Screen" install prompt on Android; instructional modal on iOS

### UX

- [ ] **UX-01**: Root-level and route-level React error boundaries with recovery UI
- [ ] **UX-02**: Shimmer skeleton states on all data-fetching routes (Dashboard, Programs, History, Cycle, Maxes)
- [ ] **UX-03**: Branded 404 page for unknown routes

### Quality

- [ ] **QUAL-01**: Component tests for auth flow, workout session, and Stripe checkout trigger
- [ ] **QUAL-02**: Firebase Analytics events verified firing in DebugView
- [ ] **QUAL-03**: SEO meta tags (og:title, og:description, og:image, twitter:card) in index.html

## v2 Requirements

### Observability

- **OBS-01**: Sentry integration for detailed web error tracking (if Firebase Analytics proves insufficient)
- **OBS-02**: Firestore real-time listener optimization based on actual usage cost data

### Growth

- **GROW-01**: Web push notifications for workout reminders
- **GROW-02**: A/B testing on onboarding flow

## Out of Scope

| Feature | Reason |
|---------|--------|
| SSR / pre-rendering | App is auth-gated; static OG tags sufficient for SEO. SSR is a rewrite-level scope change |
| Custom Stripe Elements | Stripe Checkout redirect is simpler, PCI-compliant by default, and handles 3DS/Apple Pay automatically |
| HSTS preloading | Firebase Hosting auto-configures HSTS; preload submission is irreversible and risky |
| In-app update modal | `vite-plugin-pwa` with `autoUpdate` already handles this silently |
| Native iOS app changes | This milestone is PWA-only |
| WOD admin dashboard changes | Separate codebase |
| New feature development | Strictly production readiness of existing features |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEPLOY-01 | Phase 1 | Complete |
| DEPLOY-02 | Phase 1 | Complete |
| DEPLOY-03 | Phase 1 | Complete |
| DEPLOY-04 | Phase 1 | Complete |
| BACK-01 | Phase 2 | Complete |
| BACK-02 | Phase 2 | Complete |
| BACK-03 | Phase 2 | Complete |
| SEC-01 | Phase 3 | Pending |
| SEC-02 | Phase 3 | Pending |
| SEC-03 | Phase 3 | Complete |
| SEC-04 | Phase 3 | Complete |
| PWA-01 | Phase 4 | Pending |
| PWA-02 | Phase 4 | Pending |
| PWA-03 | Phase 4 | Pending |
| PWA-04 | Phase 4 | Pending |
| UX-01 | Phase 5 | Pending |
| UX-02 | Phase 5 | Pending |
| UX-03 | Phase 5 | Pending |
| QUAL-01 | Phase 6 | Pending |
| QUAL-02 | Phase 6 | Pending |
| QUAL-03 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

---
*Requirements defined: 2026-03-21*
*Last updated: 2026-03-21 after roadmap creation — all 21 requirements mapped*

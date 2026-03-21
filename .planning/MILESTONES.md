# Milestones

## v1.0 PWA Production Readiness (Shipped: 2026-03-21)

**Phases completed:** 7 phases, 17 plans
**Timeline:** 32 days (2026-02-17 → 2026-03-21)
**TypeScript LOC:** 17,846 (16,832 PWA + 1,014 Cloud Functions)
**Requirements:** 21/21 satisfied | **E2E Flows:** 5/5 verified
**Commits:** 103

**Key accomplishments:**
1. Firebase Hosting deployment pipeline with CI/CD (GitHub Actions), PR preview deploys, and manual fallback
2. Cloud Functions for AI workout generation (Gemini SDK) and Stripe checkout/webhook/portal with auth gating
3. Firestore security rules with per-user ownership enforcement, premiumEntitlement write protection, and AI rate limiting (5/day)
4. Production PWA icons, branded offline fallback page, cross-platform install prompt, Lighthouse PWA audit pass
5. Error boundaries (root + route-level), skeleton loading states on all data-fetching routes, branded 404 page
6. Firebase Analytics event instrumentation, SEO meta tags (OG/Twitter), component test coverage for auth/checkout/workout flows

**Delivered:** Production-ready PWA with real payments (Stripe), real AI workouts (Gemini Cloud Function), security-hardened Firestore, CI/CD pipeline, and production-grade UX polish — ready to ship to real users.

**Git range:** feat(01-01) → docs(phase-07)

### Known Tech Debt
- 12 items across 6 categories (see audit report)
- firebase-tools not in devDependencies (manual deploy requires global install)
- functions/ tests not included in CI pipeline
- `setUserProperties()` exported but never called in analytics.ts
- Node.js 20 deprecation warning (GitHub Actions forces Node.js 24 after June 2026)
- Nyquist validation: 1 compliant, 4 partial, 2 missing phases

**Archive:** [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) | [milestones/v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md) | [milestones/v1.0-MILESTONE-AUDIT.md](milestones/v1.0-MILESTONE-AUDIT.md)

---

## v1.0 MVP (Shipped: 2026-03-16)

**Phases completed:** 16 phases, 43 plans
**Timeline:** 30 days (2026-02-15 → 2026-03-16)
**TypeScript LOC:** 44,211 (14,618 test LOC)
**Requirements:** 72/72 satisfied | **E2E Flows:** 10/10 verified

**Key accomplishments:**
1. Full React Native + Expo scaffold with Firebase Auth (Apple, Google, Email, Guest) on iOS/Android/Web
2. Complete TypeScript port of iOS Domain layer (cycle adaptation, injury engine, benchmarks, pain analysis, rehab generation) with 100% test coverage
3. Offline-first data layer with dual repository pattern (Firestore for auth users, AsyncStorage for guests)
4. Core workout loop: exercise library (202+), set logging, timers (ForTime/AMRAP/EMOM), PR detection, history, progress charts
5. Differentiating features: cycle tracking/adaptation, injury management, AI workout generation (Gemini), programs, benchmarks, WODs, readiness survey
6. RevenueCat + Stripe dual subscription pipeline with entitlement gating across all platforms

**Delivered:** Cross-platform strength training app with cycle-aware adaptation, injury modification, AI workout generation, and offline-first architecture — rebuilt from iOS Swift to React Native targeting iOS, Android, and Web.

**Git range:** feat(01-01) → feat(16-01)

### Known Tech Debt
- Firestore security rules require manual deploy: `firebase deploy --only firestore:rules`
- ~30 human verification items (visual UI, background timers, live APIs, notifications)
- `stripeSubscriptionId` not in TypeScript UserProfile type
- Nyquist validation partial across 15/16 phases

**Archive:** [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) | [milestones/v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md)

---


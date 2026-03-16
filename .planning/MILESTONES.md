# Milestones

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


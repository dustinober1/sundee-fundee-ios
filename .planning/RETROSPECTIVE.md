# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-16
**Phases:** 16 | **Plans:** 43

### What Was Built
- Complete React Native + Expo cross-platform app (iOS, Android, Web)
- Full TypeScript port of iOS Domain layer with numeric parity verification
- Firebase backend: Auth (Apple/Google/Email/Guest), Firestore with offline persistence, Cloud Functions (AI + Stripe)
- Dual subscription pipeline: RevenueCat (mobile) + Stripe (web) with unified entitlements
- 72 requirements satisfied across auth, onboarding, workout core, execution, programs, benchmarks, WODs, cycle tracking, cycle adaptation, readiness, injury management, AI workouts, 1RM tracking, subscriptions, and platform design

### What Worked
- **Domain-first architecture**: Porting pure Swift logic to TypeScript first (Phase 2) meant all business rules were tested before any UI existed — zero domain bugs in later phases
- **Dual repository pattern**: Firestore + AsyncStorage behind protocol interfaces made guest/auth modes seamless
- **Gap-closure phases (8-16)**: Post-audit micro-phases effectively caught and fixed integration wiring issues before milestone close
- **Milestone audit before completion**: Running `/gsd:audit-milestone` identified 9 concrete gaps that would have shipped as bugs
- **TDD on domain layer**: 100% test coverage on ported domain code caught subtle numeric differences early

### What Was Inefficient
- **9 gap-closure phases**: Phases 8-16 were all audit-driven fixes that ideally would have been caught during initial phase verification
- **ROADMAP.md checkbox drift**: Several phases showed `[ ]` despite having complete summaries — manual checkbox maintenance doesn't scale
- **Human verification backlog**: ~30 items accumulated that require physical device testing (timers, background state, visual UI)
- **Nyquist validation**: Only 1/16 phases fully compliant — validation was treated as optional rather than part of phase completion

### Patterns Established
- String unions over TypeScript enums for domain types
- `jest.mock()` factory with `mock`-prefixed variables (Babel hoisting safety)
- Platform-specific file extensions (`.web.ts`) with Metro resolver
- `formatWeight(value, unit)` threading pattern for all weight display
- Module-level shared state for Expo Router cross-screen data passing
- Static helper methods on Views for testability

### Key Lessons
1. **Audit before ship, not after**: Running milestone audit caught 9 integration gaps. Should be run after each major phase, not just at milestone end.
2. **Thread cross-cutting concerns early**: Weight unit threading (PLAT-05) required 3 separate fix phases (10, 13, 16) because it wasn't threaded consistently in the initial implementation.
3. **Test the wiring, not just the units**: Domain logic was 100% tested but the wiring between screens (cycle gates, guest upgrade, readiness persistence) had gaps that only integration-level verification caught.
4. **Firestore subcollection rules need explicit matches**: Nested subcollections (injuries/{id}/painLogs/{id}) require their own match block — not inherited from parent.
5. **Guest-to-auth migration is a first-class feature**: Phases 9 + 11 were needed because guest upgrade wasn't treated as a primary user flow during initial implementation.

### Cost Observations
- Model mix: predominantly sonnet for execution, opus for planning and audits
- 30-day timeline from scaffold to shipped milestone
- Notable: Phases 1-7 (core features) completed in ~15 days; Phases 8-16 (gap closure) took another ~15 days — suggesting integration verification should happen earlier

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 16 | 43 | Established GSD workflow; audit-driven gap closure pattern emerged |

### Cumulative Quality

| Milestone | Test Files | Test LOC | Requirements | E2E Flows |
|-----------|-----------|----------|-------------|-----------|
| v1.0 | 72 | 14,618 | 72/72 | 10/10 |

### Top Lessons (Verified Across Milestones)

1. Audit milestone requirements before marking complete — catches wiring gaps that unit tests miss
2. Thread cross-cutting concerns (like weight units) in the first phase that introduces them, not as separate fix phases later

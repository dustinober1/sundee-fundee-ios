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

## Milestone: v1.0 — PWA Production Readiness

**Shipped:** 2026-03-21
**Phases:** 7 | **Plans:** 17

### What Was Built
- Firebase Hosting deployment pipeline with CI/CD (GitHub Actions), PR preview deploys, manual fallback
- Cloud Functions: AI workout generation (Gemini SDK) and Stripe checkout/webhook/portal with auth gating
- Firestore security rules with per-user ownership, premiumEntitlement write protection, AI rate limiting
- Production PWA: icons, branded offline fallback, cross-platform install prompt, Lighthouse audit pass
- Error boundaries (root + route-level), skeleton loading states, branded 404 page
- Firebase Analytics events, SEO meta tags, component test coverage for critical flows

### What Worked
- **Sequential phase dependencies were correct**: deploy → backend → security → UX → polish. Each phase built on the previous, with no circular dependencies or backtracking
- **Milestone audit caught 2 critical gaps**: Firestore rules were written but never deployed; Dashboard links pointed to wrong routes. Both caught before ship
- **Gap closure phase (7) was fast**: One plan, 78 seconds — targeted fix based on audit precision
- **TDD on gap closure**: Dashboard route regression tests now prevent future link breakage
- **Reuse of v1.0 MVP patterns**: Domain-first architecture and repository layer from RN milestone carried over cleanly to PWA

### What Was Inefficient
- **Phase 5 and 6 directories deleted prematurely**: A refactor commit (61a7dba) removed planning directories, losing VERIFICATION.md files. Audit had to verify by codebase inspection instead
- **ROADMAP.md checkbox inconsistency**: Some plan checkboxes showed `[ ]` despite having SUMMARY.md files (Phases 3, 4, 5, 6). Manual maintenance doesn't scale
- **Nyquist validation partial**: Only 1/7 phases fully compliant. Validation treated as optional, same pattern as v1.0 MVP
- **12 tech debt items accumulated**: firebase-tools not in devDeps, functions tests not in CI, dead code (setUserProperties), Node.js 20 deprecation

### Patterns Established
- Three-workflow CI/CD pattern: ci.yml (lint/test/build), preview.yml (PR previews), deploy.yml (production dispatch)
- `--only firestore:rules` for rules-only deploy (indexes.json not needed)
- Firestore transaction rate limiting with atomic counter pattern
- CSP 'unsafe-inline' for Vite/React SPA (revisit if SSR added)
- void logEvent() fire-and-forget analytics pattern
- MemoryRouter in tests for Link href resolution in jsdom
- Deferred navigation pattern (pendingNavigation) for install prompt UX

### Key Lessons
1. **Wire deployment before marking security complete**: Firestore rules were code-complete in Phase 3 but never deployed. "Code exists" ≠ "feature works". Phase 7 gap closure fixed this — always verify deployment, not just implementation
2. **Don't delete planning directories during active milestone**: Phase 5/6 cleanup lost VERIFICATION.md files, making audit harder. Wait for milestone completion to archive
3. **Audit remains essential**: Two milestones in a row, the audit caught critical gaps. This is now a proven pattern, not just a good idea
4. **Tech debt list is a feature, not a burden**: The 12-item debt list from the audit gives the next milestone a clear starting point for cleanup work

### Cost Observations
- Model mix: balanced profile (opus for planning, sonnet for execution)
- 1-day intensive execution (all 7 phases completed 2026-03-21)
- Notable: Gap closure phase (7) took 78 seconds — targeted audit findings are dramatically faster to fix than discovery-based debugging

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 MVP | 16 | 43 | Established GSD workflow; audit-driven gap closure pattern emerged |
| v1.0 PWA | 7 | 17 | Sequential dependency ordering; single-day intensive execution |

### Cumulative Quality

| Milestone | Test Files | Test LOC | Requirements | E2E Flows |
|-----------|-----------|----------|-------------|-----------|
| v1.0 MVP | 72 | 14,618 | 72/72 | 10/10 |
| v1.0 PWA | 80+ | 17,846 | 21/21 | 5/5 |

### Top Lessons (Verified Across Milestones)

1. Audit milestone requirements before marking complete — catches wiring gaps that unit tests miss (verified: v1.0 MVP caught 9 gaps, v1.0 PWA caught 2 critical gaps)
2. Thread cross-cutting concerns (like weight units) in the first phase that introduces them, not as separate fix phases later
3. Verify deployment, not just implementation — code-complete ≠ feature-works (verified: v1.0 PWA Firestore rules gap)
4. Don't clean up planning directories during active milestone — wait for archive step

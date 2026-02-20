# Domain Pitfalls

**Domain:** Flutter full rewrite of an existing offline-first workout tracker (web → Flutter web + Android + iOS + Firebase Hosting)
**Researched:** 2026-02-20
**Confidence:** MEDIUM-HIGH

## Critical Pitfalls

### Pitfall 1: Offline parity regression ("works online, fails in gym")

**What goes wrong:**
The Flutter rewrite ships with UI parity but loses behavioral parity in offline flows (start workout, log sets, finish workout, see recent history) because web+mobile storage semantics differ from current Dexie-first model.

**Why it happens:**
Teams prioritize visual parity and route parity, but do not codify “offline acceptance criteria” from the shipped app. They also pick storage packages that behave differently across platforms without explicit contract tests.

**How to avoid:**
- Define a **parity contract** before coding: exact offline user journeys that must pass on web, Android, iOS.
- Build a repository abstraction first and run the same domain tests against each platform backend.
- Add a hard release gate: no milestone close until offline scenarios pass on all 3 platforms.

**Warning signs:**
- “Feature complete” demos always use network-on environments.
- Reconnect causes duplicate or missing workout sets.
- Team cannot answer: “What is source of truth while offline?” in one sentence.

**Phase to address:**
Phase 9 — Foundations and parity contract

---

### Pitfall 2: Wrong local database choice for Flutter web parity

**What goes wrong:**
The selected local DB works well on mobile but has web limitations that break parity or reliability (query semantics, sync behavior, or durability assumptions differ on IndexedDB-backed web implementations).

**Why it happens:**
SQLite assumptions from mobile are carried into web without validating real web support constraints.

**How to avoid:**
- Treat web as first-class at architecture time, not a later adapter.
- Validate package/platform constraints early:
  - `sqflite` web is experimental via `sqflite_common_ffi_web`.
  - Isar web has explicit limitations (e.g., unsupported sync methods / feature gaps).
  - Drift web can degrade to fallback implementations; must inspect chosen storage mode and missing features.
- Run storage spike tests for: transaction safety, multi-tab behavior, migration behavior, and recovery after browser restart.

**Warning signs:**
- “We’ll solve web storage later” language.
- Different query behavior between mobile and web in early QA.
- IndexedDB quota/eviction behavior not tested.

**Phase to address:**
Phase 9 — Data layer spike and decision lock

---

### Pitfall 3: Flutter web route refresh/deep-link failures on Firebase Hosting

**What goes wrong:**
Direct navigation or refresh on non-root routes returns 404 because Firebase Hosting rewrites were not configured as SPA rewrites.

**Why it happens:**
Routing works in local dev, so hosting rewrite rules are deferred until late deploy hardening.

**How to avoid:**
- Configure SPA rewrite in `firebase.json` from day one (`"source": "**"` → `"destination": "/index.html"`).
- Add CI smoke tests for deep links (`/dashboard`, `/workout/...`, `/progress`) on preview channels.
- Keep rewrite/redirect ordering explicit and documented.

**Warning signs:**
- QA reports “works after clicking in app, fails on reload.”
- Shared deep links open 404 in production preview.

**Phase to address:**
Phase 11 — Hosting and release pipeline

---

### Pitfall 4: Assuming old Flutter web service-worker defaults still provide offline

**What goes wrong:**
Team assumes Flutter-generated service worker behavior from older guidance, but default behavior changed/deprecated; offline expectations are silently unmet.

**Why it happens:**
Migration plans rely on stale Flutter web PWA assumptions.

**How to avoid:**
- Explicitly choose and document web offline strategy for Flutter (do not rely on implicit defaults).
- Add explicit offline acceptance tests in CI and manual QA.
- Version-pin and periodically re-verify Flutter web/PWA behavior in release notes before milestone lock.

**Warning signs:**
- “Offline should just work because Flutter web generates SW.”
- No owned service-worker/update strategy doc.

**Phase to address:**
Phase 10 — Web runtime/offline architecture

---

### Pitfall 5: Dual-backend sync conflicts during cutover (legacy web + new Flutter app)

**What goes wrong:**
During migration period, users may use both old and new clients; writes conflict or overwrite each other, creating data drift in workouts, PRs, and active cycles.

**Why it happens:**
Rewrite planning treats cutover as instant, but real users overlap clients for days/weeks.

**How to avoid:**
- Define temporary dual-client sync protocol: idempotent write IDs, timestamps, deterministic conflict policy.
- Add migration metadata versioning in records.
- Instrument conflict counters and alert thresholds in production.

**Warning signs:**
- Support reports “my completed workout disappeared/reverted.”
- Same workout appears twice with different set data.

**Phase to address:**
Phase 10 — Sync and migration protocol

---

### Pitfall 6: Auth/session parity mismatch across web, Android, iOS

**What goes wrong:**
Users appear signed in on one platform and signed out on another unexpectedly; sync queue stalls because auth refresh behavior differs by platform lifecycle.

**Why it happens:**
Auth is implemented as platform-specific UI flows without a common session lifecycle model.

**How to avoid:**
- Build one auth state machine shared by all platforms.
- Test token refresh, app background/foreground, and offline-login edge behavior per platform.
- Add explicit user-facing sync/auth status states (connected, pending, auth required).

**Warning signs:**
- Sync queue remains pending after reconnect until app restart.
- Token-expiry bugs only reproducible on one platform.

**Phase to address:**
Phase 10 — Auth + sync integration

---

### Pitfall 7: Underestimating plugin/platform drift in FlutterFire and ecosystem packages

**What goes wrong:**
Builds pass on one platform but fail on another due to package/platform version drift (iOS deployment targets, Android tooling, web compatibility).

**Why it happens:**
Dependencies are upgraded opportunistically without cross-platform lockstep validation.

**How to avoid:**
- Freeze a tested dependency matrix for Flutter, FlutterFire, and critical plugins.
- Gate dependency bumps behind 3-platform CI.
- Track official FlutterFire release notes for breaking changes before upgrades.

**Warning signs:**
- “Only iOS release build fails,” or “web-only runtime break after plugin upgrade.”
- Long-lived branch carrying unmerged dependency changes.

**Phase to address:**
Phase 9 and ongoing release hygiene

---

### Pitfall 8: UI parity without interaction parity (mobile-first ergonomics regress)

**What goes wrong:**
Screens look equivalent but one-handed/touch ergonomics regress (tap targets, bottom-nav safe areas, rest-timer behavior), reducing workout usability.

**Why it happens:**
Visual snapshot testing is used as parity proxy; interaction ergonomics are not measured.

**How to avoid:**
- Define ergonomic acceptance checks (thumb-zone reachability, 44px+ touch targets, timer interrupt behavior).
- Run on-device validation for Android and iOS before declaring parity.
- Include motion/performance budget checks for workout logging screens.

**Warning signs:**
- Increased mis-taps during set logging.
- Users abandoning in-progress logs on mobile.

**Phase to address:**
Phase 12 — UX polish and production readiness

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Build web first, “port” to mobile later | Fast early demos | Divergent architecture and expensive rework | Never for this milestone |
| Skip parity contract and rely on exploratory QA | Less upfront planning | Hidden offline regressions in production | Never |
| One-off platform auth logic | Faster initial implementation | Persistent session/sync inconsistency | Only in prototype spikes |
| No migration telemetry for conflicts | Fewer analytics tasks | Invisible data corruption risk | Never during cutover |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase Hosting + Flutter web router | Missing SPA rewrites | Add rewrite to `/index.html`, test deep-link refresh in CI |
| FlutterFire auth + offline queue | Treat auth state as UI-only | Model auth and sync as shared state machine with retries/backoff |
| Legacy web + Flutter cutover | Assume single-client usage | Design dual-client conflict strategy and idempotent writes |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded local query patterns on web storage | Slow dashboard/progress load on web | Add indexed query design and pagination from start | Medium data volumes (~months of logs) |
| Rendering-heavy progress charts without profiling | Jank on low-end phones | Profile chart redraws and cache computed aggregates | Mid-tier devices under workout history growth |
| Sync-on-every-change without batching | Battery/network churn, UI hitching | Batch + debounce + background-friendly flush policies | Frequent set logging sessions |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Shipping permissive Firebase rules during migration | Unauthorized read/write | Enforce least-privilege rules and stage-specific rule tests |
| Treating local cache as trusted source for privileged actions | Tampering risk | Re-validate privileged operations server-side |
| Weak environment separation across dev/stage/prod | Data leakage or accidental prod writes | Strict project/environment isolation and CI guardrails |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Offline state hidden or ambiguous | User distrusts saved workouts | Persistent, clear offline/sync status indicators |
| Silent conflict resolution without user messaging | “My data changed unexpectedly” | Deterministic policy + user-visible “updated from another device” cues |
| Installability and app-shell treated as secondary | Web feels unreliable vs old app | First-class hosting + offline + deep-link QA gates |

## "Looks Done But Isn't" Checklist

- [ ] **Offline parity:** Verify full workout lifecycle offline on web, Android, and iOS (not just read-only screens).
- [ ] **Storage durability:** Verify data survives app restart, browser restart, and reconnect scenarios.
- [ ] **Routing/deep links:** Verify direct URL open + refresh on all major routes in Firebase preview and production.
- [ ] **Cutover safety:** Verify dual-client conflict handling with deterministic outcomes.
- [ ] **Auth/sync resilience:** Verify token expiry + reconnect + pending queue flush.
- [ ] **Ergonomics parity:** Verify one-handed/touch target behavior in active workout flows on real devices.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Offline parity regression discovered late | HIGH | Freeze feature work, restore parity contract tests, patch data layer first |
| Route/deep-link 404s in prod | MEDIUM | Hotfix Hosting rewrites, invalidate cache, run synthetic deep-link monitors |
| Cutover conflict corruption | HIGH | Pause writes if needed, run reconciliation job, communicate user impact, backfill from logs |
| Platform-specific auth drift | MEDIUM | Patch session state machine, force re-auth for stale clients, add regression tests |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Offline parity regression | Phase 9 | Contract tests pass across web/Android/iOS offline scenarios |
| Wrong DB choice for web parity | Phase 9 | Storage spike report signed off with platform caveats and test evidence |
| Service worker/default offline assumption drift | Phase 10 | Explicit offline strategy doc + passing offline tests in CI |
| Dual-client sync conflicts | Phase 10 | Conflict simulation tests + production conflict metrics baseline |
| Firebase Hosting deep-link failures | Phase 11 | Automated deep-link refresh tests green in preview/prod |
| UX interaction parity regressions | Phase 12 | Device QA checklist passed for workout logging ergonomics |

## Sources

- Firebase Hosting full config (SPA rewrites): https://firebase.google.com/docs/hosting/full-config
- Firebase Hosting Flutter integration: https://firebase.google.com/docs/hosting/frameworks/flutter
- Flutter supported platforms: https://docs.flutter.dev/reference/supported-platforms
- Flutter web docs: https://docs.flutter.dev/platform-integration/web
- Flutter announce: default web service worker removal/deprecation context: https://groups.google.com/g/flutter-announce/c/0Vv-j_TyrdI
- Flutter tracking issue for service worker deprecation/removal: https://github.com/flutter/flutter/issues/156910
- Flutter web FAQ (service worker deprecation mention): https://docs.flutter.dev/platform-integration/web/faq
- sqflite package platform support (web experimental via ffi web): https://pub.dev/packages/sqflite
- Isar limitations (web caveats): https://isar.dev/limitations
- Drift web platform and storage implementation caveats: https://drift.simonbinder.eu/platforms/web/
- Drift web storage API behavior: https://pub.dev/documentation/drift/latest/web/DriftWebStorage-class.html

---
*Pitfalls research for: Flutter multi-platform migration of Sundee-Fundee*
*Researched: 2026-02-20*
# Project Milestones: Sundee-Fundee

## v1.2 UAT Access + Onboarding Reliability (Shipped: 2026-02-25)

**Delivered:** Restored Firestore access reliability for core training surfaces, eliminated onboarding false prompts for returning users, added workout write durability with sync recovery, wired the GitHub Actions CI integration lane, and captured automated test evidence closing QA-02.

**Phases completed:** 8–12 (12 plans total)

**Key accomplishments:**
- Fixed enrollment contract drift with legacy-safe normalization and recoverable access lifecycle model (validEmpty / recoverableFailure / blockingFailure) with auto-retry UX.
- Shipped workout write durability: pending intent queue, sync-gated finish flow, and manual retry UX for unresolved completion sync.
- Eliminated onboarding false prompts via deterministic bootstrap evaluator, auto-heal for stale flags, and clear restart-reset contract.
- Hardened injury-first resume/restart UX with one-time legacy recovery notice and bootstrap matrix regression guardrails.
- Wired GitHub Actions `quality-integration` CI lane with Linux desktop + xvfb-run, replacing Firebase emulator approach.
- Closed QA-02: automated `critical_access_flow_test.dart` provider-override evidence for full `login → dashboard → programs → workout start` journey.

**Stats:**
- 5 phases, 12 plans
- Timeline: 2026-02-24 to 2026-02-25

**Git range:** `9968c60` → `741533a`

**Tech debt carried forward:** QA-01 CI confirmation pending; dashboard UX inconsistencies (raw error text, no-op CTAs).

**What's next:** Start next milestone definition with `/gsd-new-milestone`.

---

## v1.1 Onboarding Persistence + Injury-Aware Plans (Shipped: 2026-02-24)

**Delivered:** Account-level onboarding persistence, injury-aware adaptation/disclaimer flows, and safe plan cancellation with guarded re-enrollment and history integrity.

**Phases completed:** 5-7 (10 plans total)

**Key accomplishments:**
- Implemented canonical onboarding/injury profile persistence with legacy-safe normalization and rules hardening.
- Added bootstrap routing for onboarding resume/restart and injury-required gating across auth flows.
- Shipped deterministic injury adaptation engine plus provider wiring and per-injury disclaimer acknowledgment persistence.
- Added injury-aware UI gates and workout execution controls (recovery prep, replacement labeling, revert warnings).
- Delivered explicit enrollment lifecycle, two-step cancellation UX, and canceled-state surfaces across programs/workout/dashboard.
- Added guarded restore-vs-new re-enrollment and persisted workout enrollment markers for post-cancel history integrity.

**Stats:**
- 86 files changed
- 10,636 insertions, 432 deletions
- 3 phases, 10 plans, 24 tasks
- Timeline: 2026-02-23 to 2026-02-24

**Git range:** `2da651e` -> `821707b`

**What's next:** Start next milestone definition with `$gsd-new-milestone`.

---

## v1 Foundation Release (Shipped: 2026-02-23)

**Delivered:** Stable cycle-aware strength training app with verified week-by-week progression and clean full-suite evidence.

**Phases completed:** 1-4 (14 plans total)

**Key accomplishments:**
- Hardened auth/session and Firestore contract baseline with deterministic tests.
- Converted progression flow to explicit week-complete + jump semantics.
- Implemented female cycle-aware workout adaptation and surface-level explainability.
- Added shared sync confidence UX and offline/reconnect documentation.
- Stabilized full test suite to clean `flutter analyze` + full `flutter test`.

**Stats:**
- 286 files changed
- 28,107 insertions
- 4 phases, 14 plans, 42 tasks
- Timeline: 2026-02-15 to 2026-02-23

**Git range:** `31d07eb` -> `c0aa08b`

**What's next:** Start v2 milestone planning.

---

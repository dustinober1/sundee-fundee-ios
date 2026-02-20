# Roadmap: Strength (Workout Tracker)

## Overview

v2.0 is a full Flutter rewrite of Sundee-Fundee with behavior parity to v1.1 across web, Android, and iOS. The roadmap is organized around delivery boundaries that users can verify directly: foundation/parity harness, core workflows, insights, sync, and production cutover. Every v2.0 requirement is mapped to exactly one phase with observable success criteria.

## Milestones

- ✅ **v1.0 MVP** — Phases 1-4 (shipped 2026-02-19) · [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Sundee-Fundee** — Phases 5-8 (shipped 2026-02-20) · [archive](milestones/v1.1-ROADMAP.md)
- 📋 **v2.0 Flutter Full Rewrite** — Phases 9-14 (planned)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-4) — SHIPPED 2026-02-19</summary>

- [x] Phase 1: Smart Guidance (3/3 plans) — completed 2026-02-18
- [x] Phase 2: Visual Progress (3/3 plans) — completed 2026-02-19
- [x] Phase 3: Cloud Sync (3/3 plans) — completed 2026-02-19
- [x] Phase 4: E2E Verification (2/2 plans) — completed 2026-02-19

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

---

<details>
<summary>✅ v1.1 Sundee-Fundee (Phases 5-8) — SHIPPED 2026-02-20</summary>

- [x] Phase 5: Rebrand (1/1 plans) — completed 2026-02-20
- [x] Phase 6: PWA Foundation (2/2 plans) — completed 2026-02-20
- [x] Phase 7: Service Worker (2/2 plans) — completed 2026-02-20
- [x] Phase 8: Install Experience + Icon Enrichment (2/2 plans) — completed 2026-02-20

Full details: [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)

</details>

---

### 📋 v2.0 Flutter Full Rewrite (Planned)

**Milestone Goal:** Users get v1.1-equivalent workout tracking outcomes in a Flutter app on web, Android, and iOS, with production-ready deployment and safe cutover.

### Phase 9: Cross-Platform Foundation + Parity Gates
**Goal**: Users can run the Flutter app on web, Android, and iOS with explicit parity test gates in place before feature migration proceeds.
**Depends on**: Phase 8
**Requirements**: PLAT-01, QUAL-01, QUAL-02
**Success Criteria** (what must be TRUE):
  1. User can launch and navigate the Flutter app on web, Android, and iOS from the same product baseline.
  2. A tester can execute cross-platform acceptance tests for critical flows and get explicit pass/fail parity results.
  3. A tester can run offline parity scenarios (offline use, reconnect, persistence) on all 3 platforms and verify they pass.
**Plans**: TBD

Plans:
- [ ] 09-01: TBD (run /gsd-plan-phase 9 to break down)

### Phase 10: Onboarding + Program/Cycle Parity
**Goal**: Users can set up their profile and manage training programs/cycles in Flutter with v1.1-equivalent behavior.
**Depends on**: Phase 9
**Requirements**: ONBD-01, ONBD-02, PROG-01, PROG-02
**Success Criteria** (what must be TRUE):
  1. User can complete onboarding with the same required fields and completion rules as v1.1.
  2. User profile data remains available after app restart on web, Android, and iOS.
  3. User can browse the same program catalog structure and metadata as v1.1.
  4. User can start and track active cycles with behavior matching v1.1.
**Plans**: TBD

Plans:
- [ ] 10-01: TBD (run /gsd-plan-phase 10 to break down)

### Phase 11: Workout Logging + Rest + Offline Continuity
**Goal**: Users can complete the full workout logging loop in Flutter, including rest timing and offline continuity.
**Depends on**: Phase 10
**Requirements**: WORK-01, WORK-02, WORK-03
**Success Criteria** (what must be TRUE):
  1. User can log sets (reps/weight), complete workouts, and see saved workout results with v1.1-equivalent semantics.
  2. User can use rest-timer behavior during active workouts with equivalent workflow to v1.1.
  3. User can keep logging workouts while offline and see local workout state preserved after reconnect.
**Plans**: TBD

Plans:
- [ ] 11-01: TBD (run /gsd-plan-phase 11 to break down)

### Phase 12: Recommendations + Progress Insights Parity
**Goal**: Users receive the same coaching outcomes and progress insights in Flutter as in v1.1.
**Depends on**: Phase 11
**Requirements**: RECO-01, RECO-02, CHRT-01, CHRT-02
**Success Criteria** (what must be TRUE):
  1. User receives recommendation outputs equivalent to v1.1 for equivalent workout history inputs.
  2. User sees PR and plateau outcomes that match v1.1 decision logic.
  3. User can view 1RM trend, weekly volume, and activity insights with calculation parity to v1.1.
  4. User can open progress insights from local data without needing an active network.
**Plans**: TBD

Plans:
- [ ] 12-01: TBD (run /gsd-plan-phase 12 to break down)

### Phase 13: Supabase Sync Parity (Optional Cloud)
**Goal**: Users can use optional Supabase auth/sync in Flutter with local-first sync semantics and clear status feedback.
**Depends on**: Phase 11
**Requirements**: SYNC-01, SYNC-02, SYNC-03
**Success Criteria** (what must be TRUE):
  1. User can optionally authenticate and sync workout data from the Flutter app using Supabase-backed sync.
  2. User sees sync states (`offline`, `pending`, `syncing`, `synced`, `error`) with v1.1-equivalent semantics.
  3. User writes are persisted locally first, then queued/retried to cloud automatically when connectivity returns.
**Plans**: TBD

Plans:
- [ ] 13-01: TBD (run /gsd-plan-phase 13 to break down)

### Phase 14: Release Hardening + Cutover Safety
**Goal**: Users can safely transition to the Flutter app in production without silent data loss or deployment breakage.
**Depends on**: Phase 12, Phase 13
**Requirements**: PLAT-02, DATA-01, DPLY-01, DPLY-02, DPLY-03
**Success Criteria** (what must be TRUE):
  1. User gets equivalent behavior outcomes across web, Android, and iOS for the same workout inputs.
  2. Existing user data has a defined migration/continuity path with no silent data loss during cutover.
  3. User can open and refresh deep links on Firebase-hosted web routes without 404 errors.
  4. Team can produce reproducible signed Android and iOS release builds from pipeline.
  5. Production rollout uses defined telemetry thresholds and a tested rollback path.
**Plans**: TBD

Plans:
- [ ] 14-01: TBD (run /gsd-plan-phase 14 to break down)

## Progress

| Phase | Milestone | Goal | Requirements | Plans Complete | Status | Completed |
|-------|-----------|------|--------------|----------------|--------|-----------|
| 1. Smart Guidance | v1.0 | Smart weight recommendations | RECOM-01/02/03 | 3/3 | ✅ Complete | 2026-02-18 |
| 2. Visual Progress | v1.0 | Progress visualization | CHART-01/02/03 | 3/3 | ✅ Complete | 2026-02-19 |
| 3. Cloud Sync | v1.0 | Supabase backup + restore | SYNC-01/02/03 | 3/3 | ✅ Complete | 2026-02-19 |
| 4. E2E Verification | v1.0 | Verified test coverage | TEST-01/02/03 | 2/2 | ✅ Complete | 2026-02-19 |
| 5. Rebrand | v1.1 | Sundee-Fundee everywhere | BRAND-01/02/03 | 1/1 | ✅ Complete | 2026-02-20 |
| 6. PWA Foundation | v1.1 | Installable PWA basics | PWA-01/02/04/05/06 | 2/2 | ✅ Complete | 2026-02-20 |
| 7. Service Worker | v1.1 | Offline shell + caching | PWA-03 | 2/2 | ✅ Complete | 2026-02-20 |
| 8. Install + Icon Polish | v1.1 | Install UX + icon enrichment | INSTALL-01/02, ICON-01/02/03/04 | 2/2 | ✅ Complete | 2026-02-20 |
| 9. Foundation + Parity Gates | v2.0 | Flutter baseline + test gates | PLAT-01, QUAL-01, QUAL-02 | 0/TBD | Not started | - |
| 10. Onboarding + Programs | v2.0 | Onboarding + catalog/cycles parity | ONBD-01/02, PROG-01/02 | 0/TBD | Not started | - |
| 11. Workout Flow | v2.0 | Logging + rest + offline continuity | WORK-01/02/03 | 0/TBD | Not started | - |
| 12. Insights Parity | v2.0 | Recommendations + progress parity | RECO-01/02, CHRT-01/02 | 0/TBD | Not started | - |
| 13. Supabase Sync | v2.0 | Optional auth/sync parity | SYNC-01/02/03 | 0/TBD | Not started | - |
| 14. Release + Cutover | v2.0 | Production hardening + safe migration | PLAT-02, DATA-01, DPLY-01/02/03 | 0/TBD | Not started | - |

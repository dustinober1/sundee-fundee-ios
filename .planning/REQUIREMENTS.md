# Requirements: Sundee-Fundee v2.0 Flutter Full Rewrite

**Defined:** 2026-02-20
**Core Value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.

## v2.0 Requirements

Requirements for the v2.0 milestone. These define full feature parity in Flutter across web, Android, and iOS.

### Platform Foundation

- [x] **PLAT-01**: User can use Sundee-Fundee from a Flutter application on web, Android, and iOS.
- [ ] **PLAT-02**: User gets equivalent behavior outcomes across all 3 platforms for the same workout inputs.

### Onboarding

- [x] **ONBD-01**: User can complete onboarding with the same required profile fields and completion rules as v1.1.
- [x] **ONBD-02**: User profile data persists locally and remains available after app restart on each platform.

### Programs & Cycles

- [x] **PROG-01**: User can browse the same program catalog with equivalent structure and metadata as v1.1.
- [x] **PROG-02**: User can start and track active cycles with behavior equivalent to v1.1.

### Workout Flow

- [ ] **WORK-01**: User can log sets (reps/weight), complete workouts, and persist results with v1.1-equivalent semantics.
- [ ] **WORK-02**: User can use rest-timer workflow behavior equivalent to v1.1 during active workouts.
- [ ] **WORK-03**: User can continue workout logging offline and retain local workout state through reconnect.

### Recommendations / PR / Plateau

- [ ] **RECO-01**: User receives recommendation outputs equivalent to v1.1 for equivalent workout history inputs.
- [ ] **RECO-02**: User gets PR and plateau outcomes that match v1.1 decision logic.

### Progress Insights

- [ ] **CHRT-01**: User can view 1RM trend, weekly volume, and activity insights with calculation parity to v1.1.
- [ ] **CHRT-02**: User can access progress insights from local data without requiring an active network.

### Sync (Supabase retained in v2.0)

- [ ] **SYNC-01**: User can optionally authenticate and sync data using Supabase-backed sync from the Flutter app.
- [ ] **SYNC-02**: User sees sync status states (`offline`, `pending`, `syncing`, `synced`, `error`) equivalent to v1.1 semantics.
- [ ] **SYNC-03**: User writes are local-first and queued/retried for cloud sync when connectivity returns.

### Data Continuity

- [ ] **DATA-01**: Existing users have a defined migration/continuity path with no silent data loss during cutover.

### Deployment & Release

- [ ] **DPLY-01**: User can open and refresh deep links on Firebase-hosted web routes without 404 failures.
- [ ] **DPLY-02**: Team can produce reproducible signed Android and iOS release builds via pipeline.
- [ ] **DPLY-03**: Production rollout includes cutover safety controls (telemetry thresholds and rollback path).

### Quality Gates

- [x] **QUAL-01**: Critical flows have cross-platform acceptance tests with explicit parity pass criteria.
- [x] **QUAL-02**: Offline parity scenarios pass on web, Android, and iOS before release.

## Future Requirements (Post-v2.0)

### UX & Observability Enhancements

- **UXOP-01**: User can see enhanced sync transparency (source device and last-sync timestamp details).
- **UXOP-02**: User gets platform-adaptive chart interactions while preserving data interpretation consistency.
- **UXOP-03**: Team has first-class performance/crash instrumentation dashboards for ongoing optimization.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Social/community features | Scope expansion unrelated to parity objective |
| Wearables/live sensor integrations | High integration variance; defer until parity is stable |
| Real-time collaborative conflict tooling | High complexity beyond current solo-use core value |
| Pixel-identical UI across all platforms | Behavior parity is required; exact pixel parity is not |
| Nutrition tracking | Not part of workout-tracking parity scope |
| Video analysis | Storage/bandwidth heavy; not required for parity milestone |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLAT-01 | Phase 9 | Complete |
| PLAT-02 | Phase 14 | Pending |
| ONBD-01 | Phase 10 | Complete |
| ONBD-02 | Phase 10 | Complete |
| PROG-01 | Phase 10 | Complete |
| PROG-02 | Phase 10 | Complete |
| WORK-01 | Phase 11 | Pending |
| WORK-02 | Phase 11 | Pending |
| WORK-03 | Phase 11 | Pending |
| RECO-01 | Phase 12 | Pending |
| RECO-02 | Phase 12 | Pending |
| CHRT-01 | Phase 12 | Pending |
| CHRT-02 | Phase 12 | Pending |
| SYNC-01 | Phase 13 | Pending |
| SYNC-02 | Phase 13 | Pending |
| SYNC-03 | Phase 13 | Pending |
| DATA-01 | Phase 14 | Pending |
| DPLY-01 | Phase 14 | Pending |
| DPLY-02 | Phase 14 | Pending |
| DPLY-03 | Phase 14 | Pending |
| QUAL-01 | Phase 9 | Complete |
| QUAL-02 | Phase 9 | Complete |

**Coverage:**
- v2.0 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-02-20*
*Last updated: 2026-02-21 after Phase 9 completion*

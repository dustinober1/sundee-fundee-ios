# Requirements: Strength (Workout Tracker)

**Defined:** 2026-02-17
**Core Value:** Users can reliably track their strength training progress offline and receive actionable insights to improve performance.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Recommendations

- [x] **RECOM-01**: User receives weight suggestions for next workout based on rules (e.g. 5lb increase)
- [x] **RECOM-02**: System detects plateaus (3+ workouts without progress) and notifies user
- [x] **RECOM-03**: User sees confetti celebration when setting a new PR

### Charts

- [ ] **CHART-01**: User can view line chart of 1RM progress over time per exercise
- [ ] **CHART-02**: User can view bar chart of weekly volume load
- [ ] **CHART-03**: User can view workout frequency heatmap (GitHub style)

### Sync

- [ ] **SYNC-01**: User data automatically backs up to Supabase when online
- [ ] **SYNC-02**: User can restore data from cloud to a new device
- [ ] **SYNC-03**: User sees visual indicator of sync status (synced, pending, offline)

### Testing

- [ ] **TEST-01**: E2E test verifies user can complete full workout flow
- [ ] **TEST-02**: E2E test verifies PR celebration triggers correctly
- [ ] **TEST-03**: E2E test verifies data syncs to remote mock

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Recommendations

- **RECOM-V2-01**: Deload week suggestions based on fatigue indicators
- **RECOM-V2-02**: Warm-up set calculator

### Social

- **SOC-V2-01**: Share workout summary image to social media
- **SOC-V2-02**: Follow friends and view their logs

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Real-time social feed | High complexity, dilutes focus on individual progress |
| Video analysis | High bandwidth/storage costs, better tools exist |
| Native mobile app | Web-first covers 90% of needs, PWA installable |
| Nutrition tracking | Focus is on training, plenty of dedicated food apps |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RECOM-01 | Phase 1 | Complete |
| RECOM-02 | Phase 1 | Complete |
| RECOM-03 | Phase 1 | Complete |
| CHART-01 | Phase 2 | Pending |
| CHART-02 | Phase 2 | Pending |
| CHART-03 | Phase 2 | Pending |
| SYNC-01 | Phase 3 | Pending |
| SYNC-02 | Phase 3 | Pending |
| SYNC-03 | Phase 3 | Pending |
| TEST-01 | Phase 4 | Pending |
| TEST-02 | Phase 4 | Pending |
| TEST-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-17*
*Last updated: 2026-02-18 with Phase 1 completion*

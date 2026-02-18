# Roadmap: Strength (Workout Tracker)

**Phase Strategy:** Dependency-driven delivery of remaining v1 features.
1. **Smart Guidance** enhances the core loop immediately.
2. **Visual Progress** provides long-term retention value.
3. **Cloud Sync** secures the data generated in phases 1 & 2.
4. **E2E Verification** solidifies the release for production.

## Phases

- [x] **Phase 1: Smart Guidance** - Implement weight recommendations, plateau detection, and PR celebrations.
  Plans:
  - [x] 01-01-PLAN.md — Wire workout data persistence + DB schema v4 + Tooltip component
  - [x] 01-02-PLAN.md — Build recommendation engine, plateau detection, PR detection logic
  - [x] 01-03-PLAN.md — Integrate recommendation UI, PR celebrations, plateau modals into workout flow
- [ ] **Phase 2: Visual Progress** - Build 1RM charts, volume visualization, and activity heatmaps.
- [ ] **Phase 3: Cloud Sync** - Implement Supabase backup, cross-device restore, and sync status UI.
- [ ] **Phase 4: E2E Verification** - Automate testing for critical user flows and sync reliability.

## Phase Details

### Phase 1: Smart Guidance
**Goal**: Users receive actionable guidance and feedback during their training.
**Depends on**: Existing Core Loop (Tasks 1-15)
**Requirements**: RECOM-01, RECOM-02, RECOM-03
**Plans:** 3 plans
**Success Criteria**:
  1. User sees a specific weight suggestion for their next set based on previous performance.
  2. User is notified when they have stalled on an exercise for 3+ sessions.
  3. User sees a visual celebration (confetti) immediately upon logging a PR.
  4. User can accept or manually override the recommended weight.

### Phase 2: Visual Progress
**Goal**: Users can visualize their strength progress and training habits over time.
**Depends on**: Phase 1 (Data accumulation)
**Requirements**: CHART-01, CHART-02, CHART-03
**Success Criteria**:
  1. User can view a line graph showing their estimated 1RM increase over time for a specific exercise.
  2. User can see a bar chart representing total volume lifted per week.
  3. User can view a contribution graph (heatmap) showing workout frequency over the last year.
  4. Charts handle empty states gracefully for new users.

### Phase 3: Cloud Sync
**Goal**: User data is securely backed up and retrievable on other devices.
**Depends on**: Phase 2
**Requirements**: SYNC-01, SYNC-02, SYNC-03
**Success Criteria**:
  1. User data is automatically uploaded to Supabase after finishing a workout.
  2. User can log in on a fresh device and see their previous workout history.
  3. User sees a visual "Synced" checkmark or "Offline" indicator in the UI.
  4. User can continue using the app offline without errors, with sync queuing for later.

### Phase 4: E2E Verification
**Goal**: Critical user flows are protected against regression.
**Depends on**: Phase 3 (Full feature set)
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria**:
  1. CI pipeline passes a test simulating a complete workout from start to finish.
  2. Automated test confirms PR celebration triggers correctly.
  3. Automated test verifies local data appears in remote mock after sync.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Smart Guidance | 3/3 | Complete | 2026-02-18 |
| 2. Visual Progress | 0/3 | Not started | - |
| 3. Cloud Sync | 0/3 | Not started | - |
| 4. E2E Verification | 0/3 | Not started | - |

# Roadmap: Sundee Fundee v2

## Overview

Three phases build on the existing SwiftUI/CloudKit/HealthKit codebase. Phase 1 delivers the recovery score — the core value proposition of v2 — including HealthKit sleep integration, the scoring engine, and the dashboard UI. Phase 2 adds deload automation, which consumes the recovery score as its primary trigger signal. Phase 3 delivers the social layer, which is architecturally independent but ships last because its activity feed is seeded by events validated in the earlier phases.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Recovery Score Foundation** - Users see a daily 0-100 recovery score on the dashboard, backed by HRV, sleep, training load, cycle phase, and pain logs
- [ ] **Phase 2: Deload Detection and Active Recovery** - App detects fatigue signals and suggests a deload week with active recovery programming after user confirmation
- [ ] **Phase 3: Social Layer** - Users can add friends via invite link, view an activity feed, and high-five friends' PRs and workouts

## Phase Details

### Phase 1: Recovery Score Foundation
**Goal**: Users always know whether today is a push day or a rest day — the recovery score is visible on the dashboard and backed by real biometric and training data
**Depends on**: Nothing (first phase)
**Requirements**: HK-01, HK-02, HK-03, REC-01, REC-02, REC-03, REC-04, REC-05, REC-06
**Success Criteria** (what must be TRUE):
  1. User sees a color-coded 0-100 recovery score on the dashboard every time the app opens
  2. User can tap the score card to see a breakdown screen showing each input's contribution (HRV, sleep, load, cycle phase, pain)
  3. User can view a 30-day recovery trend chart with cycle phase color bands
  4. Score computes correctly when Apple Watch or HealthKit permissions are absent — missing components are omitted and weights redistributed, score is not blank
  5. HRV does not read as "low recovery" every luteal phase — per-phase HRV baseline normalizes the score against cycle phase expectation
**Plans**: 5 plans
Plans:
- [x] 01-01-PLAN.md — Pure domain recovery score calculator with TDD (types, sub-scorers, HRV normalization)
- [x] 01-02-PLAN.md — HealthKit sleep integration and sleep deduplication with TDD
- [ ] 01-03-PLAN.md — RecoveryScoreRecord CloudKit model and RecoveryScoreViewModel
- [ ] 01-04-PLAN.md — AppTheme recovery tokens, RecoveryScoreCard, InputBarRow UI components
- [ ] 01-05-PLAN.md — Dashboard integration, RecoveryBreakdownView, RecoveryTrendChart, visual verification
**UI hint**: yes

### Phase 2: Deload Detection and Active Recovery
**Goal**: Users receive a data-backed deload suggestion when fatigue signals accumulate, and can confirm a full active recovery week that replaces lifting with mobility and cardio
**Depends on**: Phase 1
**Requirements**: DLD-01, DLD-02, DLD-03, DLD-04
**Success Criteria** (what must be TRUE):
  1. App surfaces a deload suggestion sheet when consecutive low recovery scores, high ACWR, or plateau flags accumulate — with a clear explanation of which signals triggered it
  2. User must explicitly confirm before any program changes take effect — no silent auto-enrollment
  3. Confirmed deload replaces the current week's lifting sessions with mobility, yoga, and light cardio alternatives
  4. After accepting or dismissing a deload suggestion, no new suggestion appears for 4 weeks
**Plans**: TBD

### Phase 3: Social Layer
**Goal**: Users can connect with friends via invite link, follow their PRs and workout completions in a shared activity feed, and react with a high-five
**Depends on**: Phase 1, Phase 2
**Requirements**: SOC-01, SOC-02, SOC-03, SOC-04, SOC-05, SOC-06
**Success Criteria** (what must be TRUE):
  1. User can generate and share an invite link via Messages, AirDrop, or share sheet, and the recipient appears in their friends list after accepting
  2. User can view an activity feed showing friends' PRs, workout completions, and challenge achievements in reverse chronological order
  3. User can tap a high-five button on any friend's feed item as a reaction
  4. User has a profile page showing their training stats (total workouts, PRs, streaks) that friends can view
  5. Friend activity persists and loads correctly across app restarts — data is stored in CloudKit shared zones, not only in memory
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Recovery Score Foundation | 0/5 | Planning complete | - |
| 2. Deload Detection and Active Recovery | 0/TBD | Not started | - |
| 3. Social Layer | 0/TBD | Not started | - |

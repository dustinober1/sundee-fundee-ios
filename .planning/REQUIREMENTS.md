# Requirements: Sundee Fundee v2

**Defined:** 2026-04-15
**Core Value:** Users always know whether today is a push day or a rest day — the recovery score is the single source of truth for training readiness.

## v1 Requirements

Requirements for v2 release. Each maps to roadmap phases.

### Recovery Score

- [ ] **REC-01**: User sees a daily 0-100 recovery score on the dashboard, color-coded green/yellow/red
- [ ] **REC-02**: Recovery score is computed on app foreground from up to 5 inputs: HRV, sleep, training volume (ACWR), cycle phase, and pain logs
- [ ] **REC-03**: User can tap the dashboard score card to see a breakdown screen showing each input's contribution
- [ ] **REC-04**: HRV baseline is normalized per cycle phase so luteal-phase HRV drops don't trigger false low scores
- [ ] **REC-05**: User can view recovery score trends over time on a chart correlated with cycle phase
- [ ] **REC-06**: Recovery score degrades gracefully when HealthKit permissions are denied or Apple Watch is absent (components with no data are omitted and weight redistributed)

### HealthKit Sleep

- [ ] **HK-01**: App requests HealthKit sleep analysis authorization
- [ ] **HK-02**: App reads sleep duration and quality from HealthKit (HKCategoryType.sleepAnalysis)
- [ ] **HK-03**: Sleep samples from multiple sources (Watch + iPhone) are deduplicated to avoid inflated duration

### Deload Automation

- [ ] **DLD-01**: App auto-detects deload need from multiple signals: consecutive low recovery scores, high ACWR, plateau detector flags
- [ ] **DLD-02**: User receives a deload suggestion with clear explanation of why, and must confirm before any changes
- [ ] **DLD-03**: Confirmed deload generates an active recovery week with mobility, yoga, and light cardio replacing lifting
- [ ] **DLD-04**: A 4-week cooldown prevents repeated deload suggestions after one is accepted or dismissed

### Social

- [ ] **SOC-01**: User can add friends via invite link shared through Messages, AirDrop, or share sheet
- [ ] **SOC-02**: User can accept a friend invite and see the sender in their friends list
- [ ] **SOC-03**: User has a profile page showing training stats (total workouts, PRs, streaks)
- [ ] **SOC-04**: User can view an activity feed showing friends' PRs, workout completions, and challenge achievements
- [ ] **SOC-05**: User can high-five a friend's activity item as a reaction
- [ ] **SOC-06**: Social data is stored via CloudKit shared zones — each user owns their activity zone, friends subscribe as participants

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Recovery Enhancements

- **REC-07**: Resting heart rate as an additional recovery input
- **REC-08**: Recovery score notifications (morning push with score)
- **REC-09**: Rest day active recovery suggestions based on score level (specific mobility routines)

### Social Enhancements

- **SOC-07**: Enhanced share cards with recovery score overlay
- **SOC-08**: Weekly digest of friend activity
- **SOC-09**: Friend comparison charts (opt-in)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Friend search/discovery | CloudKit `CKDiscoverUserIdentitiesOperation` is deprecated with no replacement — invite-link only |
| Leaderboards/competitive ranking | Against app values — social should be supportive, not competitive |
| Direct messaging | Adds moderation burden, out of scope for a fitness app |
| Photo sharing in feed | Storage/bandwidth cost, deferred indefinitely |
| Background delivery for score | Unreliable (watchdog throttling) — compute lazily on foreground |
| Nutrition/macro tracking | Separate domain, doesn't strengthen core value |
| Body composition tracking | Deferred to v3 |
| RPE per-set tracking | Recovery score covers fatigue at a higher level |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REC-01 | — | Pending |
| REC-02 | — | Pending |
| REC-03 | — | Pending |
| REC-04 | — | Pending |
| REC-05 | — | Pending |
| REC-06 | — | Pending |
| HK-01 | — | Pending |
| HK-02 | — | Pending |
| HK-03 | — | Pending |
| DLD-01 | — | Pending |
| DLD-02 | — | Pending |
| DLD-03 | — | Pending |
| DLD-04 | — | Pending |
| SOC-01 | — | Pending |
| SOC-02 | — | Pending |
| SOC-03 | — | Pending |
| SOC-04 | — | Pending |
| SOC-05 | — | Pending |
| SOC-06 | — | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19

---
*Requirements defined: 2026-04-15*
*Last updated: 2026-04-15 after initial definition*

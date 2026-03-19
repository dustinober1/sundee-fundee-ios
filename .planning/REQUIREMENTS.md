# Requirements: Sundee Fundee (Swift Rebuild)

**Defined:** 2026-03-18
**Core Value:** Users get personalized, cycle-aware strength training that adapts to their body — with seamless sync across iPhone and Apple Watch.

## v1 Requirements

Requirements for App Store launch. Each maps to roadmap phases.

### Bug Fixes

- [x] **FIX-01**: AI workout generation prescribes weights in the user's selected unit (lbs or kg), not hardcoded lbs
- [x] **FIX-02**: Sign-out and account deletion wipe all model types through current schema (V12), not stale V10 references
- [x] **FIX-03**: Guest mode uses a stable UUID as userID instead of empty string, preserving data on sign-in upgrade
- [x] **FIX-04**: Subscription tier defaults to free on cold launch until StoreKit verification completes, preventing brief premium access window
- [x] **FIX-05**: SwiftData migration plan is applied to both CloudKit and local persistent store paths

### CloudKit & Sync

- [ ] **SYNC-01**: CloudKit sync is activated in production with verified schema compliance (all optionals, no unique constraints, optional relationships with inverses)
- [ ] **SYNC-02**: CloudKit production schema is deployed via CloudKit Console before TestFlight distribution
- [ ] **SYNC-03**: User's workout data syncs across all their Apple devices via iCloud without manual intervention
- [ ] **SYNC-04**: Container open failure triggers a user-visible error instead of silently deleting the local store

### watchOS Companion — Core

- [ ] **WATCH-01**: watchOS app starts an HKWorkoutSession (Traditional Strength Training) that contributes to Activity rings
- [ ] **WATCH-02**: User can log sets (weight + reps) from Apple Watch during an active workout session
- [ ] **WATCH-03**: Watch displays current exercise name, target sets/reps, and previous best weight
- [ ] **WATCH-04**: Watch shows a rest timer countdown with haptic feedback on completion
- [ ] **WATCH-05**: Watch displays live heart rate and calories burned during workout (via HKLiveWorkoutBuilder)
- [ ] **WATCH-06**: User can end a workout from the Watch without needing the iPhone
- [ ] **WATCH-07**: Workout data logged on Watch appears in iPhone history after session ends
- [ ] **WATCH-08**: Watch app recovers active workout state if terminated and relaunched mid-workout

### watchOS Companion — Differentiators

- [ ] **WATCH-09**: Watch displays current cycle phase and adaptation rationale during active workout
- [ ] **WATCH-10**: Watch face complication shows cycle phase, streak count, or last workout date
- [ ] **WATCH-11**: Watch delivers haptic feedback when a personal record is set during workout

### Push Notifications (APNs)

- [ ] **NOTIF-01**: User receives a local push notification when rest timer expires while app is backgrounded
- [ ] **NOTIF-02**: User can schedule daily workout reminder push notifications at a chosen time
- [ ] **NOTIF-03**: User receives a push notification when a new WOD is published
- [ ] **NOTIF-04**: User receives a push notification when their workout streak is about to break
- [ ] **NOTIF-05**: User can toggle each notification type on/off in Settings, with preferences persisted

### Data & Analytics

- [ ] **DATA-01**: User can export their workout data as CSV files
- [ ] **DATA-02**: User can view weekly training volume charts (sets per muscle group, total volume over time)
- [ ] **DATA-03**: User sees cycle-phase-specific education copy explaining why today's workout was adapted

### App Store Readiness

- [ ] **STORE-01**: App Store metadata (description, keywords, screenshots) is complete and submitted
- [ ] **STORE-02**: Privacy policy is accessible from within the app
- [ ] **STORE-03**: Signed production binary is submitted to App Store Connect

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced watchOS

- **WATCH-20**: User can complete a workout on Watch without iPhone nearby (independent session)
- **WATCH-21**: AI workout generation results are viewable on Watch

### Advanced AI

- **AI-20**: AI workout generation uses full workout history for personalization (not just current context)

### HealthKit Write

- **HK-20**: Completed workouts are saved to Apple Health as HKWorkout records

### Content

- **CONT-20**: Exercise library includes still-image or video form demonstrations

## Out of Scope

| Feature | Reason |
|---------|--------|
| Android / Web targets | Customer requires Apple-only |
| React Native / cross-platform | Replaced by native Swift |
| Firebase / Firestore backend | Using CloudKit instead |
| RevenueCat | Using StoreKit 2 directly |
| Social feed / activity sharing | Distinct product surface, moderation burden, dilutes focus |
| Nutrition / macro tracking | Separate domain, not core to strength training |
| Real-time coaching / chat | AI generation + cycle adaptation serves this need |
| Video exercise library | Storage/CDN cost, defer to v2+ |
| Gamification (badges, points, leaderboards) | Shallow engagement vs training quality |
| iPad-specific layout | iPhone + Watch focus for v1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FIX-01 | Phase 1 | Complete |
| FIX-02 | Phase 1 | Complete |
| FIX-03 | Phase 1 | Complete |
| FIX-04 | Phase 1 | Complete |
| FIX-05 | Phase 1 | Complete |
| SYNC-01 | Phase 2 | Pending |
| SYNC-02 | Phase 2 | Pending |
| SYNC-03 | Phase 2 | Pending |
| SYNC-04 | Phase 2 | Pending |
| NOTIF-01 | Phase 3 | Pending |
| NOTIF-02 | Phase 3 | Pending |
| NOTIF-03 | Phase 3 | Pending |
| NOTIF-04 | Phase 3 | Pending |
| NOTIF-05 | Phase 3 | Pending |
| WATCH-01 | Phase 5 | Pending |
| WATCH-02 | Phase 5 | Pending |
| WATCH-03 | Phase 5 | Pending |
| WATCH-04 | Phase 5 | Pending |
| WATCH-05 | Phase 5 | Pending |
| WATCH-06 | Phase 5 | Pending |
| WATCH-07 | Phase 5 | Pending |
| WATCH-08 | Phase 5 | Pending |
| WATCH-09 | Phase 6 | Pending |
| WATCH-10 | Phase 6 | Pending |
| WATCH-11 | Phase 6 | Pending |
| DATA-01 | Phase 7 | Pending |
| DATA-02 | Phase 7 | Pending |
| DATA-03 | Phase 7 | Pending |
| STORE-01 | Phase 8 | Pending |
| STORE-02 | Phase 8 | Pending |
| STORE-03 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0 ✓

Note: Phase 4 (watchOS Scaffold) is a foundation phase with no isolated v1 requirements — it creates the XcodeGen target, shared domain package, minimal Watch schema, and WatchConnectivity service that make WATCH-01 through WATCH-11 verifiable in Phases 5 and 6.

---
*Requirements defined: 2026-03-18*
*Last updated: 2026-03-18 — traceability complete after roadmap creation*

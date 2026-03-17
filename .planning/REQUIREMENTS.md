# Requirements: Sundee Fundee v1.1

**Defined:** 2026-03-16
**Core Value:** Users get personalized, cycle-aware strength training that adapts to their body — available on any platform, online or offline.

## v1.1 Requirements

Requirements for launch readiness. Each maps to roadmap phases.

### Notifications

- [ ] **NOTIF-01**: User receives local push when rest timer expires while app is backgrounded
- [ ] **NOTIF-02**: User can grant notification permission via deferred prompt (after first workout, not cold launch)
- [ ] **NOTIF-03**: App registers FCM push token and stores it in Firestore under user document
- [ ] **NOTIF-04**: User receives remote push when a new WOD is published
- [ ] **NOTIF-05**: User receives remote push 3 days before and on subscription expiry
- [ ] **NOTIF-06**: User can configure notification preferences per type (rest timer, reminders, WOD, subscription) in Settings
- [ ] **NOTIF-07**: Workout reminder notifications include cycle-phase-aware copy when cycle tracking is enabled
- [ ] **NOTIF-08**: User can schedule daily workout reminder at a preferred time

### Analytics

- [ ] **ANLYT-01**: Firebase Analytics tracks screen views automatically via Expo Router
- [ ] **ANLYT-02**: Key events logged: workout_started, workout_completed, subscription_started, ai_workout_generated, cycle_phase_updated
- [ ] **ANLYT-03**: User properties set for subscription tier (free/premium) and cycle tracking opt-in
- [ ] **ANLYT-04**: Crashlytics captures native crashes and JS errors via recordError()
- [ ] **ANLYT-05**: Crashlytics custom keys attached: current screen, subscription tier, cycle phase
- [ ] **ANLYT-06**: OTA update capability via EAS Update for JS-layer hotfixes

### Security

- [ ] **SEC-01**: Firestore security rules deployed to production (auth-gated user docs, public read for programs/WODs)
- [ ] **SEC-02**: Firestore rules validated via Rules Simulator before deploy
- [ ] **SEC-03**: Firebase App Check confirmed active in production mode (DeviceCheck iOS, Play Integrity Android)
- [ ] **SEC-04**: PrivacyInfo.xcprivacy privacy manifest added with correct SDK declarations

### Store Submission

- [ ] **STORE-01**: EAS production build profiles configured for iOS and Android
- [ ] **STORE-02**: App Store Connect metadata complete (screenshots 6.7"/6.5", description, keywords, privacy policy URL)
- [ ] **STORE-03**: Play Store metadata complete (Health & Fitness declaration, data safety, screenshots)
- [ ] **STORE-04**: Age rating questionnaire completed for both stores
- [ ] **STORE-05**: Privacy policy accessible in-app from Settings screen
- [ ] **STORE-06**: App submitted to App Store and Play Store
- [ ] **STORE-07**: Web app deployed (Expo web build or EAS Hosting)

### Device Verification

- [x] **VERIFY-01**: All ~30 human verification items from v1.0 triaged and resolved
- [x] **VERIFY-02**: Core workout flow verified on iOS simulator and Android emulator
- [ ] **VERIFY-03**: Offline mode verified (airplane mode workout completion + sync on reconnect)
- [ ] **VERIFY-04**: Auth flows verified on all platforms (Apple, Google, Email, Guest, guest-to-auth upgrade)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Notifications

- **NOTIF-09**: Streak notification with motivational content
- **NOTIF-10**: Rich media notifications (images in push)
- **NOTIF-11**: Firebase Remote Config for A/B testing notification copy

### Analytics

- **ANLYT-07**: Funnel analysis dashboards in Firebase Console
- **ANLYT-08**: Custom retention cohort analysis

## Out of Scope

| Feature | Reason |
|---------|--------|
| Social features / friend activity | Not core to training value; moderation overhead |
| Video content / streaming | Storage/bandwidth cost; defer to future |
| Wearable integrations | Separate SDK targets; defer to post-launch |
| Nutrition tracking | Distinct domain; dilutes strength training focus |
| Sentry (parallel crash reporting) | Crashlytics sufficient; dual reporters interfere |
| Google Analytics / Mixpanel (parallel analytics) | Firebase Analytics covers all launch needs; dual systems create conflicting data |
| Manual APNs certificate management | Use Expo credential management with APNs auth keys instead |
| Background fetch for rest timer | Unreliable on iOS; use scheduled local notification with absolute timestamp |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NOTIF-01 | Phase 20 | Pending |
| NOTIF-02 | Phase 20 | Pending |
| NOTIF-03 | Phase 20 | Pending |
| NOTIF-04 | Phase 21 | Pending |
| NOTIF-05 | Phase 21 | Pending |
| NOTIF-06 | Phase 20 | Pending |
| NOTIF-07 | Phase 20 | Pending |
| NOTIF-08 | Phase 20 | Pending |
| ANLYT-01 | Phase 19 | Pending |
| ANLYT-02 | Phase 19 | Pending |
| ANLYT-03 | Phase 19 | Pending |
| ANLYT-04 | Phase 19 | Pending |
| ANLYT-05 | Phase 19 | Pending |
| ANLYT-06 | Phase 19 | Pending |
| SEC-01 | Phase 22 | Pending |
| SEC-02 | Phase 22 | Pending |
| SEC-03 | Phase 18 | Pending |
| SEC-04 | Phase 18 | Pending |
| STORE-01 | Phase 18 | Pending |
| STORE-02 | Phase 22 | Pending |
| STORE-03 | Phase 22 | Pending |
| STORE-04 | Phase 22 | Pending |
| STORE-05 | Phase 22 | Pending |
| STORE-06 | Phase 23 | Pending |
| STORE-07 | Phase 23 | Pending |
| VERIFY-01 | Phase 17 | Complete |
| VERIFY-02 | Phase 17 | Complete |
| VERIFY-03 | Phase 17 | Pending |
| VERIFY-04 | Phase 17 | Pending |

**Coverage:**
- v1.1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-16*
*Last updated: 2026-03-16 after roadmap creation (phases 17-23)*

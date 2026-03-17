# Roadmap: Sundee Fundee — React Native

## Milestones

- ✅ **v1.0 MVP** — Phases 1-16 (shipped 2026-03-16)
- 🚧 **v1.1 Launch Readiness** — Phases 17-23 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-16) — SHIPPED 2026-03-16</summary>

- [x] Phase 1: Foundation and Infrastructure (3/3 plans) — completed 2026-03-14
- [x] Phase 2: Domain Layer Port (5/5 plans) — completed 2026-03-14
- [x] Phase 3: Data Layer and Offline Architecture (2/2 plans) — completed 2026-03-14
- [x] Phase 4: Core Workout Loop (8/8 plans) — completed 2026-03-15
- [x] Phase 5: Differentiating Features (9/9 plans) — completed 2026-03-15
- [x] Phase 6: Subscriptions and Monetization (3/3 plans) — completed 2026-03-15
- [x] Phase 7: Polish and Pre-Launch (3/3 plans) — completed 2026-03-15
- [x] Phase 8: Fix Cycle Adaptation Wiring (1/1 plans) — completed 2026-03-15
- [x] Phase 9: Fix Guest Migration + AI Profile Wiring (2/2 plans) — completed 2026-03-15
- [x] Phase 10: UI Polish Fixes (1/1 plans) — completed 2026-03-15
- [x] Phase 11: Wire Guest Upgrade Entry Point (1/1 plans) — completed 2026-03-15
- [x] Phase 12: Fix Firestore Pain Log Security Rules (1/1 plans) — completed 2026-03-15
- [x] Phase 13: Complete Weight Unit Threading (1/1 plans) — completed 2026-03-16
- [x] Phase 14: Fix Readiness Survey Persistence (1/1 plans) — completed 2026-03-16
- [x] Phase 15: Wire AI Preview Adaptation Context (1/1 plans) — completed 2026-03-16
- [x] Phase 16: Thread Weight Unit into Program Session (1/1 plans) — completed 2026-03-16

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

### v1.1 Launch Readiness (In Progress)

**Milestone Goal:** Get the app verified on real devices, instrumented with analytics and crash reporting, equipped with push notifications, and submitted to all three platforms (iOS, Android, Web).

- [x] **Phase 17: Device Verification** - Triage and resolve all ~30 v1.0 human verification items; confirm core flows on simulator, emulator, and offline
- [ ] **Phase 18: Foundation Config + Build Infrastructure** - Add all v1.1 native modules to app.json, configure EAS production build profiles, confirm App Check in production mode, add PrivacyInfo.xcprivacy
- [ ] **Phase 19: Analytics + Crash Reporting** - Wire Firebase Analytics and Crashlytics into the app with platform-branched wrappers, key event instrumentation, and OTA update capability
- [ ] **Phase 20: Notification Infrastructure** - Build the full local notification and FCM token pipeline; wire rest timer notification, deferred permission prompt, notification preferences, and cycle-aware reminder copy
- [ ] **Phase 21: Remote Notifications** - Implement Cloud Functions for WOD and subscription expiry FCM fan-out
- [ ] **Phase 22: Security + Store Prep** - Deploy and validate Firestore security rules; complete all App Store, Play Store, and in-app metadata requirements
- [ ] **Phase 23: Production Submission** - Build signed production binaries and submit to App Store, Play Store, and web hosting

## Phase Details

### Phase 17: Device Verification
**Goal**: The app is confirmed working on real-world targets — known v1.0 issues are resolved and core flows are verified end-to-end on both mobile platforms and in offline conditions
**Depends on**: Phase 16 (v1.0 complete)
**Requirements**: VERIFY-01, VERIFY-02, VERIFY-03, VERIFY-04
**Success Criteria** (what must be TRUE):
  1. All ~30 v1.0 human verification items are triaged; each is either resolved, documented as a known limitation, or deferred with a written rationale
  2. User can complete a full workout (start → log sets → finish) on iOS simulator and Android emulator without any blocking errors
  3. User can complete a workout in airplane mode and, upon reconnecting, see their completed workout appear in history without manual intervention
  4. User can sign in with Apple, Google, email/password, and as guest, and a guest user can upgrade to a full account with their existing data preserved — all on both platforms
**Plans**: 3 plans
Plans:
- [x] 17-01-PLAN.md — Environment setup and blocker-tier verification sweep (8 items)
- [x] 17-02-PLAN.md — Degraded-tier and cosmetic-tier verification sweep (25 items)
- [x] 17-03-PLAN.md — Cross-platform smoke tests, offline verification, and auth flow matrix

### Phase 17.1: Repo Restructure: Promote RN to Root (INSERTED)

**Goal:** Promote the React Native app from SundeeFundeeRN/ subdirectory to the repo root, archive legacy Swift artifacts, and update all configuration references — so that all dev commands run from root without subdirectory prefixes
**Requirements**: RESTRUCTURE-01, RESTRUCTURE-02
**Depends on:** Phase 17
**Plans:** 2 plans

Plans:
- [ ] 17.1-01-PLAN.md — Promote SundeeFundeeRN/ to root and archive legacy Swift
- [ ] 17.1-02-PLAN.md — Update configs (.gitignore, firebase.json, CLAUDE.md) and validate test suite

### Phase 18: Foundation Config + Build Infrastructure
**Goal**: All v1.1 native modules are registered in app.json, EAS production build profiles are locked in, Firebase App Check is confirmed active in production mode, and the iOS privacy manifest is present and correct — producing a new EAS development build that unblocks all subsequent phases
**Depends on**: Phase 17
**Requirements**: SEC-03, SEC-04, STORE-01
**Success Criteria** (what must be TRUE):
  1. A new EAS development build installs and runs on iOS and Android with no missing native module errors for @react-native-firebase/messaging, /crashlytics, /analytics
  2. eas.json contains a submit.production section with ascAppId for iOS and serviceAccountKeyPath + track: "internal" for Android
  3. Firebase App Check dashboard shows DeviceCheck (iOS) and Play Integrity (Android) in production mode — not debug tokens
  4. PrivacyInfo.xcprivacy exists in the iOS project with correct NSPrivacyAccessedAPICategory entries for cycle/health data classified as sensitive health information linked to user identity
**Plans**: TBD

### Phase 19: Analytics + Crash Reporting
**Goal**: The app is fully observable in production — screen views and key events are tracked in Firebase Analytics, crashes and JS errors are captured by Crashlytics, user properties are set, and OTA update capability is active
**Depends on**: Phase 18
**Requirements**: ANLYT-01, ANLYT-02, ANLYT-03, ANLYT-04, ANLYT-05, ANLYT-06
**Success Criteria** (what must be TRUE):
  1. Firebase Analytics DebugView shows screen_view events firing automatically as the user navigates between tabs and screens via Expo Router
  2. Firebase Analytics DebugView shows all five key events (workout_started, workout_completed, subscription_started, ai_workout_generated, cycle_phase_updated) firing at the correct user actions
  3. Firebase Analytics shows subscription_tier and cycle_tracking_enabled user properties set correctly for both free and premium users
  4. Crashlytics dashboard receives a test non-fatal error (via recordError) from a preview build, with current_screen, subscription_tier, and cycle_phase custom keys attached
  5. Running eas update produces a published update that installs on a connected device without requiring a new binary build
**Plans**: TBD

### Phase 20: Notification Infrastructure
**Goal**: Users receive a local push when their rest timer expires in the background, can grant notification permission after their first workout, have their FCM token stored in Firestore, and can configure notification preferences — including a daily reminder with cycle-phase-aware copy
**Depends on**: Phase 18
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-06, NOTIF-07, NOTIF-08
**Success Criteria** (what must be TRUE):
  1. User receives a local push notification when the rest timer expires while the app is backgrounded or the phone screen is off
  2. After completing their first workout, the user is shown a notification permission prompt — not during cold app launch
  3. After granting permission, the user's FCM push token is saved to their Firestore user document and is readable in the Firebase console
  4. User can open Settings and toggle notification types (rest timer, reminders, WOD, subscription) on or off, with the preference persisted across app restarts
  5. When the user schedules a daily workout reminder and has cycle tracking enabled, the delivered notification body contains cycle-phase-aware copy (e.g., references their current phase)
**Plans**: TBD

### Phase 21: Remote Notifications
**Goal**: Users receive a remote push notification when a new WOD is published and when their subscription is approaching or at expiry — delivered via Cloud Functions to all registered FCM tokens
**Depends on**: Phase 20
**Requirements**: NOTIF-04, NOTIF-05
**Success Criteria** (what must be TRUE):
  1. When a new WOD document is created in Firestore, all users with a stored FCM token receive a push notification on their device within 60 seconds
  2. A user whose subscription expires in 3 days receives a push notification; the same user receives another notification on the expiry date itself
  3. Tapping either remote notification opens the app to the relevant screen (WOD tab for new WOD; Settings/subscription screen for expiry)
**Plans**: TBD

### Phase 22: Security + Store Prep
**Goal**: Firestore security rules are deployed and validated in production, protecting sensitive health data; all App Store and Play Store metadata, privacy declarations, and age ratings are complete; and the privacy policy is accessible from within the app
**Depends on**: Phase 18
**Requirements**: SEC-01, SEC-02, STORE-02, STORE-03, STORE-04, STORE-05
**Success Criteria** (what must be TRUE):
  1. Firestore security rules are deployed to production; the Rules Simulator confirms an unauthenticated read of a user's cycle data is denied, a program/WOD public read succeeds, and an authenticated user can only read and write their own documents
  2. App Store Connect listing has 6.9-inch (1320x2868px) screenshots uploaded, an app description, keyword field, and a reachable privacy policy URL
  3. Play Store listing has the Health and Fitness sensitive data declaration complete, the data safety section filled, and age rating questionnaire submitted
  4. Both stores have age rating questionnaires completed and submitted
  5. User can reach the privacy policy from within the app via a link in the Settings screen without leaving the app or being shown a broken URL
**Plans**: TBD

### Phase 23: Production Submission
**Goal**: Signed production binaries are submitted to the App Store and Play Store, and the web app is publicly deployed — making the app available for review and distribution on all three platforms
**Depends on**: Phase 21, Phase 22
**Requirements**: STORE-06, STORE-07
**Success Criteria** (what must be TRUE):
  1. A signed iOS .ipa is submitted to App Store Connect via EAS Submit and appears in the Builds list with status "Processing" or better
  2. A signed Android .aab is manually uploaded to Play Console Internal Testing track (first submission) and appears as a valid build ready for review
  3. The web app is deployed to a public URL via Expo web build or EAS Hosting and is accessible in a browser without login
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation and Infrastructure | v1.0 | 3/3 | Complete | 2026-03-14 |
| 2. Domain Layer Port | v1.0 | 5/5 | Complete | 2026-03-14 |
| 3. Data Layer and Offline Architecture | v1.0 | 2/2 | Complete | 2026-03-14 |
| 4. Core Workout Loop | v1.0 | 8/8 | Complete | 2026-03-15 |
| 5. Differentiating Features | v1.0 | 9/9 | Complete | 2026-03-15 |
| 6. Subscriptions and Monetization | v1.0 | 3/3 | Complete | 2026-03-15 |
| 7. Polish and Pre-Launch | v1.0 | 3/3 | Complete | 2026-03-15 |
| 8. Fix Cycle Adaptation Wiring | v1.0 | 1/1 | Complete | 2026-03-15 |
| 9. Fix Guest Migration + AI Profile Wiring | v1.0 | 2/2 | Complete | 2026-03-15 |
| 10. UI Polish Fixes | v1.0 | 1/1 | Complete | 2026-03-15 |
| 11. Wire Guest Upgrade Entry Point | v1.0 | 1/1 | Complete | 2026-03-15 |
| 12. Fix Firestore Pain Log Security Rules | v1.0 | 1/1 | Complete | 2026-03-15 |
| 13. Complete Weight Unit Threading | v1.0 | 1/1 | Complete | 2026-03-16 |
| 14. Fix Readiness Survey Persistence | v1.0 | 1/1 | Complete | 2026-03-16 |
| 15. Wire AI Preview Adaptation Context | v1.0 | 1/1 | Complete | 2026-03-16 |
| 16. Thread Weight Unit into Program Session | v1.0 | 1/1 | Complete | 2026-03-16 |
| 17. Device Verification | v1.1 | 3/3 | Complete | 2026-03-17 |
| 17.1 Repo Restructure | v1.1 | 0/2 | Not started | - |
| 18. Foundation Config + Build Infrastructure | v1.1 | 0/TBD | Not started | - |
| 19. Analytics + Crash Reporting | v1.1 | 0/TBD | Not started | - |
| 20. Notification Infrastructure | v1.1 | 0/TBD | Not started | - |
| 21. Remote Notifications | v1.1 | 0/TBD | Not started | - |
| 22. Security + Store Prep | v1.1 | 0/TBD | Not started | - |
| 23. Production Submission | v1.1 | 0/TBD | Not started | - |

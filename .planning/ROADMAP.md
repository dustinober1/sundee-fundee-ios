# Roadmap: Sundee Fundee (Swift Rebuild)

## Overview

This is a brownfield rebuild of an existing Swift 6 + SwiftUI codebase. The app has substantial functionality already working — the path to App Store submission is resolving critical correctness bugs, activating CloudKit sync (disabled in production), adding a watchOS companion, wiring APNs push notifications, and producing the App Store deliverables. Phases follow the dependency chain: fix what is broken before activating what is disabled, and activate CloudKit before adding the Watch target that depends on it.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Critical Bug Fixes** - Resolve correctness bugs that compound with every subsequent phase
- [ ] **Phase 2: CloudKit Activation** - Enable production iCloud sync across all user devices
- [ ] **Phase 3: Push Notifications** - Wire APNs infrastructure and all notification types
- [ ] **Phase 4: watchOS Scaffold** - Add Watch target, shared domain package, and WatchConnectivity service
- [ ] **Phase 5: watchOS Core Workout** - Set logging from wrist with HKWorkoutSession, rest timer, and iPhone sync
- [ ] **Phase 6: watchOS Differentiators** - Cycle phase glance, watch face complications, and PR haptics
- [ ] **Phase 7: Data & Analytics** - CSV export, volume charts, and cycle phase education UI
- [ ] **Phase 8: App Store Submission** - Metadata, privacy policy, and production binary submission

## Phase Details

### Phase 1: Critical Bug Fixes
**Goal**: The iOS app is stable, correct, and safe to build on — metric users get correct weights, sign-out wipes the right schema, guest data persists through sign-in, StoreKit defaults to free until verified, and migration runs against both store paths
**Depends on**: Nothing (first phase)
**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04, FIX-05
**Success Criteria** (what must be TRUE):
  1. A user with kg selected as their unit receives AI-generated workout prescriptions in kg, not lbs
  2. A user who signs out or deletes their account has all V12 model data wiped, with no stale V10 references surviving
  3. A guest user who creates an account retains all workout data they logged before signing in (stable UUID preserved)
  4. The app shows free-tier access on cold launch until StoreKit verification completes — no brief premium window
  5. SwiftData migration runs against both the CloudKit-backed and local persistent store paths without boot crash
**Plans:** 3 plans

Plans:
- [ ] 01-01-PLAN.md — Fix SwiftData migration path + StoreKit cold-launch gate (FIX-04, FIX-05)
- [ ] 01-02-PLAN.md — Fix sign-out/delete schema wipe + guest UUID stability (FIX-02, FIX-03)
- [ ] 01-03-PLAN.md — Fix AI weight unit threading in prompt builder (FIX-01)

### Phase 2: CloudKit Activation
**Goal**: User workout data syncs across all their Apple devices via iCloud, with the production schema deployed and container failure surfaced as a user-visible error rather than silent store deletion
**Depends on**: Phase 1
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04
**Success Criteria** (what must be TRUE):
  1. A workout logged on iPhone appears on a second iPhone (or iPad) signed into the same iCloud account without manual action
  2. A new install on a second device shows the user's full workout history after CloudKit sync completes
  3. If iCloud is unavailable, the app shows a clear error message rather than silently deleting local data
  4. The Production CloudKit schema is deployed before TestFlight distribution — the app works in TestFlight, not just Development
**Plans**: TBD

Plans:
- [ ] 02-01: CloudKit model compatibility audit — verify all 22 V12 models for optional properties, no .unique, no .deny delete rules
- [ ] 02-02: Activate CloudKit flag and entitlements — flip production flag, add iCloud entitlement to project.yml
- [ ] 02-03: Deploy Production CloudKit schema via CloudKit Console
- [ ] 02-04: Add container open failure alert — replace silent store deletion with user-facing error + temp copy safeguard
- [ ] 02-05: Validate sync on two physical devices via TestFlight

### Phase 3: Push Notifications
**Goal**: Users receive APNs notifications for rest timer expiry, workout reminders, new WODs, and streak warnings — each toggleable in Settings
**Depends on**: Phase 2
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05
**Success Criteria** (what must be TRUE):
  1. When the rest timer completes and the app is backgrounded, the user receives a push notification on their iPhone
  2. A user who sets a daily workout reminder at 7 AM receives a push notification at that time each day
  3. When a new WOD is published (via admin dashboard), subscribed users receive a push notification
  4. A user whose workout streak is about to break receives a reminder push notification
  5. Each notification type can be independently toggled on or off in Settings, and the preference persists across app restarts
**Plans**: TBD

Plans:
- [ ] 03-01: APNs infrastructure — add Push Notifications entitlement to project.yml, configure .p8 auth key, register for remote notifications
- [ ] 03-02: Permission flow — UNUserNotificationCenter authorization request with Settings deep-link fallback
- [ ] 03-03: Rest timer background notification — local UNNotificationRequest triggered when timer ends while backgrounded
- [ ] 03-04: Workout reminder scheduling — time-picker in Settings, local repeating notification at chosen time
- [ ] 03-05: WOD alert — server-side push from admin dashboard to CloudKit device token storage; receive and display
- [ ] 03-06: Streak nudge notification — schedule local notification when streak is 1 day from breaking
- [ ] 03-07: Notification Settings UI — per-type toggles persisted to SwiftData UserPreferences

### Phase 4: watchOS Scaffold
**Goal**: The watchOS target exists, builds, and can exchange data with iPhone — XcodeGen config, SundeeFundeeShared expansion, minimal Watch schema, and WatchConnectivityService activated on both sides
**Depends on**: Phase 2
**Requirements**: (No isolated v1 requirements — this phase creates the infrastructure that makes WATCH-01 through WATCH-11 verifiable in Phases 5-6)
**Success Criteria** (what must be TRUE):
  1. A watchOS app target builds without errors from the XcodeGen project.yml configuration
  2. The Watch app launches on a paired Apple Watch without crashing
  3. Sending a test message from Watch to iPhone via WatchConnectivityService results in the iPhone receiving it (verified in Xcode console)
  4. Domain types from SundeeFundeeShared (cycle phase, weight calculations) are accessible from the Watch target without duplication
**Plans**: TBD

Plans:
- [ ] 04-01: Add watchOS target to project.yml — XcodeGen platform: watchOS, deploymentTarget 10.0, bundle ID, signing
- [ ] 04-02: Create SundeeFundeeWatch/ source tree — SwiftUI @main App, ContentView, AppDelegate scaffold
- [ ] 04-03: Define WatchAppSchemaV1 — 4-model minimal schema (WorkoutTemplate, CompletedWorkout, CompletedSet, UserPreferences)
- [ ] 04-04: Expand SundeeFundeeShared package — move Domain/ types (CycleProgramGenerator, WeightCalculations, InjuryAdaptationEngine) into shared package accessible by both targets
- [ ] 04-05: Implement WatchConnectivityService — @Observable singleton with WCSession on both sides; activate at launch; transferUserInfo + updateApplicationContext

### Phase 5: watchOS Core Workout
**Goal**: Users can log a complete strength training session from their Apple Watch — from starting a session to viewing the workout in iPhone history — with an HKWorkoutSession contributing to Activity rings, a rest timer with haptics, live heart rate and calories, and reliable sync even if the app is killed mid-workout
**Depends on**: Phase 4
**Requirements**: WATCH-01, WATCH-02, WATCH-03, WATCH-04, WATCH-05, WATCH-06, WATCH-07, WATCH-08
**Success Criteria** (what must be TRUE):
  1. Starting a workout on Watch creates an HKWorkoutSession and the workout appears as an active session in the Activity app, contributing to the Move ring
  2. A user can log a set (weight + reps) from Apple Watch, with the current exercise name, target sets/reps, and previous best weight visible on screen
  3. The rest timer counts down on Watch and delivers a haptic notification when time expires
  4. Live heart rate and calories burned update on screen during the workout session
  5. Ending a workout on Watch (without iPhone) saves the session and the workout appears in iPhone workout history after sync
  6. If the Watch app is killed mid-workout and relaunched, the active workout state is recovered and logging continues from where the user left off
**Plans**: TBD

Plans:
- [ ] 05-01: HealthKit authorization — request HKWorkoutSession write + HR + calories in iPhone onboarding; validate on Watch at session start
- [ ] 05-02: HKWorkoutSession + HKLiveWorkoutBuilder integration — start/pause/end session, live HR and calories via HKLiveWorkoutBuilder queries
- [ ] 05-03: Set logging UI — Digital Crown or +/- controls for weight and reps; exercise name, target, previous best from WCSession context
- [ ] 05-04: Rest timer with haptic — countdown display, WKHapticType.notification on expiry, local Watch notification when backgrounded
- [ ] 05-05: Workout end flow — correct session shutdown order (session.end() before builder.finishWorkout()), transferUserInfo to iPhone
- [ ] 05-06: Watch-side SwiftData checkpointing — write each set to WatchAppSchemaV1 CompletedSet on log; recover state in applicationDidFinishLaunching via HKHealthStore.recoverActiveWorkoutSession
- [ ] 05-07: iPhone sync receiver — WatchConnectivityService receives transferUserInfo payload; writes CompletedWorkout to iPhone SwiftData + Firestore; shows in history

### Phase 6: watchOS Differentiators
**Goal**: The Watch app surfaces cycle phase context during workouts, watch face complications give the user a glanceable view of their training status, and PRs deliver a haptic celebration on the wrist
**Depends on**: Phase 5
**Requirements**: WATCH-09, WATCH-10, WATCH-11
**Success Criteria** (what must be TRUE):
  1. During an active workout on Watch, the current cycle phase name and a one-line adaptation rationale are visible on screen
  2. A watch face complication shows cycle phase, streak count, or last workout date (user's choice of data) without opening the app
  3. When a personal record is set during a Watch-logged set, the Watch delivers a distinct haptic notification
**Plans**: TBD

Plans:
- [ ] 06-01: Cycle phase glance view — display current phase and adaptation rationale in Watch workout UI, sourced from WCSession applicationContext
- [ ] 06-02: WidgetKit complications — accessoryCircular (cycle phase icon), accessoryRectangular (streak + last workout), accessoryCorner (phase abbreviation); use WidgetKit not ClockKit
- [ ] 06-03: PR haptic feedback — detect PR during set log (compare against previous best from WCSession context); trigger WKHapticType.success

### Phase 7: Data & Analytics
**Goal**: Users can export their workout data, view volume trends over time, and understand why today's workout was adapted for their cycle phase
**Depends on**: Phase 2
**Requirements**: DATA-01, DATA-02, DATA-03
**Success Criteria** (what must be TRUE):
  1. A user can export their complete workout history as one or more CSV files from within the app
  2. A user can view a chart showing weekly training volume (sets per muscle group and total volume over time)
  3. When a workout has been adapted for the user's cycle phase, the app shows an explanation of why — naming the phase and the specific adaptations made
**Plans**: TBD

Plans:
- [ ] 07-01: CSV export — query all CompletedWorkout + CompletedSet records; write to CSV with workout date, exercise, weight, reps, unit; share via UIActivityViewController
- [ ] 07-02: Volume analytics repository — aggregate sets-per-muscle-group and total volume per week from SwiftData history
- [ ] 07-03: Volume charts UI — weekly volume bar charts using Swift Charts; time range picker (4w, 12w, 1y)
- [ ] 07-04: Cycle phase education UI — show phase name + adaptation rationale card in workout detail view; copy driven by CycleProgramGenerator explanation output

### Phase 8: App Store Submission
**Goal**: The app is submitted to App Store Connect and approved for distribution — with complete metadata, an in-app privacy policy link, and a signed production binary
**Depends on**: Phase 7
**Requirements**: STORE-01, STORE-02, STORE-03
**Success Criteria** (what must be TRUE):
  1. The App Store listing has a complete description, keyword set, and screenshots for all required device sizes
  2. A user can navigate to the privacy policy from within the app without leaving to a browser (or with a clear in-app browser modal)
  3. A signed production binary is submitted to App Store Connect and passes App Review
**Plans**: TBD

Plans:
- [ ] 08-01: App Store metadata — write description, subtitle, keywords; produce screenshots for iPhone 16 Pro and Apple Watch Ultra 2 sizes via Simulator
- [ ] 08-02: Privacy policy — host at sundeefundee.com/privacy; add Settings link that opens in SFSafariViewController
- [ ] 08-03: Production binary — archive release build, validate with Xcode Organizer, submit to App Store Connect via Xcode or Transporter

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
Note: Phase 3 (APNs) and Phase 4 (watchOS Scaffold) both depend on Phase 2 and can be worked in parallel if desired.
Note: Phase 7 (Data & Analytics) depends only on Phase 2 and can be worked in parallel with Phases 3-6.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Critical Bug Fixes | 0/3 | Planning complete | - |
| 2. CloudKit Activation | 0/5 | Not started | - |
| 3. Push Notifications | 0/7 | Not started | - |
| 4. watchOS Scaffold | 0/5 | Not started | - |
| 5. watchOS Core Workout | 0/7 | Not started | - |
| 6. watchOS Differentiators | 0/3 | Not started | - |
| 7. Data & Analytics | 0/4 | Not started | - |
| 8. App Store Submission | 0/3 | Not started | - |

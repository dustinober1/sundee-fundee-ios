# iOS TestFlight Readiness Design

## Purpose

Get the native iOS app from "builds in Simulator" to "installable via TestFlight for internal testers" as fast as possible. Fix what's broken, hide what's incomplete, and ship.

## Context

- **Swift Package** (`SundeeFundee/`): Domain logic, data layer, auth, subscription, UI views. Builds clean, 321 tests passing.
- **Xcode Project** (`SundeeFundeeApp/`): Shell app with `project.yml`, imports SundeeFundeeKit. Builds for Simulator.
- **Entitlements**: Sign in with Apple, HealthKit, CloudKit, push notifications already configured.
- **Backend**: CloudKit is the long-term data store. Firebase/web app is temporary.
- **Team ID**: Available but not yet set in `project.yml`.
- **App Icon**: Does not exist — needs to be generated from `Logo.jpeg`.

## Approach: Fix-Forward

Audit every screen, fix blocking issues, hide incomplete screens, ship to TestFlight. Rough edges are expected in beta — the goal is getting real-device feedback fast.

## Design

### 1. Screen Audit & Triage

Run every screen in the Simulator. Categorize each as:

- **Ship** — Functional, goes to testers as-is
- **Fix** — Blocking issue (crash, broken nav, missing data flow) must be resolved
- **Hide** — Placeholder or non-functional, conditionally remove from tab bar

Screens to audit:

| Screen | Flow |
|--------|------|
| Auth | Sign in with Apple → session persistence → sign out |
| Onboarding | Full flow → sets user profile → lands on dashboard |
| Dashboard | Renders with real data and empty state |
| Workouts | List → detail → exercise picker → AI workout flow |
| Programs | List → enrollment |
| Maxes | List → add/edit 1RM entries |
| Benchmarks | List → log results |
| Cycle | Calendar view → period logging |
| Pain tracking | Pain entry → body location picker |
| Settings | Profile, subscription, preferences |

For **Hide** screens: conditionally remove the tab item or gate navigation. Do not delete code — just prevent testers from reaching it.

### 2. Fix Blocking Issues

Priority order:
1. **Crashes** — any screen that crashes on launch or interaction
2. **Auth flow** — must complete end-to-end (sign in → session → sign out)
3. **Onboarding** — must complete and persist user profile
4. **Core data operations** — CRUD for workouts and maxes (the minimum useful actions)
5. **Navigation** — all visible tabs must navigate without dead ends

Non-blocking issues (visual polish, minor layout bugs) are deferred.

### 3. Signing & Provisioning

1. Set `DEVELOPMENT_TEAM` in `SundeeFundeeApp/project.yml` to the real Team ID
2. Register App ID `com.sundeefundee.app` in Apple Developer portal with capabilities:
   - Sign in with Apple
   - HealthKit
   - CloudKit (container: `iCloud.com.sundeefundee.app`)
   - Push Notifications
3. Use Xcode automatic signing — no manual certificate/profile management
4. Create CloudKit container `iCloud.com.sundeefundee.app` in CloudKit Dashboard if it doesn't exist

### 4. App Icon

1. Source: `Logo.jpeg` at project root
2. Generate all required sizes (1024x1024 for App Store, plus @2x/@3x variants)
3. Place in `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/`
4. Update `Contents.json` to reference the generated files
5. Cosmetic — can be refined later, just needs to exist for archive upload

### 5. Device Testing

After signing is configured:
1. Build and run on a real iPhone
2. Verify Sign in with Apple works on device (Simulator uses sandbox)
3. Verify HealthKit permissions prompt and data read/write
4. Verify CloudKit data round-trip (save → read back)
5. Fix any device-only issues (Simulator doesn't surface all problems)

### 6. TestFlight Upload

1. **App Store Connect**: Create app record for `com.sundeefundee.app` (name, language, bundle ID)
2. **Archive**: Xcode → Product → Archive (Any iOS Device destination, Release config)
3. **Validate**: Xcode Organizer → Validate App (checks signing, entitlements, icon)
4. **Upload**: Xcode Organizer → Distribute App → App Store Connect
5. **Internal testing group**: Create group (e.g., "Friends & Family"), add testers by email
6. **Beta notes**: What to test, known issues list from the audit

Internal testers don't require Apple review. Builds are available within minutes of processing.

## Execution Order

1. Screen audit in Simulator — categorize Ship/Fix/Hide
2. Fix blocking issues — crashes, auth, onboarding, core CRUD
3. Hide incomplete screens — gate placeholder views
4. Set Team ID + register App ID with capabilities
5. Create CloudKit container if needed
6. Generate app icon from Logo.jpeg
7. Build to personal device — verify auth, HealthKit, CloudKit
8. Fix device-only issues
9. Create App Store Connect record + internal test group
10. Archive + upload to TestFlight
11. Invite testers with test notes + known issues

## Exit Criteria

- App installs from TestFlight
- Testers can sign in with Apple
- Testers can navigate all visible (non-hidden) screens
- Testers can log a workout or 1RM entry
- Known issues documented in TestFlight beta notes

## Out of Scope

- CI/CD automation (manual archive + upload is fine for small group)
- App Store listing or screenshots
- Firebase/web app data sync
- Feature polish beyond blocking fixes
- External TestFlight testing (requires Apple review)

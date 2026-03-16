# Project Research Summary

**Project:** Sundee Fundee — React Native Rewrite (v1.1 Launch Readiness)
**Domain:** Cross-platform fitness app (iOS, Android, Web) — hormonal-cycle-aware strength training
**Researched:** 2026-03-16
**Confidence:** HIGH (all four research areas grounded in official documentation with version-specific verification)

## Executive Summary

Sundee Fundee v1.1 is a launch readiness milestone for a React Native + Expo + Firebase app built on a solid v1.0 foundation. The v1.0 base (auth, Firestore data layer, workout execution, cycle adaptation, AI generation, RevenueCat payments, domain logic port) is fully built and verified. The v1.1 work is a bounded set of production-gate requirements: push notifications, Firebase Analytics, Crashlytics crash reporting, Firestore security rules hardening, EAS production build configuration, and App Store / Play Store submission preparation. These are not new product features — they are the safety net and store compliance work that converts a working app into a shippable one.

The recommended approach is sequenced by hard dependencies. Native module additions (`@react-native-firebase/messaging`, `@react-native-firebase/crashlytics`, `@react-native-firebase/analytics`) must be baked into a new EAS build before any code using them can run on device. This build-first constraint means `app.json` plugin configuration and `eas.json` submission config should be locked in first, followed by analytics/crashlytics (self-contained), then the notification infrastructure, then remote Cloud Functions for WOD and subscription expiry notifications, and finally store submission prep as the last gate. The existing `.web.ts` / `.native.ts` platform branching pattern already in the codebase is the right model for all new Firebase modules.

The key risks are: (1) dual notification library conflict if `expo-notifications` and `@react-native-firebase/messaging` are both registered for display — use `expo-notifications` for all display, messaging only for background data events; (2) App Store rejection from an incomplete `PrivacyInfo.xcprivacy` manifest, which is required for all apps as of February 2025 and demands explicit declarations of cycle/health data; (3) silent analytics data loss from event name violations — Firebase drops events silently for names over 40 characters or with reserved prefixes; and (4) the Google Play Store first submission must be a manual AAB upload before any EAS automated submission will work. All of these are avoidable with the correct pre-submission checklist.

---

## Key Findings

### Recommended Stack

The v1.0 stack (Expo SDK 55, `@react-native-firebase` v23.8.8, Firebase Auth/Firestore/Functions/AppCheck, RevenueCat, Zustand, TypeScript domain layer) is stable and does not change for v1.1. Four new packages are required: `@react-native-firebase/analytics`, `@react-native-firebase/crashlytics`, `@react-native-firebase/messaging`, and `expo-device` + `expo-task-manager` (supporting packages for background push). All must be pinned at `^23.8.8` (RNF packages) or `~55.0.x` (Expo packages) to match existing versioning. The RNF v23.8.0–23.8.2 config plugin regression (affecting Crashlytics and Analytics Expo plugin setup) was fixed in v23.8.3; v23.8.8 is confirmed safe.

**Core technologies (v1.1 additions):**
- `@react-native-firebase/analytics` ^23.8.8 — event and screen tracking, initializes via existing `@react-native-firebase/app` plugin, no extra Firebase project config needed
- `@react-native-firebase/crashlytics` ^23.8.8 — native crash capture + non-fatal JS error recording; requires own config plugin entry in `app.json` and `RNFBCrashlytics` in `forceStaticLinking`
- `@react-native-firebase/messaging` ^23.8.8 — FCM token acquisition and background data message handler; requires `RNFBMessaging` in `forceStaticLinking`; does NOT own notification display (expo-notifications owns that)
- `expo-notifications` ~55.0.12 — already installed; owns all local notification scheduling and remote notification display; `enableBackgroundRemoteNotifications: true` plugin option required
- EAS CLI 18.4.x — already configured; needs `submit.production` block added to `eas.json` for iOS (`ascAppId`) and Android (`serviceAccountKeyPath`, `track: "internal"`)

See `.planning/research/STACK.md` for complete version compatibility table and installation commands.

### Expected Features

The v1.1 feature set is defined by store submission requirements and production-quality expectations, not product differentiation. All v1.0 differentiators (cycle adaptation, injury engine, AI workout generation, WOD feed, benchmark catalog) are already built and verified.

**Must have (table stakes — P1, blocks store submission):**
- Firestore security rules deployed and validated — health/cycle data is sensitive; open test mode rules are a critical security and compliance failure
- Local rest timer notification — core workout loop, hooks into already-built rest timer component
- FCM token registration and Firestore storage — prerequisite for all remote notifications
- Crashlytics active in production build with `recordError()` on all catch boundaries
- Firebase Analytics wired into: `workout_started`, `workout_completed`, `subscription_started`, `ai_workout_generated`, `cycle_phase_updated`, screen views via `usePathname` hook
- EAS production build profiles for iOS and Android configured in `eas.json`
- App Store Connect metadata: 6.9-inch screenshots (1320x2868px), description, keywords, privacy policy URL accessible in-app
- Play Store metadata: Health and Fitness data declaration, data safety section, age rating questionnaire
- Privacy policy link in Settings screen
- Firebase App Check confirmed in production mode (not debug)

**Should have (P2, add before or alongside launch):**
- New WOD remote notification — Cloud Function Firestore trigger → FCM fan-out to stored tokens
- Subscription expiry remote notification — RevenueCat webhook → Cloud Function → FCM (3 days before + day-of cadence)
- Analytics user properties: subscription tier, cycle tracking opt-in
- Crashlytics custom keys: current screen, cycle phase, subscription tier
- OTA update via EAS Update — JS-layer hotfix capability for launch week

**Defer to v1.x based on data:**
- Daily training reminder notification — measure push permission grant rate first; do not build prefs if permissions are being denied
- Cycle-phase-aware notification copy — measure cycle tracking adoption via Analytics before building
- Notification preferences screen — add after first notification type is live

**Future consideration (v2+):**
- Streak notifications with motivational content — validate retention data first
- Firebase Remote Config for notification copy A/B testing
- Rich media push notifications (platform-specific, high complexity for marginal launch value)

See `.planning/research/FEATURES.md` for full prioritization matrix and dependency graph.

### Architecture Approach

The v1.1 architecture is additive — all new components integrate cleanly with the existing layered structure (Screens → Zustand/Hooks → Domain → Repositories → Firebase). No existing architecture decisions change. The new work follows three established patterns already in the codebase: (1) `.web.ts` / `.native.ts` platform branching for Firebase modules without web support (analytics and crashlytics get no-op `.web.ts` stubs); (2) thin wrapper modules in `src/firebase/` exposing only what the app needs; (3) side-effect hooks (`usePushToken`, `useNotificationNavigation`) mounted in layout files with no render output.

**Major new components:**
1. `src/firebase/analytics.ts` + `analytics.web.ts` — thin wrapper around RNF analytics; no-ops on web; exposes `logEvent`, `logScreen`, `setUserId`
2. `src/firebase/crashlytics.ts` + `crashlytics.web.ts` — wrapper exposing `recordError`, `setUser`, `log`; ErrorBoundary calls this in `componentDidCatch`
3. `src/firebase/messaging.ts` — FCM token retrieval, token refresh listener, background message handler registration (registered in `index.ts` before `AppRegistry`, not inside any component)
4. `src/notifications/` module — `NotificationService.ts` (schedule/cancel), `NotificationPermissions.ts` (request/check), `usePushToken.ts` (FCM token lifecycle), `useNotificationNavigation.ts` (tap-to-route)
5. Cloud Functions: `sendWODNotification` (Firestore trigger), `sendSubscriptionExpiryNotification` (scheduled/webhook)

**Modified files (all additive, low risk):**
- `app/_layout.tsx` — add analytics init, crashlytics init, ErrorBoundary, `setUserId` on sign-in
- `app/(app)/_layout.tsx` — mount `usePushToken()` and `useNotificationNavigation()` hooks
- `index.ts` — register `setBackgroundMessageHandler` before `AppRegistry.registerComponent`
- `src/repositories/FirestoreUserRepo.ts` — add `saveFCMToken(uid, token)` with `{ merge: true }`
- `app.json` — 3 new plugins, iOS entitlements, `forceStaticLinking` additions
- `eas.json` — add `submit.production` section

**Build order constraint:** `app.json` plugin changes require a new EAS build (dev client) before any code using the new modules can run on device. This is the hard dependency that sequences all v1.1 work.

See `.planning/research/ARCHITECTURE.md` for complete data flow diagrams and file-level integration map.

### Critical Pitfalls

1. **Dual notification library conflict** — `expo-notifications` and `@react-native-firebase/messaging` both attempt to register Android notification channels, causing swallowed notifications. Resolution: `expo-notifications` owns all display; `messaging` handles background data events only. Do not call `messaging().onMessage()` to display notifications.

2. **`setBackgroundMessageHandler` inside a component** — Registering the FCM background handler in `useEffect` inside `_layout.tsx` means it is never called in background/quit state where components do not mount. It must be called in `index.ts` before `AppRegistry.registerComponent`.

3. **`forceStaticLinking` array incomplete after adding new RNFB modules** — Each new `@react-native-firebase/*` package requires its pod name added to `forceStaticLinking` manually. Missing entries produce cryptic iOS linker errors (`Non-modular header inside framework module`). Add `RNFBAnalytics`, `RNFBCrashlytics`, `RNFBMessaging` alongside existing entries.

4. **App Store rejection from incomplete `PrivacyInfo.xcprivacy`** — Apple requires this manifest (enforced February 2025) declaring all privacy-impacting APIs. Cycle data and health metrics are classified as "Sensitive Health Information" and must be declared as "linked to user identity." Missing or miscategorized declarations cause rejection with ITMS-91053.

5. **Firebase Analytics silent data loss** — Event names over 40 characters or with reserved prefixes (`firebase_`, `google_`, `ga_`) are silently dropped with no error. Define all event names as constants in a single `analyticsEvents.ts` file. Verify every event via Firebase DebugView before declaring instrumentation complete.

6. **Google Play first submission must be manual** — EAS Submit cannot submit to a Play Console app that has never had a manual upload. Build the AAB via EAS, download it, upload manually to Internal Testing track in Play Console, then automate all subsequent submissions.

7. **APNs Key vs Certificate confusion (FCM v1)** — FCM v1 API (required since June 2024) requires APNs Authentication Key (.p8), not APNs Certificate (.p12). Using a certificate causes silent push failures on iOS. Apple developer accounts have a hard limit of 2 APNs keys.

8. **Crashlytics not reporting in development builds** — `expo-dev-client` catches errors before Crashlytics can see them. Test crash reporting only in `preview` or `production` EAS builds. Do not attempt to configure `firebase.json` in managed workflow — the config plugin handles everything.

See `.planning/research/PITFALLS.md` for the full 20-pitfall catalog with warning signs and phase-specific guidance.

---

## Implications for Roadmap

Based on the combined research, the v1.1 work has a clear dependency-driven sequence. The hard constraint is that native module additions require a new EAS build before any code using them can be tested on device. Everything else flows from this.

### Phase 1: Foundation Config + Build Infrastructure
**Rationale:** All v1.1 native modules (`@react-native-firebase/messaging`, `/crashlytics`, `/analytics`, `expo-device`, `expo-task-manager`) require `app.json` plugin registration and a new EAS development build before any code using them can run. Doing this first unblocks all subsequent phases. The `eas.json` submission config should also be locked in here.
**Delivers:** A new EAS development build with all v1.1 native modules available; `eas.json` `submit.production` section for both platforms
**Addresses:** EAS production build config (P1), `forceStaticLinking` completeness (Pitfall 13), Android `targetSdkVersion: 35` requirement (Pitfall 18)
**Avoids:** Discovering native module gaps mid-phase (Pitfall 3); build-first constraint violations that would force re-work

### Phase 2: Analytics + Crash Reporting
**Rationale:** Self-contained — no dependencies on notifications or Cloud Functions. Wire in immediately after the Phase 1 build. Analytics and Crashlytics are the observability layer needed before any user-facing features go live. Getting them in early means launch-week issues are visible.
**Delivers:** `src/firebase/analytics.ts` + `.web.ts`, `src/firebase/crashlytics.ts` + `.web.ts`, ErrorBoundary in root layout, `setUserId` on sign-in, key event instrumentation, screen tracking via `usePathname`
**Uses:** `@react-native-firebase/analytics` ^23.8.8, `@react-native-firebase/crashlytics` ^23.8.8
**Implements:** Platform branching pattern (`.web.ts` no-ops), thin Firebase wrapper pattern
**Avoids:** Analytics web platform silent no-op (Pitfall 12 — use Firebase JS SDK analytics for web via `.web.ts`); silent event data loss (Pitfall 14 — define event names as constants, verify via DebugView)

### Phase 3: Notification Infrastructure + FCM Token
**Rationale:** Depends on Phase 1 build (messaging module available). Local notifications are a core workout feature (rest timer) and the FCM token is a prerequisite for all remote notifications in Phase 4. Refactoring existing inline `expo-notifications` calls into a `NotificationService` module first establishes clean infrastructure before FCM is layered on.
**Delivers:** `src/notifications/` module (NotificationService, NotificationPermissions, usePushToken, useNotificationNavigation), FCM token stored in Firestore `/users/{uid}`, permission prompt flow (post-workout timing, not cold on launch)
**Avoids:** Dual notification library conflict (Pitfall 9 — `expo-notifications` owns display, messaging owns background data only); foreground notifications silently dropped (Pitfall 10 — `setNotificationHandler` as first notification setup step); iOS permission one-shot waste (aggressive prompting anti-pattern); background handler inside a component (Pitfall 4 — register in `index.ts`)

### Phase 4: Remote Notifications (Cloud Functions)
**Rationale:** Depends on FCM tokens being stored in Firestore (Phase 3). Cloud Functions for WOD delivery and subscription expiry are server-side and can be built and tested in the Firebase emulator independently of app changes.
**Delivers:** `sendWODNotification` Cloud Function (Firestore trigger), `sendSubscriptionExpiryNotification` Cloud Function (RevenueCat webhook → scheduled), `useNotificationNavigation` routing via notification data payload
**Avoids:** Routing data in FCM `notification` object instead of `data` key (anti-pattern); APNs key vs certificate confusion (Pitfall 15 — verify `.p8` key in EAS and Firebase console before writing any send code)

### Phase 5: Security Hardening + Store Submission Prep
**Rationale:** Firestore security rules block both store submissions — this is a hard dependency for any submission, not just a nice-to-have. Store metadata, screenshots, privacy manifest, and platform-specific declarations must all be ready before any submission attempt. Running this in parallel with Phase 4 Cloud Function work is appropriate.
**Delivers:** Production Firestore security rules deployed and validated via Rules Simulator; `PrivacyInfo.xcprivacy` audit complete; App Store Connect metadata (6.9-inch screenshots at 1320x2868px, description, keywords, privacy policy); Play Store metadata (Health and Fitness declaration, data safety, age rating); privacy policy link in Settings screen; Firebase App Check confirmed in production mode
**Avoids:** Open rules exposing health data (Pitfall 6 — critical, no exceptions); App Store rejection from privacy manifest (Pitfall 16 — audit against Apple's required reasons API list); wrong screenshot dimensions (Pitfall 20 — 6.9-inch required, not 6.5-inch); health data privacy label errors (Pitfall 19 — cycle data is "Sensitive Health Information," must be "linked to user identity")

### Phase 6: Production Builds + Store Submission
**Rationale:** Final gate. Requires all prior phases complete. iOS and Android have different submission mechanics — iOS can be fully automated via EAS Submit from first build; Android requires one manual upload before automation works.
**Delivers:** Signed production iOS `.ipa` submitted to App Store Connect; signed production Android `.aab` with first manual upload to Play Console Internal Testing; EAS Submit automated for all subsequent builds
**Avoids:** Android first-submission failure (Pitfall 17 — manual AAB upload to Internal Testing track is required before `eas submit` works); Google Play API level rejection (Pitfall 18 — `targetSdkVersion: 35` required after August 2025, set in Phase 1)

### Phase Ordering Rationale

- Phase 1 before everything because native module additions require a full EAS build — no other phase can be tested on device without it
- Phases 2 and 3 can be developed in parallel after Phase 1 build completes (no dependency between analytics/crashlytics and notifications)
- Phase 4 strictly after Phase 3 (FCM tokens must exist in Firestore before Cloud Functions can fan out)
- Phase 5 can run in parallel with Phases 2–4 (security rules and store metadata have no code dependencies on notification or analytics work)
- Phase 6 is a gate that requires Phase 5 complete (Firestore rules deployed, metadata ready) and Phase 3 complete (notifications working in a preview build)

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Remote Notifications / Cloud Functions):** FCM fan-out to large user bases, RevenueCat webhook integration specifics, and the exact data payload shape for `useNotificationNavigation` routing need to be pinned down before implementation
- **Phase 5 (Security + Submission Prep):** Firestore security rules testing approach (firebase-rules-unit-testing library setup) and the exact `PrivacyInfo.xcprivacy` required reason API list for this specific SDK combination may benefit from a targeted research pass

Phases with standard patterns (skip research-phase):
- **Phase 1 (Config + Build):** Plugin additions and `eas.json` config are well-documented; STACK.md provides exact JSON
- **Phase 2 (Analytics + Crashlytics):** Standard RNF integration with established `.web.ts` pattern already in codebase; ARCHITECTURE.md provides exact file structure
- **Phase 3 (Notification Infrastructure):** `expo-notifications` is already in the project; ARCHITECTURE.md provides exact data flow for FCM token registration
- **Phase 6 (Store Submission):** EAS Submit process is step-by-step documented in STACK.md; manual first Android upload is a one-time action

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All package versions verified against official Expo and RNF docs; v23.8.8 RNF plugin regression confirmed fixed; EAS CLI version confirmed |
| Features | HIGH | Store submission requirements verified against current Apple and Google guidelines (2026); feature dependencies map is explicit |
| Architecture | HIGH | New component structure verified against existing codebase (via direct inspection in research); all modification risks assessed as LOW (additive only) |
| Pitfalls | HIGH | 20 pitfalls identified across v1.0 and v1.1 scope, each with specific warning signs and phase-tagged remediation |

**Overall confidence:** HIGH

### Gaps to Address

- **Web analytics implementation:** `@react-native-firebase/analytics` is a no-op on web. The `.web.ts` stub should use the Firebase JS SDK (`firebase/analytics`) to send events from the web platform. The exact Firebase JS SDK analytics initialization for the web build needs to be verified against the existing `src/firebase/app.web.ts` setup during Phase 2.
- **RevenueCat webhook → Cloud Function → FCM exact integration:** PITFALLS.md flags the RevenueCat + Stripe entitlement sync risk, but the exact Cloud Function webhook handler structure for subscription expiry FCM triggers was not fully detailed in STACK.md or ARCHITECTURE.md. This should be researched during Phase 4 planning.
- **Multi-device push token support:** The current architecture stores one FCM token per user (last-registered device wins). This is an accepted v1.1 tradeoff. If multi-device support is needed before v2, the data model migration to `/users/{uid}/devices/{deviceId}` subcollection should be planned explicitly.
- **Apple privacy manifest SDK audit:** The specific `NSPrivacyAccessedAPICategory` reasons required for the exact combination of Firebase SDK version, RevenueCat, expo-secure-store, and expo-notifications in this project have not been fully enumerated. A pre-submission audit against Apple's required reason APIs list is a required step in Phase 5.

---

## Sources

### Primary (HIGH confidence)
- [Expo Push Notifications Setup](https://docs.expo.dev/push-notifications/push-notifications-setup/) — token registration, FCM V1 credentials, SDK 54+ dev build requirement
- [Expo Notifications API Reference](https://docs.expo.dev/versions/latest/sdk/notifications/) — `scheduleNotificationAsync`, trigger types, `enableBackgroundRemoteNotifications`
- [EAS Submit — iOS](https://docs.expo.dev/submit/ios/) — App Store Connect API key requirements, `ascAppId`
- [EAS Submit — Android](https://docs.expo.dev/submit/android/) — Google Play service account, manual first upload limitation
- [React Native Firebase — Crashlytics Usage](https://rnfirebase.io/crashlytics/usage) — config plugin, dev-client limitation
- [React Native Firebase — Analytics Usage](https://rnfirebase.io/analytics/usage) — installation, Expo setup
- [Firebase Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started) — rule structure, deployment
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — privacy requirements, privacy manifest
- [Google Play Health Apps Declaration](https://support.google.com/googleplay/android-developer/answer/14738291) — health data categories, data safety section
- [Expo GitHub fyi — First Android Submission](https://github.com/expo/fyi/blob/main/first-android-submission.md) — manual first upload requirement
- [RNF Issue #8829](https://github.com/invertase/react-native-firebase/issues/8829) — v23.8.0–23.8.2 plugin regression, confirmed fixed in 23.8.3+

### Secondary (MEDIUM confidence)
- [React Native Firebase — Messaging Usage](https://rnfirebase.io/messaging/usage) — background handler, token management patterns
- [React Native Firebase — Analytics Screen Tracking](https://rnfirebase.io/analytics/screen-tracking) — manual tracking in RN (no native lifecycle callbacks)
- [GitHub — RNF messaging plugin background modes](https://github.com/invertase/react-native-firebase/issues/7577) — iOS UIBackgroundModes configuration pattern
- Codebase inspection of `app.json`, `app/_layout.tsx`, `app/(app)/_layout.tsx`, `useRestTimer.ts`, `FirestoreUserRepo.ts`, `UserRepository.ts` — existing integration state verified

### Tertiary (MEDIUM confidence, third-party summaries)
- [iOS App Store Review Guidelines 2026 — third-party summary](https://theapplaunchpad.com/blog/app-store-review-guidelines) — screenshot size requirements cross-referenced against Apple first-party requirements
- [Google Play Health Apps Update January 2026 — third-party summary](https://myappmonitor.com/blog/google-play-health-apps-update-2026-requirements) — health declaration deadline cross-referenced against official Google docs

---
*Research completed: 2026-03-16*
*Ready for roadmap: yes*

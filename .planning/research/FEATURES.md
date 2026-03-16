# Feature Research

**Domain:** Cross-platform fitness / strength training app with hormonal-cycle-aware training
**Researched:** 2026-03-16 (v1.1 launch readiness update; v1.0 original 2026-03-14)
**Confidence:** HIGH (core features verified across multiple sources; React Native-specific notes are MEDIUM based on library docs + community evidence)

---

## v1.1 Launch Readiness — Feature Landscape

This section covers the five feature areas that gate store submission: push notifications, analytics, crash reporting, device testing/verification, and Firestore security rules + store submission prep. All five are new to v1.1; the v1.0 feature landscape is preserved below.

---

### Table Stakes (Users Expect These — v1.1 scope)

Features required for a production app on any major platform. Missing these will trigger App Store or Play Store rejection, or signal to users the app is not production-grade.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Push notification permission prompt | iOS and Android both require explicit user consent before any notification is delivered. Missing the prompt means no notifications ever reach users. | LOW | Use `expo-notifications` `requestPermissionsAsync()`. Must explain why permissions are needed before prompting (Apple guideline). Prompt timing matters: too early in onboarding = high denial rate. Best practice: prompt on first workout completion or when user enters Settings > Notifications. |
| Local rest timer notification | Workout loop already has a rest timer. Users background the app mid-rest; they need a push when time expires. This is the most universally expected notification in any strength app. | LOW | Schedule with `expo-notifications` `scheduleNotificationAsync()`. Must cancel on early return to app. Does not require FCM — fires locally from device. Works offline. Dependency: existing rest timer component (already built). |
| Local streak / reminder notifications | Users expect to be reminded to train; habit-loop apps (Duolingo effect) have normalized daily nudges. Missing = low re-engagement. | LOW | Scheduled repeating local notification. User-configurable time. Cancel on workout completion for that day. Requires permission granted. |
| FCM remote push token registration | Required for any server-initiated notification (new WOD, subscription expiry, admin broadcasts). Without a stored token, no server can reach the device. | MEDIUM | Register token on app open with `expo-notifications` `getExpoPushTokenAsync()`. Store Expo push token (preferred) or native FCM token in Firestore under `users/{uid}/pushTokens`. Refresh on `addNotificationResponseReceivedListener`. Requires Firebase project configured for FCM V1 API. |
| New WOD remote notification | Users who depend on the WOD feed need to know a new one is available. No notification = feature goes unnoticed. | MEDIUM | Triggered by Firebase Cloud Function on WOD publish. Fan-out to all subscribed users. Requires FCM server integration from Cloud Functions. Dependency: FCM token stored per user. |
| Subscription expiry remote notification | Churned subscribers who don't notice expiry are a lost revenue opportunity. Standard practice in every subscription app. | MEDIUM | RevenueCat provides webhooks for `EXPIRATION` events. Cloud Function receives webhook, sends FCM to affected user. 3 days before + day-of is the standard cadence. |
| Crash reporting (Crashlytics) | Users do not file bug reports; they silently churn. Crash reporting is the only signal of native-layer failures. Expected by any team maintaining a production app. | MEDIUM | `@react-native-firebase/crashlytics` with config plugin in `app.config.js`. Requires custom dev build (cannot use Expo Go). Automatically captures native crashes. JS errors must be explicitly logged with `crashlytics().recordError(error)`. |
| Analytics funnel visibility (Firebase Analytics) | Without event tracking, decisions about subscription conversion, feature adoption, and retention are guesses. All mature apps instrument key flows. | MEDIUM | `@react-native-firebase/analytics`. Auto-logs screen views via Expo Router integration. Custom events needed for: `workout_started`, `workout_completed`, `subscription_started`, `ai_workout_generated`, `cycle_phase_updated`. Up to 500 distinct event types supported. |
| Privacy policy accessible in-app | Apple App Store and Google Play both require a working privacy policy URL. Apps without one are rejected. iOS additionally requires it be reachable from within the app itself (not just external URL). | LOW | Add privacy policy link in Settings screen. If not already built, a static web page hosted on any public URL is sufficient. Firestore user data + health data disclosures required. |
| App Store metadata (screenshots, description, keywords) | Required for submission. No screenshots = rejection. Poor metadata = zero organic discovery. | MEDIUM | Minimum: 3 screenshots per required device size (iPhone 6.7", 6.5", 5.5"; iPad if included). Each screenshot should demonstrate a core differentiator (cycle view, AI workout, workout logging). EAS Build does not generate these automatically. |
| Age rating declaration | Apple requires completing the age rating questionnaire before submission. Google requires the updated age rating form (deadline January 31 2026 for existing apps). Missing or incorrect = rejection or removal. | LOW | In App Store Connect: choose appropriate content rating. For Google Play Console: complete the questionnaire (Sundee Fundee has no violence, no sexual content, mild health data). |
| Health & fitness data declaration (Google Play) | Google requires apps that access health data to fill out the Health Features Declaration form. Sundee Fundee tracks cycle, injury, and workout data — all qualify. Missing = submission blocked. | LOW | In Play Console: Data Safety section. Declare: health and fitness data (cycle data), fitness info (workout logs). State that data is not shared with third parties for advertising. |
| Firebase App Check active in production | Prevents unauthorized callers from hitting Firestore and Cloud Functions. Already built (v1.0). Must be verified active and not in debug mode before submission. | LOW | Confirm `DeviceCheck` (iOS) and `Play Integrity` (Android) are configured, not `debug` providers. App Check enforcement should be on for Firestore and Cloud Functions in Firebase Console. Verify in Firebase Console > App Check > Apps tab. |
| Firestore security rules deployed to production | Default Firestore rules (test mode) allow any read/write. Shipping without proper rules means user data is publicly accessible. This is a critical security gate, not a feature. | MEDIUM | Rules must: (1) require auth for all user document reads/writes, (2) restrict users to their own `uid`-keyed documents, (3) allow public reads for programs and WODs, (4) block writes to programs/WODs from non-admin users. Deploy with Firebase CLI: `firebase deploy --only firestore:rules`. Test with Rules Simulator in Firebase Console before deploying. Propagation takes up to 10 minutes. |
| EAS production build configured | `eas build --platform ios --profile production` and equivalent for Android must produce store-ready binaries. Build config errors found only at submission time cause multi-day delays. | MEDIUM | `eas.json` must define a `production` profile with correct `bundleIdentifier` (iOS) and `applicationId` (Android). iOS requires a paid Apple Developer account and provisioning profile. Android requires a keystore (EAS generates and manages this). First Android Play Store submission must be manual (Google API requires at least one manual upload before API access). |

---

### Differentiators (v1.1 scope)

Features that go beyond baseline expectations and add launch-time value.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Notification preferences screen | Users who can control which notifications they receive are less likely to disable all of them. Granular opt-in (rest timer, streak reminders, WOD alerts, subscription alerts) reduces overall notification churn. | LOW | In-app toggle list in Settings. Store preferences in Firestore user document. Check preference before scheduling or sending each notification type. |
| Cycle-phase-aware workout reminder copy | "It's your follicular phase — a great week for a PR attempt" is more compelling than "Time to work out." Generic reminder apps do not do this. Sundee Fundee uniquely can. | LOW | Use current cycle phase from Firestore at notification send time. FCM data payload includes phase; notification body is selected from a phase-keyed copy bank. Requires Cloud Function to compose message. |
| Analytics user property: subscription status | Segmenting analytics by free vs. paid users reveals whether premium features are driving conversion. Without this, funnel analysis is blind to monetization signals. | LOW | Set `analytics().setUserProperties({ subscriptionTier: 'free' | 'premium' })` on auth + subscription state change. RevenueCat customer info is the source of truth. |
| Analytics user property: cycle tracking opt-in | Understanding what proportion of users activate cycle tracking, and whether they retain better, is the primary product hypothesis to validate post-launch. | LOW | Set as user property on onboarding completion and on cycle tracking toggle. Surfaces in Firebase Analytics audience explorer. |
| Crashlytics custom keys for debug context | Native crashes without context ("crash in libsystem_kernel.dylib") are undiagnosable. Attaching current screen, cycle phase, and subscription status to every crash report makes triage faster. | LOW | `crashlytics().setAttributes({ screen, cyclePhase, subscriptionTier })` on key state changes. These persist and appear on every crash report. |
| OTA update capability (EAS Update) | Hotfixes for JS-layer bugs can be shipped without a full App Store review cycle (usually 24-48 hours). Critical for launch week when issues are discovered quickly. | MEDIUM | `expo-updates` + EAS Update service. Not a substitute for native changes (which still require full submission). Configure `updates.url` in `app.config.js`. Publish with `eas update --branch production`. |

---

### Anti-Features (v1.1 scope)

Patterns that seem helpful but cause complexity or rejection risk.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Notification scheduling via background fetch | "Keep the rest timer accurate when the app is killed" | Background fetch on iOS is unreliable; iOS throttles background execution aggressively. A killed-app rest timer cannot be maintained with background fetch alone. | Schedule the notification at rest timer start with an absolute future timestamp. If the user returns to the app before the timer fires, cancel the scheduled notification. This is the only reliable approach. |
| Aggressive notification permission prompting (during onboarding) | "More prompts = more permissions granted" | iOS users who deny the first prompt cannot be re-prompted by the app; they must go to Settings manually. Prompting too early (before the user sees app value) results in high denial rates and kills the notification channel permanently. | Prompt after first workout completion, or from a Settings screen with explanation. Never prompt cold on launch. |
| Google Analytics / Mixpanel in parallel with Firebase Analytics | "More data sources = better insights" | Dual analytics creates conflicting funnel counts, increases SDK weight, and costs more. Two analytics systems are harder to maintain than one and neither is definitive. | Firebase Analytics covers all needs for launch (funnels, retention, custom events, user properties). Add Mixpanel only if product analytics (not just metrics) is needed post-PMF. |
| Sentry in addition to Crashlytics | "Belt and suspenders for crash reporting" | Dual crash reporters add SDK weight and can interfere with each other. Crashlytics is sufficient and already in the Firebase ecosystem (no additional account). | Use Crashlytics exclusively. Add Sentry only if non-JS crashes (native modules, third-party SDKs) are consistently missed by Crashlytics, which is rare. |
| Manual APNs certificate management | "I want full control over push credentials" | APNs certificates expire annually and require manual renewal; misconfigured certificates silently stop push delivery. | Use Expo's automatic credential management (`eas credentials`) or the Expo push service abstraction. Both handle APNs auth keys (which do not expire) rather than certificates. |
| Firestore rules in "test mode" (open read/write) for launch | "We'll tighten them later" | Open rules expose all user health data (cycle logs, injury profiles, workout history) to any authenticated or unauthenticated caller. This violates App Store data privacy requirements and creates real legal exposure with health data. | Deploy proper rules before production. The v1.1 milestone already has this flagged. No exceptions. |

---

## Feature Dependencies (v1.1 additions)

```
FCM Token Registration
    └──requires──> Auth (uid needed to store token in Firestore)
    └──enables──> New WOD Remote Notification
    └──enables──> Subscription Expiry Notification
    └──enables──> Cycle-Phase-Aware Reminder Copy

Local Rest Timer Notification
    └──requires──> expo-notifications permission granted
    └──requires──> existing rest timer component (already built)
    └──independent of──> FCM (fires locally, no server)

Firebase Analytics
    └──requires──> @react-native-firebase/app + @react-native-firebase/analytics
    └──requires──> custom dev build (not Expo Go)
    └──enhanced by──> Analytics User Properties (subscription status, cycle opt-in)

Crashlytics
    └──requires──> @react-native-firebase/app + @react-native-firebase/crashlytics
    └──requires──> custom dev build (not Expo Go, not expo-dev-client for native crash testing)
    └──enhanced by──> Crashlytics Custom Keys (screen, cycle phase, subscription tier)

EAS Production Build
    └──requires──> eas.json production profile configured
    └──requires──> Apple Developer paid account (iOS)
    └──requires──> Android keystore (EAS-managed)
    └──enables──> App Store submission
    └──enables──> Play Store submission
    └──enables──> EAS Update (OTA)

App Store Submission
    └──requires──> EAS production build (iOS)
    └──requires──> App Store Connect metadata (screenshots, description)
    └──requires──> Privacy policy URL (accessible in-app)
    └──requires──> Age rating questionnaire
    └──requires──> Firebase App Check in production mode

Play Store Submission
    └──requires──> EAS production build (Android)
    └──requires──> Health & Fitness data declaration
    └──requires──> Manual first upload (API cannot submit before first manual upload)
    └──requires──> Firestore security rules deployed

Firestore Security Rules
    └──requires──> Firebase CLI configured
    └──blocks──> both store submissions (security prerequisite)
    └──validates via──> Firebase Rules Simulator before deploy
```

### Dependency Notes

- **FCM token requires auth:** Never store a push token without a user UID. Guest users who haven't authenticated cannot receive targeted remote notifications — only broadcast topics (acceptable tradeoff for v1.1).
- **Analytics and Crashlytics both require custom dev builds:** `expo-dev-client` catches JS errors before Crashlytics can see them. For native crash testing specifically, remove `expo-dev-client` and run a standard debug build. During normal development, the dev client is fine; just confirm Crashlytics is capturing in a TestFlight or internal test track build before launch.
- **Firestore rules block both submissions:** Deploy and validate rules before either submission starts. Rules changes take up to 10 minutes to propagate; factor this into testing timeline.
- **First Play Store submission must be manual:** EAS Submit automates subsequent submissions, but Google requires one manual APK/AAB upload via Play Console before the API works. Do this before configuring EAS Submit for Android.
- **Notification permission prompt timing:** The first prompt is the only automated prompt iOS allows. If denied, the user must go to Settings > Notifications manually. Do not waste this prompt on first launch. Trigger it after demonstrated value (first workout complete).

---

## MVP Definition (v1.1)

### Launch With (v1.1)

The minimum to submit to App Store and Play Store with a production-quality experience.

- [ ] Local rest timer notification — in-workout critical path, already has timer component to hook into
- [ ] FCM token registration and storage — prerequisite for all remote notifications
- [ ] New WOD remote notification — FCM from Cloud Function on WOD publish
- [ ] Subscription expiry remote notification — RevenueCat webhook → Cloud Function → FCM
- [ ] Notification permission prompt (post-workout timing) — only one chance on iOS
- [ ] Firebase Analytics wired into: `workout_started`, `workout_completed`, `subscription_started`, `ai_workout_generated`, `cycle_phase_updated`, screen views via Expo Router
- [ ] Crashlytics active in production build with `recordError()` on catch boundaries
- [ ] Crashlytics custom keys: screen name, subscription tier, cycle phase
- [ ] Firestore security rules deployed and validated (blocks all submissions)
- [ ] Firebase App Check confirmed in production mode (not debug)
- [ ] EAS production build profiles configured for iOS and Android
- [ ] App Store Connect metadata: screenshots (6.7", 6.5"), description, keywords, privacy policy URL
- [ ] Play Store metadata: Health & Fitness declaration, data safety section, screenshots
- [ ] Age rating questionnaire completed (both stores)
- [ ] Privacy policy link in Settings screen

### Add After Validation (v1.x)

- [ ] Daily training reminder notification — add after push permission rates measured; don't pre-build if users aren't granting permissions
- [ ] Cycle-phase-aware notification copy — add after cycle tracking adoption is measured via Analytics
- [ ] OTA update (EAS Update) — add if launch-week hotfixes become necessary; not strictly needed before first submission
- [ ] Notification preferences screen — add after first notification type is live; no point building prefs with one notification type

### Future Consideration (v2+)

- [ ] Streak notification with motivational content — gamification pattern; validate retention data first
- [ ] Firebase Remote Config for notification copy — A/B testing notification messages requires validated user base first
- [ ] Push notification rich media (images in notification) — platform-specific implementation; extra complexity for marginal gain at launch

---

## Feature Prioritization Matrix (v1.1)

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Firestore security rules | HIGH (blocks submission + protects health data) | LOW | P1 |
| Local rest timer notification | HIGH | LOW | P1 |
| FCM token registration | HIGH (prerequisite for remote push) | LOW | P1 |
| Crashlytics | HIGH (without it, crashes are invisible) | MEDIUM | P1 |
| Firebase Analytics (key events) | HIGH (without it, post-launch decisions are blind) | MEDIUM | P1 |
| App Store metadata + screenshots | HIGH (required for submission) | MEDIUM | P1 |
| Play Store metadata + declarations | HIGH (required for submission) | LOW | P1 |
| EAS production build config | HIGH (required for submission) | MEDIUM | P1 |
| Privacy policy in-app link | HIGH (App Store rejection risk without it) | LOW | P1 |
| New WOD remote notification | MEDIUM | MEDIUM | P2 |
| Subscription expiry notification | MEDIUM | MEDIUM | P2 |
| Analytics user properties | MEDIUM (segment-level insight) | LOW | P2 |
| Crashlytics custom keys | MEDIUM (faster triage) | LOW | P2 |
| Notification preferences screen | MEDIUM | LOW | P2 |
| OTA update (EAS Update) | MEDIUM (launch-week safety net) | MEDIUM | P2 |
| Cycle-phase notification copy | LOW (differentiator, not table stakes) | LOW | P3 |
| Daily training reminder | LOW (depends on permission grant rate) | LOW | P3 |

**Priority key:**
- P1: Must have for store submission
- P2: Should have before launch, add in parallel
- P3: Nice to have, add post-launch based on data

---

## Competitor Feature Analysis (v1.1 context)

| Feature | Hevy | Strong | Fitbod | Our Approach |
|---------|------|--------|--------|--------------|
| Rest timer push notification | Yes | Yes | Yes | Yes — local, offline, schedule at timer start |
| Remote notifications (WOD/content) | No | No | Yes (workout reminders) | Yes — FCM via Cloud Function |
| Analytics instrumentation | Firebase (internal) | Internal | Internal | Firebase Analytics, visible in console |
| Crash reporting | Internal | Internal | Internal | Crashlytics, alertable |
| OTA update capability | Yes (Expo) | No (native) | Unknown | EAS Update (JS layer only) |
| Privacy policy in-app | Yes | Yes | Yes | Yes — Settings screen |
| Health data declaration (Play) | Yes | Yes | Yes | Yes — required before submission |

---

## Sources

- [Expo Notifications SDK Docs](https://docs.expo.dev/versions/latest/sdk/notifications/) — official, HIGH confidence
- [Expo Push Notifications Setup Guide](https://docs.expo.dev/push-notifications/push-notifications-setup/) — official, HIGH confidence
- [Expo — Using Push Notification Services](https://docs.expo.dev/guides/using-push-notifications-services/) — official, HIGH confidence
- [Expo — Send Notifications with FCM and APNs](https://docs.expo.dev/push-notifications/sending-notifications-custom/) — official, HIGH confidence
- [React Native Firebase — Crashlytics Usage](https://rnfirebase.io/crashlytics/usage) — official RNFirebase docs, HIGH confidence
- [React Native Firebase — Analytics Usage](https://rnfirebase.io/analytics/usage) — official RNFirebase docs, HIGH confidence
- [Expo — Using Firebase](https://docs.expo.dev/guides/using-firebase/) — official, HIGH confidence
- [Firebase — Best Practices for FCM Token Management](https://firebase.google.com/docs/cloud-messaging/manage-tokens) — official Firebase docs, HIGH confidence
- [Firebase — Get Started with Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started) — official Firebase docs, HIGH confidence
- [EAS Submit — Introduction](https://docs.expo.dev/submit/introduction/) — official, HIGH confidence
- [EAS Submit — iOS](https://docs.expo.dev/submit/ios/) — official, HIGH confidence
- [EAS Submit — Android](https://docs.expo.dev/submit/android/) — official, HIGH confidence
- [Expo — Deploy: Build for App Stores](https://docs.expo.dev/deploy/build-project/) — official, HIGH confidence
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — official Apple, HIGH confidence
- [iOS App Store Review Guidelines 2026](https://theapplaunchpad.com/blog/app-store-review-guidelines) — third-party summary, MEDIUM confidence
- [App Store App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) — official Apple, HIGH confidence
- [Google Play Health Apps Declaration](https://support.google.com/googleplay/android-developer/answer/14738291) — official Google, HIGH confidence
- [Google Play Health Apps Update: New January 2026 Requirements](https://myappmonitor.com/blog/google-play-health-apps-update-2026-requirements) — third-party summary, MEDIUM confidence
- [Expo — Publish Your Web App](https://docs.expo.dev/deploy/web/) — official, HIGH confidence
- [Expo — EAS Hosting Get Started](https://docs.expo.dev/eas/hosting/get-started/) — official, HIGH confidence
- [Expo GitHub fyi — First Android Submission](https://github.com/expo/fyi/blob/main/first-android-submission.md) — official Expo, HIGH confidence

---

## v1.0 Feature Landscape (preserved from 2026-03-14 research)

The section below documents the feature research that informed the v1.0 build. All features listed as v1.0 MVP are already built and verified.

---

### Table Stakes (v1.0 — all built)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Workout logging (sets, reps, weight) | Core loop of any strength app | LOW | Built |
| Rest timer (in-workout) | Strength training requires controlled rest periods | LOW | Built |
| Exercise library with instructions | Users can't log what they can't find | MEDIUM | Built (202+ exercises) |
| Personal records / 1RM tracking | PRs are the primary retention mechanic | LOW | Built |
| Workout history / chronological log | Users reference past sessions | LOW | Built |
| Progress charts and analytics | Visualizing strength gains | MEDIUM | Built |
| Offline functionality | Gyms have unreliable connectivity | HIGH | Built (Firestore offline persistence) |
| Auth with social/Apple sign-in | Users expect cross-device data recovery | LOW | Built (Apple, Google, Email, Guest) |
| Cloud sync / multi-device | Users switch between devices | MEDIUM | Built |
| Program/plan catalog | Many users want structure | MEDIUM | Built |
| Customizable workout builder | Experienced users want custom routines | MEDIUM | Built |
| Notifications and rest timer alerts | Users leave the app mid-workout | LOW | Rest timer built; push notifications are v1.1 |
| Settings: units (lbs/kg) | Internationalisation basics | LOW | Built |
| Account management and data export | Privacy + portability | LOW | Built |

### Differentiators (v1.0 — all built)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hormonal cycle phase tracking | No major cross-platform strength app does this | HIGH | Built |
| Cycle-aware load adaptation | Automatic weight/rep adjustment by cycle phase | HIGH | Built |
| Injury profile and adaptation engine | Adapts exercises around active injuries | HIGH | Built |
| AI workout generation (Gemini) | Personalized workout on demand | HIGH | Built (Cloud Functions) |
| Rehab session generation | Targeted rehab protocols | HIGH | Built |
| Pain trend analysis | Tracks pain over time, surfaces insights | MEDIUM | Built |
| Benchmark catalog with result tracking | Structured performance benchmarks | MEDIUM | Built |
| WOD (Workout of the Day) feed | Daily curated workouts | MEDIUM | Built |
| Readiness survey | Daily check-in feeds workout adaptation | LOW | Built |
| Android + Web reach | Cross-platform with React Native | HIGH | Built |
| Art Deco aesthetic | Distinctive visual identity | MEDIUM | Built (cream/navy/orange) |
| Dual pricing (RevenueCat + Stripe) | Web subscribers pay less | MEDIUM | Built |

### Anti-Features (v1.0 — deferred or avoided)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Social feed / friend activity | "Everyone does it" | Moderation cost; shifts product identity | PR notifications + program leaderboard |
| Video content / exercise streaming | Form guidance | Storage and CDN costs | Animated GIFs or illustrated statics; YouTube links |
| Real-time coaching / live classes | Peloton effect | Separate product (instructors, streaming) | Async AI workout feedback |
| Nutrition tracking / macro logging | One-app expectation | Distinct domain, dilutes focus | Phase-aware nutrition guidance (editorial) |
| Wearable integrations | "Watch app?" | Separate SDK targets; RN has limited watch support | HealthKit/Health Connect write-back |
| Data migration from iOS SwiftData app | Existing users want history | CloudKit → Firestore migration pipeline complexity | Fresh start, confirmed in PROJECT.md |
| Gamification points/levels/badges | "Makes it more fun" | Engagement loops require maintenance; power users find them patronising | PRs are the natural reward loop |

---

*Feature research for: Cross-platform fitness / strength training app (Sundee Fundee v1.1 launch readiness)*
*Researched: 2026-03-16*

# Stack Research

**Domain:** Cross-platform fitness app (iOS, Android, Web) — React Native + Expo + Firebase
**Researched:** 2026-03-16
**Confidence:** HIGH (push notifications, EAS build/submit — verified against official Expo and RNF docs), MEDIUM (Analytics/Crashlytics config plugin — one RNF regression noted and confirmed fixed)

---

## v1.1 Research Scope

This document **supplements** the v1.0 stack (see prior entries for Expo SDK 55, Firebase Auth/Firestore, RevenueCat, TypeScript domain layer). It covers **only new capabilities** needed for the v1.1 Launch Readiness milestone:

1. Push notifications — local (reminders, rest timers, streaks) + remote via FCM (new WOD, subscription expiring)
2. Firebase Analytics + Crashlytics
3. EAS production build pipeline
4. App Store, Play Store, and web store submission

---

## Recommended Stack

### Push Notifications

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `expo-notifications` | ~55.0.12 (already installed) | Token registration, local notification scheduling, foreground handler | Already in `package.json`. Single API for local and remote on iOS and Android. Handles APNs credential management automatically via EAS. Expo push tokens abstract the FCM/APNs split so you send to one endpoint for both platforms. SDK 54+ requires a development build — Expo Go no longer works for push. |
| `expo-device` | ~55.0.9 | Detect physical vs simulator at runtime | Simulators do not support push notifications. Required check before calling `getExpoPushTokenAsync` to avoid runtime crash. Not in `package.json` yet — needs install. |
| `expo-task-manager` | ~55.0.9 | Background task execution for headless notifications | Required to handle FCM data-only messages when app is backgrounded or killed. Pairs with `Notifications.registerTaskAsync`. Not in `package.json` yet — needs install. |
| `@react-native-firebase/messaging` | ^23.8.8 (match existing RNF version) | Raw FCM token access + background message handling on Android | `expo-notifications` handles most use cases, but `@react-native-firebase/messaging` is needed when you must send FCM data payloads directly (e.g., from Cloud Functions without routing through Expo Push Service). Also required to call `messaging().getToken()` for direct FCM sends from backend. Not in `package.json` yet — needs install. |

**Push architecture decision:** Use `expo-notifications` as the primary token registration and display layer for simplicity. Add `@react-native-firebase/messaging` only for the background data-message handler on Android (FCM silent pushes for WOD delivery). Do NOT use both for notification display — `expo-notifications` and `@react-native-firebase/messaging` both attempt to register Android notification channels, which conflicts. The pattern: expo-notifications owns display; messaging owns background data events.

**FCM V1 credential requirement (Android):** Expo push service requires a **Google Service Account Key JSON** (not the legacy server key) to relay FCM V1 messages. Set up via `eas credentials` → Android → production → Google Service Account. The `google-services.json` already in the project is for the app-side; the service account key is the server-side credential for EAS. Keep the service account JSON out of git.

**APNs (iOS):** EAS auto-manages APNs auth keys when you run `eas build`. No manual certificate work needed. The `GoogleService-Info.plist` already in the project covers the Firebase SDK side.

**Local notifications for this app:**

| Notification Type | Mechanism | Notes |
|------------------|-----------|-------|
| Rest timer complete | `scheduleNotificationAsync` with `TimeIntervalTrigger` | Fire once after N seconds. Cancel if user leaves workout. |
| Daily workout reminder | `scheduleNotificationAsync` with `DailyTrigger` | User-configurable time. Cancel + reschedule on settings change. |
| Streak at-risk reminder | `scheduleNotificationAsync` with `DailyTrigger` | Check if workout logged today; fire at 7 PM if not. Cancel on workout complete. |
| New WOD available | Remote push via Cloud Function → Expo Push API | Triggered by admin WOD publish. |
| Subscription expiring | Remote push via Cloud Function → Expo Push API | Triggered by RevenueCat webhook → Cloud Function. |

---

### Analytics and Crash Reporting

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@react-native-firebase/analytics` | ^23.8.8 (match existing RNF version) | User flow instrumentation, funnel analysis, screen tracking | Same RNF package family already in use for Firestore/Auth. Uses the native Firebase Analytics SDK — no separate init needed beyond adding the package and plugin. Automatically captures session counts, app open/close, device info. Zero additional Firebase project setup needed (Analytics is included in every Firebase project). Not in `package.json` yet — needs install. |
| `@react-native-firebase/crashlytics` | ^23.8.8 (match existing RNF version) | Crash reporting with symbolicated stack traces | Crashlytics is the standard for React Native crash reporting in the Firebase ecosystem. Captures both fatal crashes and non-fatal recorded errors. Uses the native Crashlytics SDK — faster reporting than JS-only solutions. Requires the `@react-native-firebase/crashlytics` config plugin in `app.json`. Not in `package.json` yet — needs install. |

**RNF v23.8 plugin regression (RESOLVED):** Versions 23.8.0–23.8.2 had an Expo config plugin validation error ("Package does not contain a valid config plugin"). This was fixed in 23.8.3 and further patched in 23.8.4. The current npm latest is 23.8.8 — safe to use. Pin to `^23.8.8` (already the version of other RNF packages in the project).

**Crashlytics limitation during development:** When running via `expo-dev-client`, `expo-dev-client` catches JS errors before Crashlytics can report them. Non-fatal recorded errors (`crashlytics().recordError(e)`) still work. Fatal crash reporting only works in production or preview builds — not in development builds.

**Key events to instrument for this app:**

| Event | Where to Fire | Why |
|-------|--------------|-----|
| `workout_started` | Workout session screen mount | Funnel top of key user action |
| `workout_completed` | Post-workout summary save | Primary success metric |
| `workout_abandoned` | App background during workout | Churn signal |
| `ai_workout_generated` | After AI generation success | Feature adoption |
| `subscription_paywall_viewed` | Paywall screen mount | Conversion funnel |
| `subscription_purchased` | RevenueCat purchase callback | Revenue event |
| `cycle_phase_changed` | Phase inference update | Feature engagement |
| `pr_detected` | PR toast trigger | Delight moment / retention signal |

---

### EAS Build Pipeline

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| EAS CLI | 18.4.0 (current on npm) | Cloud builds, submit, credentials management | Project already has EAS configured (`eas.json` with development/preview/production profiles, EAS project ID `dc7c3b9d-ee13-4713-8fab-85389863e18f` in `app.json`). EAS Build auto-manages Android keystore and iOS distribution certificates via `eas credentials`. |
| EAS Submit | bundled with EAS CLI | Automated App Store and Play Store upload | Uploads `.ipa` and `.aab` to App Store Connect and Google Play Console. Requires App Store Connect API key (iOS) and Google Service Account key (Android). |

**Current `eas.json` is minimal — needs expansion for production submit:**

```json
{
  "cli": { "version": ">= 13.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": { "FIREBASE_APP_CHECK_DEBUG_TOKEN": "<token>" }
    },
    "preview": { "distribution": "internal" },
    "production": {}
  },
  "submit": {
    "production": {
      "ios": {
        "ascAppId": "<app-store-connect-apple-id>"
      },
      "android": {
        "serviceAccountKeyPath": "./google-play-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

Add the `submit.production` block. The `ascAppId` comes from App Store Connect → App Information → Apple ID (numeric, not bundle ID). The Google Play service account JSON is a separate credential from the FCM service account — it is a service account with Play Developer API access granted in Google Cloud Console.

**iOS submission prerequisites (one-time setup):**
1. Create App ID in App Store Connect with bundle identifier `com.sundeefundee.app`
2. Generate App Store Connect API key (under Users and Access → Keys) — store the `.p8` file and note Key ID + Issuer ID
3. Run `eas credentials` to link the API key — EAS stores it securely, no local file needed after upload
4. First submission can be automated; no manual Xcode upload required

**Android submission prerequisites (one-time setup):**
1. Create app in Google Play Console with package `com.sundeefundee.app`
2. **First upload must be manual** (Google Play API limitation) — upload an `.aab` via Play Console UI to the Internal Testing track
3. Create a Google Play service account in Google Cloud Console with `Release Manager` role on the Play app
4. Download the service account JSON; upload via `eas credentials` (keep out of git)
5. Subsequent builds can use `eas submit --platform android --profile production`

**Recommended build commands for submission:**

```bash
# Build both platforms for production (triggers EAS cloud build)
eas build --platform all --profile production

# Auto-submit to stores after build completes
eas build --platform all --profile production --auto-submit

# Submit an existing build manually
eas submit --platform ios --profile production --latest
eas submit --platform android --profile production --latest
```

---

### app.json Plugin Additions

The `app.json` `plugins` array needs the following additions for the new packages:

```json
"plugins": [
  "@react-native-firebase/app",
  "@react-native-firebase/auth",
  "@react-native-firebase/crashlytics",
  [
    "expo-notifications",
    {
      "icon": "./assets/notification-icon.png",
      "color": "#0D1A40",
      "enableBackgroundRemoteNotifications": true
    }
  ],
  "expo-apple-authentication",
  [
    "expo-build-properties",
    {
      "ios": {
        "useFrameworks": "static",
        "forceStaticLinking": [
          "RNFBApp",
          "RNFBAuth",
          "RNFBFirestore",
          "RNFBAppCheck",
          "RNFBMessaging",
          "RNFBCrashlytics"
        ]
      }
    }
  ],
  "@react-native-google-signin/google-signin",
  "expo-router",
  "expo-secure-store",
  "expo-sharing",
  "expo-audio"
]
```

Key changes:
- Add `"@react-native-firebase/crashlytics"` plugin (handles Android Gradle setup automatically)
- Add `expo-notifications` plugin with `enableBackgroundRemoteNotifications: true` (sets `UIBackgroundModes: remote-notification` in iOS Info.plist — required for background FCM handling)
- Add `"RNFBMessaging"` and `"RNFBCrashlytics"` to `forceStaticLinking` array

---

## Installation

Packages not yet in `package.json` that need to be added:

```bash
# Push notifications (supporting packages)
npx expo install expo-device expo-task-manager

# FCM messaging (background data messages)
npx expo install @react-native-firebase/messaging

# Analytics and crash reporting
npx expo install @react-native-firebase/analytics @react-native-firebase/crashlytics
```

Note: `expo-notifications` is already installed at `~55.0.12`. `expo-constants` is already installed. All `@react-native-firebase/*` packages must stay at the same version — install with `npx expo install` to get the compatible version resolved automatically.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `expo-notifications` (primary) + `@react-native-firebase/messaging` (background only) | `@react-native-firebase/messaging` for everything | Use RNF messaging exclusively only if you are NOT using the Expo Push Service and are sending all pushes directly via FCM. This project uses Expo Push Service for simplicity, so `expo-notifications` leads. |
| Firebase Crashlytics | Sentry | Choose Sentry if you need cross-platform error tracking that includes web errors in the same dashboard. Firebase Crashlytics is native-crash-focused. Since this project already uses Firebase for everything else, Crashlytics avoids adding a new vendor. |
| Firebase Analytics | Amplitude, Mixpanel | Choose Amplitude or Mixpanel if you need advanced funnel analysis, cohort analysis, or A/B testing infrastructure. Firebase Analytics is sufficient for launch-phase metrics at zero additional cost. |
| EAS Submit (automated) | Transporter / Xcode Organizer (iOS), Play Console UI (Android) | Manual upload is required only for the first Android upload (API limitation). After that, EAS Submit handles everything. iOS can be fully automated from day one. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `expo-firebase-analytics` (npm package) | Deprecated shim that wraps the old `@react-native-firebase/analytics`. No longer maintained. Has a separate `expo-firebase-analytics` package on npm that is not the same as the RNF package. | `@react-native-firebase/analytics` directly. |
| Both `expo-notifications` and `@react-native-firebase/messaging` for display | Both libraries attempt to register Android notification channels. Concurrent channel registration causes silent notification failures on Android. | expo-notifications for scheduling and display; messaging for background data event handling only. Do not call `messaging().onMessage()` to display notifications — let expo-notifications handle display. |
| `@react-native-firebase/messaging` as the sole push solution | Loses the Expo push token abstraction. Means you must maintain separate FCM and APNs sending paths in your backend (Cloud Functions). More backend complexity for the same outcome. | expo-notifications + Expo Push Service for token management, with messaging for background-only events. |
| Storing Google Play service account JSON in git | Contains private keys that allow full Play Store publish access. Leaking this key allows anyone to push app updates to production. | Upload to EAS via `eas credentials` and add the file to `.gitignore`. |
| Storing FCM service account JSON in git | Contains credentials to send push notifications to all users. | Upload to EAS via `eas credentials`. Pass to Cloud Functions via Firebase environment config, not hardcoded. |
| `eas build --auto-submit` for Android before first manual upload | Google Play API rejects programmatic uploads until the app exists in Play Console with at least one manual upload. Silently fails with a 403. | Upload the first `.aab` manually to Play Console Internal track, then automate all subsequent submissions. |
| Sentry for crash reporting alongside Crashlytics | Two crash reporters running simultaneously cause duplicated events and can interfere with each other's symbolication. | Pick one. Crashlytics is already in the Firebase ecosystem — use it. |

---

## Stack Patterns by Variant

**If push notification permissions are denied:**
- Do not re-prompt immediately. Store denial in MMKV, surface a soft prompt after the user completes 3 workouts.
- Local notifications (rest timer) still fire if permission is granted; do not disable the feature entirely on denial.

**If running on iOS simulator (no push support):**
- `expo-device` `isDevice` check must gate `getExpoPushTokenAsync` calls to prevent runtime error.
- Log a dev-only console warning; do not surface to user.

**If the app is in foreground when a remote push arrives:**
- `setNotificationHandler` must return `{ shouldShowAlert: true, shouldPlaySound: true, shouldSetBadge: false }` explicitly.
- Default behavior is to suppress the notification banner in foreground — this must be overridden.

**For background FCM data messages (WOD delivery):**
- Cloud Function sends a data-only message (no `notification` key, only `data` key) to trigger `registerTaskAsync` handler.
- iOS requires `content-available: 1` in the FCM payload.
- Android requires `priority: high` in the FCM payload.
- The background task should write new WOD data to local cache only — do not trigger a Firestore write from a background task.

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `@react-native-firebase/analytics` ^23.8.8 | Expo SDK 55, RN 0.83 | Must match other `@react-native-firebase/*` packages. Versions 23.8.0–23.8.2 had an Expo plugin regression — fixed in 23.8.3+. 23.8.8 is safe. |
| `@react-native-firebase/crashlytics` ^23.8.8 | Expo SDK 55, RN 0.83 | Same version constraint as analytics. Requires its own config plugin entry in `app.json`. |
| `@react-native-firebase/messaging` ^23.8.8 | Expo SDK 55, RN 0.83 | Must add `"RNFBMessaging"` to `forceStaticLinking` in `expo-build-properties` iOS config. |
| `expo-notifications` ~55.0.12 | Expo SDK 55 | Already installed. Background remote notifications require `enableBackgroundRemoteNotifications: true` in the plugin config. |
| `expo-task-manager` ~55.0.9 | Expo SDK 55 | Peer dependency for `Notifications.registerTaskAsync`. Must be installed even if not explicitly called — expo-notifications background tasks pull it in at build time. |
| `expo-device` ~55.0.9 | Expo SDK 55 | Lightweight — just device type detection. No native module build overhead. |
| EAS CLI 18.4.x | Expo SDK 55 | `eas.json` `cli.version` constraint `>= 13.0.0` already covers this. |

---

## Sources

- [Expo Push Notifications Setup](https://docs.expo.dev/push-notifications/push-notifications-setup/) — Package requirements, FCM V1 credentials, SDK 54+ development build requirement (HIGH confidence)
- [Expo Notifications API Reference](https://docs.expo.dev/versions/latest/sdk/notifications/) — `scheduleNotificationAsync`, trigger types, background task handler, `enableBackgroundRemoteNotifications` plugin option (HIGH confidence)
- [Expo FCM Credentials Guide](https://docs.expo.dev/push-notifications/fcm-credentials/) — Service account key setup for FCM V1 via `eas credentials` (HIGH confidence)
- [EAS Submit — iOS](https://docs.expo.dev/submit/ios/) — App Store Connect API key requirements, `ascAppId` (HIGH confidence)
- [EAS Submit — Android](https://docs.expo.dev/submit/android/) — Google Play service account, first-manual-upload limitation (HIGH confidence)
- [EAS Build Setup](https://docs.expo.dev/build/setup/) — Auto-managed credentials, `eas build:configure` (HIGH confidence)
- [React Native Firebase — Crashlytics Usage](https://rnfirebase.io/crashlytics/usage) — Config plugin requirement, dev-client limitation (HIGH confidence)
- [React Native Firebase — Analytics Usage](https://rnfirebase.io/analytics/usage) — Installation, Expo setup (HIGH confidence)
- [RNF Issue #8829](https://github.com/invertase/react-native-firebase/issues/8829) — v23.8.0–23.8.2 Expo plugin regression, confirmed fixed in 23.8.3+ (HIGH confidence — official issue tracker)
- [Expo — Using Push Notification Services](https://docs.expo.dev/guides/using-push-notifications-services/) — Expo Push Service vs direct FCM/APNs (HIGH confidence)
- [npm: expo-notifications](https://www.npmjs.com/package/expo-notifications) — Version 55.0.12 confirmed (HIGH confidence)
- [Expo Task Manager](https://docs.expo.dev/versions/latest/sdk/task-manager/) — `defineTask`, `registerTaskAsync` for background notifications (HIGH confidence)

---
*Stack research for: Sundee Fundee v1.1 Launch Readiness — push notifications, analytics, EAS build/submit additions*
*Researched: 2026-03-16*

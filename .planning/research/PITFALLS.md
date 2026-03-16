# Pitfalls Research

**Domain:** React Native + Expo + Firebase fitness app (cross-platform rewrite from native iOS)
**Researched:** 2026-03-16 (v1.1 update — launch readiness pitfalls appended)
**Confidence:** HIGH (verified against official docs and multiple independent sources)

---

## Critical Pitfalls

### Pitfall 1: Firebase JS SDK vs React Native Firebase — Wrong SDK for the Job

**What goes wrong:**
Teams start with the Firebase JS SDK (the npm `firebase` package) because it is familiar and well-documented. On Expo SDK 53+, Metro's new `unstable_enablePackageExports: true` default conflicts with Firebase's CommonJS `.cjs` files used for React Native compatibility. Auth components fail to register ("Component auth has not been registered yet"), analytics/Crashlytics/Dynamic Links are unavailable entirely, and offline persistence behaves differently than on native because the JS SDK uses IndexedDB (browser) rather than the native SQLite persistence layer.

**Why it happens:**
The Firebase JS SDK documentation is written for web. Developers reuse what they know. Expo's quick-start guides historically showed the JS SDK, creating muscle memory. Expo SDK 53 broke previously-working JS SDK setups without obvious error messages.

**How to avoid:**
Use `@react-native-firebase` (the Invertase library) from day one. This requires a custom Development Build — do not use Expo Go. Configure EAS Build from project initialization. Never mix the JS SDK and the native Firebase SDK in the same project (this causes the "dual package hazard" that produces silent failures).

**Warning signs:**
- "Component auth has not been registered yet" error
- Auth state is lost on app restart (falling back to in-memory persistence)
- Firestore offline queries returning stale or empty data on cold start
- Build-time Metro errors about `exports` field resolution

**Phase to address:** Project scaffold / Phase 1 — foundation decision. Changing SDK mid-project requires removing all SDK references.

---

### Pitfall 2: Firestore Offline Persistence — await on Writes Blocks UI

**What goes wrong:**
The app is advertised as offline-first. Developers write code like `await firestore().collection('workouts').doc(id).set(data)`. When the device has no connection, this promise does not resolve until the write is acknowledged by the server. The UI freezes or shows a spinner indefinitely during an active gym session. Users see a broken experience at exactly the moment offline-first matters most.

**Why it happens:**
Developers port server-side patterns (await the write, then navigate) to mobile without understanding that Firestore's offline mode uses an optimistic local cache. The write is applied locally immediately, but the SDK does not resolve the promise until the server confirms — which may never happen offline.

**How to avoid:**
Never await Firestore write operations in user-interactive flows. Fire-and-forget: call the write without `await`, update local UI state optimistically, and let Firestore sync in the background. Use Firestore's `onSnapshot` listeners for real-time state rather than awaiting reads after writes.

**Warning signs:**
- UI "freezes" or shows loading spinner when device is in airplane mode
- Workout timers continue but the "save" action appears to hang
- Offline test: put device in airplane mode, complete a workout, observe save behavior

**Phase to address:** Phase covering workout execution and data persistence — before any end-to-end offline testing.

---

### Pitfall 3: Expo Managed Workflow Ceiling — Discovering Native Gaps Too Late

**What goes wrong:**
The project starts in Expo managed workflow for simplicity. Months into development, a required native capability (background task for workout timers, specific HealthKit entitlement, custom notification category, or a native SDK) hits a wall. Ejecting to bare workflow mid-project is disruptive: it invalidates existing EAS Build configurations, breaks OTA update channels, and requires manually managing `ios/` and `android/` directories.

**Why it happens:**
Managed workflow is attractive because it removes native complexity. The Expo docs show compatibility lists, but developers assume "will work eventually" for borderline cases without verifying. Fitness apps specifically have requirements (background audio, persistent timers, foreground service on Android) that push against managed workflow limits.

**How to avoid:**
Audit every required native capability against Expo's managed workflow compatibility list before starting. For this project specifically: background task for active workout timers, HealthKit integration on iOS, RevenueCat StoreKit integration, Sign in with Apple, Firebase Analytics/Crashlytics. If any require bare workflow or a custom Config Plugin not yet available, switch to bare workflow from the start rather than ejecting later. Using EAS Build with a Development Client is not the same as ejecting — prefer Development Client for native modules before considering bare workflow.

**Warning signs:**
- Discovering a library's README says "requires bare workflow" after install
- `expo-doctor` flagging incompatible plugins
- A required feature can only be found as a native-only library with no Expo Config Plugin

**Phase to address:** Phase 1 scaffold — final capability audit before committing to workflow.

---

### Pitfall 4: OTA Updates Breaking Native-Dependent Code

**What goes wrong:**
An OTA update (via Expo Updates / EAS Update) ships a JS bundle change to users. The change uses a dependency that added native code in a minor version bump. Users on the old binary crash silently because the native module the JS bundle references does not exist in the installed binary. This is particularly dangerous for fitness apps where crashes during an active workout are unacceptable.

**Why it happens:**
Teams use OTA updates as a fast-release shortcut without verifying whether dependencies changed their native surface area. A `yarn upgrade` followed by an OTA push is a common mistake. The native module is missing but no build error occurs — it fails only at runtime on user devices.

**How to avoid:**
Use Expo's fingerprint tooling (`expo-updates` fingerprint) to compare native surface area between commits before every OTA push. Establish a rule: if any dependency version changed, do a full EAS Build before pushing OTA. Use separate EAS Update channels (staging, production) and test against representative binaries before rolling out to 100% of users. Never use OTA updates to ship subscription/payment changes.

**Warning signs:**
- Spike in crash rates immediately after an OTA push
- `npx expo install --check` showing version mismatches after `yarn upgrade`
- A library changelog mentioning "added native module" in a minor update

**Phase to address:** CI/CD setup phase — establish policies before any OTA updates are pushed.

---

### Pitfall 5: Sign in with Apple — Missing User Data on Subsequent Logins

**What goes wrong:**
Apple only returns the user's full name and email address on the very first Sign in with Apple authorization. On all subsequent sign-ins, these fields are null. If the app does not persist name and email to Firestore on first login, users end up with no display name, and there is no recovery path short of the user revoking and re-granting Apple login (which most users will not know to do).

**Why it happens:**
Developers test the happy path (first login) and it works perfectly. The email and name appear in the credential. Subsequent logins during development reuse a cached token, masking the bug. It surfaces only after real users install the app and log in a second time on a new device or after revoking app access.

**How to avoid:**
On the very first successful Sign in with Apple, immediately write name and email to Firestore before doing anything else. Treat this write as the most critical step of onboarding. Test by: (1) sign in, (2) revoke Apple authorization in iOS Settings > Apple ID > Sign in with Apple, (3) sign in again, (4) verify the display name is still correct.

Additionally: Firebase does not store user tokens for Sign in with Apple — account deletion requires the user to sign in again before the token can be revoked. Build account deletion with this in mind from the start.

**Warning signs:**
- Display names missing for users who signed up via Apple after initial onboarding
- User complaints about profile showing blank name

**Phase to address:** Auth phase — make this a first-class acceptance criterion for the Apple sign-in implementation.

---

### Pitfall 6: Firestore Security Rules Left Open — Health Data Exposure

**What goes wrong:**
Firestore is initialized in test mode during development (`allow read, write: if true`). The app ships — or a staging environment is accidentally indexed — with open rules. Cycle data, health metrics, injury profiles, and workout history are accessible to anyone who knows the project ID (which is in the app binary and easily extracted via APK decompilation). Automated scanners actively target Firebase projects with open rules.

**Why it happens:**
Test mode is the default for new Firestore projects. Developers focus on features and defer security. Cycle health data and readiness survey responses are among the most sensitive personal health data categories — a breach carries significant regulatory and reputational risk.

**How to avoid:**
Write production security rules on day one, before writing any data. Never ship with test mode rules. Rules must enforce: (1) users can only read/write their own documents (`request.auth.uid == resource.data.userId`), (2) admin collections (programs, WODs) are read-only for users, (3) no user can write admin flag fields. Build a Firestore Rules test suite (`firebase-rules-unit-testing`) and run it in CI. Include rules testing in the definition of "done" for every data model phase.

**Warning signs:**
- Firebase console showing "your rules are insecure" banner
- Ability to query another user's document from a different account in the emulator
- `allow write: if true` anywhere in rules that reached production

**Phase to address:** Phase 1 data architecture — rules must be written alongside the first data model, not after.

---

### Pitfall 7: RevenueCat + Stripe Entitlement Sync — Users Paying Without Getting Access

**What goes wrong:**
A user subscribes via the Stripe web checkout but the mobile app still shows the paywall because RevenueCat has not been notified of the Stripe transaction. This happens because RevenueCat does not automatically poll Stripe — it requires an explicit POST to the RevenueCat REST API linking the Stripe subscription to the app user ID. Similarly, Stripe cancellation events can take up to two hours to reflect in RevenueCat, meaning users who cancelled may retain access and users who purchased may be denied.

**Why it happens:**
RevenueCat's Stripe integration documentation is not prominently featured in the React Native quick-start guides. Teams assume RevenueCat handles all payment sources automatically, as it does for in-app purchases.

**How to avoid:**
Build a Firebase Cloud Function Stripe webhook handler that, on `checkout.session.completed` and `customer.subscription.updated` events, immediately calls the RevenueCat REST API to sync the subscription. Ensure the same `appUserID` is used in both systems — Firebase Auth UID is the right choice as the RevenueCat user identifier. For one-time purchases through Stripe, sync is never automatic; always use the webhook approach.

Entitlement names must match exactly between RevenueCat dashboard and app code — case-sensitive.

**Warning signs:**
- Web subscribers seeing paywall in the mobile app
- Customer support tickets: "I paid but the app says I'm not subscribed"
- RevenueCat dashboard showing user with no active subscriptions despite Stripe showing active subscription

**Phase to address:** Payments phase — design the webhook sync before implementing the Stripe checkout, not after.

---

### Pitfall 8: Domain Logic Port — Floating Point and Date Semantics Differ from Swift

**What goes wrong:**
The iOS app's Domain layer (21+ Swift files) uses Swift's `Date`, integer division, and enum-based type safety. When ported to TypeScript, subtle numeric and date differences cause incorrect cycle phase calculations, wrong benchmark scores, or off-by-one errors in injury recovery phase transitions. JavaScript's `Date` does not distinguish between local and UTC, there is no integer division operator (use `Math.floor(a / b)`), and TypeScript enums behave differently from Swift enums in edge cases.

**Why it happens:**
Swift-to-TypeScript ports feel straightforward because both are statically typed. The differences are subtle: Swift's `Date` is always UTC, JavaScript's `Date.now()` is UTC but `new Date()` displays in local time. Swift uses integer division by default; JS divides to float. Benchmark `roundsAndReps` scoring (`rounds * 10000 + reps`) decodes correctly in Swift's integer math but silently produces floating-point noise in JavaScript without explicit `Math.floor`.

**How to avoid:**
Store all dates as Unix timestamps (seconds since epoch) in Firestore. Never use `new Date()` string representations in stored data. Port every Domain function with a corresponding TypeScript unit test that uses the same inputs as the Swift test suite. Pay specific attention to: benchmark score encoding/decoding, cycle day calculations (period log → phase inference), and injury recovery phase multiplier math. Use `date-fns` or `dayjs` rather than raw `Date` for calendar arithmetic.

**Warning signs:**
- Cycle phase showing "Follicular" when iOS app shows "Luteal" for the same log data
- Benchmark results off by small decimal amounts
- TypeScript tests passing but producing subtly wrong outputs compared to Swift baseline

**Phase to address:** Domain logic port phase — establish baseline parity tests against the Swift domain layer before any UI integration.

---

## v1.1 Launch Readiness Pitfalls

These pitfalls are specific to adding push notifications, analytics, crash reporting, and submitting to stores — all added on top of the existing v1.0 system.

---

### Pitfall 9: expo-notifications + @react-native-firebase Dual Notification Service Conflict

**What goes wrong:**
The project already uses `@react-native-firebase/app` with `forceStaticLinking` and `useFrameworks: static` in `app.json`. Adding `@react-native-firebase/messaging` alongside `expo-notifications` creates a conflict: both libraries attempt to register an FCM message handler and claim the Android notification channel. On Android, both services try to set `com.google.firebase.messaging` values, causing duplicate channel registrations, swallowed notifications, and build errors. On iOS, APNs token registration may occur twice, leading to unpredictable behavior.

The project's `app.json` already has `RNFBApp`, `RNFBAuth`, `RNFBFirestore`, and `RNFBAppCheck` in `forceStaticLinking`. Adding `RNFBMessaging` without understanding the interaction with `expo-notifications` causes silent failures.

**Why it happens:**
Developers pick one library for local notifications (`expo-notifications`) and another for remote push via FCM (`@react-native-firebase/messaging`) without reading the compatibility guidance. The two libraries both wrap FCM at the native layer and fight for control of the message delegate.

**How to avoid:**
Pick one approach and use it exclusively:
- **Option A (recommended for this project):** Use `expo-notifications` for all notifications (local + remote). Configure FCM v1 credentials in EAS (`eas credentials`), register the FCM token via `expo-notifications` `getDevicePushTokenAsync()`, and send remote pushes using the Expo Push API or directly via FCM v1 HTTP API with the Expo-issued FCM token. Do NOT install `@react-native-firebase/messaging`.
- **Option B:** Use `@react-native-firebase/messaging` exclusively, add it to `forceStaticLinking` (`RNFBMessaging`), and replace all local notification scheduling with its API. Remove `expo-notifications`.

If remote notifications must route through Firebase Cloud Functions already in the project, Option A is cleanest: Cloud Functions call FCM v1 API directly with the token stored in Firestore, and `expo-notifications` handles all client-side display.

**Warning signs:**
- Android build errors mentioning duplicate `com.google.firebase.messaging` values
- Notifications arriving silently (not displayed) on Android despite correct permission
- `forceStaticLinking` array not containing `RNFBMessaging` but messaging module installed

**Phase to address:** Push notification phase — library selection must happen before any native build with notifications.

---

### Pitfall 10: iOS Foreground Notifications Not Showing Without setNotificationHandler

**What goes wrong:**
Push notifications and local notifications work correctly when the app is in the background or killed state on iOS. When the app is in the foreground, notifications are silently swallowed. Users never see rest timer alerts, streak reminders, or WOD notifications while actively using the app.

**Why it happens:**
On iOS, the system suppresses notifications when the app is in the foreground by default. Unlike Android, which shows notifications automatically, iOS requires the app to explicitly declare what to do with foreground notifications via a notification handler. This is an iOS platform rule that `expo-notifications` exposes but does not automatically configure.

**How to avoid:**
Call `Notifications.setNotificationHandler` at the root of the app (in `App.tsx` or the root layout, before any navigation renders) with the appropriate handler:

```typescript
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});
```

This must execute before any notification is scheduled or received. If placed inside a component that mounts after navigation, foreground notifications will still be missed during the window between app start and component mount.

**Warning signs:**
- Notifications appearing on the lock screen or notification center but not as banners while app is open
- Test: schedule a local notification 5 seconds out, keep app open, observe — no banner = missing handler

**Phase to address:** Push notification phase — add the handler as the first line of notification setup, before any scheduling logic.

---

### Pitfall 11: Firebase Crashlytics Not Reporting Crashes in Development Builds

**What goes wrong:**
The development build uses `expo-dev-client`. Developers add `@react-native-firebase/crashlytics`, trigger test crashes, open the Firebase Crashlytics dashboard, and see nothing. They conclude the integration is broken and spend hours debugging a non-existent problem. The real cause: `expo-dev-client` provides its own error overlay that intercepts native crashes before Crashlytics can report them.

Additionally, `firebase.json` (used to set `crashlytics_debug_enabled: true`) does not work in Expo managed workflow apps. The file is not processed by Expo's build system.

**Why it happens:**
The `expo-dev-client` documentation and the Crashlytics documentation are written independently and do not cross-reference this incompatibility. Developers follow both docs correctly and still get no results in development.

**How to avoid:**
- Add `@react-native-firebase/crashlytics` config plugin to `app.json` (handles Android gradle setup).
- Add `RNFBCrashlytics` to the `forceStaticLinking` array in `app.json` alongside existing RNFB entries.
- Accept that Crashlytics does not work in `development` builds — test crash reporting only in `preview` or `production` builds (EAS profiles without `developmentClient: true`).
- Build a `preview` EAS profile specifically for Crashlytics testing: `eas build --profile preview`.
- Do not try to configure `firebase.json` in Expo managed workflow — use the config plugin exclusively.
- Verify integration works by building a preview build, triggering `crashlytics().crash()`, force-closing the app, reopening it, and checking the Firebase console (crashes appear after 5-10 minutes).

**Warning signs:**
- Crashes not appearing in Firebase console during development build testing
- `firebase.json` file at project root not having any effect
- Attempting to set `crashlytics_debug_enabled` has no impact

**Phase to address:** Analytics and crash reporting phase — set the correct expectations in the phase brief before engineers start testing.

---

### Pitfall 12: @react-native-firebase/analytics Has No Web Support — Silent No-Op on Web Platform

**What goes wrong:**
The app targets iOS, Android, and Web. `@react-native-firebase/analytics` is added and works on iOS and Android. On web, analytics calls are silently no-ops — events are never sent to Firebase Analytics. The web platform has zero crash reporting and zero analytics instrumentation, which makes web funnel analysis impossible. This goes undetected because there are no errors, just missing data.

**Why it happens:**
`@react-native-firebase` uses native SDKs on iOS and Android. For "other" platforms (including web), it uses a JavaScript fallback that does not support automatic screen view tracking and has limited analytics support. The app already uses the Firebase JS SDK (`firebase` package) for web auth and Firestore — but analytics instrumentation is not wired up for the web build.

**How to avoid:**
For web analytics, use the Firebase JS SDK's analytics module directly:

```typescript
// analytics.web.ts
import { getAnalytics, logEvent } from 'firebase/analytics';
import { getApp } from 'firebase/app';

export function trackEvent(name: string, params?: Record<string, unknown>) {
  const analytics = getAnalytics(getApp());
  logEvent(analytics, name, params);
}
```

```typescript
// analytics.native.ts
import analytics from '@react-native-firebase/analytics';

export function trackEvent(name: string, params?: Record<string, unknown>) {
  analytics().logEvent(name, params);
}
```

Use the project's existing `.native.ts` / `.web.ts` platform file pattern (already established in `src/firebase/auth.web.ts` and `src/services/callCloudFunction.web.ts`) to resolve the correct implementation per platform. This gives unified analytics calls across all three platforms.

**Warning signs:**
- Firebase Analytics dashboard showing zero web events while mobile events appear
- No `measurementId` configured in the web Firebase app config
- Analytics calls in shared code but no `.web.ts` counterpart

**Phase to address:** Analytics phase — design the analytics service file with `.native.ts` / `.web.ts` split from the start, matching the existing project pattern.

---

### Pitfall 13: forceStaticLinking Array Incomplete When Adding New RNFB Modules

**What goes wrong:**
The existing `app.json` has `forceStaticLinking: ["RNFBApp", "RNFBAuth", "RNFBFirestore", "RNFBAppCheck"]`. When `@react-native-firebase/analytics` and `@react-native-firebase/crashlytics` are added, iOS builds fail with linker errors or non-modular header errors because the new modules are not in `forceStaticLinking`. The errors are cryptic (`Non-modular header inside framework module`) and can send engineers down the wrong diagnostic path.

**Why it happens:**
The `forceStaticLinking` requirement is not automatically inferred from installed packages — it must be manually maintained. The React Native Firebase docs mention this for the initial setup but do not prominently warn that every new RNFB module must be added to the array.

**How to avoid:**
Whenever a new `@react-native-firebase/*` package is added, immediately add its pod name to `forceStaticLinking` in `app.json`:

| Package | Pod name to add |
|---------|----------------|
| `@react-native-firebase/analytics` | `RNFBAnalytics` |
| `@react-native-firebase/crashlytics` | `RNFBCrashlytics` |
| `@react-native-firebase/messaging` | `RNFBMessaging` |
| `@react-native-firebase/perf` | `RNFBPerf` |

After modifying `app.json`, run a clean EAS Build — `npx expo prebuild --clean` locally or trigger a new EAS build. Do not attempt to fix linker errors by modifying the Podfile directly; keep all configuration in `app.json`.

**Warning signs:**
- iOS build failing with "Non-modular header inside framework module" after adding a new `@react-native-firebase/*` package
- Build succeeds on Android but fails on iOS after adding an RNFB module
- Pod install succeeds locally but EAS Build fails

**Phase to address:** Analytics and crash reporting phase — add entries to `forceStaticLinking` as the first step of adding each new RNFB module.

---

### Pitfall 14: Firebase Analytics Event Name and Parameter Constraints Cause Silent Data Loss

**What goes wrong:**
Custom analytics events are logged but never appear in the Firebase console. Engineers inspect the implementation, see no errors, and assume propagation delay. The real cause: Firebase Analytics silently drops events that violate naming rules. Event names over 40 characters are silently truncated. Parameter values that are numeric types appear as "(not set)" in the dashboard. Reserved event name prefixes (`firebase_`, `google_`, `ga_`) cause the entire event to be dropped. This means key funnel data (workout started, workout completed, cycle phase viewed) is missing from launch analytics.

**Why it happens:**
Firebase Analytics does not throw errors for invalid event names — it silently discards them. The React Native Firebase SDK validates some constraints client-side but not all. Developers instrument events in a rush and never verify the data appears in the debug view before shipping.

**How to avoid:**
- Event names: 1–40 characters, alphanumeric + underscore only, no reserved prefixes (`firebase_`, `google_`, `ga_`). Use snake_case consistently.
- Parameter values: stringify numeric values before passing (`value.toString()`) — numeric parameter values may show as "(not set)" in some dashboard views.
- Parameter names: 1–40 characters, same character restrictions.
- Use Firebase Analytics `DebugView` during development: enable debug mode on device (`adb shell setprop debug.firebase.analytics.app com.sundeefundee.app` on Android, scheme arg on iOS), then verify events appear in the Firebase console DebugView in real time before declaring instrumentation complete.
- Define all event names and parameter names as constants in a single `analyticsEvents.ts` file — never inline string literals in event calls.

**Warning signs:**
- Events appear in local debug logs but not in Firebase console (after appropriate propagation delay of 24h)
- Events with names over 40 characters
- Any event name containing spaces or hyphens

**Phase to address:** Analytics phase — instrument events against DebugView as part of the definition of done, not post-launch.

---

### Pitfall 15: iOS Push Notification Provisioning — APNs Key vs APNs Certificate Confusion

**What goes wrong:**
EAS Build manages iOS signing automatically. When push notifications are added, the engineer runs `eas credentials` and encounters a choice between APNs Authentication Key (.p8) and APNs Certificate (.p12). They generate both or choose the wrong one. Apple allows only 2 APNs keys per developer account (shared across all apps). Accidentally generating too many keys or using an expired certificate blocks all notifications for all apps under the developer account.

The FCM v1 API (which Firebase switched to in June 2024) requires the APNs Authentication Key (.p8), not the older APNs Certificate. Using a certificate with FCM v1 causes silent notification failures on iOS with no error at the send endpoint.

**Why it happens:**
The migration from FCM Legacy API to FCM v1 API happened in 2024. Documentation from before this date shows certificate-based setup. Engineers following older tutorials or Stack Overflow answers configure certificates and see no push delivery.

**How to avoid:**
- Use APNs Authentication Key (.p8) exclusively. Generate it once, store it securely, use it for all apps.
- In EAS, run `eas credentials --platform ios` and select "Push Notifications Key" (the .p8 key), not the certificate option.
- If using FCM to relay pushes (Cloud Functions → FCM → APNs), confirm the Firebase console shows the APNs key uploaded under Project Settings > Cloud Messaging > Apple app configuration, not a certificate.
- FCM v1 API endpoint: `https://fcm.googleapis.com/v1/projects/{project}/messages:send` — if any code references the legacy `https://fcm.googleapis.com/fcm/send` endpoint, it will stop working.

**Warning signs:**
- Push notifications working on Android but silently absent on iOS
- Firebase console showing APNs certificate (`.p12`) rather than APNs key (`.p8`) in Cloud Messaging settings
- Cloud Functions sending to FCM legacy endpoint

**Phase to address:** Push notification phase — verify APNs key configuration in EAS and Firebase console before writing any notification scheduling code.

---

### Pitfall 16: Apple Privacy Manifest (PrivacyInfo.xcprivacy) Not Present — App Store Rejection

**What goes wrong:**
Apple requires a `PrivacyInfo.xcprivacy` file in all apps submitted to the App Store, effective February 2025. The file must declare all privacy-impacting APIs used by the app and any third-party SDKs. React Native and Firebase SDKs use several required reason APIs (file timestamps, user defaults, system boot time). A missing or incomplete privacy manifest causes App Store review rejection with the code "ITMS-91053: Missing API declaration."

This app handles menstrual cycle data, readiness survey responses, and health metrics — it is under elevated scrutiny from App Store review for health data privacy compliance.

**Why it happens:**
Expo's prebuild process generates a template `PrivacyInfo.xcprivacy` in some versions but does not automatically populate all required reasons for third-party SDKs. Engineers assume the file is auto-generated correctly and do not audit its contents before submission.

**How to avoid:**
- Verify `PrivacyInfo.xcprivacy` exists in the iOS native output after `npx expo prebuild`. If absent, create it.
- Audit the file for completeness against Apple's [required reason APIs list](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files/describing-use-of-required-reason-api). Common reasons needed for this app:
  - `NSPrivacyAccessedAPICategoryFileTimestamp` (React Native file system access)
  - `NSPrivacyAccessedAPICategoryUserDefaults` (AsyncStorage, expo-secure-store)
  - `NSPrivacyAccessedAPICategorySystemBootTime` (uptime-based timers)
- Declare all data types collected in the manifest: health/fitness data (cycle logs, readiness scores), user ID, device identifiers.
- Run `xcprivacy-lint` or review via Xcode's Privacy Report before submitting.
- The manifest must be updated if new SDKs are added.

**Warning signs:**
- App Store Connect email with "ITMS-91053: Missing API declaration"
- `PrivacyInfo.xcprivacy` file absent after `npx expo prebuild`
- New SDK added without reviewing its privacy manifest requirements

**Phase to address:** App Store submission phase — treat privacy manifest audit as a required pre-submission step, not a best-effort item.

---

### Pitfall 17: Google Play Store First Submission Requires Manual Upload — EAS Submit Cannot Do It

**What goes wrong:**
The engineer sets up EAS Submit for automated Google Play Store submission and expects to run `eas submit --platform android` for the initial release. The submission fails because Google Play's API requires the app to have been manually uploaded at least once before the API can be used. EAS Submit cannot perform the first upload.

Additionally, the Play Store requires that a release be promoted through at least one internal testing track before it can be promoted to production. Attempting to publish directly to production on the first upload is rejected.

**Why it happens:**
EAS Submit documentation covers the automated flow clearly but the manual-first-upload requirement is noted as a footnote. Engineers setting up CI/CD for the first time miss it.

**How to avoid:**
- Build the first production AAB via EAS: `eas build --platform android --profile production`.
- Download the AAB from the EAS dashboard.
- Log into Google Play Console manually, create the app listing, upload the AAB to Internal Testing track, and publish to Internal Testing.
- After at least one successful internal testing release, subsequent submissions via `eas submit --platform android` work fully automated.
- Also required before `eas submit` works: set up a Google Play service account with appropriate permissions and configure the `serviceAccountKeyPath` in `eas.json`.

**Warning signs:**
- `eas submit --platform android` failing on a brand-new Play Console app
- Error message: "packageName must already exist in the play console account"
- No Google Play service account key configured in `eas.json`

**Phase to address:** App Store submission phase — manual first upload must be scheduled before any CI/CD submission pipeline is configured.

---

### Pitfall 18: Android Target API Level Requirement — Must Target API 35 by August 2025

**What goes wrong:**
The Google Play Store requires all new apps and app updates submitted after August 31, 2025 to target Android 15 (API level 35). An EAS Build that targets a lower API level will be rejected. This is relevant now because the v1.1 milestone targets store submission — any production build must be configured correctly.

**Why it happens:**
Default Expo/React Native configurations may target an older API level. Engineers do not check the `targetSdkVersion` before building for production.

**How to avoid:**
Set `targetSdkVersion` to 35 in `app.json` via `expo-build-properties`:

```json
{
  "plugins": [
    ["expo-build-properties", {
      "android": {
        "targetSdkVersion": 35,
        "compileSdkVersion": 35
      }
    }]
  ]
}
```

Verify the resulting `build.gradle` in the Android prebuild output shows the correct target. Test that the app functions correctly on Android 15 in a simulator before submitting.

**Warning signs:**
- `targetSdkVersion` below 35 in Android build output after August 2025
- Play Console showing a warning about API level compliance on upload

**Phase to address:** App Store submission phase — set API level as part of EAS configuration, before the first production build.

---

### Pitfall 19: Apple App Store Health Data Privacy Details — Missing Sensitive Data Declarations

**What goes wrong:**
App Store Connect requires all apps to complete Privacy Nutrition Labels declaring data types collected. For this app (menstrual cycle data, readiness survey health responses, injury data, workout history), failing to declare health and fitness data categories causes App Store rejection. Additionally, Apple's enhanced scrutiny of health data apps means reviewers may flag undeclared data use even after initial approval during an update review.

The specific risk: cycle phase data and period logs are classified as "Sensitive Health Information" under Apple's privacy guidelines. Declaring them incorrectly (e.g., as "Fitness" instead of "Health") triggers rejection.

**Why it happens:**
Privacy nutrition label forms are long and complex. Developers completing them quickly miss the distinction between Health vs Fitness categories, or fail to declare data linked to user identity.

**How to avoid:**
- Declare the following data types as collected and linked to user identity: Health & Fitness (cycle data, readiness scores, injury logs), Identifiers (user ID, device ID), Usage Data (screens viewed, features used).
- In the "Data linked to you" section, check: Health (cycle phase, period logs, pain scores), Fitness (workout history, PRs, benchmarks).
- Do NOT declare data as "not collected" for categories where Firebase Analytics collects device identifiers or crash context automatically.
- Complete the privacy details form before submitting the build — it can be filled in while the build is processing.
- Review Apple's [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) page and check against every Firebase module and RevenueCat data collected.

**Warning signs:**
- App Store rejection citing incomplete privacy declaration
- Privacy nutrition label left incomplete before submitting build for review
- Firebase Analytics or RevenueCat data collection not declared

**Phase to address:** App Store submission phase — complete privacy labels as a first step of submission prep, not last.

---

### Pitfall 20: iOS Screenshot Requirements Changed — Must Include 6.9-inch Display

**What goes wrong:**
The engineer prepares screenshots for iPhone 6.5-inch (iPhone 11/12/13 Pro Max) which were the required size in previous years. App Store Connect rejects the submission because Apple now requires screenshots for 6.9-inch display (iPhone 16 Pro Max / Dynamic Island devices). Screenshots from older device sizes are not accepted as substitutes.

**Why it happens:**
Teams reuse screenshot production workflows from previous apps or tutorials. The required size changed and old documentation or tools still reference the 6.5-inch requirement.

**How to avoid:**
- Minimum required: screenshots for 6.9-inch iPhone (iPhone 16 Pro Max or simulator equivalent).
- If the app supports iPad: screenshots for 13-inch iPad Pro are also required.
- Screenshot dimensions for 6.9-inch: 1320 × 2868 pixels (portrait) or 2868 × 1320 pixels (landscape).
- Use a simulator running on iPhone 16 Pro Max to capture screenshots, or design at exact pixel dimensions.
- If the app has localization planned: prepare screenshots for each language/locale — App Store Connect requires them per language.

**Warning signs:**
- App Store Connect upload showing "invalid screenshot size" error
- Screenshots captured on iPhone 14/15 Pro Max (6.7-inch) which are 1290 × 2796 px, not 1320 × 2868 px

**Phase to address:** App Store submission phase — produce screenshots in the correct size before starting the App Store Connect submission form.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use Expo Go instead of dev client for development | Faster local iteration | Firebase native modules won't work; entire auth/Firestore stack unavailable | Never — build a dev client from day one |
| Skip Firestore security rules until "closer to launch" | Faster prototyping | Health data exposed; breach risk; rules written under pressure are buggy | Never — write rules alongside the data model |
| In-memory state for workout session (no persistence) | Simpler initial implementation | Crash mid-workout loses all data; users cannot recover | MVP only if you ship a "resume workout" feature in the same phase |
| Use Firebase JS SDK for early prototyping | Familiar API, no build required | Requires full SDK swap later; offline persistence and Crashlytics unavailable | Only for non-Firebase prototyping throwaway code |
| Skip RevenueCat Stripe webhook | Faster payment integration | Web subscribers never get entitlements | Never — the webhook is not optional for dual payments |
| Hardcode user ID as empty string in fallback | Avoids null check boilerplate | Data written with no owner; security rules cannot protect it | Never — mirrors the iOS CLAUDE.md prohibition |
| Bundle entire domain TypeScript in one file | Easier initial port | Untestable; impossible to unit test individual engines | Never — mirror iOS Domain/ structure from the start |
| Test Crashlytics in development build | Faster feedback loop | Crashes not reported due to expo-dev-client overlay; engineers conclude integration is broken | Never — test Crashlytics in preview builds only |
| Skip `setNotificationHandler` for foreground | Seems to work in background testing | All foreground notifications silently dropped on iOS | Never — add it as the first line of notification setup |
| Inline analytics event strings | Faster to write | Typos cause silent data loss; no autocomplete safety | Never — define event names as constants |
| Submit to Play Store directly via `eas submit` without manual first upload | Saves one step | Submission fails; no workaround available | Never — manual first upload is required by Google |
| Skip `PrivacyInfo.xcprivacy` audit before submission | Saves review time | App Store rejection; delay to launch | Never — privacy manifest is required as of Feb 2025 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase Auth + Sign in with Apple | Not storing name/email on first login | Persist to Firestore in the same auth callback, before navigation |
| Firebase Auth + Sign in with Apple (Android) | Skipping nonce SHA256 configuration on Android | Configure `appleAuthAndroid` with state + nonce; test on Android emulator with Play Services |
| RevenueCat + Firebase Auth | Using anonymous device ID as RevenueCat user ID | Use Firebase Auth UID as `appUserID`; call `logIn()` on RevenueCat after Firebase auth resolves |
| RevenueCat + Stripe | Assuming subscription sync is automatic | Build Stripe webhook → Firebase Cloud Function → RevenueCat REST API pipeline |
| Firestore + Expo | Assuming JS SDK offline persistence works same as native | Use `@react-native-firebase/firestore` for native SQLite persistence; JS SDK uses memory-only fallback |
| Firebase Cloud Functions | Assuming instant response for AI generation | Cloud Functions have cold start latency of 5-20s; show a loading state; set minimum instances for production |
| Expo EAS Build | Using Expo Go for testing native modules | Create a Development Build via `eas build --profile development`; distribute via EAS |
| Expo OTA Updates | Pushing after `yarn upgrade` without checking native changes | Run fingerprint diff before every OTA push; full build if any native dep changed |
| expo-notifications + @react-native-firebase | Installing both without reading conflict guidance | Pick one; use expo-notifications for all notification handling with FCM v1 credentials via EAS |
| @react-native-firebase/crashlytics + expo-dev-client | Testing crash reporting in development builds | Use preview EAS profile (no `developmentClient: true`) for Crashlytics testing |
| @react-native-firebase/analytics + web platform | Expecting native SDK to work on web | Create `analytics.native.ts` and `analytics.web.ts` using the existing project's platform file pattern |
| forceStaticLinking + new RNFB modules | Forgetting to add pod name when installing new RNFB package | Add `RNFBAnalytics`, `RNFBCrashlytics`, `RNFBMessaging` to `forceStaticLinking` in `app.json` immediately on install |
| FCM v1 + APNs | Using APNs certificate (.p12) instead of APNs key (.p8) | Use .p8 key only; upload to Firebase console Cloud Messaging settings; configure in EAS credentials |
| Google Play Submit + EAS | Running `eas submit` before manual first upload | Upload manually to internal testing track first; then automate all subsequent submissions |
| Apple App Store + health data | Incomplete privacy nutrition label | Declare cycle data, readiness scores, injury logs as Health data linked to user identity |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Inline `renderItem` in FlatList (workout history, program catalog) | Janky scroll; excessive re-renders logged in Profiler | Extract `renderItem` to a named function; wrap in `useCallback`; wrap item component in `React.memo` | Visible from ~50+ items; severe at 200+ |
| No FlatList `keyExtractor` or non-stable keys | Items re-render on every list mutation; animated transitions break | Always provide a stable, unique `keyExtractor` using document ID | Immediate |
| Firestore `onSnapshot` without cleanup | Memory leak; ghost listeners accumulating across navigation | Always return the `unsubscribe` function from `useEffect` | Leaks compound over session length; critical for long workout sessions |
| Victory Native or Lottie imported globally | 600KB+ bundle size addition; slow initial load | Import chart/animation libraries lazily; audit bundle with `expo-bundle-analyzer` | Immediately at install; worsens with scale |
| All domain computation in component render | UI thread blocking during cycle phase calculation or injury engine run | Move heavy computation to `useMemo` with correct dependencies; or to a background thread via `react-native-worklets-core` | Noticeable on older Android devices |
| Firestore collection scans offline | Offline query scanning all cached documents | Enable local query index creation via persistent cache settings; design data model with query patterns in mind | Degrades as cache grows, especially for users who go offline for extended periods |
| Firebase Cloud Functions cold start for AI generation | First AI workout request takes 10-20s; user abandons | Set minimum instance count to 1 in production; implement loading state with progress indication and timeout fallback | Every cold start; worse in low-traffic periods overnight |
| Analytics events fired on every render | Firebase Analytics event count explodes; quota hit; console unusable | Only fire analytics events on intentional user actions or significant state transitions, never in render paths | Immediately if analytics calls are inside component render or tight loops |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Shipping with Firestore test mode rules | Any user (or automated scanner) can read all health data, including cycle logs, injury profiles, readiness survey responses | Write production rules before first data write; add rules to CI test suite |
| Admin flag stored in user-writable document field | User can self-promote to admin | Store admin flags in a separate collection that only Cloud Functions can write |
| Firebase API key exposed without App Check | Key is trivially extractable from app binary; bots can make unlimited Auth/Firestore requests | Enable Firebase App Check with DeviceCheck (iOS) and Play Integrity (Android) |
| Stripe webhook not verified with webhook secret | Attacker POSTs fake subscription events to unlock premium access | Always verify Stripe webhook signature (`stripe.webhooks.constructEvent`) in Cloud Function |
| RevenueCat API key in client-side JS | Key exposed in bundle; attacker can query subscriber state | Public RevenueCat key is expected client-side; never embed the secret key |
| Health/cycle data in Firestore without field-level consideration | Users' menstrual cycle data visible to Firebase project admins with console access | Minimize data stored; do not log raw cycle data to Firebase Analytics events |
| Analytics events containing PII or health data | Cycle phase, injury descriptions, or readiness scores logged to Firebase Analytics | Analytics events must contain only aggregate or category-level data; never raw health strings or user IDs |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| KeyboardAvoidingView set to `behavior="padding"` (iOS-only fix applied everywhere) | Android inputs hidden under keyboard; submit buttons unreachable | Use `react-native-keyboard-controller` for consistent cross-platform handling; set different `behavior` per platform |
| No offline indicator during workout execution | Users unsure if workout saved; tap "save" repeatedly creating duplicate entries | Show connection status in workout header; optimistic save confirmation ("Saved locally, will sync when online") |
| Workout timer stops when screen locks (no background task) | Active workout timer resets mid-session | Implement `expo-task-manager` + `expo-background-fetch` for timer persistence; test explicitly with screen lock |
| Paywall interrupts first workout attempt | Users churn before experiencing value | Gate premium features; ensure core workout execution works in guest mode before upsell |
| Art Deco design not adapted for Android material conventions | Android users feel the app is unpolished; navigation feels wrong | Test navigation gestures, back button behavior, and bottom sheet behavior on physical Android device early |
| Platform-specific modal presentation differences | Modals that look native on iOS look wrong on Android (no bottom sheet) | Use `@gorhom/bottom-sheet` for sheet-style modals; test on both platforms before considering a component "done" |
| Cycle phase data shown to users who skipped cycle opt-in | Confusing, alienating experience | Gate all cycle UI behind the onboarding opt-in flag; never assume cycle tracking is active |
| Push notification permission prompt shown too early | Users decline before seeing value; no recovery path without OS settings | Delay permission request until after first workout completion; explain benefit before prompting |
| Notification opt-in denied with no fallback | Users who deny push never get reminders or streak notifications | Offer in-app notification center as fallback; surface a re-permission prompt in Settings screen |

---

## "Looks Done But Isn't" Checklist

- [ ] **Offline workout save:** Works in airplane mode? Verify by: enable airplane mode, complete a full workout, kill app, restore connection, confirm workout appears in history.
- [ ] **Sign in with Apple persistence:** Second login returns correct display name? Verify by: sign in, revoke in iOS Settings, sign in again, check display name.
- [ ] **RevenueCat + Stripe sync:** Web subscriber sees premium in mobile app? Verify by: purchase via Stripe web checkout with a test card, open mobile app with same account, confirm entitlement unlocked.
- [ ] **Firestore security rules:** User A cannot read User B's data? Verify by: create two test accounts, attempt cross-account document read via Firebase emulator.
- [ ] **Cycle-aware adaptation on Android:** Phase multipliers apply correctly? Verify with same inputs as iOS domain unit tests.
- [ ] **AI workout generation with cold start:** First request on fresh function instance completes within timeout? Verify by: let function go idle 15 min, trigger generation, observe latency.
- [ ] **OTA update safety:** OTA push after dependency bump does not crash users on old binary? Verify fingerprint diff shows no native surface changes before pushing.
- [ ] **Workout timer survives screen lock:** Timer state preserved when phone locks mid-EMOM? Verify on physical device.
- [ ] **Guest mode:** Core workout execution works without any Firebase auth? Verify by: use app without signing in, complete workout, confirm local persistence.
- [ ] **Subscription state on app restart:** RevenueCat correctly restores entitlement without requiring re-purchase? Verify by: subscribe, force-kill app, reopen, confirm premium state.
- [ ] **Foreground notifications on iOS:** Local notification shows as banner while app is open? Verify by: schedule notification 5s out, keep app in foreground, confirm banner appears.
- [ ] **Crashlytics in preview build:** Non-JS crash triggers a report in Firebase console? Verify by: build preview profile, trigger `crashlytics().crash()`, reopen app, wait 10 min, check console.
- [ ] **Analytics web platform:** Firebase events appearing in dashboard from web build? Verify by: open web build, trigger a tracked event, confirm in Firebase DebugView.
- [ ] **Analytics event naming:** All custom events appear in Firebase console (not silently dropped)? Verify by: enable DebugView on device, trigger each instrumented event, confirm each appears.
- [ ] **Android Play Store first upload:** Manual AAB upload to Internal Testing completed before attempting `eas submit`? Verify by: check Play Console for at least one internal testing release.
- [ ] **iOS Privacy Manifest:** `PrivacyInfo.xcprivacy` present and declaring all required reason APIs? Verify by: run `npx expo prebuild`, inspect `ios/SundeeFundee/PrivacyInfo.xcprivacy`.
- [ ] **App Store privacy nutrition labels:** Health and cycle data declared as linked to user identity? Verify by: review App Store Connect Privacy section before submitting for review.
- [ ] **iOS screenshots 6.9-inch:** Screenshots captured at correct dimensions (1320 × 2868 px)? Verify by: check pixel dimensions of submitted screenshots.
- [ ] **APNs key configured:** Firebase console shows .p8 key (not certificate) for iOS FCM? Verify by: Firebase console > Project Settings > Cloud Messaging > Apple app configuration.
- [ ] **forceStaticLinking complete:** All installed RNFB modules listed in `forceStaticLinking` in `app.json`? Verify by: cross-reference installed `@react-native-firebase/*` packages against the array.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong Firebase SDK (JS vs native) discovered mid-project | HIGH | Audit all Firebase imports; swap to `@react-native-firebase`; rebuild all features that touch Auth/Firestore/Storage; re-test offline behavior end-to-end |
| Firestore rules breach discovered post-launch | HIGH | Lock rules immediately (emergency deploy); audit access logs in Firebase console; notify affected users per applicable privacy law; conduct full rules audit |
| Expo managed workflow ceiling hit mid-project | HIGH | Convert to Development Build (lower cost); only eject to bare workflow if a Config Plugin genuinely cannot cover the gap |
| Missing Apple user data discovered post-launch | MEDIUM | Prompt affected users (those with no display name) to update their profile manually; implement account repair flow in Settings |
| OTA update crash discovered in production | MEDIUM | Roll back to previous update channel immediately via `eas channel:edit`; issue full EAS Build with the fix; establish fingerprint policy to prevent recurrence |
| RevenueCat + Stripe sync not built | MEDIUM | Build webhook handler; retroactively sync existing Stripe subscribers via RevenueCat REST API batch import |
| AI Cloud Function cold start causing UX failures | LOW | Enable minimum instance count (1) via Cloud Functions config; update loading state to show progress |
| Firestore offline persistence in JS SDK (not native) | MEDIUM | Migrate to `@react-native-firebase/firestore`; test all offline scenarios after migration |
| expo-notifications + RNFB messaging conflict discovered mid-build | MEDIUM | Remove `@react-native-firebase/messaging`; rebuild with expo-notifications only; reconfigure remote push token flow |
| Crashlytics not reporting — diagnosed as broken | LOW | Switch to preview EAS build profile; Crashlytics works correctly outside dev client |
| Analytics missing on web — discovered post-launch | MEDIUM | Create `analytics.web.ts` shim using Firebase JS SDK; deploy via OTA update (no native changes) |
| App Store rejected for privacy manifest | MEDIUM | Create/complete `PrivacyInfo.xcprivacy`; rebuild; resubmit — adds 1-2 day review cycle |
| App Store rejected for incomplete privacy nutrition label | LOW | Update App Store Connect privacy details without new build; resubmit for review |
| Play Store first upload failed via EAS Submit | LOW | Download AAB from EAS dashboard; upload manually to Play Console internal testing track; then `eas submit` works |
| iOS push not working — APNs certificate instead of key | LOW | Generate APNs .p8 key in Apple Developer portal; upload to Firebase console; update EAS credentials; rebuild |
| forceStaticLinking missing entry — iOS build failure | LOW | Add pod name to `forceStaticLinking` in `app.json`; run clean EAS Build |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Wrong Firebase SDK (JS vs native) | Phase 1: Project scaffold | `@react-native-firebase` installed; Expo Go abandoned; dev client working with Firebase Auth |
| Firestore writes blocking UI offline | Phase covering workout execution | Airplane mode test: save workout, no UI freeze |
| Expo managed workflow ceiling | Phase 1: Project scaffold | Full native capability audit complete before first commit |
| OTA update breaking native modules | CI/CD setup phase | Fingerprint diff check runs in CI before every OTA push |
| Sign in with Apple missing user data | Auth phase | Second-login acceptance test in auth test suite |
| Firestore security rules open | Phase 1: Data architecture | Rules test suite passing in CI; no `allow read, write: if true` in any environment |
| RevenueCat + Stripe entitlement gap | Payments phase | Stripe webhook handler tested end-to-end with test card |
| Domain logic numeric/date drift | Domain port phase | TypeScript domain tests produce identical outputs to Swift test suite for same inputs |
| FlatList performance | History/programs list phase | Profiler shows no inline renderItem functions; scroll performance on 200+ item list measured |
| Cloud Function cold start | AI generation phase | Cold start latency measured; minimum instances configured; loading state handles 15s+ wait |
| Workout timer dies on screen lock | Workout execution phase | Physical device test: screen lock mid-EMOM, timer state preserved |
| Firestore App Check not enabled | Pre-launch security phase | App Check enforced in Firebase console; emulator bypass only in development |
| expo-notifications + RNFB messaging conflict | Push notification phase | Library selection decision made before first EAS Build with notifications |
| iOS foreground notifications silent | Push notification phase | Foreground banner test: schedule 5s notification, keep app open, banner appears |
| Crashlytics not working in dev build | Analytics/crash phase | Preview build test: crash(), reopen, Firebase console shows report within 10 min |
| Analytics web no-op | Analytics/crash phase | Firebase DebugView shows events from web build |
| forceStaticLinking incomplete | Analytics/crash phase | iOS EAS Build succeeds without linker errors after adding each new RNFB module |
| Analytics event silent drop | Analytics/crash phase | All instrumented events verified in Firebase DebugView before marking instrumentation done |
| APNs certificate vs key confusion | Push notification phase | Firebase console shows .p8 key in Cloud Messaging settings |
| Google Play first manual upload required | App Store submission phase | Internal testing track shows at least one release before `eas submit` is used |
| Android API level 35 required | App Store submission phase | `targetSdkVersion: 35` confirmed in Android build output |
| iOS Privacy Manifest missing | App Store submission phase | `PrivacyInfo.xcprivacy` present and audited after `npx expo prebuild` |
| App Store health data privacy labels | App Store submission phase | Privacy nutrition labels reviewed and completed in App Store Connect before build submission |
| iOS screenshots wrong size | App Store submission phase | Screenshots captured at 1320 × 2868 px from 6.9-inch device/simulator |
| Push permission prompt too early | Push notification phase | Permission prompt deferred until post-first-workout; Settings re-prompt available |

---

## Sources

- [Expo Firebase Guide (Official)](https://docs.expo.dev/guides/using-firebase/)
- [Firebase Dual Package Hazard — Expo Issue #36598](https://github.com/expo/expo/issues/36598)
- [Expo SDK 53 Firebase Breaking Integration — Issue #36602](https://github.com/expo/expo/issues/36602)
- [Firestore Offline Mode Gotchas for React Native — Better Programming](https://betterprogramming.pub/a-few-gotchas-to-consider-when-working-with-firestores-offline-mode-and-react-native-42al)
- [Access Data Offline — Firebase Official Docs](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [React Native Firebase — Official Docs](https://rnfirebase.io/)
- [Firestore Insecure Rules — Firebase Official Docs](https://firebase.google.com/docs/firestore/security/insecure-rules)
- [Firebase Misconfigurations — Medium](https://medium.com/@mustafamohammed789mm/firebase-misconfigurations-from-discovery-to-exploitation-0a282b81ad4f)
- [RevenueCat Stripe Billing Integration](https://www.revenuecat.com/docs/web/integrations/stripe)
- [RevenueCat React Native Installation](https://www.revenuecat.com/docs/getting-started/installation/reactnative)
- [Sign in with Apple — React Native Firebase Social Auth](https://rnfirebase.io/auth/social-auth)
- [Making Apple Authentication Work with Firebase Auth in Expo](https://vandevliet.me/making-apple-authentication-work-with-firebase-auth-w-react-native/)
- [Firebase Cloud Functions Cold Start — Official Tips](https://firebase.google.com/docs/functions/tips)
- [Overcoming Cold Start Challenges in Firebase Cloud Functions](https://infinitejs.com/posts/overcoming-cold-start-firebase-functions/)
- [5 OTA Update Best Practices — Expo Blog](https://expo.dev/blog/5-ota-update-best-practices-every-mobile-team-should-know)
- [Expo OTA Update Troubleshooting — Mindful Chase](https://www.mindfulchase.com/explore/troubleshooting-tips/mobile-frameworks/troubleshooting-ota-updates-and-build-inconsistencies-in-expo-framework.html)
- [FlatList Performance Optimization — React Native Official](https://reactnative.dev/docs/optimizing-flatlist-configuration)
- [FlashList — Shopify's FlatList Replacement](https://expo.dev/blog/what-is-the-best-react-native-list-component)
- [Keyboard Handling in React Native — Expo Docs](https://docs.expo.dev/guides/keyboard-handling/)
- [react-native-keyboard-controller Platform Differences](https://kirillzyusko.github.io/react-native-keyboard-controller/docs/recipes/platform-differences)
- [EAS Build Signing Certificate Issues — expo-cli Issue #3192](https://github.com/expo/eas-cli/issues/3192)
- [Expo Managed to Bare Workflow Migration — OneUptime](https://oneuptime.com/blog/post/2026-01-15-expo-managed-to-bare-workflow/view)
- [expo-notifications Official Docs](https://docs.expo.dev/versions/latest/sdk/notifications/)
- [Using Push Notifications — Expo Documentation](https://docs.expo.dev/guides/using-push-notifications-services/)
- [Send Notifications with FCM and APNs — Expo Documentation](https://docs.expo.dev/push-notifications/sending-notifications-custom/)
- [Expo Push Notifications Setup — Expo Documentation](https://docs.expo.dev/push-notifications/push-notifications-setup/)
- [expo-notifications Foreground Handler Issue #20351 — expo/expo](https://github.com/expo/expo/issues/20351)
- [Crashlytics Compatibility with Expo Development Build — expo/expo Discussion #24246](https://github.com/expo/expo/discussions/24246)
- [Crashlytics: crashlytics_debug_enabled in Expo managed app — invertase/react-native-firebase Discussion #7459](https://github.com/invertase/react-native-firebase/discussions/7459)
- [Crashlytics — React Native Firebase Official Docs](https://rnfirebase.io/crashlytics/usage)
- [Analytics — React Native Firebase Official Docs](https://rnfirebase.io/analytics/usage)
- [React Native Firebase Platforms Support](https://rnfirebase.io/platforms)
- [Firebase Analytics Error Codes](https://firebase.google.com/docs/analytics/errors)
- [React Native Firebase iOS Build Error 2025 — invertase/react-native-firebase Issue #8657](https://github.com/invertase/react-native-firebase/issues/8657)
- [EAS Submit — Expo Documentation](https://docs.expo.dev/submit/introduction/)
- [Submit to Google Play Store — Expo Documentation](https://docs.expo.dev/submit/android/)
- [Android API Level Requirements for Google Play — Play Console Help](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Apple Privacy Manifests — React Native Community Discussion #766](https://github.com/react-native-community/discussions-and-proposals/discussions/766)
- [Privacy Manifest Files — Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Privacy Details — App Store — Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)
- [Screenshot Specifications — App Store Connect — Apple Developer Help](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
- [App Credentials — Expo Documentation](https://docs.expo.dev/app-signing/app-credentials/)
- [Google Play Data Safety Section — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Foreground Push Notification Conflict — expo/expo Issue #36419](https://github.com/expo/expo/issues/36419)
- [Making Expo Notifications Work on Android 12+ and iOS — Medium](https://medium.com/@gligor99/making-expo-notifications-actually-work-even-on-android-12-and-ios-206ff632a845)

---
*Pitfalls research for: React Native + Expo + Firebase fitness app (Sundee Fundee cross-platform rewrite)*
*Original research: 2026-03-14 | v1.1 launch readiness update: 2026-03-16*

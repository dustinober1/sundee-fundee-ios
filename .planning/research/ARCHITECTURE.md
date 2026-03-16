# Architecture Research

**Domain:** Cross-platform fitness app — React Native + Expo + Firebase (offline-first, subscription-gated)
**Researched:** 2026-03-16 (updated for v1.1 Launch Readiness)
**Confidence:** HIGH (Firebase, RevenueCat, Expo docs); MEDIUM (folder structure patterns, community best practices)

---

## v1.1 Addendum: Launch Readiness Integration Architecture

> This section documents how push notifications, analytics/crash reporting, EAS builds, and store submission integrate with the existing v1.0 architecture. The original v1.0 architecture research follows below.

### What Already Exists in v1.0

Before describing new components, here is the verified existing state from codebase inspection:

- `expo-notifications` is already **installed** (v55) and **actively used** in `useRestTimer` and `useWorkoutTimer` for local (rest timer countdown) notifications
- `app/(app)/_layout.tsx` already calls `Notifications.setNotificationHandler()` — foreground display behavior is configured
- `@react-native-firebase/app`, `/auth`, `/firestore`, `/functions`, `/app-check` are already in the `app.json` plugins array
- `expo-build-properties` is configured with `useFrameworks: static` and `forceStaticLinking: [RNFBApp, RNFBAuth, RNFBFirestore, RNFBAppCheck]` — new RNF modules must be added here
- EAS project ID (`dc7c3b9d-ee13-4713-8fab-85389863e18f`) is already set in `app.json`
- `FirestoreUserRepo` writes to `/users/{uid}` with `{ merge: true }` — FCM tokens can extend this document without schema migration
- `src/firebase/` already uses `.web.ts` extension for platform branching (`auth.web.ts`, `callCloudFunction.web.ts`) — analytics and crashlytics follow this same pattern
- `UserProfile` type has optional fields — adding `fcmToken?: string` is backward compatible

### New Components Required

```
┌─────────────────────────────────────────────────────────────────┐
│                          Expo Router                             │
│   app/_layout.tsx  ← MODIFY: add initAnalytics(),               │
│                      initCrashlytics(), ErrorBoundary,          │
│                      setUserId() on sign-in                     │
│   app/(app)/_layout.tsx  ← MODIFY: mount usePushToken(),        │
│                             useNotificationNavigation()         │
├─────────────────────────────────────────────────────────────────┤
│  NEW: src/firebase/analytics.ts     (logEvent, logScreen)       │
│  NEW: src/firebase/analytics.web.ts (no-op stubs)               │
│  NEW: src/firebase/crashlytics.ts   (recordError, setUser)      │
│  NEW: src/firebase/crashlytics.web.ts (no-op stubs)             │
│  NEW: src/firebase/messaging.ts     (getToken, backgroundHandler│
├─────────────────────────────────────────────────────────────────┤
│  NEW: src/notifications/                                         │
│   NotificationService.ts        (schedule/cancel local notifs)  │
│   NotificationPermissions.ts    (request/check permissions)     │
│   usePushToken.ts                (FCM token lifecycle hook)     │
│   useNotificationNavigation.ts   (tap-to-navigate handler)     │
├─────────────────────────────────────────────────────────────────┤
│  MODIFY: src/repositories/FirestoreUserRepo.ts                  │
│   + saveFCMToken(uid, token): writes /users/{uid}.fcmToken      │
│  MODIFY: src/repositories/UserRepository.ts                     │
│   + fcmToken?: string on UserProfile                            │
├─────────────────────────────────────────────────────────────────┤
│  MODIFY: app.json                                                │
│   + @react-native-firebase/messaging plugin                     │
│   + @react-native-firebase/crashlytics plugin                   │
│   + expo-notifications plugin                                   │
│   + ios.infoPlist.UIBackgroundModes: [remote-notification]      │
│   + ios.entitlements.aps-environment: production                │
│   + forceStaticLinking: add RNFBCrashlytics, RNFBMessaging      │
├─────────────────────────────────────────────────────────────────┤
│  MODIFY: eas.json                                                │
│   + submit.production.ios  (ascAppId, appleId, appleTeamId)     │
│   + submit.production.android (serviceAccountKeyPath, track)    │
├─────────────────────────────────────────────────────────────────┤
│  NEW: Cloud Functions                                            │
│   sendWODNotification (Firestore trigger on WOD doc)            │
│   sendSubscriptionExpiryNotification (scheduled)                │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities (New/Modified)

| Component | Type | Responsibility |
|-----------|------|----------------|
| `src/firebase/analytics.ts` | NEW | Thin wrapper around `@react-native-firebase/analytics`; no-ops on web; exposes `logEvent`, `logScreen`, `setUserId` |
| `src/firebase/analytics.web.ts` | NEW | No-op stubs matching same export shape so web imports don't break |
| `src/firebase/crashlytics.ts` | NEW | Thin wrapper around `@react-native-firebase/crashlytics`; exposes `recordError`, `setUser`, `log` |
| `src/firebase/crashlytics.web.ts` | NEW | No-op stubs |
| `src/firebase/messaging.ts` | NEW | FCM token retrieval via `messaging().getToken()`, background handler registration, token refresh listener |
| `src/notifications/NotificationService.ts` | NEW | Schedule/cancel local notifications (rest timer, streaks, reminders). Extracts inline `expo-notifications` calls from `useRestTimer` — same behavior, more testable |
| `src/notifications/NotificationPermissions.ts` | NEW | Request + check permissions for both local and push; handles iOS vs Android 13+ differences |
| `src/notifications/usePushToken.ts` | NEW | Hook: obtains FCM token on mount, persists to Firestore `/users/{uid}`, re-registers on token refresh. Guest users skip token registration |
| `src/notifications/useNotificationNavigation.ts` | NEW | Hook: handles notification tap events via `Notifications.addNotificationResponseReceivedListener`, routes to correct screen using Expo Router `router.push()` |
| `src/repositories/FirestoreUserRepo.ts` | MODIFY | Add `saveFCMToken(uid, token)` method; uses `{ merge: true }` so no other fields are touched |
| `src/repositories/UserRepository.ts` | MODIFY | Add `fcmToken?: string` optional field to `UserProfile` |
| `app/_layout.tsx` | MODIFY | Add `initAnalytics()`, `initCrashlytics()` in `useEffect`. Add `crashlytics().setUserId(user.uid)` inside `handleUserSignIn`. Wrap `Stack` in `ErrorBoundary` |
| `app/(app)/_layout.tsx` | MODIFY | Mount `usePushToken()` and `useNotificationNavigation()` hooks. Both are side-effect-only (no render output) |
| `index.ts` | MODIFY | Add `messaging().setBackgroundMessageHandler()` before `AppRegistry.registerComponent` |
| `app.json` | MODIFY | 3 new plugins, iOS entitlements + UIBackgroundModes, 2 new forceStaticLinking entries |
| `eas.json` | MODIFY | Add `submit` section for iOS + Android |
| Cloud Functions | NEW | `sendWODNotification` reads user FCM tokens from Firestore, sends via FCM Admin SDK |

---

### Data Flows: New and Modified

#### 1. FCM Token Registration Flow

```
App launch (authenticated, non-guest user)
    ↓
usePushToken() mounts in app/(app)/_layout.tsx
    ↓
NotificationPermissions.requestPushPermission()
    [iOS: messaging().requestPermission()]
    [Android 13+: PermissionsAndroid.request(POST_NOTIFICATIONS)]
    ↓
messaging().getToken()  →  FCM device token string
    ↓
FirestoreUserRepo.saveFCMToken(uid, token)
    → Firestore /users/{uid} { fcmToken: "..." }  (merge: true)
    ↓
messaging().onTokenRefresh(token => saveFCMToken())
    (token changes on reinstall or OS rotation)
```

**Guest users:** `usePushToken` checks `isGuest === true` and returns early. No token is stored. Local notifications still work.
**Web platform:** `messaging.ts` guards with `Platform.OS === 'web'` and is a no-op. Web does not support FCM via RNF.

---

#### 2. Remote Push Send Flow (WOD notification example)

```
Firestore: WOD document created for today's date
    ↓
Cloud Function: sendWODNotification (Firestore trigger)
    → query /users where fcmToken != null (up to 500 per batch)
    → FCM Admin SDK: sendEachForMulticast({ tokens, notification, data })
    [data payload includes: { screen: 'wods', date: 'YYYY-MM-DD' }]
    ↓
FCM → APNs (iOS) / FCM direct (Android)
    ↓
Device receives message:
    ├── Foreground: messaging().onMessage() handler
    │     → NotificationService.scheduleImmediate() via expo-notifications
    ├── Background/Quit: setBackgroundMessageHandler() (in index.ts)
    │     → OS displays notification natively (no UI update)
    └── User taps notification:
          → useNotificationNavigation() listener fires
          → reads notification.request.content.data.screen
          → router.push('/wods')
```

**Critical:** `setBackgroundMessageHandler` MUST be called in `index.ts` before `AppRegistry.registerComponent`, not inside any React component. It is missed for background/quit states if registered inside a component lifecycle.

---

#### 3. Analytics Screen Tracking Flow

```
User navigates to any screen (Expo Router)
    ↓
usePathname() value changes (analytics hook in app/_layout.tsx)
    ↓
useEffect: analytics().logScreenView({ screen_name: pathname })
    ↓
Firebase Analytics console: screen_view events
```

Firebase Analytics does **not** automatically track screens in React Native — navigation runs in JS, not the native lifecycle, so native screen tracking callbacks are never triggered. Manual tracking via `usePathname` + `useEffect` is required. The existing `app/(app)/_layout.tsx` is the right mount point.

---

#### 4. Error Capture Flow

```
Uncaught component tree error
    ↓
ErrorBoundary.componentDidCatch(error, info)
    ↓
crashlytics().recordError(error)
    → Firebase Crashlytics: non-fatal issue

Caught error in hook or repository
    ↓
crashlytics().log('context message') + crashlytics().recordError(error)
    → Firebase Crashlytics: non-fatal with context

Native crash (OOM, native module abort)
    ↓
Crashlytics SDK captures automatically at next launch
    → Firebase Crashlytics: fatal crash session
```

**User identity:** `crashlytics().setUserId(user.uid)` called on sign-in in `app/_layout.tsx`. UID only — never names or emails.

---

### App.json Changes Required

```json
{
  "expo": {
    "ios": {
      "entitlements": {
        "aps-environment": "production"
      },
      "infoPlist": {
        "UIBackgroundModes": ["fetch", "remote-notification"]
      }
    },
    "plugins": [
      "@react-native-firebase/app",
      "@react-native-firebase/auth",
      "@react-native-firebase/crashlytics",
      "@react-native-firebase/messaging",
      "expo-notifications",
      "expo-apple-authentication",
      [
        "expo-build-properties",
        {
          "ios": {
            "useFrameworks": "static",
            "forceStaticLinking": [
              "RNFBApp", "RNFBAuth", "RNFBFirestore",
              "RNFBAppCheck", "RNFBCrashlytics", "RNFBMessaging"
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
  }
}
```

Note: `@react-native-firebase/analytics` does NOT require its own plugin entry — it initializes via the `@react-native-firebase/app` plugin. Only `crashlytics` and `messaging` need explicit plugin entries for Android Gradle and iOS build system changes.

---

### EAS.json Changes Required

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
        "appleId": "your@apple.com",
        "ascAppId": "YOUR_APP_STORE_CONNECT_NUMERIC_ID",
        "appleTeamId": "YOUR_10_CHAR_TEAM_ID"
      },
      "android": {
        "serviceAccountKeyPath": "./google-play-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

**iOS flow:** `eas build --platform ios --profile production` then `eas submit --platform ios --profile production`. EAS manages certificates/provisioning if credentials mode is `managed`.

**Android flow:** Requires a Google Play Service Account JSON key. Do not commit this file to the repo — add to `.gitignore`. Use EAS Secrets for CI environments.

---

### Build Order for v1.1 Features

Dependencies create a natural build order:

1. **`app.json` + `eas.json` config first** — All native module additions require a new EAS build (dev client) before any code using them can run on device. Adding plugins without building produces "module not found" errors.

2. **Analytics + Crashlytics** — Self-contained, no dependencies on other new features. Wire into `_layout.tsx` immediately after the new dev client build. Verify events appear in Firebase console before proceeding.

3. **ErrorBoundary** — Depends only on `crashlytics.ts`. Add to `_layout.tsx` alongside crashlytics init.

4. **`NotificationService.ts` refactor** — Move inline `expo-notifications` calls from `useRestTimer`/`useWorkoutTimer` into `NotificationService`. Behavior identical to today, but establishes the notification infrastructure layer before FCM is added. Tests update in parallel.

5. **FCM token registration** — Depends on `messaging.ts`, the `FirestoreUserRepo` update, and `usePushToken`. Requires an authenticated user (available via existing `SessionProvider`). Verify token appears in Firestore `/users/{uid}` before building Cloud Functions.

6. **`useNotificationNavigation`** — Depends on knowing what `data` payloads Cloud Functions will send. Define the `screen` key payload shape before writing either the client handler or the Cloud Functions.

7. **Cloud Functions for remote push** — Depend on FCM tokens being stored in Firestore (step 5) and a defined payload shape (step 6). Write and test in the Firebase emulator.

8. **EAS production builds + store submission** — Final step. Requires all prior changes working in a `preview` build. iOS: requires App Store Connect app record, screenshots, metadata. Android: requires Google Play Console app record and a Google Play Service Account key.

---

### Integration Points: New vs. Modified

**New files (create from scratch):**

| File | Purpose |
|------|---------|
| `src/firebase/analytics.ts` | Analytics wrapper, native |
| `src/firebase/analytics.web.ts` | Analytics no-ops, web |
| `src/firebase/crashlytics.ts` | Crashlytics wrapper, native |
| `src/firebase/crashlytics.web.ts` | Crashlytics no-ops, web |
| `src/firebase/messaging.ts` | FCM token + background handler |
| `src/notifications/NotificationService.ts` | Local notification scheduling |
| `src/notifications/NotificationPermissions.ts` | Permission abstraction |
| `src/notifications/usePushToken.ts` | FCM token lifecycle hook |
| `src/notifications/useNotificationNavigation.ts` | Notification tap-to-route |
| Cloud Function: `sendWODNotification` | Remote push for WOD |
| Cloud Function: `sendSubscriptionExpiryNotification` | Remote push for sub expiry |

**Modified files (touch existing code):**

| File | Change | Risk |
|------|--------|------|
| `app/_layout.tsx` | Add analytics init, crashlytics init, ErrorBoundary, setUserId | LOW — additive only |
| `app/(app)/_layout.tsx` | Mount usePushToken, useNotificationNavigation hooks | LOW — no render changes |
| `index.ts` | Add setBackgroundMessageHandler before AppRegistry | LOW — isolated, before component tree |
| `src/repositories/FirestoreUserRepo.ts` | Add saveFCMToken() method | LOW — new method, no signature changes |
| `src/repositories/UserRepository.ts` | Add fcmToken?: string to UserProfile | LOW — optional field, backward compatible |
| `src/hooks/useRestTimer.ts` | Delegate expo-notifications calls to NotificationService | LOW — refactor, same behavior |
| `src/hooks/useWorkoutTimer.ts` | Same as useRestTimer | LOW |
| `app.json` | Add 3 plugins, iOS config additions | MEDIUM — requires new EAS build |
| `eas.json` | Add submit section | LOW — no build behavior change |

---

### Anti-Patterns Specific to v1.1

**Anti-Pattern: setBackgroundMessageHandler inside a component**
Calling it in `useEffect` inside `_layout.tsx` or a screen means it is registered only after the component tree mounts. In background/quit state, the JS runtime runs without mounting components — the handler is never registered.
*Do this instead:* Register in `index.ts` before `AppRegistry.registerComponent`.

**Anti-Pattern: Requesting notification permission immediately on first launch**
iOS only allows one native OS prompt per install. Showing it without context results in low acceptance rates, and a rejected permission cannot be re-requested programmatically.
*Do this instead:* Show a soft-ask screen explaining the value before triggering the native prompt. Trigger at a contextually relevant moment (first workout start, or a dedicated notifications settings screen).

**Anti-Pattern: Using getExpoPushTokenAsync() when sending via FCM**
Expo push tokens route through Expo's push service. Sending an Expo push token to FCM's API directly will fail silently.
*Do this instead:* Use `messaging().getToken()` from `@react-native-firebase/messaging` to get the native FCM token. Use `getExpoPushTokenAsync()` only if routing through Expo's push service (not this project's architecture).

**Anti-Pattern: Storing notification payloads in the FCM `notification` object for app-handled routing**
The `notification` object triggers the OS display layer. `data` is what the app reads to determine routing.
*Do this instead:* Put routing info in `data: { screen: 'wods', ... }` and use FCM data-only messages when the app needs to handle display itself (foreground case). Use `notification` object only for background/quit where OS handles display.

---

## v1.0 Architecture (original research, 2026-03-14)

The sections below document the original v1.0 architecture research. Relevant for context on the full system structure.

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │Dashboard │  │Workouts  │  │  Cycle   │  │ Settings │  ...   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
├───────┴──────────────┴─────────────┴──────────────┴─────────────┤
│                     State / Hooks Layer                          │
│  ┌───────────┐  ┌──────────────┐  ┌────────────────────────┐    │
│  │Zustand    │  │ Custom Hooks │  │ Domain Logic (pure TS) │    │
│  │Stores     │  │ (use-cases)  │  │ /src/domain/           │    │
│  └─────┬─────┘  └──────┬───────┘  └────────────────────────┘    │
├────────┴───────────────┴────────────────────────────────────────┤
│                      Repository Layer                            │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │FirestoreRepo  │  │ LocalRepo    │  │  PaymentRepository   │  │
│  │(CRUD + sync)  │  │(AsyncStorage)│  │  (RevenueCat)        │  │
│  └───────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
├──────────┴────────────────┴────────────────────────┴─────────────┤
│                        Data Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐             │
│  │  Firestore   │  │AsyncStorage  │  │ RevenueCat │             │
│  │(native SDK)  │  │(local cache) │  │ + Stripe   │             │
│  └──────────────┘  └──────────────┘  └────────────┘             │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │Firebase Auth │  │Cloud Funcs   │                             │
│  │(Apple/Google │  │(Gemini proxy,│                             │
│  │ Email/Guest) │  │ WOD writes)  │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Screen components | Render UI, handle user events | React functional components, Expo Router pages |
| Zustand stores | Global app state (auth, subscriptions, UI flags) | Per-domain slices: useAuthStore, useSubscriptionStore |
| Custom hooks (use-cases) | Orchestrate domain logic + repository calls | `useGenerateWorkout()`, `useCycleAdaptation()` |
| Domain layer | Pure business logic — cycle adaptation, injury engine, benchmarks | Zero-dependency TypeScript modules, 100% testable |
| Repository interfaces | Typed contracts for data access | TypeScript interfaces, one implementation per backend |
| Firestore repository | CRUD to Firestore; offline handled by native SDK | react-native-firebase/firestore |
| Local repository | Offline-only guest data; persisted state | AsyncStorage via Zustand `persist` middleware |
| Payment repository | Entitlement checks, purchase flows | RevenueCat react-native-purchases (mobile + web) |
| Firebase Auth | User identity, sign-in providers | react-native-firebase/auth |
| Cloud Functions | Server-side: Gemini proxy, WOD admin writes | Node.js/TypeScript Firebase Functions |

## Recommended Project Structure

```
src/
├── app/                    # Expo Router pages (file-based routing)
│   ├── (auth)/             # Sign-in, onboarding routes
│   ├── (tabs)/             # Main tab bar: dashboard, programs, workouts, cycle, history
│   ├── _layout.tsx         # Root layout, auth gate, theme provider
│   └── +not-found.tsx      # 404 fallback
│
├── domain/                 # Pure TypeScript — zero framework deps
│   ├── cycle/              # Phase inference, adaptation multipliers
│   ├── injury/             # Injury engine, exercise substitution
│   ├── benchmarks/         # Benchmark catalog, scoring
│   ├── maxes/              # 1RM calculations
│   ├── pain/               # Pain trend analysis
│   ├── rehab/              # Rehab session generation
│   └── types.ts            # Shared domain types (enums, interfaces)
│
├── repositories/           # Data access contracts + implementations
│   ├── interfaces/         # TypeScript interfaces (IWorkoutRepo, ICycleRepo, etc.)
│   ├── firestore/          # react-native-firebase implementations
│   ├── local/              # AsyncStorage implementations (guest mode)
│   └── index.ts            # Factory: returns correct impl based on auth mode
│
├── stores/                 # Zustand global state slices
│   ├── auth-store.ts       # Auth state, currentUser, mode (authenticated/guest)
│   ├── subscription-store.ts # RevenueCat entitlements
│   └── ui-store.ts         # Modal state, loading flags
│
├── hooks/                  # Use-case hooks — orchestrate domain + repositories
│   ├── use-generate-workout.ts
│   ├── use-cycle-adaptation.ts
│   ├── use-injury-engine.ts
│   └── use-workout-execution.ts
│
├── features/               # Feature modules (self-contained per tab/feature)
│   ├── dashboard/
│   ├── programs/
│   ├── workouts/
│   ├── cycle/
│   ├── history/
│   ├── benchmarks/
│   ├── maxes/
│   └── settings/
│
├── components/             # Shared, reusable UI components
│   ├── ui/                 # Base: Button, Card, Badge, Input
│   └── workout/            # ForTimerTimer, AmrapTimer, EmomTimer, etc.
│
├── theme/                  # Design tokens: Art Deco palette, typography, spacing
│   └── index.ts
│
├── firebase/               # Firebase SDK wrappers (platform-aware)
│   ├── app.ts
│   ├── auth.ts / auth.web.ts
│   ├── firestore.ts
│   ├── appCheck.ts
│   ├── callCloudFunction.ts / callCloudFunction.web.ts
│   ├── analytics.ts / analytics.web.ts     ← new in v1.1
│   ├── crashlytics.ts / crashlytics.web.ts ← new in v1.1
│   └── messaging.ts                        ← new in v1.1
│
├── notifications/          # Notification domain (new in v1.1)
│   ├── NotificationService.ts
│   ├── NotificationPermissions.ts
│   ├── usePushToken.ts
│   └── useNotificationNavigation.ts
│
├── services/               # External service integrations (non-repository)
│   └── revenuecat.ts       # RevenueCat SDK init
│
└── utils/                  # Pure utility functions (formatters, date helpers)
```

## Architectural Patterns

### Pattern 1: Repository Factory Pattern

**What:** A factory function returns the correct repository implementation based on auth mode. Authenticated users get Firestore repos; guest users get AsyncStorage repos.

**When to use:** Required — this is how offline guest mode works without branching logic throughout the codebase.

**Trade-offs:** Adds indirection. Worth it because guest mode is a first-class requirement.

**Example:**
```typescript
// repositories/index.ts
export function getWorkoutRepo(authMode: 'authenticated' | 'guest'): IWorkoutRepository {
  return authMode === 'authenticated'
    ? new FirestoreWorkoutRepository()
    : new LocalWorkoutRepository();
}
```

### Pattern 2: Pure Domain Layer (Zero Framework Deps)

**What:** All business logic lives in `src/domain/` as plain TypeScript. No React, Firebase, or Expo imports allowed in this folder.

**When to use:** Always — enables Jest testing without mocking anything.

**Example:**
```typescript
// domain/cycle/adaptation.ts
export function adaptWorkloadForPhase(
  baseLoad: number,
  phase: CyclePhase,
  symptoms: Symptom[]
): AdaptedWorkload {
  const multiplier = PHASE_MULTIPLIERS[phase];
  return { load: baseLoad * multiplier * computeSymptomAdjustment(symptoms) };
}
```

### Pattern 3: No-Op Platform Branching for Native-Only Firebase Modules

**What:** Analytics and Crashlytics don't exist on web. Use the `.web.ts` extension to provide no-op implementations with matching type signatures. This is the established pattern already used for `auth.web.ts` and `callCloudFunction.web.ts`.

**When to use:** Any Firebase RNF module called from shared code paths that has no web equivalent.

**Example:**
```typescript
// src/firebase/crashlytics.ts (native)
import crashlytics from '@react-native-firebase/crashlytics';
export function recordError(error: Error): void {
  crashlytics().recordError(error);
}

// src/firebase/crashlytics.web.ts (web no-op)
export function recordError(_error: Error): void {
  // Crashlytics not available on web
}
```

### Pattern 4: Offline-First with react-native-firebase

**What:** Use `react-native-firebase` (native SDK wrapper) instead of the Firebase JS SDK. Firestore offline persistence is enabled by default with the native SDK.

**When to use:** Required for offline support — the Firebase JS SDK does not support Firestore offline persistence in React Native.

**Trade-offs:** Requires a custom Expo dev client. Config plugins via `app.json` handle native configuration.

```typescript
// Default behavior — no extra setup needed for offline
import firestore from '@react-native-firebase/firestore';
// This write queues locally if offline, syncs when online
await firestore().collection('users').doc(userId).collection('workouts').add(workoutData);
```

### Pattern 5: FCM Token Persisted to Existing User Document

**What:** FCM tokens are stored as a field on the existing `/users/{uid}` Firestore document, not in a separate collection. `saveFCMToken()` uses `{ merge: true }` to avoid touching other fields.

**When to use:** Appropriate for v1.1 where single active device per user is the assumed model.

**Trade-offs:** Does not support multi-device per user (last token wins). Multi-device support can be added later by switching to a `/users/{uid}/devices/{deviceId}` subcollection.

## Data Flow

### Workout Execution Flow (Offline-Critical)

```
User starts workout
    ↓
useWorkoutExecution() hook
    ↓ (reads from local cache or Firestore)
WorkoutRepository.getProgram()
    ↓
Domain: adaptWorkloadForPhase(baseLoad, cyclePhase, symptoms)
    ↓
Domain: applyInjuryModifications(exercises, injuryProfile)
    ↓
Screen renders adapted workout
    ↓
WorkoutRepository.saveCompletedSet()
    ↓ (writes to Firestore local cache immediately; syncs when online)
History updated via real-time Firestore listener
```

### Auth + Routing Flow

```
App starts
    ↓
Firebase Auth state listener (immediate — cached from last session)
    ↓
         ┌── No user → guest mode OR sign-in screen
         └── User exists → AppState: authenticated
                               ↓
                 RevenueCat.logIn(firebaseUID)
                 crashlytics().setUserId(uid)  ← new in v1.1
                 analytics().setUserId(uid)    ← new in v1.1
                               ↓
                 usePushToken() → FCM token → Firestore  ← new in v1.1
                               ↓
                 Navigate to main tabs
```

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Single FCM token per user in `/users/{uid}` sufficient. Monorepo, single Firestore database. |
| 1k-10k users | Monitor Firestore read costs on program catalog. FCM `sendEachForMulticast` batches at 500 tokens — Cloud Function must handle pagination. Consider FCM topics for WOD broadcast. |
| 10k-100k users | Switch WOD notifications to FCM topics (`messaging().subscribeToTopic('wod-updates')`) — avoids querying all tokens. Cloud Function cold starts affect AI generation; add minimum instance. |
| 100k+ users | Firestore document contention on public WOD documents. CDN-cache static WOD delivery. Multi-device token support needed. |

## Anti-Patterns

### Anti-Pattern 1: Using Firebase JS SDK for Offline Persistence

**What people do:** Install `firebase` (JS SDK) expecting offline persistence in RN.
**Why it's wrong:** Firebase JS SDK relies on IndexedDB — not available in React Native. Offline persistence silently fails.
**Do this instead:** Use `@react-native-firebase/firestore` (native SDK wrapper).

### Anti-Pattern 2: Domain Logic in Screens or Hooks

**What people do:** Write cycle math or injury substitution directly in screen components.
**Why it's wrong:** Untestable without rendering. Leads to duplication.
**Do this instead:** All business logic in `src/domain/` as pure TypeScript.

### Anti-Pattern 3: Transactions for Offline-Capable Writes

**What people do:** Use Firestore transactions for workout logging.
**Why it's wrong:** Transactions require a server round-trip and fail offline.
**Do this instead:** Standard document writes for all user data that must work offline.

### Anti-Pattern 4: setBackgroundMessageHandler Inside a Component

**What people do:** Register the FCM background handler in `useEffect` inside `_layout.tsx`.
**Why it's wrong:** Handler is missed for background/quit states where components don't mount.
**Do this instead:** Register in `index.ts` before `AppRegistry.registerComponent`.

### Anti-Pattern 5: Using getExpoPushTokenAsync() with Direct FCM Sends

**What people do:** Get Expo push tokens and send them to the FCM API directly.
**Why it's wrong:** Expo tokens route through Expo's service — they are not raw FCM tokens.
**Do this instead:** Use `messaging().getToken()` for native FCM tokens when sending via FCM Admin SDK.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Firebase Auth | `@react-native-firebase/auth` listeners → `useAuthStore` | Apple Sign-In requires native module |
| Firestore | `@react-native-firebase/firestore` with offline persistence | Offline on by default with native SDK |
| Firebase Cloud Functions | HTTP callable via `@react-native-firebase/functions` | Not for offline-critical paths |
| Firebase Analytics | `@react-native-firebase/analytics`, no-op on web | Manual screen tracking required |
| Firebase Crashlytics | `@react-native-firebase/crashlytics`, no-op on web | ErrorBoundary + setUserId on sign-in |
| FCM (Cloud Messaging) | `@react-native-firebase/messaging`, token to Firestore | Background handler in index.ts |
| RevenueCat | `react-native-purchases`, logIn with Firebase UID | Web uses Web Billing (Stripe) |
| Gemini AI | Via Firebase Cloud Function proxy | Degrades gracefully offline |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Domain ↔ Hooks | Direct TypeScript function calls | Domain has no async |
| Hooks ↔ Repositories | Repository interface method calls | Hooks never import Firestore directly |
| Notifications ↔ Expo Router | `router.push()` from useNotificationNavigation | Called from notification tap listener |
| Analytics ↔ Expo Router | `usePathname()` hook drives logScreenView | Mounted at root layout level |
| Crashlytics ↔ ErrorBoundary | Direct call in componentDidCatch | Class component required by React API |

## Sources

- [Expo Push Notifications Setup](https://docs.expo.dev/push-notifications/push-notifications-setup/) — official, current
- [Expo: Send Notifications with FCM and APNs](https://docs.expo.dev/push-notifications/sending-notifications-custom/) — official, current
- [Expo: Using Firebase](https://docs.expo.dev/guides/using-firebase/) — official, current
- [EAS Submit Configuration](https://docs.expo.dev/submit/eas-json/) — official, current
- [React Native Firebase: Messaging Usage](https://rnfirebase.io/messaging/usage) — MEDIUM confidence (official docs)
- [React Native Firebase: Crashlytics Usage](https://rnfirebase.io/crashlytics/usage) — MEDIUM confidence (official docs)
- [React Native Firebase: Analytics Screen Tracking](https://rnfirebase.io/analytics/screen-tracking) — MEDIUM confidence
- [GitHub Issue: RNF messaging plugin does not add Background Modes](https://github.com/invertase/react-native-firebase/issues/7577) — MEDIUM (community pattern)
- Codebase inspection: `app.json`, `app/_layout.tsx`, `app/(app)/_layout.tsx`, `useRestTimer.ts`, `FirestoreUserRepo.ts`, `UserRepository.ts` — HIGH confidence

---
*Architecture research for: React Native + Expo + Firebase cross-platform fitness app (Sundee Fundee)*
*v1.0 researched: 2026-03-14 | v1.1 addendum researched: 2026-03-16*

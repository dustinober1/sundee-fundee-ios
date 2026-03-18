# Phase 19: Analytics + Crash Reporting - Research

**Researched:** 2026-03-18
**Domain:** Firebase Analytics screen tracking (Expo Router), Firebase Crashlytics custom keys + recordError, EAS Update OTA configuration
**Confidence:** HIGH

## Summary

Phase 19 wires three previously-installed but unused modules — `@react-native-firebase/analytics`, `@react-native-firebase/crashlytics`, and EAS Update — into meaningful production behavior. All three native modules are already compiled into the development build from Phase 18 (verified on physical devices). The init functions (`initAnalytics`, `initCrashlytics`) are already called at app startup from `src/firebase/init.ts`. Phase 19 is entirely a JS-layer phase: no new native builds required.

The three workstreams are independent and can be implemented in parallel: (1) screen tracking via `usePathname` + `analytics().logScreenView()` in a root layout hook, (2) key event logging at five call sites spread across `workout-session.tsx`, `PaywallModal.tsx`, `ai-workout/config.tsx`, and `cycle.tsx`, and (3) Crashlytics custom key attachment + `recordError` via a shared utility, plus EAS Update setup (`expo-updates` install + `eas update:configure` + channel config in `eas.json`).

The most important pitfall: screen_view events in React Native are NOT fired automatically by the native Firebase Analytics SDK because Expo Router manages navigation in JS, not native. Manual tracking using `usePathname` hook in a root layout component is required and is the documented Expo pattern. The `google_analytics_automatic_screen_reporting_enabled` setting in `firebase.json` does NOT help for Expo Router apps.

**Primary recommendation:** Implement a `useScreenTracking` hook that calls `analytics().logScreenView()` on every `usePathname` change; place it in `app/_layout.tsx`. Wire event logging at each of the five action call sites. Add a `useCrashlyticsContext` utility that sets three custom keys (`current_screen`, `subscription_tier`, `cycle_phase`) and expose `recordError` from a thin wrapper. Set up EAS Update by installing `expo-updates`, running `eas update:configure`, adding `channel` to eas.json preview/production profiles, and triggering `eas update` to verify.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ANLYT-01 | Firebase Analytics tracks screen views automatically via Expo Router | Requires manual `usePathname` + `logScreenView` hook — native auto-tracking does not work in JS-managed navigation. Hook goes in `app/_layout.tsx`. |
| ANLYT-02 | Key events logged: workout_started, workout_completed, subscription_started, ai_workout_generated, cycle_phase_updated | Five call sites identified: `workout-session.tsx` (startWorkout at line 256, handleFinish at line 384), `PaywallModal.tsx` (purchasePackage/purchaseProduct success), `ai-workout/config.tsx` (handleGenerateWorkout success), `cycle.tsx` (savePeriodLog success). |
| ANLYT-03 | User properties set for subscription tier (free/premium) and cycle tracking opt-in | `analytics().setUserProperty(name, value)` at sign-in and on entitlement change. `isPremium` available from `useEntitlementContext()`; `cycleOptIn` from `OnboardingProfileRepo`. Set in `app/_layout.tsx` on user sign-in. |
| ANLYT-04 | Crashlytics captures native crashes and JS errors via recordError() | `crashlytics().recordError(error)` API confirmed. Module is already initialized via `initCrashlytics()`. Thin wrapper needed in `src/firebase/crashlytics.ts`. |
| ANLYT-05 | Crashlytics custom keys attached: current screen, subscription tier, cycle phase | `crashlytics().setAttributes({ current_screen, subscription_tier, cycle_phase })` at each relevant point. Can be driven by same `usePathname` hook as screen tracking. |
| ANLYT-06 | OTA update capability via EAS Update for JS-layer hotfixes | `expo-updates` not installed; `runtimeVersion` not set; no `channel` in eas.json profiles. Full first-time setup required: install package, configure, add channels. New binary needed after first configure. |
</phase_requirements>

## Standard Stack

### Core (already installed from Phase 18)
| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| @react-native-firebase/analytics | ^23.8.8 | Firebase Analytics event + screen tracking | Installed + init called; no events wired yet |
| @react-native-firebase/crashlytics | ^23.8.8 | Native crash + JS error reporting | Installed + init called; no custom keys/recordError wired yet |

### To Install
| Library | Version | Purpose | Why Needed |
|---------|---------|---------|------------|
| expo-updates | ~0.28.x (SDK 55) | OTA update client; fetches JS bundles from EAS Update | Required for ANLYT-06; not currently installed |

### Supporting (already present)
| Hook/API | Source | Purpose |
|----------|--------|---------|
| `usePathname()` | expo-router | Returns current route path; triggers on navigation |
| `useEntitlementContext()` | src/entitlements/EntitlementContext | Provides `isPremium` for user property |
| `useSession()` | src/auth/AuthContext | Provides `user` for Crashlytics `setUserId` |
| `getOnboardingProfileRepo()` | src/repositories/OnboardingProfileRepo | Provides `cycleOptIn` for user property |

**Installation:**
```bash
npx expo install expo-updates
```

## Architecture Patterns

### Recommended File Layout for Phase 19
```
src/firebase/
├── analytics.ts          # EXTEND: add logEvent, logScreenView, setUserProps helpers
├── crashlytics.ts        # EXTEND: add recordError, setCustomKeys helpers
└── init.ts               # NO CHANGE — already calls initAnalytics + initCrashlytics

src/hooks/
└── useScreenTracking.ts  # NEW: usePathname-based screen_view + Crashlytics current_screen key

app/
└── _layout.tsx           # EXTEND: call useScreenTracking(), set user properties on sign-in
```

### Pattern 1: Screen View Tracking with usePathname
**What:** A custom hook that fires `analytics().logScreenView()` on every route change, and simultaneously updates the Crashlytics `current_screen` key.
**When to use:** Mount it once in `app/_layout.tsx` (root layout, always rendered).
**Example:**
```typescript
// src/hooks/useScreenTracking.ts
// Source: Expo Router screen tracking docs (https://docs.expo.dev/router/reference/screen-tracking/)
import { useEffect } from 'react';
import { Platform } from 'react-native';
import { usePathname } from 'expo-router';

export function useScreenTracking(): void {
  const pathname = usePathname();

  useEffect(() => {
    if (Platform.OS === 'web') return;

    const screenName = pathname ?? 'unknown';

    // Fire screen_view event
    try {
      const analytics = require('@react-native-firebase/analytics').default;
      void analytics().logScreenView({
        screen_name: screenName,
        screen_class: screenName,
      });
    } catch {
      // Analytics module unavailable in test/web
    }

    // Keep Crashlytics current_screen key in sync
    try {
      const crashlytics = require('@react-native-firebase/crashlytics').default;
      void crashlytics().setAttribute('current_screen', screenName);
    } catch {
      // Crashlytics module unavailable in test/web
    }
  }, [pathname]);
}
```

In `app/_layout.tsx`:
```typescript
import { useScreenTracking } from '@/src/hooks/useScreenTracking';
// Inside RootLayout function body:
useScreenTracking();
```

### Pattern 2: logEvent at Action Call Sites
**What:** Call `analytics().logEvent(eventName, params)` immediately after a successful user action.
**When to use:** At the five identified trigger points.

```typescript
// Source: RNFB analytics reference (https://rnfirebase.io/reference/analytics)
import { Platform } from 'react-native';

// Helper — safe to call from any screen
export async function logEvent(
  eventName: string,
  params?: Record<string, string | number | boolean>
): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    const analytics = require('@react-native-firebase/analytics').default;
    await analytics().logEvent(eventName, params);
  } catch {
    // Non-fatal — analytics unavailable
  }
}
```

**Five call sites (all in existing files):**

| Event | File | Location | When to Fire |
|-------|------|----------|--------------|
| `workout_started` | `app/(app)/workout-session.tsx` | After `startWorkout()` at ~line 256 | First exercise added and workout becomes active |
| `workout_completed` | `app/(app)/workout-session.tsx` | After `finishWorkout()` succeeds in `handleFinish` at ~line 384 | Workout saved successfully |
| `subscription_started` | `src/components/paywall/PaywallModal.tsx` | After `Purchases.purchasePackage(pkg)` or `purchaseProduct` succeeds | Customer info returned with active entitlement |
| `ai_workout_generated` | `app/(app)/ai-workout/config.tsx` | After `handleGenerateWorkout` succeeds (online or offline path) at ~line 287 | Workout generated, navigating to preview |
| `cycle_phase_updated` | `app/(app)/(tabs)/cycle.tsx` | After `savePeriodLog` saves successfully at ~line 157 | Period log written to CycleRepo |

### Pattern 3: User Properties
**What:** Set `subscription_tier` (free/premium) and `cycle_tracking_enabled` (true/false) as Firebase Analytics user properties.
**When to set:** On user sign-in (in `handleUserSignIn` in `_layout.tsx`) and whenever entitlement changes.

```typescript
// Source: RNFB analytics reference
export async function setUserProperties(props: {
  subscriptionTier: 'free' | 'premium';
  cycleTrackingEnabled: boolean;
}): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    const analytics = require('@react-native-firebase/analytics').default;
    await analytics().setUserProperties({
      subscription_tier: props.subscriptionTier,
      cycle_tracking_enabled: String(props.cycleTrackingEnabled),
    });
  } catch {
    // Non-fatal
  }
}
```

Note: Firebase user property values must be strings. Boolean `cycleTrackingEnabled` must be stringified.

### Pattern 4: Crashlytics Custom Keys + recordError
**What:** Set `subscription_tier` and `cycle_phase` custom keys on Crashlytics (alongside `current_screen` set by `useScreenTracking`). Expose `recordError` wrapper.

```typescript
// Source: https://rnfirebase.io/crashlytics/usage
export async function setCrashlyticsKeys(keys: {
  subscriptionTier?: 'free' | 'premium';
  cyclePhase?: string;
}): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    const attrs: Record<string, string> = {};
    if (keys.subscriptionTier !== undefined) {
      attrs.subscription_tier = keys.subscriptionTier;
    }
    if (keys.cyclePhase !== undefined) {
      attrs.cycle_phase = keys.cyclePhase;
    }
    await crashlytics().setAttributes(attrs);
  } catch {
    // Non-fatal
  }
}

export function recordError(error: Error): void {
  if (Platform.OS === 'web') return;
  try {
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    crashlytics().recordError(error);
  } catch {
    // Non-fatal
  }
}
```

### Pattern 5: EAS Update Configuration
**What:** Install `expo-updates`, run `eas update:configure`, add `channel` to eas.json build profiles.
**Critical:** EAS Update requires a new binary build after first configuration because `expo-updates` is a native module. The dev build from Phase 18 cannot receive OTA updates. A new build (preview or production profile) is needed.

**Steps:**
1. `npx expo install expo-updates`
2. `eas update:configure` — adds `runtimeVersion` and `updates.url` to app.json
3. eas.json gets `"channel"` added to preview and production build profiles:
```json
{
  "build": {
    "preview": {
      "distribution": "internal",
      "channel": "preview"
    },
    "production": {
      "channel": "production"
    }
  }
}
```
4. Build a new preview binary: `eas build --platform ios --profile preview`
5. Publish update: `eas update --channel preview --message "Phase 19 analytics wiring"`

**ANLYT-06 verification:** Running `eas update` produces a published update; the previously-built binary fetches and applies it without a new binary build.

### Anti-Patterns to Avoid
- **Relying on native screen_view auto-tracking:** Firebase Analytics can fire screen_view for native Activities/ViewControllers, but Expo Router operates in a single Activity/ViewController. Navigation events do not cross the native boundary. `usePathname` is the only reliable trigger.
- **Setting user properties before analytics initializes:** `initAnalytics()` is called in `useEffect` at root layout. Set user properties after sign-in (inside `handleUserSignIn`), not synchronously on module load.
- **Using `firebase.json google_analytics_automatic_screen_reporting_enabled: true`:** This only works for native Android Activities, not for Expo Router JS navigation.
- **Calling `eas update` before installing expo-updates in binary:** The OTA update will be published but the running app will not check for it because the binary doesn't include the expo-updates native module.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Screen change detection | Custom navigation state listener | `usePathname()` from expo-router | Expo Router provides URL at all times; no custom listener needed |
| Analytics event deduplication | Custom event queue or debounce | None needed | Firebase Analytics SDK handles deduplication natively |
| Crashlytics breadcrumbs | Custom log store | `crashlytics().log(message)` | Native SDK already maintains a log buffer per session |
| OTA bundle serving | Custom update server | EAS Update service | Handles CDN, deployment channels, rollbacks, runtime version gating |
| User property tracking | Custom Firestore user property sync | `analytics().setUserProperties()` | Firebase aggregates across sessions automatically |

**Key insight:** All five custom events and both user properties are single-line calls. The only "architecture" is deciding where in existing code to place them — no new infrastructure is needed.

## Common Pitfalls

### Pitfall 1: Screen_view Not Appearing in DebugView
**What goes wrong:** DebugView shows no screen_view events despite hook being mounted.
**Why it happens:** `useScreenTracking` hook is placed inside a conditionally-rendered component (e.g., inside the auth guard where `return null` short-circuits). The hook must be in `app/_layout.tsx` root body, which always renders.
**How to avoid:** Call `useScreenTracking()` at the top of `RootLayout` function body, before any conditional returns.
**Warning signs:** Hook fires on initial mount but not on tab changes.

### Pitfall 2: DebugView Event Delay
**What goes wrong:** Events fired in test don't appear in Firebase DebugView for 30+ seconds or at all.
**Why it happens:** DebugView requires the device to be registered: `adb shell setprop debug.firebase.analytics.app com.sundeefundee` (Android) or the `FIRDebugEnabled` launch arg (iOS). Without this, analytics batches events for ~1 hour.
**How to avoid:** Enable DebugView mode on the test device before verifying ANLYT-01 and ANLYT-02.
**Warning signs:** No events in DebugView despite `console.log` confirming `logEvent` was called.

### Pitfall 3: Analytics User Properties Not Appearing
**What goes wrong:** User properties set but not visible in Firebase Analytics console.
**Why it happens:** User properties take up to 24 hours to appear in the Firebase Analytics console (unlike DebugView which is real-time). Also, property values must be strings — passing `true` (boolean) instead of `'true'` (string) silently drops the property.
**How to avoid:** Use DebugView for real-time verification. Always stringify boolean and number values.
**Warning signs:** DebugView shows user property events but Firebase console shows nothing for 24 hours (this is normal).

### Pitfall 4: Crashlytics recordError Not Appearing in Dashboard
**What goes wrong:** `recordError` is called but no event appears in Crashlytics dashboard.
**Why it happens:** (a) In development builds, Crashlytics sends reports in real-time but they appear under "Non-fatals" not "Crashes". (b) The device needs a network connection at time of send. (c) Reports from debug builds may be filtered in the Firebase console by default.
**How to avoid:** Use a preview build for ANLYT-04 verification (per the success criterion). In the Firebase console, enable "View all issues" to see non-fatals.
**Warning signs:** No events in Crashlytics dashboard after calling `recordError`.

### Pitfall 5: EAS Update Binary/Update Mismatch
**What goes wrong:** `eas update` publishes but the device ignores it.
**Why it happens:** Runtime version mismatch — the published update's `runtimeVersion` must match the binary's compiled `runtimeVersion`. If `expo-updates` was added after the binary was built, the binary has no update support.
**How to avoid:** Build a new binary after `eas update:configure` sets `runtimeVersion`. The Phase 18 dev build cannot receive OTA updates.
**Warning signs:** `expo-updates` API returns `Updates.isEmbeddedLaunch: true` on every launch even after publishing.

### Pitfall 6: Missing Analytics/Crashlytics Mocks in Jest
**What goes wrong:** Tests calling files that import `src/firebase/analytics.ts` fail with "native module not found".
**Why it happens:** `__mocks__/@react-native-firebase/` directory has mocks for `app.ts`, `auth.ts`, `firestore.ts` but NOT for `analytics` or `crashlytics`.
**How to avoid:** Add `__mocks__/@react-native-firebase/analytics.js` and `crashlytics.js` mocks before writing any tests that touch files importing from `src/firebase/analytics.ts` or `src/firebase/crashlytics.ts`.
**Warning signs:** Jest test fails with "Cannot find native module RNFBAnalyticsModule".

## Code Examples

Verified patterns from official sources and existing codebase conventions:

### Screen Tracking Hook (root layout)
```typescript
// src/hooks/useScreenTracking.ts
// Source: Expo Router screen tracking (https://docs.expo.dev/router/reference/screen-tracking/)
// + RNFB analytics (https://rnfirebase.io/analytics/screen-tracking)
import { useEffect } from 'react';
import { Platform } from 'react-native';
import { usePathname } from 'expo-router';

export function useScreenTracking(): void {
  const pathname = usePathname();

  useEffect(() => {
    if (Platform.OS === 'web') return;
    const screenName = pathname ?? 'unknown';

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const analytics = require('@react-native-firebase/analytics').default;
      void analytics().logScreenView({ screen_name: screenName, screen_class: screenName });
    } catch { /* non-fatal */ }

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const crashlytics = require('@react-native-firebase/crashlytics').default;
      void crashlytics().setAttribute('current_screen', screenName);
    } catch { /* non-fatal */ }
  }, [pathname]);
}
```

### logEvent Helper
```typescript
// src/firebase/analytics.ts — add below existing initAnalytics function
// Source: https://rnfirebase.io/reference/analytics
export async function logEvent(
  eventName: string,
  params?: Record<string, string | number | boolean>
): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const analytics = require('@react-native-firebase/analytics').default;
    await analytics().logEvent(eventName, params ?? {});
  } catch {
    // Non-fatal — event lost if analytics unavailable
  }
}
```

### workout_started event (workout-session.tsx)
```typescript
// After: startWorkout(); at ~line 256
import { logEvent } from '@/src/firebase/analytics';
// ...
startWorkout();
void logEvent('workout_started');
```

### subscription_started event (PaywallModal.tsx)
```typescript
// After: const { customerInfo } = await Purchases.purchasePackage(pkg); succeeds
// (Inside the success path, before navigating away)
void logEvent('subscription_started', { source: 'paywall' });
```

### Crashlytics recordError Wrapper
```typescript
// src/firebase/crashlytics.ts — add below existing initCrashlytics function
// Source: https://rnfirebase.io/crashlytics/usage
export function recordError(error: Error, context?: string): void {
  if (Platform.OS === 'web') return;
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    if (context) {
      crashlytics().log(context);
    }
    crashlytics().recordError(error);
  } catch { /* non-fatal */ }
}

export async function setCrashlyticsKeys(keys: {
  subscriptionTier?: 'free' | 'premium';
  cyclePhase?: string;
}): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    const attrs: Record<string, string> = {};
    if (keys.subscriptionTier !== undefined) attrs.subscription_tier = keys.subscriptionTier;
    if (keys.cyclePhase !== undefined) attrs.cycle_phase = keys.cyclePhase;
    if (Object.keys(attrs).length > 0) {
      await crashlytics().setAttributes(attrs);
    }
  } catch { /* non-fatal */ }
}
```

### Jest Mocks Required (Wave 0)
```javascript
// __mocks__/@react-native-firebase/analytics.js
const analytics = jest.fn(() => ({
  logScreenView: jest.fn().mockResolvedValue(undefined),
  logEvent: jest.fn().mockResolvedValue(undefined),
  setUserProperties: jest.fn().mockResolvedValue(undefined),
  setUserProperty: jest.fn().mockResolvedValue(undefined),
  setAnalyticsCollectionEnabled: jest.fn().mockResolvedValue(undefined),
}));
module.exports = analytics;
module.exports.default = analytics;
```

```javascript
// __mocks__/@react-native-firebase/crashlytics.js
const crashlytics = jest.fn(() => ({
  setCrashlyticsCollectionEnabled: jest.fn().mockResolvedValue(undefined),
  recordError: jest.fn(),
  setAttribute: jest.fn().mockResolvedValue(undefined),
  setAttributes: jest.fn().mockResolvedValue(undefined),
  log: jest.fn(),
  setUserId: jest.fn().mockResolvedValue(undefined),
  crash: jest.fn(),
}));
module.exports = crashlytics;
module.exports.default = crashlytics;
```

### EAS Update eas.json channels
```json
// eas.json after eas update:configure + manual channel addition
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": { "EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN": "..." }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview"
    },
    "production": {
      "channel": "production"
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| expo-firebase-analytics (wrapper package) | @react-native-firebase/analytics directly | Expo SDK 49+ | Unified RNFB; no wrapper layer |
| React Navigation `onStateChange` for screen tracking | `usePathname()` hook from Expo Router | Expo Router adoption | Much simpler; URL always available |
| Manual Crashlytics event upload timing | Automatic batching with configurable `crashlytics_debug_enabled` | RNFB v8+ | Debug builds send immediately |
| CodePush (App Center) for OTA | EAS Update | Microsoft retiring CodePush 2024 | EAS Update is the Expo-native successor |
| Hermes JS bundles for OTA | Hermes bytecode diffing (beta, SDK 55) | SDK 55 (2025) | Smaller update sizes via binary patch |

**Deprecated/outdated:**
- `expo-firebase-analytics`: Deprecated wrapper — project already uses RNFB directly (correct).
- `google_analytics_automatic_screen_reporting_enabled: true` in `firebase.json`: Does not work for JS-driven navigation in Expo Router. The Phase 18 RESEARCH.md set `analytics_auto_collection_enabled: true` which is separate (collection enabled vs. screen reporting).
- CodePush (App Center): Microsoft shut down 2024-03-31 — EAS Update is the migration path.

## Open Questions

1. **EAS Update binary requirement for ANLYT-06 verification**
   - What we know: `expo-updates` is a native module; ANLYT-06 success criterion says "eas update produces a published update that installs on a connected device without requiring a new binary build"
   - What's unclear: The Phase 18 dev build does NOT include expo-updates, so a new binary is needed before the OTA update can install. The success criterion may mean "subsequent updates after this first setup don't need a new binary."
   - Recommendation: Plan Wave 1 as expo-updates setup + build a new preview binary. Wave 2 as OTA update verification. The first `eas update` after that new binary requires no new binary.

2. **Cycle phase value for Crashlytics key**
   - What we know: ANLYT-05 requires `cycle_phase` custom key. `calculateCycleStatus()` exists in `src/domain/cycle/cycle-calculations.ts`.
   - What's unclear: Whether to set this in the screen tracking hook (per navigation) or once at app load. Setting it per-navigation would require loading cycle data on every route change.
   - Recommendation: Set it once at app launch (in `app/_layout.tsx` after user data loads) and update it when the cycle screen is visited. Use a string like `"follicular"`, `"ovulatory"`, `"luteal"`, `"menstrual"`, or `"unknown"` when not tracking.

3. **DebugView enablement for development testing**
   - What we know: iOS DebugView requires `-FIRDebugEnabled` launch argument (simulator) or Xcode scheme arg. Android requires `adb shell setprop`.
   - What's unclear: Whether the ANLYT-01/ANLYT-02 success criteria can be verified without DebugView (e.g., via console logs).
   - Recommendation: Document both the DebugView enablement steps (for human verification) and add Jest tests that assert `logEvent`/`logScreenView` was called (for automated verification).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30.3.0 + jest-expo 55.0.9 |
| Config file | jest.config.js (root level) |
| Quick run command | `npx jest --passWithNoTests` |
| Full suite command | `npx jest --passWithNoTests` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ANLYT-01 | `logScreenView` called when pathname changes | unit | `npx jest --testPathPattern=useScreenTracking -x` | Wave 0 |
| ANLYT-02 | `logEvent('workout_started')` called after startWorkout | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-02 | `logEvent('workout_completed')` called after finishWorkout | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-02 | `logEvent('subscription_started')` called after purchasePackage | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-02 | `logEvent('ai_workout_generated')` called after generation | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-02 | `logEvent('cycle_phase_updated')` called after savePeriodLog | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-03 | `setUserProperties` called with subscription_tier + cycle_tracking_enabled | unit | `npx jest --testPathPattern=analytics -x` | Wave 0 |
| ANLYT-04 | `recordError` calls crashlytics().recordError(error) | unit | `npx jest --testPathPattern=crashlytics -x` | Wave 0 |
| ANLYT-05 | `setAttributes` called with current_screen, subscription_tier, cycle_phase | unit | `npx jest --testPathPattern=crashlytics -x` | Wave 0 |
| ANLYT-01 | DebugView shows screen_view events | manual | N/A — requires device + Firebase Console | N/A |
| ANLYT-02 | DebugView shows all 5 key events | manual | N/A — requires device + Firebase Console | N/A |
| ANLYT-04 | Crashlytics dashboard shows non-fatal recordError | manual | N/A — requires preview build + Firebase Console | N/A |
| ANLYT-06 | `eas update` publishes and device installs without new binary | manual | N/A — requires EAS account + preview build | N/A |

### Sampling Rate
- **Per task commit:** `npx jest --passWithNoTests`
- **Per wave merge:** `npx jest --passWithNoTests`
- **Phase gate:** Full suite green + human verification of DebugView events + Crashlytics non-fatal in dashboard + `eas update` installs on device

### Wave 0 Gaps
- [ ] `__mocks__/@react-native-firebase/analytics.js` — covers ANLYT-01, ANLYT-02, ANLYT-03 (mocks `logEvent`, `logScreenView`, `setUserProperties`)
- [ ] `__mocks__/@react-native-firebase/crashlytics.js` — covers ANLYT-04, ANLYT-05 (mocks `recordError`, `setAttributes`, `setAttribute`, `log`)
- [ ] `src/hooks/__tests__/useScreenTracking.test.ts` — unit tests for ANLYT-01
- [ ] `src/firebase/__tests__/analytics.test.ts` — unit tests for `logEvent`, `setUserProperties` helpers (ANLYT-02, ANLYT-03)
- [ ] `src/firebase/__tests__/crashlytics.test.ts` — unit tests for `recordError`, `setCrashlyticsKeys` (ANLYT-04, ANLYT-05)

*(ANLYT-06 and DebugView verification are manual-only — no automated tests feasible)*

## Sources

### Primary (HIGH confidence)
- Expo Router screen tracking docs — https://docs.expo.dev/router/reference/screen-tracking/ — `usePathname` + `useGlobalSearchParams` hooks for analytics
- EAS Update getting started — https://docs.expo.dev/eas-update/getting-started/ — install steps, `eas update:configure`, channel config, publish command
- RNFB Crashlytics usage — https://rnfirebase.io/crashlytics/usage — `recordError`, `setAttribute`, `setAttributes` API
- RNFB Analytics screen tracking — https://rnfirebase.io/analytics/screen-tracking — `logScreenView` API and React Navigation integration (adapted for Expo Router)
- EAS Update introduction — https://docs.expo.dev/eas-update/introduction/ — expo-updates install requirement, new binary needed

### Secondary (MEDIUM confidence)
- Existing `src/firebase/analytics.ts`, `src/firebase/crashlytics.ts`, `src/firebase/init.ts` — confirmed Phase 18 initialization patterns that Phase 19 extends
- Existing `__mocks__/@react-native-firebase/app.ts` — mock pattern to follow for new analytics/crashlytics mocks
- Phase 18 RESEARCH.md decision: "analytics has no config plugin" — analytics module does not need its own config plugin, only JS wiring in Phase 19
- Phase 18 SUMMARY.md: EAS development builds confirmed working with analytics, crashlytics, messaging modules on physical devices

### Tertiary (LOW confidence)
- DebugView enablement via `-FIRDebugEnabled` launch arg (iOS) — standard Firebase practice but not verified against current Expo build setup
- Cycle phase string values (`"follicular"`, etc.) — inferred from `calculateCycleStatus` domain function; exact enum values need confirmation from source

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed; expo-updates is documented Expo package
- Screen tracking pattern: HIGH — official Expo Router docs confirm `usePathname` approach; RNFB docs confirm `logScreenView` API
- Event call sites: HIGH — specific line numbers identified in existing codebase; patterns are straightforward
- Crashlytics API: HIGH — `recordError`, `setAttribute`, `setAttributes` confirmed from official RNFB docs
- EAS Update setup: HIGH — official Expo docs confirm install steps and command structure
- DebugView verification flow: MEDIUM — standard Firebase practice but not verified against this specific Expo/EAS setup

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (stable — RNFB 23.x and Expo SDK 55 are current; EAS Update API is stable)

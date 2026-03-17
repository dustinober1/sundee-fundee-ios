# Phase 18: Foundation Config + Build Infrastructure - Research

**Researched:** 2026-03-17
**Domain:** EAS Build/Submit configuration, Firebase native modules (messaging/crashlytics/analytics), App Check attestation, iOS privacy manifest
**Confidence:** HIGH

## Summary

Phase 18 requires four coordinated changes: (1) installing and registering three new @react-native-firebase modules (messaging, crashlytics, analytics) in app.json plugins and expo-build-properties static linking, (2) configuring EAS production build and submit profiles in eas.json, (3) confirming Firebase App Check production attestation (DeviceCheck on iOS, Play Integrity on Android), and (4) adding a PrivacyInfo.xcprivacy via Expo's built-in `privacyManifests` field in app.json. All four produce a new EAS development build that becomes the base for Phases 19-23.

The existing codebase already has the correct patterns established: RNFB modules registered as app.json plugins, expo-build-properties with static linking, and App Check initialization with `__DEV__`-based provider switching. This phase extends those patterns rather than introducing new ones.

**Primary recommendation:** Add modules to app.json plugins + forceStaticLinking, add `privacyManifests` to expo.ios, flesh out eas.json submit section, add `react-native` config to firebase.json, then trigger a new EAS dev build. Verify on physical devices.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Privacy manifest matches legacy Swift app declarations: Health & Fitness, User ID, Name, Purchase History, Other User Content
- All data types linked to user identity, not used for tracking (NSPrivacyTracking: false)
- Cycle/menstrual data declared as sensitive health information linked to user identity
- Explicitly declare NSPrivacyAccessedAPICategoryUserDefaults (reason: CA92.1)
- Add via Expo config plugin (managed workflow) -- no ios/ directory ejection
- Do NOT expand for Phase 19 analytics/crash data types yet
- EAS managed credentials -- let EAS handle provisioning profiles and signing certificates
- Production build profile uses EAS defaults -- no custom Proguard/R8 or Bitcode config
- iOS submit section: include ascAppId (user has App Store Connect app created)
- Android submit: configure track "internal" but skip serviceAccountKeyPath -- first Play Store submission must be manual AAB upload
- Development builds keep existing debug token config for simulator testing
- Switch to production attestation in Phase 18: DeviceCheck (iOS) and Play Integrity (Android)
- Enable attestation only -- do NOT enforce (reject unattested requests) yet; enforcement deferred to Phase 22
- Dual mode: development builds use debug tokens (simulator), preview/production builds use real attestation
- EAS env vars control which App Check mode activates per build profile
- Smoke test new modules only -- not a full retest of Phase 17 deferrals
- Physical iOS device required for App Check DeviceCheck verification (simulator can't verify)
- iOS device needs to be registered in Apple Developer portal first (not currently registered)

### Claude's Discretion
- Exact Expo config plugin implementation for PrivacyInfo.xcprivacy
- Firebase module initialization code structure
- EAS env var naming and organization
- Order of operations for module registration vs build profile config
- How to verify module initialization (logging, console output)

### Deferred Ideas (OUT OF SCOPE)
- Analytics/crash data type additions to PrivacyInfo.xcprivacy -- add when Phase 19 lands those features
- App Check enforcement (reject unattested requests) -- Phase 22
- Full Phase 17 deferred item retest -- later phases as features are built
- Google Play service account key setup for automated submit -- after first manual AAB upload
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-03 | Firebase App Check confirmed active in production mode (DeviceCheck iOS, Play Integrity Android) | Existing appCheck.ts already uses `__DEV__`-based provider switching. EAS development builds have `__DEV__=true` (debug JS), preview/production have `__DEV__=false`. Current code correctly routes to debug vs production providers. Firebase Console must have DeviceCheck + Play Integrity registered. |
| SEC-04 | PrivacyInfo.xcprivacy privacy manifest added with correct SDK declarations | Expo SDK 55 supports `expo.ios.privacyManifests` in app.json with full schema (NSPrivacyAccessedAPITypes, NSPrivacyCollectedDataTypes, NSPrivacyTracking, NSPrivacyTrackingDomains). Legacy plist provides exact data types to declare. |
| STORE-01 | EAS production build profiles configured for iOS and Android | eas.json already has build profiles. Submit section needs creation with iOS ascAppId. Android submit needs track: "internal" only (no serviceAccountKeyPath per user decision). |
</phase_requirements>

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| @react-native-firebase/app | ^23.8.8 | Firebase core | Installed, plugin registered |
| @react-native-firebase/app-check | ^23.8.8 | App Check attestation | Installed, plugin NOT registered (uses direct init) |
| @react-native-firebase/auth | ^23.8.8 | Firebase Auth | Installed, plugin registered |
| @react-native-firebase/firestore | ^23.8.8 | Firestore | Installed, static linking configured |
| expo-build-properties | ~55.0.9 | iOS static framework config | Installed, plugin registered |

### To Install
| Library | Version | Purpose | Why Needed |
|---------|---------|---------|------------|
| @react-native-firebase/messaging | ^23.8.8 | FCM push token registration, background data messages | Required for Phase 20 notifications; native module must be in build |
| @react-native-firebase/crashlytics | ^23.8.8 | Native crash + JS error reporting | Required for Phase 19 analytics; needs Expo config plugin for Android setup |
| @react-native-firebase/analytics | ^23.8.8 | Firebase Analytics event tracking | Required for Phase 19 analytics; auto screen view tracking |

**Installation:**
```bash
npm install @react-native-firebase/messaging @react-native-firebase/crashlytics @react-native-firebase/analytics
```

## Architecture Patterns

### app.json Plugin Registration Pattern

All RNFB modules follow the same pattern: add to `plugins` array and add native module name to `forceStaticLinking`. The crashlytics plugin is special -- it handles Android Gradle configuration automatically.

**Current plugins array:**
```json
"plugins": [
  "@react-native-firebase/app",
  "@react-native-firebase/auth",
  // ... other plugins ...
  ["expo-build-properties", {
    "ios": {
      "useFrameworks": "static",
      "forceStaticLinking": ["RNFBApp", "RNFBAuth", "RNFBFirestore", "RNFBAppCheck"]
    }
  }]
]
```

**After Phase 18:**
```json
"plugins": [
  "@react-native-firebase/app",
  "@react-native-firebase/auth",
  "@react-native-firebase/crashlytics",
  "@react-native-firebase/messaging",
  // ... other plugins ...
  ["expo-build-properties", {
    "ios": {
      "useFrameworks": "static",
      "forceStaticLinking": [
        "RNFBApp", "RNFBAuth", "RNFBFirestore", "RNFBAppCheck",
        "RNFBMessaging", "RNFBCrashlytics", "RNFBAnalytics"
      ]
    }
  }]
]
```

Note: `@react-native-firebase/analytics` does NOT have its own Expo config plugin -- it piggybacks on `@react-native-firebase/app`. It only needs static linking.

### Privacy Manifest via app.json (no config plugin needed)

Expo SDK 55 supports `privacyManifests` directly in `expo.ios`. This is the preferred approach -- no custom config plugin, no ejection.

```json
{
  "expo": {
    "ios": {
      "privacyManifests": {
        "NSPrivacyAccessedAPITypes": [
          {
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]
          }
        ],
        "NSPrivacyCollectedDataTypes": [
          {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeHealthAndFitness",
            "NSPrivacyCollectedDataTypeLinked": true,
            "NSPrivacyCollectedDataTypeTracking": false,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
          },
          {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeOtherUserContent",
            "NSPrivacyCollectedDataTypeLinked": true,
            "NSPrivacyCollectedDataTypeTracking": false,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
          },
          {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeUserID",
            "NSPrivacyCollectedDataTypeLinked": true,
            "NSPrivacyCollectedDataTypeTracking": false,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
          },
          {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeName",
            "NSPrivacyCollectedDataTypeLinked": true,
            "NSPrivacyCollectedDataTypeTracking": false,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
          },
          {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypePurchaseHistory",
            "NSPrivacyCollectedDataTypeLinked": true,
            "NSPrivacyCollectedDataTypeTracking": false,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]
          }
        ],
        "NSPrivacyTracking": false,
        "NSPrivacyTrackingDomains": []
      }
    }
  }
}
```

Source: Expo app.json docs (https://docs.expo.dev/versions/latest/config/app/) and legacy PrivacyInfo.xcprivacy at `_legacy-swift/SundeeFundee/Resources/PrivacyInfo.xcprivacy`.

### iOS Entitlements for Messaging

Since Expo SDK 51+, the APNs notification entitlement is NOT automatically added. Must explicitly declare:

```json
{
  "expo": {
    "ios": {
      "entitlements": {
        "aps-environment": "production"
      },
      "infoPlist": {
        "UIBackgroundModes": ["remote-notification"]
      }
    }
  }
}
```

Source: React Native Firebase messaging docs (https://rnfirebase.io/messaging/usage)

### EAS Submit Configuration

```json
{
  "submit": {
    "production": {
      "ios": {
        "ascAppId": "<user-provides-this>"
      },
      "android": {
        "track": "internal"
      }
    }
  }
}
```

Per user decision: no `serviceAccountKeyPath` for Android (first submission is manual AAB upload). iOS uses `ascAppId` only -- EAS manages credentials.

Source: EAS Submit docs (https://docs.expo.dev/submit/eas-json/)

### firebase.json Configuration

The existing `firebase.json` needs a `react-native` section for crashlytics and analytics config:

```json
{
  "react-native": {
    "crashlytics_auto_collection_enabled": true,
    "crashlytics_debug_enabled": false,
    "crashlytics_ndk_enabled": false,
    "analytics_auto_collection_enabled": true,
    "messaging_auto_init_enabled": true,
    "messaging_ios_auto_register_for_remote_messages": true
  }
}
```

Source: React Native Firebase docs (https://rnfirebase.io/crashlytics/usage)

### App Check: `__DEV__` Behavior in EAS Builds

Critical insight for App Check dual-mode:

| EAS Profile | Build Type | `__DEV__` | App Check Provider |
|-------------|-----------|-----------|-------------------|
| development | Debug (dev client) | `true` | debug (token-based) |
| preview | Release JS | `false` | production (DeviceCheck/Play Integrity) |
| production | Release JS | `false` | production (DeviceCheck/Play Integrity) |

The existing `src/firebase/appCheck.ts` already uses `__DEV__` to switch between debug and production providers. This is correct and needs no changes for the dual-mode requirement. EAS development builds compile JS in debug mode (`__DEV__=true`), while preview and production builds compile in release mode (`__DEV__=false`).

**No EAS env var switching needed for App Check mode** -- `__DEV__` already handles it correctly. The `FIREBASE_APP_CHECK_DEBUG_TOKEN` env var in the development profile provides the debug token.

However, the current code reads from `EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN` while eas.json uses `FIREBASE_APP_CHECK_DEBUG_TOKEN`. This mismatch should be reconciled.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Privacy manifest | Custom config plugin to write xcprivacy file | `expo.ios.privacyManifests` in app.json | Expo SDK 55 has built-in support; no plugin needed |
| Crashlytics Android setup | Manual Gradle plugin configuration | `@react-native-firebase/crashlytics` config plugin | Plugin handles `buildscript` and `apply plugin` automatically |
| EAS credential management | Manual provisioning profiles / signing certs | EAS managed credentials (default) | EAS handles certificate lifecycle, team selection |
| Static linking config | Manual Podfile modifications | `expo-build-properties` forceStaticLinking | Already established pattern in project |

## Common Pitfalls

### Pitfall 1: Missing forceStaticLinking entries
**What goes wrong:** Build fails with CocoaPods linking errors on iOS.
**Why it happens:** RNFB modules require static frameworks on iOS. Adding to plugins without adding to forceStaticLinking causes dynamic linking attempts.
**How to avoid:** Every new RNFB module plugin needs a corresponding entry in forceStaticLinking. The native module names follow pattern: `RNFB{ModuleName}` (e.g., RNFBMessaging, RNFBCrashlytics, RNFBAnalytics).
**Warning signs:** CocoaPods error during `pod install` in EAS build logs.

### Pitfall 2: Missing aps-environment entitlement
**What goes wrong:** iOS push notifications silently fail -- no FCM token generated.
**Why it happens:** Expo SDK 51+ removed automatic inclusion of the notifications entitlement.
**How to avoid:** Explicitly add `"aps-environment": "production"` to ios.entitlements in app.json.
**Warning signs:** `messaging().getToken()` returns null or throws on iOS.

### Pitfall 3: App Check debug token env var mismatch
**What goes wrong:** App Check fails in development builds despite having a debug token configured.
**Why it happens:** Current code reads `EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN` but eas.json sets `FIREBASE_APP_CHECK_DEBUG_TOKEN`. Only `EXPO_PUBLIC_*` vars are accessible in JS at runtime.
**How to avoid:** Rename the eas.json env var to `EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN` or update the code to read the correct var.
**Warning signs:** App Check initialization warning in console during development.

### Pitfall 4: Analytics plugin assumption
**What goes wrong:** Adding `@react-native-firebase/analytics` to plugins array causes build error.
**Why it happens:** Analytics does NOT have its own Expo config plugin (unlike crashlytics and messaging). It is a JS-only module that requires only the native module to be statically linked.
**How to avoid:** Do NOT add analytics to plugins array. Only add to forceStaticLinking. Import and use from JS.
**Warning signs:** Plugin not found error during prebuild.

### Pitfall 5: Simulator testing for App Check production mode
**What goes wrong:** Trying to verify DeviceCheck attestation on iOS simulator fails.
**Why it happens:** DeviceCheck and App Attest require physical Apple hardware. Simulators cannot generate device attestation tokens.
**How to avoid:** Physical iOS device registered in Apple Developer portal required. Development builds on simulator correctly use debug tokens via `__DEV__=true`.
**Warning signs:** App Check token request fails with "unsupported" error on simulator.

### Pitfall 6: First Android Play Store submission
**What goes wrong:** Attempting to use `eas submit` for first-ever Android submission fails.
**Why it happens:** Google Play requires the first AAB to be uploaded manually through the Play Console. EAS Submit can only update existing apps.
**How to avoid:** Per user decision, skip serviceAccountKeyPath for now. First submission is manual.
**Warning signs:** EAS Submit returns authentication or "app not found" error.

## Code Examples

### Module Initialization Pattern
```typescript
// src/firebase/messaging.ts
// Source: existing project pattern (src/firebase/appCheck.ts)
import { Platform } from 'react-native';

let registered = false;

export async function initMessaging(): Promise<void> {
  if (Platform.OS === 'web') return;
  if (registered) return;

  try {
    const messaging = require('@react-native-firebase/messaging').default;
    // Request permission handled by expo-notifications, not here
    // Just ensure the module initializes without error
    const token = await messaging().getToken();
    console.log('[Messaging] FCM token acquired:', token ? 'yes' : 'no');
    registered = true;
  } catch (err) {
    console.warn('[Messaging] Initialization failed:', err);
  }
}
```

### Crashlytics Initialization
```typescript
// src/firebase/crashlytics.ts
import { Platform } from 'react-native';

let initialized = false;

export function initCrashlytics(): void {
  if (Platform.OS === 'web') return;
  if (initialized) return;

  try {
    const crashlytics = require('@react-native-firebase/crashlytics').default;
    // Enable crash collection (respects firebase.json auto_collection setting)
    crashlytics().setCrashlyticsCollectionEnabled(true);
    console.log('[Crashlytics] Initialized');
    initialized = true;
  } catch (err) {
    console.warn('[Crashlytics] Initialization failed:', err);
  }
}
```

### Analytics Initialization
```typescript
// src/firebase/analytics.ts
import { Platform } from 'react-native';

let initialized = false;

export function initAnalytics(): void {
  if (Platform.OS === 'web') return;
  if (initialized) return;

  try {
    const analytics = require('@react-native-firebase/analytics').default;
    // Enable analytics collection
    analytics().setAnalyticsCollectionEnabled(true);
    console.log('[Analytics] Initialized');
    initialized = true;
  } catch (err) {
    console.warn('[Analytics] Initialization failed:', err);
  }
}
```

### Verification: Smoke Test Module Loading
```typescript
// Temporary verification - add to app root or a debug screen
async function verifyFirebaseModules(): Promise<void> {
  if (Platform.OS === 'web') return;

  const modules = [
    { name: 'messaging', path: '@react-native-firebase/messaging' },
    { name: 'crashlytics', path: '@react-native-firebase/crashlytics' },
    { name: 'analytics', path: '@react-native-firebase/analytics' },
  ];

  for (const mod of modules) {
    try {
      const m = require(mod.path).default;
      console.log(`[Firebase] ${mod.name}: loaded OK`);
    } catch (err) {
      console.error(`[Firebase] ${mod.name}: FAILED`, err);
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom config plugin for PrivacyInfo.xcprivacy | `expo.ios.privacyManifests` in app.json | Expo SDK 50.0.17+ (early 2024) | No custom plugin code needed |
| expo-firebase-analytics package | @react-native-firebase/analytics directly | Expo SDK 49+ | Unified RNFB approach, no Expo wrapper |
| Manual APNs certificate management | EAS managed credentials + auth keys | EAS default | Simpler, automatic renewal |
| SafetyNet (Android attestation) | Play Integrity | 2023 | SafetyNet deprecated; Play Integrity is successor |

## Open Questions

1. **ascAppId value**
   - What we know: User has an App Store Connect app created
   - What's unclear: The actual numeric App Store Connect app ID
   - Recommendation: User must provide this value; it's visible in App Store Connect under General > App Information

2. **iOS physical device registration**
   - What we know: Required for DeviceCheck verification; device not currently registered
   - What's unclear: Whether user has an iOS device available and its UDID
   - Recommendation: Register device in Apple Developer portal before building; `eas device:create` can help

3. **RNFB module naming for forceStaticLinking**
   - What we know: Pattern is `RNFB{ModuleName}` -- RNFBApp, RNFBAuth, etc.
   - What's unclear: Exact names for messaging/crashlytics/analytics (not in official docs)
   - Recommendation: HIGH confidence these are RNFBMessaging, RNFBCrashlytics, RNFBAnalytics based on consistent naming convention across all existing modules

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
| SEC-03 | App Check production attestation active | manual-only | N/A -- requires physical device + Firebase Console check | N/A |
| SEC-04 | PrivacyInfo.xcprivacy present with correct entries | smoke | Verify app.json privacyManifests structure via unit test | Wave 0 |
| STORE-01 | EAS production build profiles configured | smoke | Verify eas.json structure via unit test | Wave 0 |

### Sampling Rate
- **Per task commit:** `npx jest --passWithNoTests` (ensure no regressions)
- **Per wave merge:** `npx jest --passWithNoTests` (full suite)
- **Phase gate:** Full suite green + EAS dev build installs + physical device smoke test

### Wave 0 Gaps
- [ ] `__tests__/config/app-json.test.ts` -- validates app.json plugins array includes all RNFB modules, privacyManifests structure matches legacy plist
- [ ] `__tests__/config/eas-json.test.ts` -- validates eas.json has submit.production with ios.ascAppId and android.track

## Sources

### Primary (HIGH confidence)
- Expo app.json docs (https://docs.expo.dev/versions/latest/config/app/) -- privacyManifests schema
- Expo Apple Privacy guide (https://docs.expo.dev/guides/apple-privacy/) -- privacy manifest approach
- EAS Submit docs (https://docs.expo.dev/submit/eas-json/) -- submit configuration schema
- EAS JSON schema (https://docs.expo.dev/eas/json/) -- full build + submit schema
- React Native Firebase messaging docs (https://rnfirebase.io/messaging/usage) -- iOS entitlements, plugin config
- React Native Firebase crashlytics docs (https://rnfirebase.io/crashlytics/usage) -- firebase.json options, plugin config
- React Native Firebase App Check docs (https://rnfirebase.io/app-check/usage) -- provider configuration

### Secondary (MEDIUM confidence)
- Legacy PrivacyInfo.xcprivacy (`_legacy-swift/SundeeFundee/Resources/PrivacyInfo.xcprivacy`) -- reference for data type declarations
- Existing src/firebase/appCheck.ts -- established initialization pattern

### Tertiary (LOW confidence)
- RNFB static linking module names (RNFBMessaging, RNFBCrashlytics, RNFBAnalytics) -- inferred from naming convention, not explicitly documented

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already used in project or well-documented RNFB ecosystem
- Architecture: HIGH -- extending established patterns (app.json plugins, static linking, firebase init)
- Pitfalls: HIGH -- documented in official sources and verified against existing codebase
- Privacy manifest: HIGH -- Expo SDK 55 supports privacyManifests natively, legacy plist provides exact reference
- EAS submit: HIGH -- official docs clearly document schema

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (stable -- Expo SDK 55 and RNFB 23.x are current)

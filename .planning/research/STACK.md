# Stack Research

**Domain:** Cross-platform fitness app (iOS, Android, Web) — React Native + Expo + Firebase
**Researched:** 2026-03-14
**Confidence:** HIGH (core framework/runtime), MEDIUM (supporting libraries — versions verified via official docs and community sources)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Expo SDK | 55 (stable) | Universal app framework | SDK 55 ships with RN 0.83 + React 19.2; New Architecture is now mandatory (no legacy opt-out) — start clean, no tech debt. Managed workflow keeps native code in config plugins, avoiding bare workflow maintenance burden. |
| React Native | 0.83 | Cross-platform runtime | Bundled with Expo SDK 55. Hermes v1 now opt-in; New Architecture (Fabric + JSI) is the only supported mode in SDK 55+. |
| TypeScript | 5.x (bundled) | Type safety | Required for porting domain logic from Swift with confidence. Expo CLI scaffolds TypeScript by default. |
| Expo Router | 4.x (bundled with SDK 55) | File-based navigation | Ships inside Expo SDK — no separate install for the router. Handles iOS/Android/Web routing from a single `app/` directory. Typed routes, deep linking, and shared element transitions (Apple Zoom) all built in. |

### Backend

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| React Native Firebase (`@react-native-firebase/*`) | ~21.x (latest stable per npm) | Firestore, Auth, Cloud Functions, Storage | Firestore offline persistence works out of the box on iOS and Android with RNF — no manual enablement needed. The Firebase JS SDK v12 (the web SDK used as alternative) does NOT support native offline persistence in React Native because React Native lacks IndexedDB. RNF uses native SDKs, which have offline-first caching built in. Requires development build (not Expo Go), which is expected for this project. |
| Firebase Cloud Functions | Node.js 22 runtime | Gemini API proxy, WOD admin writes | Replaces Cloudflare Worker. Functions v2 (2nd gen) uses Cloud Run under the hood — concurrency, traffic splitting, minimum instances. Use callable functions for auth-gated Gemini calls. |
| Firebase Auth | via `@react-native-firebase/auth` | Apple, Google, Email/Password, Guest | Sign in with Apple + Google Sign-In are first-class in RNF Auth. Guest mode maps to anonymous auth with optional account linking later. |

**Critical Firebase note:** The Firebase JS SDK (firebase@^12) is viable for web-only or Expo Go prototyping but does NOT provide offline persistence in React Native. For this project's offline-first gym requirement, React Native Firebase (native SDK wrapper) is mandatory.

### Payments

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `react-native-purchases` | 9.x | iOS + Android subscriptions | RevenueCat v9.7.6+ added web support via RevenueCat Web Billing (Stripe-backed), meaning a single SDK now covers iOS, Android, and web. This eliminates the need for a separate Stripe direct integration for web if you use RevenueCat's web billing. However, the PROJECT.md calls for Stripe web checkout with lower pricing — see the note below. |
| `react-native-purchases-ui` | 9.x | Paywall UI components | Pre-built paywall sheets, customer center, and subscription management UI that handle App Store/Play Store flows correctly. |
| Stripe (via RevenueCat Web Billing) | N/A | Web checkout at lower tier pricing | RevenueCat Web Billing uses Stripe as the processor. Configure a separate web billing app in RevenueCat dashboard with different pricing than the app store products. This provides the dual pricing strategy (lower web price) within the same entitlements system — users stay in sync across platforms. |

**Payments note:** Do NOT implement a raw Stripe integration separately. RevenueCat Web Billing handles Stripe under the hood while keeping entitlements unified. A separate Stripe implementation means manually syncing subscription state across mobile + web — RevenueCat eliminates this.

### State Management

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Zustand | 5.x | Client/UI state | Replaces AppState (Swift) pattern. Handles auth routing state, UI state, user preferences. Zero boilerplate vs Redux. Slice pattern scales to this app's complexity (auth, cycle, workout, injury, settings stores). |
| TanStack Query (`@tanstack/react-query`) | 5.x | Server state (Firestore queries, AI calls) | Manages loading/error/caching for non-offline Firestore reads (WOD feed, program catalog), AI workout generation, and any REST calls. Pairs with Zustand — Zustand owns local app state, TanStack Query owns server state. |

**What NOT to use:** Redux Toolkit. Significantly more boilerplate than Zustand for the same outcome. The codebase already has a clear MVVM pattern — Zustand stores map directly to the existing ViewModel layer without the action/reducer ceremony.

### Styling

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| NativeWind | 4.x (stable) | Tailwind CSS for React Native + Web | Industry standard for cross-platform Tailwind styling in 2026. Works on iOS, Android, and Web from the same utility classes. Enables the Art Deco design tokens (cream/navy/orange) as CSS custom properties reusable across all platforms. |
| Gluestack UI v3 | 3.x | Accessible base components | Built on NativeWind — copy-paste component architecture, no runtime overhead. Provides accessible primitives (modals, sheets, alerts) that work cross-platform. Use as component foundation, customize with NativeWind classes for Art Deco aesthetic. |

**NativeWind v5 note:** v5 is in preview as of March 2026 (drops babel.config.js requirement for Tailwind v4). Do NOT use v5 yet — wait for stable release. Use NativeWind v4 with Tailwind CSS v3.

### Offline Storage (Local Key-Value)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `react-native-mmkv` | 3.x | Fast synchronous local storage | 30x faster than AsyncStorage. Synchronous API — no await/Promise, no bridge. Used for: Zustand store persistence, user settings, dismissed UI states, cached readiness survey, offline workout queue. |

**What NOT to use:** `@react-native-async-storage/async-storage` for performance-critical paths. AsyncStorage is async bridge calls — acceptable for infrequent preferences but wrong for workout-execution-loop state where synchronous reads matter.

### Health Integrations (iOS only at launch)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@kingstinct/react-native-healthkit` | latest | iOS HealthKit (readiness survey HRV, sleep) | TypeScript-first, actively maintained. Expo config plugin available. Scoped to iOS only — Android path defers to manual readiness survey (matches current iOS app behavior). |

**Android health note:** Google Health Connect (`react-native-health-connect`) requires Google Play approval (5-7 day whitelist propagation), declaration forms, and minimum SDK 26. The PROJECT.md correctly defers deep health integrations on Android — do not attempt Health Connect at launch.

### Testing

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `jest-expo` | bundled with SDK 55 | Jest preset for Expo | Official Expo Jest preset — handles module mocking, native module stubs, and environment setup automatically. |
| `@testing-library/react-native` | 12.x | Component testing | Simulate user interactions without implementation details. Pairs with jest-expo for integration tests. |
| `@testing-library/jest-native` | 5.x | DOM-like matchers | Adds `toBeVisible()`, `toHaveTextContent()` etc for readable assertions. |

**Domain layer testing:** The 21-file Domain layer ported to TypeScript can be tested with pure Jest — no React Native testing overhead needed for business logic (cycle adaptation, injury engine, etc.). Same isolation principle as the Swift tests.

---

## Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `expo-secure-store` | bundled | Encrypted key-value (keychain/keystore) | Auth tokens, user ID, sensitive prefs. Not for high-frequency read/write — use MMKV for that. |
| `react-native-reanimated` | 3.x (bundled) | Animations | Workout timers, progress rings, transition animations. Required peer dep for NativeWind v4. |
| `react-native-gesture-handler` | 2.x (bundled) | Swipe/gesture interactions | Swipe-to-delete in history, workout navigation gestures. |
| `expo-notifications` | bundled | Push notifications | Rest day reminders, WOD availability. Requires development build. |
| `expo-image` | bundled | Optimized image component | Exercise illustrations, program cover images. Handles caching, progressive loading. |
| `expo-font` | bundled | Custom font loading | Art Deco typography — load in root layout. |
| `expo-splash-screen` | bundled | Splash screen control | Hold splash until auth state + fonts resolved — prevents flash of unauthenticated state. |
| `expo-build-properties` | bundled | Native build configuration | Required for `forceStaticLinking` on iOS when using RNF with Expo SDK 54+. Set in app.json plugins. |
| `@react-native-google-signin/google-signin` | 14.x | Google Sign-In for Android | Required for Android auth path. iOS uses Sign in with Apple. Has Expo config plugin. |
| `date-fns` | 4.x | Date manipulation | Cycle phase calculations, workout scheduling, WOD date matching. Lightweight, tree-shakeable, no moment.js bloat. |
| `zod` | 3.x | Runtime schema validation | Validate Firestore document shapes on read, validate AI-generated workout payloads before use. Critical for safety given Gemini output variability. |

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| EAS Build | Cloud builds for dev/preview/production | Required for react-native-purchases, RNF, and any custom native module. Development builds replace Expo Go for this project. |
| EAS Submit | App Store / Play Store submission | Automates signing and upload. |
| EAS Update | OTA updates (JS bundle only) | Fast patches that bypass app store review. Cannot update native code. Hermes bytecode diffing in SDK 55 reduces update download size by ~75%. |
| Expo CLI | Local dev server, metro bundler | `npx expo start --dev-client` targets development build. |
| Firebase Emulator Suite | Local Firestore, Auth, Functions emulation | Run `firebase emulators:start` during development. Eliminates cloud costs during development and enables deterministic testing of Cloud Functions. |
| Flipper / Expo DevTools | Debugging | Expo DevTools plugins for network inspection. React Query DevTools plugin for cache inspection. SQLite Inspector if using local SQLite. |

---

## Installation

```bash
# Bootstrap Expo project (SDK 55, managed workflow)
npx create-expo-app@latest SundeeFundee --template blank-typescript
cd SundeeFundee

# React Native Firebase (all required modules)
npx expo install @react-native-firebase/app @react-native-firebase/auth @react-native-firebase/firestore @react-native-firebase/functions @react-native-firebase/storage

# Payments
npx expo install react-native-purchases react-native-purchases-ui

# State management
npm install zustand @tanstack/react-query

# Storage
npx expo install react-native-mmkv

# Styling
npm install nativewind tailwindcss
npx expo install react-native-reanimated react-native-safe-area-context
npm install @gluestack-ui/themed @gluestack-style/react

# Auth (Google Sign-In for Android)
npx expo install @react-native-google-signin/google-signin

# Utilities
npm install date-fns zod

# Testing
npx expo install jest-expo jest
npm install -D @testing-library/react-native @testing-library/jest-native

# Build properties plugin (required for RNF + Expo SDK 55)
npx expo install expo-build-properties
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| React Native Firebase (native SDK) | Firebase JS SDK v12 | Only if targeting web-only or Expo Go prototyping. Not suitable for offline-first mobile with Firestore persistence. |
| Zustand | Redux Toolkit | If team already has Redux expertise and the codebase will exceed 10+ developers. Zustand's simplicity wins for this team size. |
| Zustand | Jotai | Jotai is atom-based — better for granular re-renders in very large UIs. Zustand's slice pattern is sufficient and more familiar to the Swift MVVM pattern being ported. |
| NativeWind v4 | StyleSheet API | If avoiding a build step or targeting an extremely simple UI. NativeWind's cross-platform consistency justifies the setup cost for this project. |
| MMKV | AsyncStorage | For infrequent, non-performance-critical storage (e.g., GDPR consent flag stored once). AsyncStorage is acceptable for single writes at startup; unacceptable in hot paths. |
| RevenueCat Web Billing (Stripe) | Stripe SDK directly | Only if requiring payment methods RevenueCat doesn't support (e.g., bank transfers, invoicing). RevenueCat's unified entitlements are worth the 1% fee for this use case. |
| Expo Router (file-based) | React Navigation | React Navigation is more configurable but requires explicit route registration. Expo Router's file-based approach maps 1:1 to the iOS app's tab structure with less boilerplate. |
| EAS Build | Local Xcode/Android Studio builds | Local builds are fine for solo development. EAS is required for CI/CD and team collaboration. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Firebase JS SDK for Firestore in React Native | No offline persistence support in RN (requires IndexedDB, which RN lacks). `enableIndexedDbPersistence()` silently fails or throws in RN environments. | React Native Firebase (`@react-native-firebase/firestore`) — native SDK, offline-first by default. |
| Expo Go for development | react-native-purchases, React Native Firebase, MMKV, and HealthKit all require native code not compiled into Expo Go. Debugging in Expo Go gives false positives for subscription and offline behavior. | EAS development build (`npx expo run:ios` or `eas build --profile development`). |
| `@react-native-async-storage/async-storage` for hot paths | Asynchronous bridge calls introduce latency in workout execution loops (timer ticks, set logging). Inconsistent behavior under memory pressure. | `react-native-mmkv` for synchronous, high-frequency reads/writes. |
| Moment.js | 232 kB bundle, no tree-shaking, officially deprecated. | `date-fns` v4 — fully tree-shakeable, TypeScript-native. |
| React Native Paper | Material Design opinionated — conflicts with Art Deco aesthetic. Significant restyling effort to diverge from MD baseline. | Gluestack UI v3 (unstyled primitives) + NativeWind for full design control. |
| Redux Toolkit | Excessive boilerplate (actions, reducers, selectors, slices) for state that Zustand handles in 10 lines. 40% bundle size increase vs Zustand per benchmarks. | Zustand v5 with slice pattern. |
| NativeWind v5 (preview) | Not yet stable as of March 2026. API surface for Tailwind v4 compatibility is still changing. Breaking changes expected before stable release. | NativeWind v4 (stable) + Tailwind CSS v3. Migrate to v5 after stable release. |
| Google Health Connect at launch | Requires Google Play whitelist approval (5-7 day delay post-submission), declaration form, min SDK 26. No equivalent to HealthKit's readiness data on Android. | Manual readiness survey on Android (matches existing iOS fallback path). |
| expo-firestore-offline-persistence (npm) | This is a community polyfill for Expo managed workflow + Firebase JS SDK. It's fragile, unmaintained, and a workaround for the wrong Firebase SDK choice. | React Native Firebase solves offline persistence correctly at the native layer. |

---

## Stack Patterns by Variant

**For offline workout execution (core requirement):**
- React Native Firebase Firestore with offline persistence (enabled by default)
- MMKV for synchronous timer state and current-set state during active workout
- Do not await Firestore writes during a set — write optimistically, sync in background

**For web platform (Expo Router web output):**
- Firebase JS SDK can be used alongside RNF for web routes only (platform-split files)
- RevenueCat Web Billing for subscription management on web
- NativeWind renders Tailwind CSS natively — same classes work on web without changes

**For AI workout generation:**
- Firebase Cloud Functions v2 callable function (replaces Cloudflare Worker)
- Validate Gemini response with Zod schema before storing
- Implement offline fallback: if function call fails, use cached recent workout structure

**For domain logic (TypeScript port):**
- Pure TypeScript modules in `src/domain/` — zero React Native dependencies
- Test with plain Jest (`jest.config.js` separate from `jest-expo` preset)
- Same isolation principle as the Swift Domain/ layer — no framework coupling

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Expo SDK 55 | React Native 0.83 | New Architecture mandatory. Legacy Architecture removed. |
| Expo SDK 55 | Node.js ^20.19.4, ^22.13.0, ^24.3.0 | Node.js 18 is NOT supported. |
| Expo SDK 55 | Xcode 26+ | Xcode 25 will not build SDK 55 projects. |
| NativeWind v4 | Tailwind CSS v3 | NativeWind v4 is NOT compatible with Tailwind CSS v4 (use NativeWind v5 preview for that, but that's unstable). |
| NativeWind v4 | react-native-reanimated 3.x | Required peer dependency. |
| React Native Firebase | Expo SDK 55 | Requires `expo-build-properties` plugin with `forceStaticLinking: true` in iOS config. Known issue — documented fix in RNF issue #8657. |
| react-native-purchases 9.x | Expo SDK 55 | Requires development build. Works in Expo Go only in "Preview API Mode" (mocked). |
| firebase@^12 (JS SDK) | Expo SDK 53+ | If used for web routes only. Do not use for iOS/Android Firestore. |
| @react-native-firebase/firestore | @react-native-firebase/app (same version) | All RNF packages must be the same version. Install with `npx expo install` to get compatible versions. |

---

## Sources

- [Expo SDK 55 Changelog](https://expo.dev/changelog/sdk-55) — SDK version, RN 0.83, New Architecture status, breaking changes (HIGH confidence)
- [Expo SDK 54 Changelog](https://expo.dev/changelog/sdk-54) — SDK 54 context, RN 0.81, legacy architecture sunset timeline (HIGH confidence)
- [Expo — Using Firebase Guide](https://docs.expo.dev/guides/using-firebase/) — Official Firebase JS SDK vs RNF guidance (HIGH confidence)
- [React Native Firebase — rnfirebase.io](https://rnfirebase.io/) — Offline support, Expo compatibility, v22 migration (HIGH confidence)
- [RevenueCat — Expo Installation](https://www.revenuecat.com/docs/getting-started/installation/expo) — RevenueCat Expo setup, development build requirement (HIGH confidence)
- [RevenueCat — Web Support announcement](https://www.revenuecat.com/blog/engineering/revenuecat-react-native-sdk-adds-react-native-web-support/) — Web Billing via Stripe in react-native-purchases 9.7.6+ (HIGH confidence)
- [Galaxies.dev — React Native Tech Stack 2025](https://galaxies.dev/article/react-native-tech-stack-2025) — Community consensus on Zustand + TanStack Query (MEDIUM confidence)
- [Firebase — Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — Offline persistence platform support (HIGH confidence)
- [RNF Issue #8657](https://github.com/invertase/react-native-firebase/issues/8657) — Expo SDK 54/55 build fix with forceStaticLinking (MEDIUM confidence)
- [NativeWind Installation](https://www.nativewind.dev/docs/getting-started/installation) — NativeWind v4 setup, v5 preview status (HIGH confidence)
- [react-native-mmkv GitHub](https://github.com/mrousavy/react-native-mmkv) — Performance benchmarks vs AsyncStorage (HIGH confidence)
- [Expo — In-App Purchases Guide](https://docs.expo.dev/guides/in-app-purchases/) — Official Expo stance on payments (HIGH confidence)
- [Firebase JS SDK Issue #7947](https://github.com/firebase/firebase-js-sdk/issues/7947) — Confirms Firestore persistence is not supported in Firebase JS SDK for React Native (HIGH confidence)

---
*Stack research for: Sundee Fundee React Native + Expo + Firebase rewrite*
*Researched: 2026-03-14*

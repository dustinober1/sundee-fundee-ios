---
phase: 01-foundation-and-infrastructure
plan: 03
subsystem: auth
tags: [auth, firebase, expo-router, react-native, ui, platform-aware, web, ios, android, typescript]

# Dependency graph
requires:
  - 01-02 (SessionProvider, useSession, four auth hooks: useAppleSignIn, useGoogleSignIn, useEmailAuth, useGuestSignIn)
provides:
  - sign-in screen with platform-adaptive provider buttons (Apple on iOS, Google on Android/Web)
  - verify-email screen with resend capability and back-to-sign-in
  - AuthButton reusable component with inline spinner + error states
  - OfflineBanner component using expo-network
  - Protected route guard in app/(app)/_layout.tsx using Redirect pattern
  - Tab shell (Dashboard + Settings) with Art Deco styling
  - Settings screen with sign-out confirmation dialog (window.confirm on web, Alert.alert on native)
  - Platform-aware Firebase wrappers unified for web and native (src/firebase/auth.ts + auth.web.ts)
affects:
  - all subsequent phases (tab shell is the root UI surface for every feature)
  - Phase 3 (protected route guard enforces auth before data access)
  - Phase 6 (settings screen is where subscription management will appear)

# Tech tracking
tech-stack:
  added:
    - react-dom (Expo web support)
    - react-native-web (Expo web support)
    - expo-network (OfflineBanner connectivity detection)
    - eas project config (EAS project ID added to app.json)
  patterns:
    - Platform-aware auth wrappers: src/firebase/auth.ts (native) and auth.web.ts (web) — Metro resolver selects at bundle time
    - Redirect pattern for protected routes (app/(app)/_layout.tsx) — compatible with Expo Router without Stack.Protected
    - Inline auth errors: error displayed below failed button, not in modal
    - All-buttons-disabled during any in-progress auth operation (managed via isAnyLoading flag)
    - window.confirm fallback for web (Alert.alert is a no-op on web)
    - Explicit auth redirect on sign-in screen: useEffect on user watches for authenticated state and pushes to tabs

key-files:
  created:
    - SundeeFundeeRN/src/components/AuthButton.tsx
    - SundeeFundeeRN/src/components/OfflineBanner.tsx
    - SundeeFundeeRN/src/components/__tests__/AuthButton.test.tsx
    - SundeeFundeeRN/app/sign-in.tsx
    - SundeeFundeeRN/app/verify-email.tsx
    - SundeeFundeeRN/app/(app)/_layout.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/_layout.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/index.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/settings.tsx
    - SundeeFundeeRN/src/firebase/auth.web.ts
  modified:
    - SundeeFundeeRN/src/firebase/auth.ts (renamed from auth.native.ts; refactored all auth imports to use platform wrappers)
    - SundeeFundeeRN/src/auth/AuthContext.tsx (updated to import from platform wrappers + sendEmailVerification/linkWithCredential added)
    - SundeeFundeeRN/src/auth/useAppleSignIn.ts (updated import to platform wrapper)
    - SundeeFundeeRN/src/auth/useGoogleSignIn.ts (updated import to platform wrapper)
    - SundeeFundeeRN/src/auth/useEmailAuth.ts (updated import to platform wrapper)
    - SundeeFundeeRN/src/auth/useGuestSignIn.ts (updated import to platform wrapper)
    - SundeeFundeeRN/app.json (EAS project ID added)
    - SundeeFundeeRN/package.json (react-dom, react-native-web added)

key-decisions:
  - "auth.native.ts renamed to auth.ts — TypeScript module resolution requires the base file to exist for the .web.ts extension override to work correctly"
  - "sign-in.tsx uses explicit useEffect(user => router.replace('/(app)/(tabs)')) — onAuthStateChanged in SessionProvider does not trigger Expo Router navigation automatically"
  - "Alert.alert is a no-op on web — added window.confirm fallback in settings.tsx sign-out confirmation"
  - "sendEmailVerification and linkWithCredential added to platform wrappers — required by verify-email screen and guest upgrade flow"
  - "All auth hooks refactored to import from src/firebase/auth.ts platform wrapper — prevents @react-native-firebase/auth from bundling on web"

patterns-established:
  - "Platform wrapper pattern: src/firebase/auth.ts (native) + auth.web.ts (web) — all auth code imports from src/firebase/auth.ts, Metro resolves to correct platform at build time"
  - "Inline error pattern: AuthButton accepts error prop, renders below button as small text — never modal"
  - "All-disabled-during-auth: isAnyLoading = anyHook.isLoading; all AuthButton disabled={isAnyLoading}"
  - "Redirect guard pattern: app/(app)/_layout.tsx checks user/emailVerified, returns <Redirect> before rendering <Stack>"

requirements-completed: [AUTH-05, AUTH-06, PLAT-01, PLAT-02, PLAT-03]

# Metrics
duration: ~60min (including verification fixes)
completed: 2026-03-14
---

# Phase 1 Plan 03: Foundation and Infrastructure Summary

**Auth UI complete: platform-adaptive sign-in screen (Apple on iOS, Google on web/Android), protected route guard, two-tab shell (Dashboard + Settings), sign-out with confirmation, and cross-platform Firebase wrappers enabling web support**

## Performance

- **Duration:** ~60 min (including multiple fix rounds during cross-platform verification)
- **Started:** 2026-03-14
- **Completed:** 2026-03-14
- **Tasks:** 3 of 3
- **Files modified:** ~18

## Accomplishments

- Built complete auth UI: sign-in screen with platform-adaptive buttons (Apple on iOS, Google on Android/Web), email toggle, guest link, inline errors, all-disabled-during-auth, and offline banner
- Built protected route guard (redirect pattern) and two-tab shell (Dashboard + Settings) with Art Deco cream/navy/orange styling
- Settings screen with sign-out confirmation dialog (native Alert.alert + web window.confirm fallback) that clears session and returns to auth screen
- Refactored all auth code to use platform-aware Firebase wrappers (src/firebase/auth.ts + auth.web.ts) enabling Expo web build without bundling React Native Firebase on web

## Task Commits

1. **Task 1: Build AuthButton, OfflineBanner, sign-in, verify-email** - `e4d2e1f` (feat)
2. **Task 2: Build protected route guard, tab shell, and settings** - `59d5472` (feat)
3. **Task 3: Verify complete auth flow on all platforms (fixes)** - `e4d979a`, `196b4b4`, `9eb1580` (fix/chore)

**Plan metadata:** *(final docs commit)*

## Files Created/Modified

- `SundeeFundeeRN/src/components/AuthButton.tsx` - Reusable full-width button: spinner, inline error, disabled state, variant (primary/secondary/text)
- `SundeeFundeeRN/src/components/OfflineBanner.tsx` - expo-network connectivity banner, renders null when online
- `SundeeFundeeRN/src/components/__tests__/AuthButton.test.tsx` - Unit tests: render, spinner, error, onPress, disabled
- `SundeeFundeeRN/app/sign-in.tsx` - Auth screen with platform switch (Apple iOS / Google web+Android), email fields, guest link, explicit auth redirect
- `SundeeFundeeRN/app/verify-email.tsx` - Email verification waiting screen with resend + back-to-sign-in
- `SundeeFundeeRN/app/(app)/_layout.tsx` - Protected route guard: redirects unauthenticated to /sign-in, unverified non-anonymous to /verify-email
- `SundeeFundeeRN/app/(app)/(tabs)/_layout.tsx` - Tab layout: Dashboard + Settings, NAVY bar, ORANGE active tint, CREAM inactive
- `SundeeFundeeRN/app/(app)/(tabs)/index.tsx` - Dashboard placeholder with welcome, user email/name, guest upgrade nudge
- `SundeeFundeeRN/app/(app)/(tabs)/settings.tsx` - Settings: user info, Create Account (guest only), Sign Out with confirmation
- `SundeeFundeeRN/src/firebase/auth.ts` - Native platform auth wrapper (renamed from auth.native.ts)
- `SundeeFundeeRN/src/firebase/auth.web.ts` - Web platform auth wrapper (Firebase JS SDK compat)

## Decisions Made

- **auth.native.ts renamed to auth.ts:** TypeScript requires the base file (auth.ts) to exist for the .web.ts extension override to function correctly with Metro resolver. The native-specific file becomes the default fallback.

- **Explicit redirect in sign-in.tsx:** onAuthStateChanged in SessionProvider updates React context state but does not trigger Expo Router navigation. Added a useEffect watching the `user` value from `useSession()` to call `router.replace('/(app)/(tabs)')` on authentication.

- **window.confirm fallback for web sign-out:** `Alert.alert()` is a no-op in React Native Web — the confirmation dialog never appeared. Added a Platform-aware branch: native uses Alert.alert, web uses window.confirm.

- **Platform wrappers extended with sendEmailVerification and linkWithCredential:** verify-email.tsx needed sendEmailVerification; the guest upgrade flow needed linkWithCredential. Both added to both platform wrapper files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] All auth hooks imported directly from @react-native-firebase/auth instead of platform wrappers**
- **Found during:** Task 3 (cross-platform verification — web build failed)
- **Issue:** AuthContext.tsx, useAppleSignIn.ts, useGoogleSignIn.ts, useEmailAuth.ts, useGuestSignIn.ts all imported `auth` from `@react-native-firebase/auth` directly. On web, Metro cannot resolve this native module, causing build failure.
- **Fix:** Refactored all imports to use `src/firebase/auth.ts` platform wrapper. Renamed `auth.native.ts` to `auth.ts` for correct TypeScript module resolution.
- **Files modified:** All five auth hooks + AuthContext.tsx + src/firebase/auth.ts (renamed)
- **Verification:** Web build succeeded after refactor
- **Committed in:** `196b4b4`

**2. [Rule 2 - Missing Critical] sendEmailVerification and linkWithCredential missing from platform wrappers**
- **Found during:** Task 3 (verify-email screen and guest upgrade path could not call these functions)
- **Issue:** Platform wrapper exports did not include sendEmailVerification or linkWithCredential — required for email verification UX and guest-to-authenticated upgrade
- **Fix:** Added both to src/firebase/auth.ts (native) and auth.web.ts (web)
- **Files modified:** `SundeeFundeeRN/src/firebase/auth.ts`, `SundeeFundeeRN/src/firebase/auth.web.ts`
- **Committed in:** `196b4b4`

**3. [Rule 1 - Bug] sign-in.tsx had no auth redirect after successful sign-in**
- **Found during:** Task 3 (signing in as guest showed no navigation to dashboard)
- **Issue:** Plan comment said "onAuthStateChanged will trigger navigation automatically" — this is incorrect for Expo Router. Context state changes don't auto-navigate.
- **Fix:** Added `useEffect(() => { if (user) router.replace('/(app)/(tabs)'); }, [user])` to sign-in.tsx
- **Files modified:** `SundeeFundeeRN/app/sign-in.tsx`
- **Committed in:** `e4d979a`

**4. [Rule 1 - Bug] Alert.alert is a no-op on web — sign-out confirmation never appeared**
- **Found during:** Task 3 (web verification — tapping Sign Out immediately signed out with no dialog)
- **Issue:** `Alert.alert()` has no implementation in React Native Web; the buttons are never shown and no callback fires.
- **Fix:** Added Platform.OS check: web uses `window.confirm('Are you sure you want to sign out?')` as fallback
- **Files modified:** `SundeeFundeeRN/app/(app)/(tabs)/settings.tsx`
- **Committed in:** `e4d979a`

**5. [Rule 3 - Blocking] Missing react-dom and react-native-web for Expo web support**
- **Found during:** Task 3 (web build startup — Metro reported missing peer dependencies)
- **Issue:** Expo web requires react-dom and react-native-web as peer dependencies; neither was installed
- **Fix:** Installed both packages
- **Files modified:** `SundeeFundeeRN/package.json`
- **Committed in:** `9eb1580`

**6. [Rule 3 - Blocking] Missing EAS project config for web build**
- **Found during:** Task 3 (EAS attempted to use app.json without projectId)
- **Issue:** app.json lacked `expo.extra.eas.projectId` field required for EAS builds
- **Fix:** Added EAS project ID to app.json
- **Files modified:** `SundeeFundeeRN/app.json`
- **Committed in:** `9eb1580`

---

**Total deviations:** 6 auto-fixed (4 Rule 1 bugs, 1 Rule 2 missing critical, 1 Rule 3 blocking)
**Impact on plan:** All fixes were discovered during cross-platform verification (Task 3). The core UI was implemented correctly; the deviations were all cross-platform compatibility issues that surfaced when running on web for the first time. No scope creep.

## Issues Encountered

- The plan comment in sign-in.tsx that "onAuthStateChanged will trigger navigation automatically" was incorrect for Expo Router — navigation must be triggered explicitly via router.replace(). This is a fundamental Expo Router behavior difference from React Navigation.
- Platform.OS branching for Alert vs window.confirm is a recurring pattern that will be needed in future phases whenever confirmation dialogs are used on web.

## User Setup Required

None - no external service configuration required beyond what was set up in Plans 01 and 02.

## Next Phase Readiness

- Phase 1 is complete: auth layer (Plan 02) + auth UI (Plan 03) + infrastructure (Plan 01)
- Phase 2 (Domain Layer Port) can begin — it has no dependency on UI, only on the Jest infrastructure from Plan 01
- The tab shell has two placeholder tabs; all subsequent feature phases will add tabs here
- Platform-aware Firebase wrapper pattern is established — all future Firebase calls should import from src/firebase/ wrappers, not directly from SDK packages

---
*Phase: 01-foundation-and-infrastructure*
*Completed: 2026-03-14*

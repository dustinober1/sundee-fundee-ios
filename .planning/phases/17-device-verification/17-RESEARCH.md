# Phase 17: Device Verification - Research

**Researched:** 2026-03-16
**Domain:** React Native / Expo end-to-end verification, iOS simulator automation, offline testing, cross-platform auth
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Triage Process**
- Group items by risk level: blockers (breaks core flow) → degraded (works but ugly/noisy) → cosmetic (polish)
- Fix blockers first, then sweep degraded, then cosmetic
- Claude automates testing via iOS simulator MCP tools first, then hands off a short list of items that truly need human eyes/hands
- Fix bugs immediately as found (not batched after full sweep)
- Physical-device-only items (haptics, real push notifications) explicitly deferred to Phase 18 when EAS dev build is available

**Testing Targets**
- Primary iOS target: iPhone 16 Pro simulator
- Android: basic smoke test on emulator — confirm app launches, navigates, and completes a workout (not a full item-by-item sweep)
- Web: quick smoke test (`expo start --web`) — confirm app loads and navigates without crashes (no deep verification)

**Fix vs Document Threshold**
- Bar: everything polished — all visual items (charts, toasts, animations) must look correct on simulator
- Only truly impossible items (physical device haptics, real push delivery) get deferred
- Firebase-dependent tests use Firebase Emulator (no risk of corrupting real data)
- Items that look correct on simulator marked as "verified on simulator" with a note that physical device confirmation happens in Phase 18
- Live Firebase validation deferred to Phase 18 EAS build

**Offline Verification**
- Use simulator's network link conditioner to disable/enable network
- Key scenario: go offline → start workout → log sets → finish → go online → verify workout appears in history with correct data (covers VERIFY-03)
- Include app kill resilience: after completing workout offline, force-kill app, relaunch still offline, verify workout data persists, then go online and verify sync
- Scripted steps (not exploratory)

### Claude's Discretion
- Exact ordering of items within each risk tier
- Which simulator MCP tools to use for each verification item
- How to structure the triage checklist output
- Test data setup for offline scenarios

### Deferred Ideas (OUT OF SCOPE)
- Physical device verification (haptics, real push notifications, App Check) — Phase 18
- Firestore security rules production deploy — Phase 22
- Nyquist validation gap closure — separate effort, not Phase 17 scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VERIFY-01 | All ~30 human verification items from v1.0 triaged and resolved | Full catalog of 30 items below; triage strategy documented in Architecture Patterns |
| VERIFY-02 | Core workout flow verified on iOS simulator and Android emulator | Simulator automation patterns, workout flow test script documented |
| VERIFY-03 | Offline mode verified (airplane mode workout completion + sync on reconnect) | Network link conditioner approach, offline + kill + relaunch + reconnect scripted steps |
| VERIFY-04 | Auth flows verified on all platforms (Apple, Google, Email, Guest, guest-to-auth upgrade) | Auth test matrix covering all 5 paths across iOS/Android/Web |
</phase_requirements>

---

## Summary

Phase 17 is a verification-only phase — no new features. The task is to systematically triage all ~30 human verification items accumulated across 16 v1.0 phases, execute them against iOS simulator (primary), Android emulator (smoke test), and web (smoke test), fix any blockers found, and produce a triage report. Physical-device-only behaviors (haptics, real push delivery, App Check tokens) are explicitly deferred to Phase 18.

The ~30 items span every v1.0 phase and cluster into five risk areas: auth/onboarding flows, core workout UI/behavior, offline sync, subscription/payment flows (mostly deferred — requires live RC/Stripe), and visual rendering (charts, toasts, animations). Most items are visual or behavioral — they can be verified via iOS simulator screenshots and interaction scripting. A subset requires live Firebase connection (Firestore sync, pain log persistence, WOD display) and should use the Firebase Emulator to avoid corrupting real data.

The critical path is: (1) boot app on simulator with test data, (2) triage all 30 items by risk tier, (3) fix blockers immediately, (4) verify degraded items, (5) confirm visual/cosmetic items via screenshot, (6) run Android smoke test, (7) run web smoke test, (8) execute offline scenario, (9) produce triage report.

**Primary recommendation:** Use the iOS 16 Pro simulator as the primary verification target. Run the Firebase Emulator for all Firestore-dependent tests. Execute the offline scenario via Network Link Conditioner in iOS Simulator. Defer physical-device-only items to Phase 18 with written rationale.

---

## Complete Catalog of Human Verification Items

The following 30 items are sourced directly from VERIFICATION.md files across all 16 v1.0 phases. This is the authoritative list for VERIFY-01.

### Phase 1: Foundation and Infrastructure (4 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P1-1 | Sign in as Guest on web (`npx expo start --web`) | Auth screen loads, Google button visible (not Apple), "Continue as Guest" works, lands on Dashboard showing "Guest User", Settings shows sign-out confirmation, sign-out returns to auth screen | Blocker | Web smoke test |
| P1-2 | Session persistence across app restart | After signing in, close and reopen app → lands directly on Dashboard without re-auth | Blocker | iOS Simulator |
| P1-3 | Firestore user document sync (AUTH-07) | Sign in with email/Apple/Google → user doc appears at `/users/{uid}` with email, displayName, timestamps | Degraded | Firebase Emulator |
| P1-4 | Platform button differentiation (Apple on iOS, Google on Android/Web) | iOS shows Apple button only; Android/Web shows Google button only | Degraded | iOS Sim + Android Emulator |

### Phase 3: Data Layer and Offline Architecture (5 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P3-1 | Complete 5-step onboarding as female user | 5 steps shown (name, experience, goal, gender, cycle), Art Deco styling, progress bar advances, Back button works steps 2-5, cycle toggle works, Complete lands on Dashboard | Blocker | iOS Simulator |
| P3-2 | Complete onboarding as male user | 4 steps shown (cycle step skipped), Next becomes "Complete" on step-gender for Male, lands on Dashboard without step-cycle | Blocker | iOS Simulator |
| P3-3 | Restart app after completing onboarding | Lands directly on Dashboard tab, onboarding never shown again, no routing flicker | Blocker | iOS Simulator |
| P3-4 | Guest onboarding persistence | Guest completes onboarding, kills app, reopens — skips onboarding (reads from `@sundee/onboarding_profile` key) | Blocker | iOS Simulator |
| P3-5 | Web Firestore offline writes | Go browser tab offline → trigger profile save → go online → writes flush from IndexedDB to Firestore | Degraded | Web build + DevTools network throttle |

### Phase 4: Core Workout Loop (5 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P4-1 | Complete workout flow end-to-end | Start Workout → add exercise → log sets with ghost text → complete set → rest timer appears → skip rest → finish → workout in History as "Custom" | Blocker | iOS Simulator |
| P4-2 | Rest timer background/screen-lock persistence | Start rest timer, lock simulator screen, return — timer shows correct remaining time, notification fires at 0 | Degraded | iOS Simulator (no real notif on sim) |
| P4-3 | ForTime/AMRAP/EMOM timed workout modes | Countdown plays, timers work, AMRAP red urgency at <30s, EMOM per-minute notifications | Degraded | iOS Simulator (audio/notif limited) |
| P4-4 | PR detection toast and haptic feedback | Log higher weight → orange PR toast at top, PR badge on set row, haptic fires | Degraded | iOS Simulator (visual only; haptic deferred to P18) |
| P4-5 | Exercise detail 1RM line chart renders | Navigate to Maxes tab → tap exercise → line chart renders (orange line, cream background) + 5-row rep-range PR table | Degraded | iOS Simulator |

### Phase 5: Differentiating Features (5 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P5-1 | End-to-end AI workout generation (live Gemini API) | Workout generated within 60s, incorporates cycle phase and injuries, preview shows exercises | Degraded | Requires live Gemini API key (Firebase Emulator can't simulate Cloud Functions with real API keys) |
| P5-2 | Cycle tab conditional visibility | cycleOptIn=true user sees Cycle tab; cycleOptIn=false user does not | Degraded | iOS Simulator |
| P5-3 | Offline AI workout fallback badge | Airplane mode → AI Workout → Generate → "offline" badge shows with generateOfflineWorkout() result, no crash | Blocker | iOS Simulator (Network Link Conditioner) |
| P5-4 | Pain trend chart renders with multiple pain logs | Log 3+ pain readings → LineChart shows pain progression with trend direction text | Degraded | iOS Simulator + Firebase Emulator |
| P5-5 | WOD card displays today's WOD from Firestore | Dashboard shows today's WOD name and description | Degraded | Firebase Emulator (seed WOD doc for today) |

### Phase 6: Subscriptions and Monetization (5 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P6-1 | RevenueCat paywall purchase flow (iOS/Android) | PaywallModal appears, tapping CTA triggers native purchase sheet, feature unlocks | Deferred to P18 | Requires physical device + App Store Sandbox |
| P6-2 | Stripe web checkout flow | Clicking Subscribe opens Stripe Checkout, after test payment Firestore premiumEntitlement becomes true | Deferred to P18 | Requires deployed Cloud Functions + live Stripe keys |
| P6-3 | Cross-platform entitlement sync | Subscribe on web via Stripe → iOS app shows premium status | Deferred to P18 | Requires both services live |
| P6-4 | Trial banner appearance (days 6-7) | Orange banner shows "Your trial ends in X day(s)" in final 2 days | Deferred to P18 | Requires live RevenueCat trial subscription |
| P6-5 | Trial ended modal (one-time) | Modal on first launch after trial expiry with Subscribe + Continue CTAs | Deferred to P18 | Requires live expired RevenueCat trial |

### Phase 7: Polish and Pre-Launch (4 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P7-1 | Weight unit live update (lbs → kg) | Toggle in Settings → all weights on Maxes tab and workout session update to kg immediately | Degraded | iOS Simulator |
| P7-2 | Delete account end-to-end flow | Type DELETE → spinner → Cloud Function executes → AsyncStorage cleared → goodbye screen → Done to sign-in | Degraded | Firebase Emulator + iOS Simulator |
| P7-3 | Export data — mobile share sheet | Settings → Export Data → CSV → native iOS share sheet appears with .zip attachment | Cosmetic | iOS Simulator |
| P7-4 | App Check on physical device | No Firebase permission errors in console at startup | Deferred to P18 | Physical device only |

### Phase 8: Fix Cycle Adaptation Wiring (3 items — not in explicit `human_verification` yaml but mentioned in body)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P8-1 | Cycle banner display for opted-in user with period logs | CyclePhaseBanner shows current cycle phase (e.g., "Luteal — Day 22") on Dashboard | Degraded | iOS Simulator + Firebase Emulator |
| P8-2 | Adaptation indicator visible in workout for opted-in user | Adaptation banner shows load adjustment (e.g., "+12% — Ovulation phase") in workout session | Degraded | iOS Simulator + Firebase Emulator |
| P8-3 | Opted-out user sees no cycle UI | No CyclePhaseBanner on Dashboard, no adaptation banner in workout | Degraded | iOS Simulator |

### Phase 9: Guest Migration (1 item)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P9-1 | Pending migration retry on real device | Sign in as guest → generate data → upgrade → force-kill mid-migration → relaunch → all data in Firestore | Degraded | iOS Simulator (can kill app; Firestore Emulator for data verification) |

### Phase 10: UI Polish Fixes (3 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P10-1 | Goodbye screen — no system back button visible | After delete account, goodbye screen has no back arrow/header | Cosmetic | iOS Simulator |
| P10-2 | Web CSV export — single download dialog | Settings → Export CSV → exactly one .zip browser download (not 7 separate .csv files) | Cosmetic | Web build |
| P10-3 | Weight unit toggling on workout-detail | Set kg in Settings → open completed workout from History → all weights in kg including Volume MetaStat | Degraded | iOS Simulator |

### Phase 12: Fix Firestore Pain Log Rules (3 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P12-1 | Pain log persists after app restart | Log pain level → force-quit app → reopen → navigate to injury → entry still visible | Blocker | Firebase Emulator + iOS Simulator |
| P12-2 | Pain trend chart renders with real Firestore data | Log 3+ pain entries → PainTrendChart shows trend line (not empty state) | Degraded | Firebase Emulator + iOS Simulator |
| P12-3 | Firebase rules deployed to production | `firebase deploy --only firestore:rules` succeeds | Deferred to P22 | Per CONTEXT.md: explicitly deferred |

### Phase 15: AI Preview Adaptation Context (2 items)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P15-1 | AdaptationChip visual appearance on preview screen | Orange pill shows "Adapting for: Luteal phase · Left Shoulder · Readiness 7/10" | Cosmetic | iOS Simulator |
| P15-2 | AdaptationChip hidden when no adaptation data exists | No chip appears for user with no cycle tracking, no injuries, no readiness survey | Cosmetic | iOS Simulator |

### Phase 16: Weight Unit in Program Session (1 item)

| ID | Test | Expected | Risk Tier | Simulator-Testable? |
|----|------|----------|-----------|---------------------|
| P16-1 | Live kg display on enrolled program session screen | Settings → kg → program session → ExerciseRow badges show kg (e.g., "102.0 kg") | Degraded | iOS Simulator |

---

**Total items: 39 enumerated** (some phases had more items in their body than in the yaml frontmatter; 30 is the approximate count from the yaml `human_verification` sections)

**Triage summary by tier:**
- **Blockers** (must fix): P1-2, P3-1, P3-2, P3-3, P3-4, P4-1, P5-3, P12-1 = 8 items
- **Degraded** (must address): P1-3, P1-4, P3-5, P4-2, P4-3, P4-4, P4-5, P5-1, P5-2, P5-4, P5-5, P7-1, P7-2, P8-1, P8-2, P8-3, P9-1, P10-3, P12-2, P16-1 = 20 items
- **Cosmetic** (nice to have): P7-3, P10-1, P10-2, P15-1, P15-2 = 5 items
- **Deferred** (explicitly out of scope): P6-1 through P6-5, P7-4, P12-3 = 7 items

---

## Standard Stack

### Core Testing Infrastructure

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| iOS Simulator (Xcode) | Latest (iPhone 16 Pro) | Primary verification target | Per CONTEXT.md locked decision |
| Android Emulator (Pixel 9) | Available via SDK | Android smoke test | Confirmed via `emulator -list-avds` |
| Firebase Emulator Suite | Latest | Firestore + Auth local testing | Already configured in `firebase.json` |
| `npx expo start` | Expo 55.x | App launch on simulator | Standard Expo development workflow |
| Network Link Conditioner | Built into iOS Simulator | Offline scenario simulation | Built-in; enables airplane mode simulation |

### Existing Test Infrastructure

| Artifact | Purpose | Status |
|----------|---------|--------|
| `SundeeFundeeRN/jest.config.js` | Jest + jest-expo preset | Available; 72 test files, 1311+ tests |
| `SundeeFundeeRN/firestore.rules.test.ts` | Firebase Rules unit testing | Available; excluded from Jest |
| Firebase Emulator | Local Firestore + Auth | Configured in `firebase.json` |
| iOS Simulator MCP tools | `screenshot`, `tap`, `swipe`, `get_ui_hierarchy`, `launch_app`, `type_text` | Referenced in CONTEXT.md as available |

### Simulator Setup Commands

```bash
# Start iOS Simulator (iPhone 16 Pro)
xcrun simctl boot "iPhone 16 Pro"

# Start Firebase Emulator (for Firestore-dependent tests)
cd SundeeFundeeRN && firebase emulators:start --only firestore,auth

# Start Expo dev server targeting iOS simulator
cd SundeeFundeeRN && npx expo start --ios

# Start Expo for web smoke test
cd SundeeFundeeRN && npx expo start --web

# Start Android emulator
~/Library/Android/sdk/emulator/emulator -avd Pixel_9

# Start Expo for Android
cd SundeeFundeeRN && npx expo start --android
```

---

## Architecture Patterns

### Triage Workflow

```
Phase 17 Execution Order:
1. Environment setup (simulator, Firebase Emulator, app launch)
2. Blocker sweep (8 items) — fix immediately if broken
3. Degraded sweep (20 items) — fix visual/behavioral issues
4. Cosmetic sweep (5 items) — screenshot confirmation
5. Android smoke test (P1-4 + full workout end-to-end)
6. Web smoke test (P1-1, P3-5, P10-2)
7. Offline scenario (VERIFY-03)
8. Auth flow matrix (VERIFY-04)
9. Produce triage report
```

### Simulator Automation Pattern

The iOS Simulator MCP tools (`screenshot`, `tap`, `swipe`, `get_ui_hierarchy`, `launch_app`, `type_text`) enable Claude to automate most visual verification without human interaction.

**Pattern for automated verification:**
```typescript
// 1. Launch app
launch_app({ bundleId: 'com.sundeefundee.app' })

// 2. Take screenshot to confirm visual state
screenshot({ deviceId: 'iPhone 16 Pro' })

// 3. Inspect UI hierarchy for element presence
get_ui_hierarchy({ deviceId: 'iPhone 16 Pro' })
// Confirms: element exists, text matches, accessibility label present

// 4. Interact
tap({ deviceId: 'iPhone 16 Pro', coordinate: { x: 195, y: 400 } })
type_text({ deviceId: 'iPhone 16 Pro', text: 'DELETE' })
swipe({ deviceId: 'iPhone 16 Pro', from: { x: 350, y: 400 }, to: { x: 50, y: 400 } })
```

**What simulator can verify:** Visual layout, navigation transitions, UI hierarchy, text content, onboarding flow routing, weight unit display, PR toast rendering, chart rendering (visual screenshot), cycle tab visibility, adaptation banner presence.

**What simulator cannot verify (deferred to P18):** Real haptic feedback, real push notification delivery to lock screen, App Check device attestation, RevenueCat / Stripe live payment flows.

### Offline Scenario Pattern (VERIFY-03)

The Network Link Conditioner in iOS Simulator allows programmatic network toggling.

```
Scripted offline test sequence:
1. Sign in as test user with completed onboarding
2. Enable Network Link Conditioner → "100% Loss" preset (airplane mode equivalent)
3. Navigate to Workout tab → tap "Start Workout"
4. Add exercise → log 3 sets (reps + weight)
5. Tap "Finish Workout"
6. Verify workout appears in History tab immediately (AsyncStorage persistence)
7. Force-kill app
8. Relaunch app (still offline)
9. Verify workout still in History (crash recovery from AsyncStorage)
10. Disable Network Link Conditioner (restore network)
11. Wait 5-15 seconds
12. Verify workout synced to Firestore (via Firebase Emulator UI or CLI query)
```

The key code paths tested by this scenario:
- `useWorkoutSession.ts` → auto-saves to AsyncStorage on every set completion
- `LocalWorkoutRepo.ts` → persists via `@sundee/workouts` key
- Native Firestore offline persistence → queues write during offline period
- `FirestoreWorkoutRepo.ts` → flushes queued write on reconnect
- `history.tsx` → reads from appropriate repo based on `isGuest` flag

### Auth Flow Matrix (VERIFY-04)

| Platform | Apple Sign-In | Google Sign-In | Email/Password | Guest | Guest → Auth Upgrade |
|----------|--------------|----------------|----------------|-------|----------------------|
| iOS Simulator | Test (simulator supports) | N/A (iOS uses Apple) | Test | Test | Test |
| Android Emulator | N/A | Test | Test | Test | Test |
| Web | N/A | Test | Test | Test | Test |

**Guest-to-auth upgrade** (critical path — involved 3 fix phases: 9, 11, and migration):
1. Sign in as guest on iOS simulator
2. Complete onboarding, log a workout
3. Navigate to Settings → "Create Account"
4. Sign up with email/password (or tap Apple if simulator supports it)
5. Verify: all guest data preserved (workout appears in History, onboarding not re-shown)
6. Verify: Firestore has `/users/{uid}` doc with migrated data

### Firebase Emulator Pattern for Firestore Tests

```bash
# Start emulator with data import (if available)
firebase emulators:start --only firestore,auth --import=./emulator-data

# Configure app to use emulator (EXPO_PUBLIC_USE_EMULATOR=true)
# app checks for this env var and connects to localhost:8080 (Firestore) + localhost:9099 (Auth)

# Query emulator Firestore to verify data
curl http://localhost:8080/v1/projects/sundeefundee/databases/(default)/documents/users/{uid}/workouts
```

The app already has Firebase Emulator support (used in Phase 12 for Firestore rules testing via `firestore.rules.test.ts`). The same setup applies for runtime testing with the emulator.

### Triage Report Structure

The planner should structure the PLAN to produce a triage report with this format for each item:

```markdown
| Item ID | Description | Status | Action Taken | Notes |
|---------|-------------|--------|--------------|-------|
| P4-1 | Complete workout flow | VERIFIED | Screenshot confirmed full flow | Visual: History shows "Custom" badge |
| P4-4 | PR toast visual | VERIFIED | Screenshot shows orange toast | Haptic deferred to P18 |
| P12-1 | Pain log persistence | FIXED | Rule deploy unblocked persistence | Used Firebase Emulator |
| P6-1 | RevenueCat paywall | DEFERRED | Physical device required | Phase 18 EAS build |
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Network state control in iOS Simulator | Custom network mocking | Network Link Conditioner (built into iOS Simulator) | Built-in, reliable, works with real network stack |
| Visual regression comparison | Custom screenshot diffing | Manual screenshot review + iOS Simulator MCP `screenshot` + `get_ui_hierarchy` | No screenshot diffing setup needed; visual confirmation is sufficient |
| Firestore write verification | Custom Firebase client | Firebase Emulator UI (`localhost:4000`) + CLI queries | Already configured; zero real data risk |
| Android verification | Full item-by-item Android sweep | Single smoke test (launch + navigate + complete one workout) | Per locked decision in CONTEXT.md |

---

## Common Pitfalls

### Pitfall 1: Running Against Live Firebase Instead of Emulator
**What goes wrong:** Accidentally writing test data (pain logs, workout records, fake user accounts) to the production Firestore.
**Why it happens:** App defaults to production Firebase unless emulator env var is set.
**How to avoid:** Always set `EXPO_PUBLIC_USE_EMULATOR=true` (or equivalent) before running Firestore-dependent tests. Verify emulator is running before testing.
**Warning signs:** Firebase Console shows test data appearing; Firestore rules tests fail with "permission denied" on emulator when real Firebase connection is used.

### Pitfall 2: Simulator Session State Contamination
**What goes wrong:** A previous test's AsyncStorage state bleeds into the next test's scenario (e.g., onboarding marked complete from a previous run, guest upgrade state already migrated).
**Why it happens:** iOS Simulator persists AsyncStorage between launches unless explicitly cleared.
**How to avoid:** Use `xcrun simctl erase <UDID>` to reset simulator state between test scenarios. Alternatively, use separate simulators for different test personas.

### Pitfall 3: Misidentifying Simulator Limitations as Bugs
**What goes wrong:** Haptic feedback "not working" on simulator gets logged as a blocker rather than a known simulator limitation.
**Why it happens:** Some iOS APIs (haptics, push notifications to lock screen, App Check) silently no-op or behave differently on simulator vs. physical device.
**How to avoid:** Per locked decisions, physical-device-only behaviors (haptics, real push delivery, App Check) are deferred to Phase 18. Mark these as "verified on simulator; physical device confirmation in Phase 18."

### Pitfall 4: Android Emulator Not Fully Configured for Firebase
**What goes wrong:** Android emulator can't connect to Firebase because `google-services.json` isn't configured or Firebase initialization fails on the emulator.
**Why it happens:** Android Firebase setup requires `google-services.json` in `/android/app/` directory and correct package name.
**How to avoid:** Confirm `google-services.json` exists (`SundeeFundeeRN/google-services.json` is present in git). The EAS build system handles placement. For bare workflow, confirm `app.json` plugin handles it. The smoke test is just launch + navigation + workout — Firebase is not required for this.

### Pitfall 5: Web Build Requires Node/Metro to Be Running
**What goes wrong:** Web smoke test attempts fail because Metro bundler isn't running.
**Why it happens:** `expo start --web` must be running in a terminal before testing web behavior.
**How to avoid:** Start the Metro bundler first, wait for "Metro waiting on..." message, then open browser.

### Pitfall 6: Firebase Emulator Port Conflicts
**What goes wrong:** `firebase emulators:start` fails because ports 8080, 9099, or 4000 are already in use.
**Why it happens:** Previous emulator session wasn't terminated, or another service is using the port.
**How to avoid:** Run `lsof -ti:8080 | xargs kill` before starting emulators. Or use `firebase emulators:start --only firestore,auth` to limit which emulators start.

---

## Code Examples

### Expo Network Link Conditioner Control (Offline Testing)

The iOS Simulator's Network Link Conditioner can be toggled via `simctl`:
```bash
# Enable 100% packet loss (airplane mode equivalent)
xcrun simctl spawn booted defaults write com.apple.CaptiveNetwork.plist /Library/Preferences/SystemConfiguration/com.apple.NetworkInterfaceIPConfigLog.plist 'CaptiveNetworkSupportEnabled' -bool false

# Easier: Use Simulator menu → Features → Network Link Conditioner → 100% Loss
# OR use the simctl status_bar command to simulate network states
xcrun simctl status_bar "iPhone 16 Pro" override --cellularBars 0 --wifiBars 0
```

### Checking AsyncStorage State in Simulator

```bash
# View AsyncStorage contents (stored in simulator's app container)
xcrun simctl get_app_container booted com.sundeefundee.app data
# Then navigate to Library/Application Support/RCTAsyncLocalStorage_V1/

# Reset simulator to clean state
xcrun simctl erase "iPhone 16 Pro"
```

### Firebase Emulator + App Connection Pattern

The app uses `EXPO_PUBLIC_USE_EMULATOR` to switch between emulator and production. Check `src/firebase/firestore.ts` and `src/firebase/auth.ts` for the emulator connection logic:

```typescript
// Source: SundeeFundeeRN/src/firebase/firestore.ts (existing pattern)
// Emulator connection is already configured for firestore.rules.test.ts
// Same pattern applies for runtime emulator testing
if (process.env.EXPO_PUBLIC_USE_EMULATOR === 'true') {
  connectFirestoreEmulator(db, 'localhost', 8080);
  connectAuthEmulator(auth, 'http://localhost:9099');
}
```

### Workout Session AutoSave Key (Crash Recovery)

From `useWorkoutSession.ts` — workout data auto-saves to AsyncStorage on every set completion:
```typescript
// Source: SundeeFundeeRN/src/hooks/useWorkoutSession.ts
const WORKOUT_AUTOSAVE_KEY = '@sundee/active_workout';
// Written on every completeSet() call
// Read on mount (crash recovery)
// Cleared on finishWorkout()
```

This means offline workout completion survives app kills — the offline test (VERIFY-03) will work even with force-kill.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| All verification deferred to physical device | Simulator-first verification with clear deferred list | Most items can be checked now without waiting for Phase 18 EAS build |
| Ad hoc manual testing | Scripted steps from VERIFICATION.md | Reproducible, documented verification |
| Live Firebase for all tests | Firebase Emulator for Firestore-dependent items | Zero risk of corrupting production data |

---

## Environment Pre-Conditions

Before any verification work begins, these must be confirmed:

1. **iOS Simulator available:** iPhone 16 Pro simulator exists (`xcrun simctl list` confirms it)
2. **Android Emulator available:** Pixel 9 AVD exists (`emulator -list-avds` confirms it)
3. **Firebase Emulator runnable:** `firebase.json` in project root, `firebase` CLI available
4. **Expo CLI available:** `npx expo start` runnable from `SundeeFundeeRN/`
5. **`google-services.json` present:** Confirmed at `SundeeFundeeRN/google-services.json` (in git)
6. **`GoogleService-Info.plist` present:** Confirmed at `SundeeFundeeRN/GoogleService-Info.plist` (in git)
7. **Node modules installed:** `SundeeFundeeRN/node_modules/` exists (large; likely present)

**Note on EAS dev build:** The CONTEXT.md notes that iOS Simulator MCP tools can be used for this phase. The app can run as an Expo Go app OR as a development build. Since some dependencies (`@react-native-firebase/*`, `react-native-purchases`) are native modules that don't work in Expo Go, a development build (EAS) is required for full verification. However, `npx expo run:ios` (bare workflow build) can also produce a local development build for the simulator without requiring EAS cloud. Check if a dev build is already installed on the simulator.

---

## Open Questions

1. **EAS dev build availability on simulator**
   - What we know: The app uses `@react-native-firebase/*` native modules that don't work in Expo Go
   - What's unclear: Whether a development build `.app` bundle is already installed on the iPhone 16 Pro simulator from previous v1.0 work
   - Recommendation: Check `xcrun simctl listapps booted` for installed apps. If not present, run `npx expo run:ios --simulator "iPhone 16 Pro"` to build and install locally (no EAS required for simulator builds).

2. **Expo public environment variable for Firebase Emulator**
   - What we know: Phase 12 used `firestore.rules.test.ts` which uses the `@firebase/rules-unit-testing` SDK directly (not the app client)
   - What's unclear: Whether the app itself has an `EXPO_PUBLIC_USE_EMULATOR` env var or similar to route to emulator at runtime
   - Recommendation: Check `src/firebase/firestore.ts` and `src/firebase/auth.ts` for emulator connection logic. If absent, Firestore-dependent tests should use live Firebase with test accounts (not emulator), or add the connection logic as a Wave 0 task.

3. **AI workout generation (P5-1) without live API key**
   - What we know: Requires live Gemini API key and deployed Cloud Functions
   - What's unclear: Whether the GEMINI_API_KEY secret is set in Firebase Functions for the dev project
   - Recommendation: If key is not set, mark P5-1 as "degraded — requires live API" and verify the offline fallback path (P5-3) instead. The offline fallback is testable via airplane mode on simulator.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Jest + jest-expo 55.x |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="src/__tests__" --passWithNoTests` |
| Full suite command | `cd SundeeFundeeRN && npx jest` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| VERIFY-01 | All ~30 items triaged | Manual + Simulator | Triage report artifact | No automated test possible; output is a triage document |
| VERIFY-02 | Core workout flow on iOS + Android | Simulator automation | iOS Simulator MCP scripts | Android: manual smoke test |
| VERIFY-03 | Offline workout + sync | Simulator + Network Link Conditioner | Scripted offline steps | App kill + relaunch test included |
| VERIFY-04 | All auth flows | Simulator automation | iOS Simulator MCP scripts | Guest-to-auth upgrade is the critical path |

### Per-Task Verification

- **Per task commit:** `cd SundeeFundeeRN && npx jest --passWithNoTests` (confirm no regressions from any bug fixes)
- **Per wave merge:** Full Jest suite — `cd SundeeFundeeRN && npx jest`
- **Phase gate:** Full suite green + triage report complete before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] Check if dev build is installed on simulator — run `xcrun simctl listapps booted` or `npx expo run:ios`
- [ ] Verify Firebase Emulator connectivity from app at runtime — check `src/firebase/firestore.ts` for emulator connection support
- [ ] Confirm EAS dev client or local `expo run:ios` build is available before attempting any simulator verification

---

## Sources

### Primary (HIGH confidence)
- VERIFICATION.md files from all 16 v1.0 phases — direct source of all 30 human verification items
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — triage context and tech debt summary
- `.planning/phases/17-device-verification/17-CONTEXT.md` — locked decisions and constraints
- `SundeeFundeeRN/package.json` — dependency versions (Expo 55, RN 0.83.2, Firebase 23.x)
- `firebase.json` — Firebase Emulator configuration confirmed
- `SundeeFundeeRN/jest.config.js` — test framework configuration

### Secondary (MEDIUM confidence)
- `.planning/RETROSPECTIVE.md` — lessons learned about verification gaps
- Expo Simulator documentation patterns (from training knowledge, consistent with Expo 55.x)
- Firebase Emulator Suite documentation patterns (known to work with rules unit testing in this project)

### Tertiary (LOW confidence — not independently verified)
- iOS Simulator Network Link Conditioner bash commands (flag for validation during execution)
- Specific `xcrun simctl` commands for AsyncStorage access (should be verified before use)

---

## Metadata

**Confidence breakdown:**
- Human verification item catalog: HIGH — sourced directly from VERIFICATION.md files
- Triage risk tiers: HIGH — based on impact analysis from phase goals and CONTEXT.md
- Simulator automation feasibility: MEDIUM — iOS Simulator MCP tools referenced in CONTEXT.md as available; exact tool API not independently verified
- Firebase Emulator approach: HIGH — confirmed configured in project (`firebase.json`)
- Android/Web smoke test scope: HIGH — directly from locked decisions in CONTEXT.md

**Research date:** 2026-03-16
**Valid until:** 2026-04-16 (stable tech, 30-day window)

---
phase: 07-polish-and-pre-launch
plan: "01"
subsystem: ui
tags: [weight-units, formatWeight, app-check, firebase, settings, react-native]

# Dependency graph
requires:
  - phase: 06-subscriptions-and-monetization
    provides: Settings infrastructure (SettingsRepo, AppSettings interface with weightUnit field)
  - phase: 02-domain-layer-port
    provides: weight-unit-conversion.ts (lbToKg, kgToLb, POUNDS_PER_KG)
provides:
  - formatWeight utility (lbs→display string with unit suffix, kg rounded to nearest 0.5)
  - formatWeightNumeric utility (lbs→number for input fields)
  - parseWeightInput utility (user input→stored lbs)
  - App Check initialization with debug/production provider switching
  - Weight unit toggle in Settings (between Rest Timer and Subscription sections)
  - Weight unit threading: maxes.tsx, SetRow, ExerciseCard, workout-session
affects: [08-testing-and-release, workout-session, maxes, settings]

# Tech tracking
tech-stack:
  added:
    - "@react-native-firebase/app-check: ^23.x"
    - "expo-file-system (via expo install)"
    - "expo-sharing (via expo install)"
    - "react-native-zip-archive"
    - "react-native-worklets (missing transitive dep of reanimated 4.x)"
  patterns:
    - "formatWeight pattern: all weight displays call formatWeight(storedLbs, unit) — no hardcoded 'lbs' strings"
    - "parseWeightInput pattern: TextInput onCompleteSet calls parseWeightInput(rawInput, unit) → stored lbs"
    - "Settings load pattern: each screen that needs weightUnit loads from getSettingsRepo on mount"
    - "App Check: initAppCheck() called in _layout.tsx useEffect before any Firestore calls"

key-files:
  created:
    - SundeeFundeeRN/src/utils/formatWeight.ts
    - SundeeFundeeRN/src/utils/__tests__/formatWeight.test.ts
    - SundeeFundeeRN/src/firebase/appCheck.ts
  modified:
    - SundeeFundeeRN/app/(app)/(tabs)/settings.tsx
    - SundeeFundeeRN/app/(app)/_layout.tsx
    - SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx
    - SundeeFundeeRN/app/(app)/workout-session.tsx
    - SundeeFundeeRN/src/components/workout/SetRow.tsx
    - SundeeFundeeRN/src/components/workout/ExerciseCard.tsx

key-decisions:
  - "formatWeight kg rounding: Math.round(kg * 2) / 2 — 0.5 kg increments match metric gym plate granularity"
  - "parseWeightInput empty string returns 0, not NaN — prevents undefined storage on accidental empty field"
  - "App Check init: non-fatal failure (warn + continue) — security reduced but app not broken on init error"
  - "App Check web: Platform.OS === 'web' early-return — RNF App Check not applicable on web"
  - "weightUnit defaults to 'lb' everywhere via optional prop — backward compatible with callers that don't pass it"
  - "react-native-worklets installed as Rule 3 auto-fix — missing transitive dep of reanimated 4.x blocked Jest"

patterns-established:
  - "Weight display pattern: formatWeight(storedLbs, unit) for strings, formatWeightNumeric for number inputs"
  - "Settings load pattern per-screen: useEffect on mount calls getSettingsRepo(isGuest).getSettings(uid)"

requirements-completed:
  - PLAT-04
  - PLAT-05

# Metrics
duration: 6min
completed: "2026-03-15"
---

# Phase 7 Plan 01: Weight Unit Switching and App Check Summary

**lbs/kg toggle with 0.5 kg rounding, formatWeight utility with 19 tests, App Check init before Firebase calls**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-15T19:44:29Z
- **Completed:** 2026-03-15T19:50:15Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- formatWeight utility converts stored lbs to display strings with unit suffix; kg values rounded to nearest 0.5 kg
- parseWeightInput converts user kg/lbs input back to stored lbs for Firestore persistence
- App Check initialized in _layout.tsx before any Firebase calls, with debug token in dev and appAttest/PlayIntegrity in prod
- Weight unit toggle added to Settings between Rest Timer and Subscription sections, saves via SettingsRepo
- All weight displays in maxes.tsx, SetRow, and workout-session threaded with user's weightUnit preference

## Task Commits

1. **test(07-01): add failing tests for formatWeight utility** - `5339f9a`
2. **feat(07-01): formatWeight utility and App Check initialization** - `3d3ace9`
3. **feat(07-01): weight unit toggle in Settings and formatWeight threading** - `5d4219e`

## Files Created/Modified

- `SundeeFundeeRN/src/utils/formatWeight.ts` — formatWeight, formatWeightNumeric, parseWeightInput pure functions
- `SundeeFundeeRN/src/utils/__tests__/formatWeight.test.ts` — 19 tests covering all behaviors and edge cases
- `SundeeFundeeRN/src/firebase/appCheck.ts` — initAppCheck with dev/prod provider switching, web guard, double-init guard
- `SundeeFundeeRN/app/(app)/(tabs)/settings.tsx` — Weight Unit section, picker modal, handleSelectWeightUnit
- `SundeeFundeeRN/app/(app)/_layout.tsx` — initAppCheck() in useEffect at app startup
- `SundeeFundeeRN/app/(app)/(tabs)/maxes.tsx` — loads weightUnit from settings, formats 1RM with formatWeightNumeric
- `SundeeFundeeRN/app/(app)/workout-session.tsx` — loads weightUnit on mount, passes to ExerciseCard
- `SundeeFundeeRN/src/components/workout/ExerciseCard.tsx` — accepts/passes weightUnit to SetRow
- `SundeeFundeeRN/src/components/workout/SetRow.tsx` — uses formatWeightNumeric for display, parseWeightInput for storage, dynamic unit suffix

## Decisions Made

- **Kg rounding to 0.5:** `Math.round(kg * 2) / 2` — matches metric plate increments, 61.235 rounds to 61.0 not 61.5 (closer to 61 than 61.5)
- **Test correction:** Initial test expected 135 lbs → 61.5 kg but 61.235 rounds to 61.0; fixed test expectation to match correct math
- **App Check non-fatal:** Initialization failure logs warning and continues — Firebase security reduced but app functional
- **weightUnit defaults to 'lb':** All new props optional with default — backward compatible with existing callers

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing react-native-worklets dependency**
- **Found during:** Task 1 verification (running formatWeight tests)
- **Issue:** `Cannot find module 'react-native-worklets/plugin'` — missing transitive dependency of react-native-reanimated 4.x that blocked all Jest test runs
- **Fix:** `npm install react-native-worklets --legacy-peer-deps`
- **Files modified:** package.json, package-lock.json
- **Verification:** Jest test suite runs successfully after install
- **Committed in:** `5339f9a` (part of test commit)

**2. [Rule 1 - Bug] Fixed incorrect test expectation for kg rounding**
- **Found during:** Task 1 GREEN phase (running tests after implementation)
- **Issue:** Test expected `formatWeight(135, 'kg')` → `'61.5 kg'` but 135 lbs = 61.235 kg which rounds to 61.0, not 61.5
- **Fix:** Updated test assertion to match correct mathematical result `'61.0 kg'`
- **Files modified:** `src/utils/__tests__/formatWeight.test.ts`
- **Verification:** All 19 tests pass
- **Committed in:** `3d3ace9` (part of feat commit)

---

**Total deviations:** 2 auto-fixed (1 blocking dependency, 1 test correctness)
**Impact on plan:** Both fixes necessary for test infrastructure and correctness. No scope creep.

## Issues Encountered

- npx expo install with `--legacy-peer-deps` required double-dash syntax: `npx expo install pkg -- --legacy-peer-deps` (expo CLI intercepts flags)
- Jest 30.x renamed `--testPathPattern` to `--testPathPatterns` — used updated flag

## User Setup Required

- App Check debug token: set `EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN` in `.env.local` for development
- App Check production: requires Firebase Console configuration of App Attest (iOS) and Play Integrity (Android) providers before release

## Next Phase Readiness

- Weight unit switching fully wired through all workout-data screens
- App Check initialized at app startup — Firebase calls are secured
- history.tsx weight display audit: workout volumes in HistoryCard show totalVolume (aggregate lbs) — may need formatWeight treatment in future plan if volumes are displayed to users
- exercise-detail.tsx PR history display: shows historical weights in lbs — candidate for formatWeight in next polish pass

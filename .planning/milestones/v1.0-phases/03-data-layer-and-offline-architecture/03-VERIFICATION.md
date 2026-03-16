---
phase: 03-data-layer-and-offline-architecture
verified: 2026-03-14T00:00:00Z
status: human_needed
score: 14/14 automated must-haves verified
re_verification: false
human_verification:
  - test: "Complete 5-step onboarding as female user"
    expected: "5 steps shown (name, experience, goal, gender, cycle), Art Deco styling with cream/navy/orange, progress bar advances each step, Back button works on steps 2-5, cycle toggle works, tapping Complete lands on Dashboard tab"
    why_human: "Visual styling, progress bar rendering, and full navigation flow cannot be verified programmatically"
  - test: "Complete onboarding as male user"
    expected: "4 steps shown (cycle step skipped), after selecting Male on step-gender the Next button becomes 'Complete', tapping it saves and lands on Dashboard without showing step-cycle"
    why_human: "Gender-based step skip is code-verified but the runtime routing behavior requires manual confirmation"
  - test: "Restart the app after completing onboarding"
    expected: "User lands directly on Dashboard tab, onboarding is never shown again"
    why_human: "hasCompletedOnboarding persistence and route guard behavior require a live app to confirm no flicker or redirect loop"
  - test: "Complete onboarding as a guest user"
    expected: "Guest goes through same 5 (or 4) step flow; after completion, restarting the app skips onboarding (reads from @sundee/onboarding_profile AsyncStorage key)"
    why_human: "The bug that caused guest loop was already fixed, but the correct storage key path requires runtime confirmation"
  - test: "Web Firestore offline writes"
    expected: "When browser tab is offline, writes queue locally (IndexedDB) and flush on reconnect"
    why_human: "persistentLocalCache behavior requires a running web build with network toggling"
---

# Phase 3: Data Layer and Offline Architecture Verification Report

**Phase Goal:** Build the repository layer with dual Firestore/AsyncStorage implementations and the 5-step onboarding flow UI
**Verified:** 2026-03-14
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Plan 01 — Repository Layer)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | UserProfile includes onboarding fields (name, experienceLevel, primaryGoal, gender, cycleOptIn, hasCompletedOnboarding) | VERIFIED | `src/repositories/UserRepository.ts` lines 11-30: ExperienceLevel, PrimaryGoal types defined; all 6 optional fields added to UserProfile interface |
| 2 | OnboardingProfileRepo saves and retrieves profile data via Firestore or AsyncStorage depending on auth state | VERIFIED | `OnboardingProfileRepo.ts`: getOnboardingProfileRepo(isGuest) returns LocalOnboardingProfileRepo (true) or FirestoreOnboardingProfileRepo (false); both classes implement saveProfile/getProfile |
| 3 | WorkoutRepo saves and retrieves workout records via Firestore subcollection or AsyncStorage | VERIFIED | `FirestoreWorkoutRepo.ts`: uses /users/{uid}/workouts/{id}; `LocalWorkoutRepo.ts`: uses @sundee/workouts key; full save/get/history/delete implemented |
| 4 | SettingsRepo saves and retrieves app settings (weightUnit, notificationsEnabled) | VERIFIED | `SettingsRepo.ts`: AppSettings interface + DEFAULT_SETTINGS constant; Firestore merges into /users/{uid}; Local uses @sundee/settings |
| 5 | ReadinessRepo saves and retrieves readiness survey records by date | VERIFIED | `ReadinessRepo.ts`: ReadinessSurveyRecord interface; Firestore uses /users/{uid}/readiness/{date} subcollection; Local uses @sundee/readiness_surveys |
| 6 | Factory functions return Firestore implementations for authenticated users and AsyncStorage for guests | VERIFIED | All 4 factory functions (getOnboardingProfileRepo, getWorkoutRepo, getSettingsRepo, getReadinessRepo) tested in repoFactory.test.ts; 96 tests pass |
| 7 | Guest-to-auth migration reads all AsyncStorage data, batch-writes to Firestore, then clears local storage | VERIFIED | `migration.ts` lines 31-86: AsyncStorage.multiGet → batch writes → batch.commit() → multiRemove; null-check on each pair; clear only after successful commit |
| 8 | Web Firestore persistence is enabled so offline writes survive tab close | VERIFIED | `firebase/firestore.ts` lines 57-66: initializeFirestore with persistentLocalCache({}); try-catch falls back to getFirestore on re-init |

### Observable Truths (Plan 02 — Onboarding Flow)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 9 | User completes 5-step onboarding (name, experience, goal, gender, cycle opt-in) and data persists | VERIFIED (code) / HUMAN for runtime | 5 screen files exist in app/(onboarding)/; OnboardingContext.completeOnboarding calls saveProfile atomically; visual/runtime confirmation needed |
| 10 | Cycle opt-in step is skipped for male users | VERIFIED | useOnboardingFlow.ts line 50: `if (currentStep === 'step-gender' && draft.gender === 'male') return null`; step-gender.tsx calls completeOnboarding when nextStep is null |
| 11 | All data saved atomically on final step completion (no partial persistence) | VERIFIED | OnboardingContext.tsx lines 88-101: single saveProfile() call with all draft fields + hasCompletedOnboarding: true; no intermediate saves in any step screen |
| 12 | Guests go through the same onboarding flow as authenticated users | VERIFIED | app/(app)/_layout.tsx redirects to /(onboarding)/step-name regardless of auth type; getOnboardingProfileRepo(isGuest) handles persistence routing |
| 13 | After completion, user lands on Dashboard tab and never sees onboarding again | VERIFIED (code) / HUMAN for runtime | step-gender.tsx and step-cycle.tsx call router.replace('/(app)/(tabs)'); (app)/_layout.tsx checks hasCompletedOnboarding from same repo; runtime confirmation needed |
| 14 | Back button on each step allows revisiting/changing answers | VERIFIED | step-gender.tsx and step-cycle.tsx have Back button via getPreviousStep(); step-name.tsx has no Back button (first step) |

**Score:** 14/14 truths code-verified; 5 items require human runtime confirmation

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/repositories/UserRepository.ts` | Expanded UserProfile with onboarding fields | VERIFIED | hasCompletedOnboarding, name, experienceLevel, primaryGoal, gender, cycleOptIn all present |
| `src/repositories/OnboardingProfileRepo.ts` | OnboardingProfileRepository interface + factory | VERIFIED | Interface, OnboardingProfile type, getOnboardingProfileRepo(isGuest) factory all exported |
| `src/repositories/FirestoreOnboardingProfileRepo.ts` | Firestore implementation | VERIFIED | Full saveProfile + getProfile with real Firestore calls |
| `src/repositories/LocalOnboardingProfileRepo.ts` | AsyncStorage implementation | VERIFIED | Uses @sundee/onboarding_profile key |
| `src/repositories/WorkoutRepo.ts` | WorkoutRepository interface + factory | VERIFIED | WorkoutRecord, WorkoutRepository, getWorkoutRepo exported |
| `src/repositories/FirestoreWorkoutRepo.ts` | Firestore subcollection implementation | VERIFIED | Full save/get/history/delete with /users/{uid}/workouts/{id} subcollection |
| `src/repositories/LocalWorkoutRepo.ts` | AsyncStorage array implementation | VERIFIED | JSON array with sort by completedAt |
| `src/repositories/SettingsRepo.ts` | SettingsRepository interface + factory | VERIFIED | AppSettings, DEFAULT_SETTINGS, getSettingsRepo exported |
| `src/repositories/FirestoreSettingsRepo.ts` | Firestore merge implementation | VERIFIED | Merges into /users/{uid} doc |
| `src/repositories/LocalSettingsRepo.ts` | AsyncStorage implementation | VERIFIED | Uses @sundee/settings key |
| `src/repositories/ReadinessRepo.ts` | ReadinessRepository interface + factory | VERIFIED | ReadinessSurveyRecord, ReadinessRepository, getReadinessRepo exported |
| `src/repositories/FirestoreReadinessRepo.ts` | Firestore subcollection implementation | VERIFIED | /users/{uid}/readiness/{date} with orderBy |
| `src/repositories/LocalReadinessRepo.ts` | AsyncStorage array implementation | VERIFIED | Uses @sundee/readiness_surveys key |
| `src/repositories/migration.ts` | Guest-to-auth migration | VERIFIED | migrateGuestDataToFirestore with atomic commit and safe multiRemove |
| `src/repositories/index.ts` | Barrel re-exports | VERIFIED | All types, interfaces, factories, and migration function re-exported |
| `src/firebase/firestore.ts` | Web Firestore IndexedDB persistence | VERIFIED | persistentLocalCache({}) with hot-reload fallback |
| `app/(onboarding)/_layout.tsx` | Onboarding route group layout | VERIFIED | Wraps children in OnboardingProvider + headerless Stack |
| `app/(onboarding)/step-name.tsx` | Name input screen | VERIFIED | TextInput, disabled Next until name non-empty, no Back button |
| `app/(onboarding)/step-experience.tsx` | Experience level selection screen | VERIFIED | 3 option cards |
| `app/(onboarding)/step-goal.tsx` | Primary goal selection screen | VERIFIED | 5 option cards |
| `app/(onboarding)/step-gender.tsx` | Gender selection screen | VERIFIED | 3 cards; Male path calls completeOnboarding; Back button present |
| `app/(onboarding)/step-cycle.tsx` | Cycle opt-in screen (conditional) | VERIFIED | Toggle switch, Complete button calls completeOnboarding, Back button present |
| `src/onboarding/OnboardingContext.tsx` | In-memory state accumulator + save function | VERIFIED | Draft state, all setters, completeOnboarding atomic save |
| `src/onboarding/useOnboardingFlow.ts` | Step navigation logic | VERIFIED | ONBOARDING_STEPS, getNextStep with gender-skip, getTotalSteps, getPreviousStep |
| `app/_layout.tsx` | Root layout with onboarding route | VERIFIED | (onboarding) route added to Stack; routing decisions delegated to (app)/_layout.tsx |
| `app/(app)/_layout.tsx` | Onboarding gate | VERIFIED | Reads hasCompletedOnboarding via getOnboardingProfileRepo; redirects to step-name if false |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `OnboardingProfileRepo.ts` | `UserRepository.ts` | imports ExperienceLevel, PrimaryGoal, Gender types | VERIFIED | Line 9: `import type { ExperienceLevel, PrimaryGoal } from './UserRepository'` |
| `FirestoreOnboardingProfileRepo.ts` | `firebase/firestore.ts` | getFirestoreInstance() | VERIFIED | Line 7: `import { getFirestoreInstance } from '../firebase/firestore'`; used in saveProfile and getProfile |
| `migration.ts` | `firebase/firestore.ts` | batch writes via getFirestoreInstance() | VERIFIED | Line 11 import; line 27 `const db = getFirestoreInstance()`; line 83 `await batch.commit()` |
| `OnboardingContext.tsx` | `OnboardingProfileRepo.ts` | getOnboardingProfileRepo(isGuest).saveProfile(uid, profile) | VERIFIED | Line 17 import; line 90-91 `getOnboardingProfileRepo(isGuest)` then `repo.saveProfile(...)` |
| `app/_layout.tsx` | `UserRepository.ts` | reads UserProfile for routing | VERIFIED | Line 19 import; used in buildUserProfile and createOrUpdateUser calls |
| `app/(app)/_layout.tsx` | `OnboardingProfileRepo.ts` | reads hasCompletedOnboarding | VERIFIED | Line 18 import; line 40-44: getOnboardingProfileRepo(isGuest).getProfile(uid) then checks hasCompletedOnboarding |
| `useOnboardingFlow.ts` | `app/(onboarding)/step-cycle.tsx` | skips cycle step when gender is 'male' | VERIFIED | useOnboardingFlow line 50 returns null for male; step-gender.tsx calls completeOnboarding when nextStep is null |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ONBD-01 | 03-01, 03-02 | User completes profile setup (name, experience level, goal, gender) | VERIFIED | UserProfile expanded with all fields; 5-step onboarding collects each; OnboardingContext saves atomically |
| ONBD-02 | 03-02 | User can opt into cycle tracking during onboarding | VERIFIED | step-cycle.tsx provides toggle switch; cycleOptIn stored in OnboardingProfile |
| ONBD-03 | 03-02 | Onboarding steps adapt based on user selections (skip cycle for male) | VERIFIED | getNextStep() returns null for male on step-gender; step-gender calls completeOnboarding directly |
| WORK-11 | 03-01 | All workout logging works offline without data loss | VERIFIED | LocalWorkoutRepo for guests; Firestore with persistentLocalCache for web; native Firestore has built-in offline persistence |
| AUTH-07 | 03-01, 03-02 | User data syncs across devices when authenticated | VERIFIED | Firestore implementations sync to /users/{uid}; migration helper moves guest data to Firestore on auth |

No orphaned requirements: all 5 IDs are covered by plan claims and implementation evidence.

### Anti-Patterns Found

None found. Scanned all 26 created/modified files for TODO/FIXME/placeholder patterns, empty implementations, and stub returns. The only `return null` occurrences are legitimate "document not found" returns inside real Firestore/AsyncStorage query flows.

### Human Verification Required

#### 1. Full female onboarding flow

**Test:** Start fresh app (or clear AsyncStorage), sign in, and complete onboarding selecting Female gender.
**Expected:** 5 steps rendered with Art Deco styling (cream background, navy text, orange buttons); progress bar advances (1/5 through 5/5); Back button is absent on step-name, present on all others; cycle toggle is visible and functional on step-cycle; tapping Complete lands on Dashboard tab.
**Why human:** Visual styling, progress bar rendering, and Back/Next navigation cannot be verified programmatically.

#### 2. Male gender path — cycle step skipped

**Test:** Complete onboarding selecting Male on step-gender.
**Expected:** Total steps shown as 4; Next button label changes to "Complete" when Male is selected; tapping Complete skips step-cycle entirely and lands on Dashboard.
**Why human:** Runtime routing after completeOnboarding requires live app to confirm no step-cycle screen appears.

#### 3. Onboarding gate — returning user

**Test:** Kill and restart the app after completing onboarding.
**Expected:** User lands directly on Dashboard tab with no onboarding screens shown. No routing flicker.
**Why human:** hasCompletedOnboarding persistence and the (app)/_layout.tsx null-loading-state behavior require a live app with actual AsyncStorage/Firestore reads to confirm no flicker.

#### 4. Guest onboarding persistence

**Test:** Sign in as guest, complete onboarding, kill the app, reopen.
**Expected:** Guest skips onboarding on reopen. Profile reads from @sundee/onboarding_profile AsyncStorage key (not @sundee/user_profile — this was the bug fixed in commit 28c4a63).
**Why human:** The key mismatch bug was fixed in code but needs runtime confirmation the fix works end-to-end.

#### 5. Web Firestore offline writes

**Test:** Open web build, go offline, trigger a profile save (complete onboarding), go back online.
**Expected:** Save queues locally in IndexedDB, then flushes to Firestore on reconnect.
**Why human:** persistentLocalCache IndexedDB behavior requires a running web build with network toggling; cannot verify via grep.

### Summary

Phase 3 goal is substantially achieved. All 14 observable truths are verified in code:

- All 4 repository interfaces (OnboardingProfile, Workout, Settings, Readiness) are fully implemented with real Firestore and AsyncStorage persistence — no stubs.
- All 8 implementation classes (4 Firestore + 4 AsyncStorage) have working query logic.
- All 4 factory functions route correctly based on isGuest.
- The migration helper implements the atomic commit-before-clear pattern.
- Web Firestore offline persistence is wired via persistentLocalCache.
- All 5 onboarding screens exist with substantive UI (option cards, text input, toggle).
- OnboardingContext accumulates draft state and saves atomically on the final step.
- The (app)/_layout.tsx route guard reads from the same storage key that OnboardingContext writes to.
- 741 tests pass. TypeScript compiles cleanly (tsc --noEmit exits 0).

The 5 human verification items are runtime confirmation of already-verified code behavior — they are not suspected gaps, but the visual styling, navigation routing, and offline behavior cannot be confirmed without a live device/simulator run.

---

_Verified: 2026-03-14_
_Verifier: Claude (gsd-verifier)_

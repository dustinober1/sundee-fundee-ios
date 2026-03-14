---
phase: 03-data-layer-and-offline-architecture
plan: 02
subsystem: onboarding
tags: [onboarding, expo-router, react-context, asyncstorage, art-deco, repository-pattern]

# Dependency graph
requires:
  - phase: 03-01
    provides: OnboardingProfileRepository (getOnboardingProfileRepo factory), LocalOnboardingProfileRepo, FirestoreOnboardingProfileRepo
  - phase: 01
    provides: SessionProvider, useSession, AuthContext (user, isGuest, isLoading)
  - phase: 02
    provides: Domain types (Gender, ExperienceLevel, PrimaryGoal)
provides:
  - 5-step onboarding flow UI (step-name, step-experience, step-goal, step-gender, step-cycle)
  - OnboardingContext with in-memory draft accumulation and atomic final save
  - useOnboardingFlow hook with gender-adaptive step skipping (male users skip cycle step)
  - (onboarding) route group layout wrapping screens in OnboardingProvider
  - Root layout (app/_layout.tsx) that delegates all routing to (app)/_layout.tsx
  - (app)/_layout.tsx that reads hasCompletedOnboarding from OnboardingProfileRepo for gate
affects:
  - Phase 04: Any feature using onboarding completion state (Dashboard, profile display)
  - Phase 06: Settings screen may allow re-triggering cycle opt-in flow

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "OnboardingContext accumulates draft in-memory; single atomic saveProfile() call on final step — no partial writes"
    - "getNextStep() returns null as completion signal — screens call completeOnboarding() when next step is null"
    - "getOnboardingProfileRepo(isGuest) used in both OnboardingContext (write) and (app)/_layout.tsx (read) — same storage key for consistency"
    - "expo-router Redirect pattern for route guarding — Redirect component not Stack.Protected"

key-files:
  created:
    - SundeeFundeeRN/src/onboarding/OnboardingContext.tsx
    - SundeeFundeeRN/src/onboarding/useOnboardingFlow.ts
    - SundeeFundeeRN/src/onboarding/__tests__/OnboardingContext.test.tsx
    - SundeeFundeeRN/src/onboarding/__tests__/useOnboardingFlow.test.ts
    - SundeeFundeeRN/app/(onboarding)/_layout.tsx
    - SundeeFundeeRN/app/(onboarding)/step-name.tsx
    - SundeeFundeeRN/app/(onboarding)/step-experience.tsx
    - SundeeFundeeRN/app/(onboarding)/step-goal.tsx
    - SundeeFundeeRN/app/(onboarding)/step-gender.tsx
    - SundeeFundeeRN/app/(onboarding)/step-cycle.tsx
  modified:
    - SundeeFundeeRN/app/_layout.tsx (removed onboardingComplete gate; Stack renders unconditionally)
    - SundeeFundeeRN/app/(app)/_layout.tsx (switched to getOnboardingProfileRepo for hasCompletedOnboarding check)

key-decisions:
  - "OnboardingContext saves all data atomically on final step completion — no partial persistence during the flow"
  - "getNextStep() returns null as the completion signal rather than a named 'done' route — screens handle null by calling completeOnboarding"
  - "Male users skip cycle step: getNextStep('step-gender', {gender:'male'}) returns null, triggering completion from gender screen"
  - "app/_layout.tsx no longer gates on onboardingComplete state — blank-page bug when no user signed in; (app)/_layout.tsx owns all routing decisions"
  - "(app)/_layout.tsx reads hasCompletedOnboarding via getOnboardingProfileRepo (not LocalUserRepo) — same storage location as OnboardingContext writes to"

patterns-established:
  - "OnboardingContext pattern: accumulate draft in context, single atomic save at flow end — use for any multi-step wizard"
  - "Route guard reads from same repo factory as writer — ensures storage location consistency between write and read path"

requirements-completed:
  - ONBD-01
  - ONBD-02
  - ONBD-03
  - AUTH-07

# Metrics
duration: ~35min
completed: "2026-03-14"
---

# Phase 3 Plan 2: Onboarding Flow Summary

**5-step onboarding wizard (name, experience, goal, gender, cycle opt-in) with Art Deco styling, gender-adaptive step skipping, atomic persistence via OnboardingProfileRepo, and route guard using getOnboardingProfileRepo for storage-consistent completion check**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-03-14
- **Tasks:** 3 (2 code tasks + 1 human-verify checkpoint)
- **Files created:** 10
- **Files modified:** 2

## Accomplishments

- 5-screen onboarding wizard with Art Deco styling (cream/navy/orange palette), progress bar, and Back navigation on all steps except the first
- OnboardingContext accumulates draft in-memory; `completeOnboarding()` performs a single atomic `saveProfile()` on the final step — no partial writes during the flow
- Male users see 4 steps (cycle opt-in skipped); female/other users see all 5 steps — governed by `getNextStep()` returning null when gender is 'male'
- Two routing bugs discovered and fixed during Playwright end-to-end verification (see Deviations)

## Task Commits

Each task was committed atomically:

1. **Task 1: OnboardingContext, useOnboardingFlow hook, and 5 onboarding screens** - `aa65e5c` (test) + `893452d` (feat)
2. **Task 2: Wire onboarding gate into root layout and app layout** - `c29b56b` (feat)
3. **Task 3: Checkpoint — end-to-end verification** — human verification (no code commit)
4. **Bug fix: Two routing bugs found during verification** - `28c4a63` (fix)

## Files Created/Modified

- `SundeeFundeeRN/src/onboarding/OnboardingContext.tsx` — In-memory draft accumulator with `completeOnboarding()` atomic save
- `SundeeFundeeRN/src/onboarding/useOnboardingFlow.ts` — Step navigation logic, gender-based cycle step skip, `getNextStep` / `getPreviousStep` / `getTotalSteps`
- `SundeeFundeeRN/src/onboarding/__tests__/OnboardingContext.test.tsx` — Tests for atomic save, draft initialization
- `SundeeFundeeRN/src/onboarding/__tests__/useOnboardingFlow.test.ts` — Tests for male skip, female path, null signals, step counts
- `SundeeFundeeRN/app/(onboarding)/_layout.tsx` — Route group layout wrapping children in OnboardingProvider
- `SundeeFundeeRN/app/(onboarding)/step-name.tsx` — TextInput screen with disabled Next until name entered
- `SundeeFundeeRN/app/(onboarding)/step-experience.tsx` — 3 option cards (Beginner/Intermediate/Advanced)
- `SundeeFundeeRN/app/(onboarding)/step-goal.tsx` — 5 option cards for primary training goal
- `SundeeFundeeRN/app/(onboarding)/step-gender.tsx` — 3 option cards; Male path calls completeOnboarding directly
- `SundeeFundeeRN/app/(onboarding)/step-cycle.tsx` — Toggle for cycle tracking opt-in; final step for female/other
- `SundeeFundeeRN/app/_layout.tsx` — Removed onboardingComplete state gate; Stack renders unconditionally
- `SundeeFundeeRN/app/(app)/_layout.tsx` — Switched to `getOnboardingProfileRepo` for hasCompletedOnboarding read

## Decisions Made

- Atomic save on final step only: accumulating draft in-memory and saving once prevents partial state from being persisted if user backs out mid-flow.
- `getNextStep()` returning `null` as a completion signal keeps navigation logic in one place — screens check for null before navigating and call `completeOnboarding()` accordingly.
- Route guard in `(app)/_layout.tsx` uses `getOnboardingProfileRepo(isGuest)` (not `LocalUserRepo`) to read `hasCompletedOnboarding` — the same factory that `OnboardingContext` writes to, ensuring both paths use the `@sundee/onboarding_profile` key in AsyncStorage.

## Deviations from Plan

### Auto-fixed Issues (Rule 1 — Bug fixes found during human verification)

**1. [Rule 1 - Bug] Root layout blank page when no user signed in**
- **Found during:** Task 3 (Playwright end-to-end verification)
- **Issue:** `app/_layout.tsx` gated the entire `<Stack>` render on `onboardingComplete !== null`. When no user was signed in, `handleUserSignIn` never fired, so `onboardingComplete` remained `null` forever, showing a blank CREAM view instead of the sign-in screen.
- **Fix:** Removed the `onboardingComplete` state and its splash gate from `app/_layout.tsx` entirely. The root layout now renders the Stack unconditionally; all routing decisions (auth check, onboarding check) are handled by `(app)/_layout.tsx`.
- **Files modified:** `SundeeFundeeRN/app/_layout.tsx`
- **Commit:** `28c4a63`

**2. [Rule 1 - Bug] Guest users looped back to onboarding after completing it**
- **Found during:** Task 3 (Playwright end-to-end verification)
- **Issue:** `OnboardingContext` saved the profile via `getOnboardingProfileRepo(isGuest)` → `LocalOnboardingProfileRepo` → key `@sundee/onboarding_profile`. But `(app)/_layout.tsx` read `hasCompletedOnboarding` from `LocalUserRepo` → key `@sundee/user_profile`. The two repos used different AsyncStorage keys, so the completion flag was never found on restart, causing an infinite redirect loop.
- **Fix:** Changed `(app)/_layout.tsx` to use `getOnboardingProfileRepo(isGuest)` for the `hasCompletedOnboarding` check — the same repo factory the write path uses.
- **Files modified:** `SundeeFundeeRN/app/(app)/_layout.tsx`
- **Commit:** `28c4a63`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in routing logic discovered via end-to-end verification)
**Impact on plan:** Both fixes required for correct guest onboarding. No scope creep.

## Issues Encountered

None beyond the two routing bugs documented above — both were caught and fixed during the human-verify checkpoint.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Onboarding flow fully wired end-to-end for both authenticated and guest users
- `hasCompletedOnboarding` flag is set in the correct storage location and read by the route guard
- `OnboardingProfile` data (name, experienceLevel, primaryGoal, gender, cycleOptIn) is available for Dashboard and settings screens in subsequent phases
- No blockers for Phase 4

---
*Phase: 03-data-layer-and-offline-architecture*
*Completed: 2026-03-14*

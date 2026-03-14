# Phase 3: Data Layer and Offline Architecture - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

All data access goes through typed repository interfaces; Firestore and AsyncStorage implementations are swappable; offline workout logging is guaranteed with no data loss. Includes onboarding flow (name, experience, goal, gender, cycle opt-in) with data persistence for both authenticated and guest users.

</domain>

<decisions>
## Implementation Decisions

### Onboarding flow design
- One question per screen with progress bar at top
- 5 steps matching iOS: name → experience level → primary goal → gender → cycle opt-in
- Cycle opt-in step shown for female + prefer-not-to-say genders; skipped for male users
- Back button on each step to revisit/change answers
- All data saved at once on final step completion (no partial persistence)
- Guests go through the same onboarding flow as authenticated users
- After completion, user lands directly on Dashboard tab
- Once completed, onboarding is never shown again (gated by hasCompletedOnboarding flag)

### Repository scope & contracts
- Build 4 repositories in Phase 3: OnboardingProfileRepo, WorkoutRepo (stub interface + implementations), SettingsRepo, ReadinessRepo (stub interface + implementations)
- Onboarding profile data extends the existing /users/{uid} Firestore document — no separate collection
- UserProfile interface expands to include: name, experienceLevel, primaryGoal, gender, cycleOptIn, hasCompletedOnboarding
- Factory function per repo (e.g., getWorkoutRepo(isGuest)) returns Firestore or AsyncStorage implementation based on auth state
- All repository interfaces use async/await with Promises — no real-time listeners in Phase 3

### Offline sync behavior
- Rely entirely on Firestore's built-in offline persistence (@react-native-firebase/firestore on native, enablePersistence on web)
- No custom offline queue layer — Firestore handles write queuing and sync automatically
- Guest data is inherently offline via AsyncStorage — no sync needed until account upgrade
- Offline status shown via existing OfflineBanner component only — no per-item sync indicators
- Conflict resolution: last-write-wins (Firestore's default merge behavior)

### Guest-to-auth data migration
- On guest sign-up: read all data from AsyncStorage, write to Firestore under new UID, then clear AsyncStorage
- If migration fails (e.g., network drop): keep local data intact, retry later — no data loss
- Migration UX: silent with loading spinner ("Setting up your account...") — no dedicated migration screen
- Guest upgrade is always a fresh account — no existing Firestore data to conflict with

### Claude's Discretion
- Exact Firestore document schema shapes for workout, settings, and readiness repos
- AsyncStorage key naming conventions
- Error handling patterns within repository implementations
- Integration test structure for Firebase emulator verification
- Whether to use Firestore batch writes during guest migration or sequential writes

</decisions>

<specifics>
## Specific Ideas

- iOS onboarding flow (OnboardingFlowView.swift) is the reference: 5 steps with OnboardingStep enum, OnboardingEligibilityEvaluator controls cycle step visibility
- The existing UserRepository + FirestoreUserRepo + LocalUserRepo pattern is the template for all new repositories
- WorkoutRepo and ReadinessRepo are "stubs" in the sense that their interfaces and implementations are built, but the UI that uses them comes in later phases
- ReadinessSurvey storage functions were explicitly deferred from Phase 2 domain layer to Phase 3 repository layer

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UserRepository` interface + `FirestoreUserRepo` + `LocalUserRepo`: established dual-implementation pattern to follow for all new repos
- `getFirestoreInstance()` in `firebase/firestore.ts`: platform-aware Firestore accessor (native vs web) — all repos must use this
- `OfflineBanner` component: already handles offline status display via NetInfo
- `AuthContext` / `SessionProvider`: provides auth state that repo factory functions will consume
- Domain types from Phase 2 (`src/domain/`): workout types, readiness survey types, etc. — repos will persist these

### Established Patterns
- Platform-specific file extensions (.native.ts / .web.ts) for platform branching — may be needed for AsyncStorage vs web localStorage
- Firestore merge writes: `set(data, { merge: true })` — used in FirestoreUserRepo, carry forward
- Jest mock infrastructure in `__mocks__/` — extend for new repo tests
- Kebab-case file names, barrel index.ts exports per directory

### Integration Points
- `AuthContext.isGuest` drives which repo implementation the factory returns
- Onboarding completion triggers `hasCompletedOnboarding` flag on user profile → `AppState` routing reads this to skip onboarding on subsequent launches
- WorkoutRepo interface must align with domain types from `src/domain/history/` and `src/domain/ai-workout/`
- ReadinessRepo interface must align with `src/domain/readiness/readiness-survey.ts`

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-data-layer-and-offline-architecture*
*Context gathered: 2026-03-14*

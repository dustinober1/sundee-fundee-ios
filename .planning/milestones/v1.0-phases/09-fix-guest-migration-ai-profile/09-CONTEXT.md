# Phase 9: Fix Guest Migration + AI Profile Wiring - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Close two audit gaps: (1) call migrateGuestDataToFirestore during guest-to-auth upgrade so AsyncStorage data is preserved in Firestore, and (2) replace hardcoded AI workout profile values with real user data. Requirements: AUTH-07, AIWK-02.

</domain>

<decisions>
## Implementation Decisions

### Migration trigger & UX
- Call `migrateGuestDataToFirestore` immediately after `linkWithCredential` succeeds in `useGuestSignIn.upgrade()`
- Reuse the existing `isLoading` spinner — no additional migration UI
- Migration only runs on anonymous → permanent upgrade (linkWithCredential path), NOT on fresh sign-in after guest session
- AsyncStorage key removal after success is sufficient idempotency — no extra migration-complete flag needed

### Migration data scope
- Expand MIGRATION_KEYS from 4 to all 12 AsyncStorage keys used by Local repos:
  - Original 4: `@sundee/onboarding_profile`, `@sundee/workouts`, `@sundee/settings`, `@sundee/readiness_surveys`
  - Add 8: `@sundee/exercise-maxes`, `@sundee/injuries`, `@sundee/pain_logs`, `@sundee/period_logs`, `@sundee/cycle_settings`, `@sundee/benchmark_results`, `@sundee/custom_benchmarks`, `@sundee/program_enrollment`, `@sundee/custom-exercises`
- Each key maps to the exact Firestore path its corresponding FirestoreXxxRepo reads from — data immediately visible after migration
- Handle Firestore 500-operation batch limit: split into multiple batches if needed, commit sequentially, only clear AsyncStorage after ALL batches succeed
- `multiRemove` clears all 12 keys unconditionally after successful migration

### AI profile fields — read from real user data
- Replace 4 hardcoded values in `ai-workout/config.tsx`:
  - `gender: 'female'` → `profile?.gender ?? 'female'`
  - `experienceLevel: 'intermediate'` → `profile?.experienceLevel ?? 'intermediate'`
  - `primaryGoal: 'general_fitness'` → `profile?.primaryGoal ?? 'general_fitness'`
  - `weightUnit: 'lb'` → `settings?.weightUnit ?? 'lb'`
- Also wire two additional context fields:
  - `maxes`: Read from ExerciseMaxRepo — pass all user exercise maxes
  - `recentWorkouts`: Read last 5 workouts from WorkoutRepo for training split awareness
- Fallback to current hardcoded values if profile or settings are null (same output as today for edge cases)

### Error handling on migration failure
- If migration throws, complete the upgrade anyway (linkWithCredential already succeeded)
- Set `@sundee/migration_pending` flag in AsyncStorage before migration attempt; clear on success
- On each app launch (in `_layout.tsx`), check for `migration_pending` flag and retry migration in background
- Claude's Discretion on retry limit (retry every launch with no limit vs capped retries)
- No user-facing migration status — fully transparent background operation

### Claude's Discretion
- Exact Firestore path mapping for each new AsyncStorage key (follow existing FirestoreXxxRepo patterns)
- Retry limit for failed migration (lean toward unlimited since each attempt is cheap)
- Whether to batch-read all 12 keys with a single multiGet or use individual getItem calls
- Test file organization for expanded migration + AI profile wiring

</decisions>

<specifics>
## Specific Ideas

- Follow the same pattern as existing migration.ts switch/case but add cases for each new key
- The profile is already fetched in `ai-workout/config.tsx` for `cycleOptIn` — reuse that same fetch for gender/experienceLevel/primaryGoal
- Settings repo call may already exist in config.tsx or can be added alongside profile fetch
- ExerciseMaxRepo.getMaxes() and WorkoutRepo.getHistory() are existing repo methods — no new interfaces needed

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `migrateGuestDataToFirestore` in `src/repositories/migration.ts`: Existing implementation with atomic batch + safe multiRemove — needs expansion, not rewrite
- `useGuestSignIn` in `src/auth/useGuestSignIn.ts`: `upgrade()` function is the integration point for calling migration
- `getOnboardingProfileRepo(isGuest)`: Already called in config.tsx for cycleOptIn — profile has gender, experienceLevel, primaryGoal
- `getSettingsRepo(isGuest)`: Returns settings with weightUnit
- `getExerciseMaxRepo(isGuest)`: Returns maxes via getMaxes()
- `getWorkoutRepo(isGuest)`: Returns history via getHistory()
- All 12 Local*Repo files define their AsyncStorage keys as constants

### Established Patterns
- Repository factory: `getXxxRepo(isGuest)` returns Firestore or AsyncStorage implementation
- Migration uses Firestore batch writes with `db.batch()` + `batch.set()` + `batch.commit()`
- Config screen loads adaptation context via `useFocusEffect` with async IIFE pattern
- Fallback pattern: `profile?.field ?? defaultValue` for graceful degradation

### Integration Points
- `useGuestSignIn.upgrade()`: Add migrateGuestDataToFirestore call after linkWithCredential
- `app/_layout.tsx`: Add migration retry check on app launch for pending migrations
- `ai-workout/config.tsx` lines 200-221: Replace hardcoded context values with profile/settings reads
- `src/repositories/migration.ts`: Expand MIGRATION_KEYS array and add switch cases for 8 new data types

</code_context>

<deferred>
## Deferred Ideas

- Wire bodyWeightKg, desiredSkills, benchmarkSummaries, workoutCompletionRate to AI context — future enhancement
- Settings screen migration status indicator — decided not needed
- Migration for users who sign out of guest and create fresh account (abandoned data) — out of scope

</deferred>

---

*Phase: 09-fix-guest-migration-ai-profile*
*Context gathered: 2026-03-15*

# Phase 9: Fix Guest Migration + AI Profile Wiring - Research

**Researched:** 2026-03-15
**Domain:** Firebase anonymous-to-permanent auth migration; AI workout context wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Call `migrateGuestDataToFirestore` immediately after `linkWithCredential` succeeds in `useGuestSignIn.upgrade()`
- Reuse the existing `isLoading` spinner — no additional migration UI
- Migration only runs on anonymous → permanent upgrade (linkWithCredential path), NOT on fresh sign-in after guest session
- AsyncStorage key removal after success is sufficient idempotency — no extra migration-complete flag needed
- Expand MIGRATION_KEYS from 4 to all 12 AsyncStorage keys:
  - Original 4: `@sundee/onboarding_profile`, `@sundee/workouts`, `@sundee/settings`, `@sundee/readiness_surveys`
  - Add 8: `@sundee/exercise-maxes`, `@sundee/injuries`, `@sundee/pain_logs`, `@sundee/period_logs`, `@sundee/cycle_settings`, `@sundee/benchmark_results`, `@sundee/custom_benchmarks`, `@sundee/program_enrollment`, `@sundee/custom-exercises`
- Each key maps to the exact Firestore path its corresponding FirestoreXxxRepo reads from — data immediately visible after migration
- Handle Firestore 500-operation batch limit: split into multiple batches if needed, commit sequentially, only clear AsyncStorage after ALL batches succeed
- `multiRemove` clears all 12 keys unconditionally after successful migration
- Replace 4 hardcoded values in `ai-workout/config.tsx`:
  - `gender: 'female'` → `profile?.gender ?? 'female'`
  - `experienceLevel: 'intermediate'` → `profile?.experienceLevel ?? 'intermediate'`
  - `primaryGoal: 'general_fitness'` → `profile?.primaryGoal ?? 'general_fitness'`
  - `weightUnit: 'lb'` → `settings?.weightUnit ?? 'lb'`
- Also wire two additional context fields:
  - `maxes`: Read from ExerciseMaxRepo — pass all user exercise maxes
  - `recentWorkouts`: Read last 5 workouts from WorkoutRepo for training split awareness
- Fallback to current hardcoded values if profile or settings are null
- If migration throws, complete the upgrade anyway (linkWithCredential already succeeded)
- Set `@sundee/migration_pending` flag in AsyncStorage before migration attempt; clear on success
- On each app launch (in `_layout.tsx`), check for `migration_pending` flag and retry migration in background
- No user-facing migration status — fully transparent background operation

### Claude's Discretion

- Exact Firestore path mapping for each new AsyncStorage key (follow existing FirestoreXxxRepo patterns)
- Retry limit for failed migration (lean toward unlimited since each attempt is cheap)
- Whether to batch-read all 12 keys with a single multiGet or use individual getItem calls
- Test file organization for expanded migration + AI profile wiring

### Deferred Ideas (OUT OF SCOPE)

- Wire bodyWeightKg, desiredSkills, benchmarkSummaries, workoutCompletionRate to AI context — future enhancement
- Settings screen migration status indicator
- Migration for users who sign out of guest and create fresh account (abandoned data)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-07 | User data syncs across devices when authenticated | Migration.ts expansion to 12 keys + linkWithCredential trigger + pending-flag retry ensures guest data reaches Firestore and becomes visible on all devices |
| AIWK-02 | AI incorporates cycle phase, injuries, and readiness into workout generation | Profile/settings/maxes/recentWorkouts wired into WorkoutGenerationContext in config.tsx replaces four hardcoded stub values so AI receives real user context |
</phase_requirements>

---

## Summary

Phase 9 closes two audit gaps that were always present but never wired: (1) the guest-to-auth upgrade path calls `linkWithCredential` but never calls `migrateGuestDataToFirestore`, so guest users who upgrade permanently lose all their local data, and (2) the AI workout config builds a `WorkoutGenerationContext` with four hardcoded profile values (`gender`, `experienceLevel`, `primaryGoal`, `weightUnit`) plus empty arrays for `maxes` and `recentWorkouts`, ignoring real user data that is already loaded or loadable via existing repo methods.

Both fixes are surgical. The migration expansion adds 8 switch-cases to `migration.ts` following the exact same pattern as the existing 4 cases, uses `multiGet` for the read phase (one round-trip), splits into multiple batches if the 500-op Firestore limit is approached, and wires the call into `useGuestSignIn.upgrade()` after the `linkWithCredential` call succeeds. A `@sundee/migration_pending` flag is set before each attempt and cleared on success; `_layout.tsx` checks this flag on every launch to retry silently in background. The AI profile wiring reuses the `profile` that `config.tsx` already fetches for `cycleOptIn` — it just reads `profile.gender`, `profile.experienceLevel`, and `profile.primaryGoal` from that same object instead of discarding it.

**Primary recommendation:** Treat both gaps as independent mini-features within one phase. Address migration.ts first (data correctness), then AI profile wiring (context quality). Both are low-risk because all the infrastructure (repos, batch API, profile fetch) is already in place.

---

## Standard Stack

### Core (all already installed — no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@react-native-async-storage/async-storage` | already installed | Read/clear guest data | Project standard for local persistence |
| `@react-native-firebase/firestore` | already installed | Batch write destination | Project standard Firestore SDK |
| `@react-native-firebase/auth` | already installed | `linkWithCredential` | Project standard auth SDK |

No new packages required for either gap. All repository interfaces (`getOnboardingProfileRepo`, `getSettingsRepo`, `getExerciseMaxRepo`, `getWorkoutRepo`) are already callable from `config.tsx`.

---

## Architecture Patterns

### Confirmed AsyncStorage Key Inventory (all 12)

Reading all Local*Repo files confirms the complete key set:

| AsyncStorage Key | Source File | Data Shape |
|-----------------|-------------|-----------|
| `@sundee/onboarding_profile` | `LocalOnboardingProfileRepo.ts` | `OnboardingProfile` object |
| `@sundee/settings` | `LocalSettingsRepo.ts` | `AppSettings` object |
| `@sundee/workouts` | `LocalWorkoutRepo.ts` | `WorkoutRecord[]` — each has `.id` |
| `@sundee/readiness_surveys` | `LocalReadinessRepo.ts` | `ReadinessSurveyRecord[]` — each has `.date` |
| `@sundee/exercise-maxes` | `LocalExerciseMaxRepo.ts` | `ExerciseMax[]` — each has `.exerciseId` + `.repRange` |
| `@sundee/injuries` | `LocalInjuryRepo.ts` | `InjuryProfileRecord[]` — each has `.id` |
| `@sundee/pain_logs` | `LocalInjuryRepo.ts` | `PainLogRecord[]` — each has `.id` + `.injuryId` |
| `@sundee/period_logs` | `LocalCycleRepo.ts` | `PeriodLogRecord[]` — each has `.id` |
| `@sundee/cycle_settings` | `LocalCycleRepo.ts` | `CycleSettings` object (single) |
| `@sundee/benchmark_results` | `LocalBenchmarkRepo.ts` | `BenchmarkResultRecord[]` — each has `.id` |
| `@sundee/custom_benchmarks` | `LocalBenchmarkRepo.ts` | `BenchmarkDefinition[]` — each has `.id` |
| `@sundee/program_enrollment` | `LocalProgramRepo.ts` | `ProgramEnrollment` object (single) |
| `@sundee/custom-exercises` | `LocalExerciseRepo.ts` | `Exercise[]` — each has `.id` |

Note: CONTEXT.md lists 12 keys but the actual count including `@sundee/custom-exercises` is 13. The CONTEXT.md list appears to include `@sundee/custom-exercises` as a 9th addition making it 13 total keys. The `multiRemove` call must include all 13.

### Confirmed Firestore Path Mappings

Reading all Firestore*Repo files confirms the exact destination paths:

| AsyncStorage Key | Firestore Path | Write Pattern |
|-----------------|---------------|---------------|
| `@sundee/onboarding_profile` | `/users/{uid}` | `batch.set(docRef, data, { merge: true })` |
| `@sundee/settings` | `/users/{uid}` | `batch.set(docRef, data, { merge: true })` |
| `@sundee/workouts` | `/users/{uid}/workouts/{workout.id}` | one doc per item |
| `@sundee/readiness_surveys` | `/users/{uid}/readiness/{survey.date}` | one doc per item |
| `@sundee/exercise-maxes` | `/users/{uid}/exerciseMaxes/{exerciseId}_{repRange}` | compositeId doc per item |
| `@sundee/injuries` | `/users/{uid}/injuries/{injury.id}` | one doc per item |
| `@sundee/pain_logs` | `/users/{uid}/injuries/{log.injuryId}/painLogs/{log.id}` | nested subcollection |
| `@sundee/period_logs` | `/users/{uid}/periodLogs/{log.id}` | one doc per item |
| `@sundee/cycle_settings` | `/users/{uid}/cycleSettings/settings` | single doc `set` |
| `@sundee/benchmark_results` | `/users/{uid}/benchmarkResults/{result.id}` | one doc per item |
| `@sundee/custom_benchmarks` | `/users/{uid}/customBenchmarks/{benchmark.id}` | one doc per item |
| `@sundee/program_enrollment` | `/users/{uid}/enrollment/active` | single doc `set` |
| `@sundee/custom-exercises` | `/users/{uid}/customExercises/{exercise.id}` | one doc per item |

Pain logs require nested doc references: `db.collection('users').doc(uid).collection('injuries').doc(log.injuryId).collection('painLogs').doc(log.id)`. Each nested doc still uses one batch operation slot.

### Pattern 1: Multi-Batch Migration (Firestore 500-op limit)

**What:** When migrating more than 500 documents, split operations into sequential batches of at most 499 operations each. Commit each batch before starting the next. Only clear AsyncStorage after ALL batches commit successfully.

**When to use:** Always — even though typical guest data is well under 500 ops, the code must handle the edge case without crashing.

**Implementation:**

```typescript
// Source: Firestore docs + existing migration.ts patterns
const MAX_BATCH_OPS = 499; // 1 buffer below the 500 limit

interface BatchOp {
  ref: FirebaseFirestore.DocumentReference;
  data: unknown;
  merge?: boolean;
}

async function commitInChunks(db: FirebaseFirestore.Firestore, ops: BatchOp[]): Promise<void> {
  for (let i = 0; i < ops.length; i += MAX_BATCH_OPS) {
    const chunk = ops.slice(i, i + MAX_BATCH_OPS);
    const batch = db.batch();
    for (const op of chunk) {
      if (op.merge) {
        batch.set(op.ref, op.data as Record<string, unknown>, { merge: true });
      } else {
        batch.set(op.ref, op.data as Record<string, unknown>);
      }
    }
    await batch.commit(); // throws on failure — caller handles
  }
}
```

AsyncStorage is cleared only after the outer `commitInChunks` call completes without throwing.

### Pattern 2: Migration Pending Flag + App Launch Retry

**What:** Set `@sundee/migration_pending` in AsyncStorage before calling `migrateGuestDataToFirestore`. Clear it on success. On each app launch, `_layout.tsx` checks for this flag and retries migration in background using the current auth user's uid.

**Key constraint:** The retry in `_layout.tsx` must only fire when the current user is NOT anonymous (i.e., the upgrade already succeeded in a prior session). If the user is still anonymous, there is no uid to migrate into.

```typescript
// In _layout.tsx handleUserSignIn (called by SessionProvider):
if (!user.isAnonymous) {
  // Check for pending migration from a previously interrupted upgrade
  void retryPendingMigration(user.uid);
}

async function retryPendingMigration(uid: string): Promise<void> {
  try {
    const pending = await AsyncStorage.getItem('@sundee/migration_pending');
    if (pending !== 'true') return;
    await migrateGuestDataToFirestore(uid);
    // migrateGuestDataToFirestore clears the flag on success
  } catch {
    // Retry will happen on next launch — silent failure
  }
}
```

**Retry limit decision:** Unlimited retries (each attempt is cheap, data is preserved in AsyncStorage until cleared, and the flag auto-clears on success). This matches the CONTEXT.md guidance.

### Pattern 3: multiGet for Read Phase

**What:** Use a single `AsyncStorage.multiGet([...ALL_KEYS])` call to read all 13 keys in one native bridge crossing rather than 13 individual `getItem` calls.

**Why:** `multiGet` reduces native bridge overhead by 10-13x for this operation, and the existing migration.ts already uses this pattern for the original 4 keys — extending it to 13 is the natural evolution.

```typescript
const pairs = await AsyncStorage.multiGet([...MIGRATION_KEYS]);
// Returns [[key, value | null], ...] for each key
// null values are skipped in the switch/case loop
```

### Pattern 4: AI Profile Wiring in config.tsx

**What:** The `loadAdaptationContext` callback already fetches `profile` from `getOnboardingProfileRepo(isGuest)`. It uses `profile?.cycleOptIn` to decide whether to load cycle data, then discards the profile object. The fix is to store `profile` in state and use it when building `WorkoutGenerationContext`.

**Current code (lines 131-175 of config.tsx):** Profile is fetched then immediately falls out of scope.

**Required state additions:**
```typescript
// Add alongside existing adaptation context state:
const [profile, setProfile] = useState<OnboardingProfile | null>(null);
const [settings, setSettings] = useState<AppSettings | null>(null);
const [userMaxes, setUserMaxes] = useState<ExerciseMax[]>([]);
const [recentWorkouts, setRecentWorkouts] = useState<WorkoutRecord[]>([]);
```

**loadAdaptationContext additions** — after the profile fetch, persist it:
```typescript
setProfile(profile);

// Load settings (parallel with existing loads)
const settingsRepo = getSettingsRepo(isGuest);
const userSettings = await settingsRepo.getSettings(uid);
setSettings(userSettings);

// Load exercise maxes
const maxRepo = getExerciseMaxRepo(isGuest);
const allMaxes = await maxRepo.getAllMaxes(uid);
setUserMaxes(allMaxes);

// Load last 5 workouts
const workoutRepo = getWorkoutRepo(isGuest);
const history = await workoutRepo.getHistory(uid, 5);
setRecentWorkouts(history);
```

**WorkoutGenerationContext construction** — replace hardcoded values (lines 200-221):
```typescript
const context: WorkoutGenerationContext = {
  // ...existing fields unchanged...
  maxes: userMaxes.map(m => ({ name: m.exerciseId, weightLb: m.weight })),
  recentWorkouts: recentWorkouts.slice(0, 5).map(w => ({
    date: new Date(w.completedAt),
    focus: w.focus ?? 'full_body',
    exercises: w.exercises?.map(e => e.name) ?? [],
    durationMinutes: w.durationMinutes ?? 0,
  })),
  experienceLevel: profile?.experienceLevel ?? 'intermediate',
  primaryGoal: profile?.primaryGoal ?? 'general_fitness',
  gender: profile?.gender ?? 'female',
  weightUnit: settings?.weightUnit ?? 'lb',
  // ...rest unchanged...
};
```

**Fallback guarantee:** `profile?.field ?? defaultValue` pattern means output is identical to today when profile is null. No regression risk.

### Anti-Patterns to Avoid

- **Clearing AsyncStorage before all batches commit:** If batch 2 of 3 fails, you've already lost the data batch 1 covered. Always clear only after the final batch succeeds.
- **Calling migrateGuestDataToFirestore on fresh sign-in:** Migration must ONLY run in the `linkWithCredential` path. A new email/Apple/Google sign-in (not an upgrade) has no AsyncStorage guest data worth migrating.
- **Blocking the upgrade on migration failure:** `linkWithCredential` has already succeeded. If migration throws, catch it, set the pending flag, and complete the upgrade — the user is now authenticated regardless.
- **Reading profile twice in config.tsx:** The profile is already fetched for `cycleOptIn`. Do not add a second `getOnboardingProfileRepo(isGuest).getProfile(uid)` call — save the result from the first call.
- **Using individual getItem calls for migration reads:** 13 separate bridge crossings vs. one `multiGet`. Always use `multiGet`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Batch size chunking | Custom batch management class | Simple loop with `slice(i, i + 499)` | Firestore batch API handles atomicity within each chunk; loop handles sequencing |
| Migration idempotency | Complex state machine | AsyncStorage key removal (already in place) + pending flag | Keys removed on success = natural idempotency; flag survives app kill |
| Profile data fetching | New hook or context | `getOnboardingProfileRepo(isGuest).getProfile(uid)` — already called in config.tsx | One repo call, one await, done |
| Retry logic | Exponential backoff or timer | Check flag in `handleUserSignIn` (already fires on each sign-in event) | App launches are the natural retry trigger |

---

## Common Pitfalls

### Pitfall 1: Pain Logs Require Nested Doc References

**What goes wrong:** `@sundee/pain_logs` is stored as a flat array in AsyncStorage but must be written to a nested subcollection `/users/{uid}/injuries/{injuryId}/painLogs/{logId}` in Firestore. If you treat it like a top-level subcollection (`/users/{uid}/painLogs/{logId}`), the data will not be visible to `FirestoreInjuryRepo.getPainLogs()` which queries the nested path.

**Why it happens:** Pain logs have an `injuryId` field but are stored flat locally (all pain logs in one array), while Firestore nests them under each injury doc.

**How to avoid:** In the `@sundee/pain_logs` switch case, iterate each log and construct the full nested path: `db.collection('users').doc(uid).collection('injuries').doc(log.injuryId).collection('painLogs').doc(log.id)`.

**Warning signs:** Pain log history shows empty after guest upgrade despite data existing locally.

### Pitfall 2: Exercise Maxes Use compositeId as Doc ID

**What goes wrong:** `FirestoreExerciseMaxRepo` uses `${exerciseId}_${repRange}` as the document ID. If migration writes each max with just `.id` (which may not exist on `ExerciseMax` type) or uses a generated UUID, `getMaxes()` will not find them via field-query-then-map.

**Why it happens:** `ExerciseMax` in the PR domain has `exerciseId`, `repRange`, `weight`, `estimated1RM`, `achievedAt` — but no `.id` field. The composite key is a Firestore-specific naming convention.

**How to avoid:** In the `@sundee/exercise-maxes` case, construct `compositeId = \`\${max.exerciseId}_\${max.repRange}\`` and use it as the doc ID: `db.collection('users').doc(uid).collection('exerciseMaxes').doc(compositeId)`.

### Pitfall 3: Cycle Settings and Program Enrollment Are Single-Doc, Not Arrays

**What goes wrong:** These two keys store a single JSON object, not an array. If you iterate over them expecting `Array<{ id: string }>` and call `.map()`, you'll get a runtime error or write no documents.

**Why it happens:** `@sundee/cycle_settings` → `CycleSettings` object. `@sundee/program_enrollment` → `ProgramEnrollment` object. Both are stored and read as single objects in their Local repos.

**How to avoid:** Handle these with a direct `batch.set(singleDocRef, data)` (not a loop). The doc ID for cycle settings is `'settings'`; for enrollment it is `'active'`.

### Pitfall 4: multiRemove Must Include All 13 Keys

**What goes wrong:** CONTEXT.md mentions "12 keys" but the actual LocalExerciseRepo adds `@sundee/custom-exercises` making the total 13. If `multiRemove` misses any key, the migration-pending flag clears but stale guest data remains in AsyncStorage.

**Why it happens:** Count discrepancy in CONTEXT.md vs. actual files.

**How to avoid:** Derive the `MIGRATION_KEYS` array directly from reading all Local*Repo files (confirmed above: 13 keys). Pass the same constant array to both `multiGet` and `multiRemove`.

### Pitfall 5: upgrade() Must Not Re-throw Migration Errors

**What goes wrong:** If `migrateGuestDataToFirestore` throws and `upgrade()` re-throws that error, the caller (sign-in screen) will display an error and the user will think the upgrade failed — but `linkWithCredential` already succeeded. The user is now authenticated.

**Why it happens:** The natural pattern `try { await migrate() } catch (e) { throw e }` propagates the error.

**How to avoid:** Wrap the migration call in a separate try/catch that catches, sets the pending flag, and does NOT re-throw:

```typescript
try {
  await AsyncStorage.setItem('@sundee/migration_pending', 'true');
  await migrateGuestDataToFirestore(uid);
  // migrateGuestDataToFirestore clears @sundee/migration_pending via multiRemove
} catch (migrationError) {
  console.warn('[upgrade] Migration failed — will retry on next launch:', migrationError);
  // Do NOT re-throw — linkWithCredential already succeeded
}
```

### Pitfall 6: useGuestSignIn.upgrade() Currently Ignores the uid After linkWithCredential

**What goes wrong:** The current `upgrade()` implementation calls `linkWithCredential(currentUser, credential)` and returns the result but never extracts the uid. The migration call needs the authenticated uid from the upgraded user, not the old anonymous uid.

**Why it happens:** The anonymous UID and the upgraded UID are the same after `linkWithCredential` (this is the point of account linking). However, it's safer to read `result.user.uid` from the `linkWithCredential` result to be explicit.

**How to avoid:** The existing anonymous UID persists through `linkWithCredential` — Firebase preserves it. Reading `getCurrentUser()?.uid` after `linkWithCredential` returns the same uid that was already in use. Either `currentUser.uid` before the call or `result.user.uid` after are equivalent.

### Pitfall 7: handleGenerateWorkout Dependency Array Must Include New State

**What goes wrong:** The `useCallback` for `handleGenerateWorkout` in config.tsx has a dependency array. Adding `profile`, `settings`, `userMaxes`, and `recentWorkouts` state vars without adding them to that array means stale values get captured.

**Why it happens:** React's `useCallback` captures references at creation time.

**How to avoid:** Add all new state variables to the `useCallback` dependency array at line 258 of config.tsx.

---

## Code Examples

### Migration.ts Expansion (complete new switch cases)

```typescript
// Source: confirmed from FirestoreExerciseMaxRepo.ts, FirestoreInjuryRepo.ts,
//         FirestoreCycleRepo.ts, FirestoreBenchmarkRepo.ts, FirestoreProgramRepo.ts,
//         FirestoreExerciseRepo.ts

case '@sundee/exercise-maxes': {
  const maxes = data as Array<{ exerciseId: string; repRange: string }>;
  for (const max of maxes) {
    const compositeId = `${max.exerciseId}_${max.repRange}`;
    const docRef = db.collection('users').doc(uid).collection('exerciseMaxes').doc(compositeId);
    ops.push({ ref: docRef, data: max });
  }
  break;
}

case '@sundee/injuries': {
  const injuries = data as Array<{ id: string }>;
  for (const injury of injuries) {
    const docRef = db.collection('users').doc(uid).collection('injuries').doc(injury.id);
    ops.push({ ref: docRef, data: injury });
  }
  break;
}

case '@sundee/pain_logs': {
  const painLogs = data as Array<{ id: string; injuryId: string }>;
  for (const log of painLogs) {
    const docRef = db
      .collection('users').doc(uid)
      .collection('injuries').doc(log.injuryId)
      .collection('painLogs').doc(log.id);
    ops.push({ ref: docRef, data: log });
  }
  break;
}

case '@sundee/period_logs': {
  const logs = data as Array<{ id: string }>;
  for (const log of logs) {
    const docRef = db.collection('users').doc(uid).collection('periodLogs').doc(log.id);
    ops.push({ ref: docRef, data: log });
  }
  break;
}

case '@sundee/cycle_settings': {
  // Single object, not array
  const docRef = db.collection('users').doc(uid).collection('cycleSettings').doc('settings');
  ops.push({ ref: docRef, data });
  break;
}

case '@sundee/benchmark_results': {
  const results = data as Array<{ id: string }>;
  for (const result of results) {
    const docRef = db.collection('users').doc(uid).collection('benchmarkResults').doc(result.id);
    ops.push({ ref: docRef, data: result });
  }
  break;
}

case '@sundee/custom_benchmarks': {
  const benchmarks = data as Array<{ id: string }>;
  for (const b of benchmarks) {
    const docRef = db.collection('users').doc(uid).collection('customBenchmarks').doc(b.id);
    ops.push({ ref: docRef, data: b });
  }
  break;
}

case '@sundee/program_enrollment': {
  // Single object, not array
  const docRef = db.collection('users').doc(uid).collection('enrollment').doc('active');
  ops.push({ ref: docRef, data });
  break;
}

case '@sundee/custom-exercises': {
  const exercises = data as Array<{ id: string }>;
  for (const exercise of exercises) {
    const docRef = db.collection('users').doc(uid).collection('customExercises').doc(exercise.id);
    ops.push({ ref: docRef, data: exercise });
  }
  break;
}
```

Note: The refactored migration.ts collects all ops into an array first, then calls `commitInChunks`. This is cleaner than building a single batch and is required for the 500-op limit handling.

### useGuestSignIn.upgrade() Integration Point

```typescript
// In upgrade() after linkWithCredential succeeds:
const result = await linkWithCredential(currentUser, credential);

// Migrate guest data — non-blocking, upgrade complete regardless
const { migrateGuestDataToFirestore } = await import('../repositories/migration');
try {
  await AsyncStorage.setItem('@sundee/migration_pending', 'true');
  await migrateGuestDataToFirestore(currentUser.uid);
  // migration.ts clears the pending flag via multiRemove
} catch (migrationError) {
  console.warn('[upgrade] Migration deferred:', migrationError);
  // Pending flag remains — _layout.tsx retries on next launch
}

return result;
```

### _layout.tsx Migration Retry

```typescript
// In handleUserSignIn, after profile persistence:
if (!user.isAnonymous) {
  void retryPendingMigration(user.uid);
}

async function retryPendingMigration(uid: string): Promise<void> {
  try {
    const pending = await AsyncStorage.getItem('@sundee/migration_pending');
    if (pending !== 'true') return;
    const { migrateGuestDataToFirestore } = await import('./src/repositories/migration');
    await migrateGuestDataToFirestore(uid);
  } catch {
    // Silent — retry on next launch
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Single Firestore batch for all operations | Multiple sequential batches with 499-op chunks | Required for guests with large datasets; no regression for small datasets |
| `multiGet` on 4 keys | `multiGet` on 13 keys | One round-trip regardless of key count |
| Hardcoded `gender: 'female'` etc. in AI context | `profile?.gender ?? 'female'` from real user data | AI workout quality improvement for all users |
| Profile fetched for `cycleOptIn` then discarded | Profile saved in state and reused for AI context | Zero extra async calls |

---

## Open Questions

1. **ExerciseMax.weight field name**
   - What we know: `WorkoutGenerationContext.ExerciseMax` has `{ name: string; weightLb: number }` while `domain/pr-detection/pr-types.ExerciseMax` has `{ exerciseId, repRange, weight, ... }`
   - What's unclear: The mapping `name: max.exerciseId, weightLb: max.weight` assumes `weight` is in lbs. If the user has kg units, the AI receives kg values labeled as lbs.
   - Recommendation: Use `name: max.exerciseId, weightLb: max.weight` for now. The AI context field is `weightLb` and the existing domain stores weight without unit. This is a pre-existing ambiguity — document it but do not fix in this phase (deferred per CONTEXT.md).

2. **WorkoutRecord.focus and WorkoutRecord.exercises field availability**
   - What we know: `WorkoutRecord` is defined in `WorkoutRepo.ts` but not read in this research session
   - What's unclear: Whether `WorkoutRecord` has a `focus` field and an `exercises` array with `.name` strings for the `recentWorkouts` mapping
   - Recommendation: Read `WorkoutRepo.ts` during planning and adapt the mapping accordingly. Use safe optional chaining: `w.focus ?? 'full_body'` and `w.exercises?.map(e => e.name) ?? []`.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Jest (jest-expo) |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest src/repositories/__tests__/migration.test.ts --no-coverage` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-07 | All 13 keys migrate to correct Firestore paths | unit | `npx jest migration.test.ts -t "migrates"` | Partial ✅ (4 cases exist, 9 new) |
| AUTH-07 | Batch splits at 499 ops, all batches commit sequentially | unit | `npx jest migration.test.ts -t "batch"` | ❌ Wave 0 |
| AUTH-07 | AsyncStorage cleared only after all batches succeed | unit | `npx jest migration.test.ts -t "clears"` | ✅ (pattern exists) |
| AUTH-07 | migration_pending flag set before attempt, cleared on success | unit | `npx jest migration.test.ts -t "pending"` | ❌ Wave 0 |
| AUTH-07 | upgrade() calls migrateGuestDataToFirestore after linkWithCredential | unit | `npx jest useGuestSignIn.test.ts -t "upgrade"` | Partial ✅ (upgrade called, migration not asserted) |
| AUTH-07 | _layout.tsx retries migration when pending flag is set for non-anonymous user | unit | `npx jest -- -t "retryPendingMigration"` | ❌ Wave 0 |
| AIWK-02 | profile.gender/experienceLevel/primaryGoal flow into context | unit | `npx jest config.test.tsx -t "profile"` | ❌ Wave 0 |
| AIWK-02 | settings.weightUnit flows into context | unit | `npx jest config.test.tsx -t "weightUnit"` | ❌ Wave 0 |
| AIWK-02 | exercise maxes mapped to ExerciseMax[] in context | unit | `npx jest config.test.tsx -t "maxes"` | ❌ Wave 0 |
| AIWK-02 | last 5 workouts mapped to recentWorkouts in context | unit | `npx jest config.test.tsx -t "recentWorkouts"` | ❌ Wave 0 |
| AIWK-02 | hardcoded fallback values used when profile is null | unit | `npx jest config.test.tsx -t "fallback"` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd SundeeFundeeRN && npx jest src/repositories/__tests__/migration.test.ts src/auth/__tests__/useGuestSignIn.test.ts --no-coverage`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `SundeeFundeeRN/src/repositories/__tests__/migration.test.ts` — add cases for all 9 new key types, batch-split behavior, pending flag lifecycle
- [ ] `SundeeFundeeRN/src/auth/__tests__/useGuestSignIn.test.ts` — add assertion that migration is called after upgrade, pending flag is set before, upgrade succeeds even when migration throws
- [ ] `SundeeFundeeRN/app/(app)/ai-workout/__tests__/config.test.tsx` — new file covering profile/settings/maxes/recentWorkouts wiring and fallback behavior

---

## Sources

### Primary (HIGH confidence)

- Direct codebase reading — all files read via Read tool on 2026-03-15
  - `SundeeFundeeRN/src/repositories/migration.ts` — existing 4-key implementation
  - `SundeeFundeeRN/src/auth/useGuestSignIn.ts` — integration point
  - `SundeeFundeeRN/app/(app)/ai-workout/config.tsx` — hardcoded values confirmed at lines 206-214
  - All `Local*Repo.ts` files — all 13 AsyncStorage key constants confirmed
  - All `Firestore*Repo.ts` files — all Firestore collection/document paths confirmed
  - `SundeeFundeeRN/src/domain/ai-workout/workout-generation-context.ts` — `WorkoutGenerationContext` type confirmed
  - `SundeeFundeeRN/src/repositories/OnboardingProfileRepo.ts` — `OnboardingProfile` interface with `gender`, `experienceLevel`, `primaryGoal`

### Secondary (MEDIUM confidence)

- Firebase official documentation (Firestore batch limit = 500 ops) — confirmed via WebSearch citing [Firebase Firestore transactions docs](https://firebase.google.com/docs/firestore/manage-data/transactions)
- AsyncStorage `multiGet` performance benefit vs individual calls — [react-native-async-storage docs](https://github.com/invertase/react-native-async-storage/blob/master/docs/API.md) confirms batch operations reduce native bridge overhead
- Firebase anonymous auth account linking behavior (UID preserved) — [Firebase anonymous auth docs](https://firebase.google.com/docs/auth/web/account-linking)

### Tertiary (LOW confidence)

- None — all key findings are verified by direct codebase reading

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed no new packages needed; all repos and APIs are already in use
- Architecture: HIGH — all Firestore paths read directly from source repos; all AsyncStorage keys confirmed from source repos
- Pitfalls: HIGH — each pitfall is based on concrete data shape mismatches found in the code (nested pain_logs subcollection, composite exerciseMax key, single-doc cycle_settings/enrollment)
- AI profile wiring: HIGH — exact lines in config.tsx identified; existing profile fetch reuse confirmed

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable — no new dependencies, internal codebase only)

# Phase 3: Data Layer and Offline Architecture - Research

**Researched:** 2026-03-14
**Domain:** Repository pattern, Firestore offline persistence, AsyncStorage, onboarding flow routing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Onboarding flow design**
- One question per screen with progress bar at top
- 5 steps matching iOS: name → experience level → primary goal → gender → cycle opt-in
- Cycle opt-in step shown for female + prefer-not-to-say genders; skipped for male users
- Back button on each step to revisit/change answers
- All data saved at once on final step completion (no partial persistence)
- Guests go through the same onboarding flow as authenticated users
- After completion, user lands directly on Dashboard tab
- Once completed, onboarding is never shown again (gated by hasCompletedOnboarding flag)

**Repository scope and contracts**
- Build 4 repositories in Phase 3: OnboardingProfileRepo, WorkoutRepo (stub interface + implementations), SettingsRepo, ReadinessRepo (stub interface + implementations)
- Onboarding profile data extends the existing /users/{uid} Firestore document — no separate collection
- UserProfile interface expands to include: name, experienceLevel, primaryGoal, gender, cycleOptIn, hasCompletedOnboarding
- Factory function per repo (e.g., getWorkoutRepo(isGuest)) returns Firestore or AsyncStorage implementation based on auth state
- All repository interfaces use async/await with Promises — no real-time listeners in Phase 3

**Offline sync behavior**
- Rely entirely on Firestore's built-in offline persistence (@react-native-firebase/firestore on native, enablePersistence on web)
- No custom offline queue layer — Firestore handles write queuing and sync automatically
- Guest data is inherently offline via AsyncStorage — no sync needed until account upgrade
- Offline status shown via existing OfflineBanner component only — no per-item sync indicators
- Conflict resolution: last-write-wins (Firestore's default merge behavior)

**Guest-to-auth data migration**
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ONBD-01 | User completes profile setup (name, experience level, goal, gender) | Expanding UserProfile interface + OnboardingProfileRepo backed by Firestore/AsyncStorage |
| ONBD-02 | User can opt into cycle tracking during onboarding | cycleOptIn boolean field on UserProfile; conditional step rendering in onboarding screens |
| ONBD-03 | Onboarding steps adapt based on user selections (e.g., skip cycle for male users) | Stack.Protected guard pattern in Expo Router v5 / manual step-skip logic in onboarding flow |
| WORK-11 | All workout logging works offline without data loss | Firestore offline persistence (enabled by default in @react-native-firebase/firestore v23); stub WorkoutRepo interface built here |
| AUTH-07 | User data syncs across devices when authenticated | Firestore offline persistence + write queuing handles sync automatically; UserProfile extended fields persist to /users/{uid} |
</phase_requirements>

---

## Summary

Phase 3 is fundamentally a pattern-replication phase. The project already has a proven repository dual-implementation pattern (FirestoreUserRepo / LocalUserRepo satisfying UserRepository). All four new repositories (OnboardingProfileRepo, WorkoutRepo, SettingsRepo, ReadinessRepo) follow the same structure: a TypeScript interface file, a Firestore class, a LocalStorage class, and a factory function. No new infrastructure libraries are needed.

The biggest decision area is onboarding routing. Expo Router SDK 55 ships `Stack.Protected` with a `guard` boolean prop, which is the canonical way to gate onboarding screens. The `hasCompletedOnboarding` field on UserProfile drives the guard. Because all profile data is saved at once on the final step, persistence is a single Firestore set (or AsyncStorage write) at completion, not incremental.

Offline guarantee (WORK-11) is satisfied entirely by `@react-native-firebase/firestore`, which enables offline persistence by default on native. No custom queue is needed. On web, the Firebase JS SDK requires `enableIndexedDbPersistence()` called once before any Firestore reads/writes — this belongs in `firestore.ts`'s web branch.

**Primary recommendation:** Expand UserProfile in UserRepository.ts, add the four new repos following the established Firestore/Local dual pattern, implement onboarding screens with Stack.Protected routing, and enable Firestore web persistence in firestore.ts. No new dependencies required.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @react-native-firebase/firestore | ^23.8.8 (already installed) | Authenticated user persistence with offline write queuing | Native SDK; offline persistence ON by default; no extra setup |
| @react-native-async-storage/async-storage | 2.2.0 (already installed) | Guest user local persistence | Established in Phase 1; LocalUserRepo template already uses it |
| expo-router | ~55.0.5 (already installed) | Onboarding flow routing with Stack.Protected guard | SDK 55 ships Stack.Protected — no Redirect workarounds needed |
| firebase (JS SDK) | ^12.10.0 (already installed) | Web-platform Firestore | Already in firestore.ts web branch; needs enableIndexedDbPersistence added |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| expo-network | ~55.0.8 (already installed) | Online/offline detection for OfflineBanner | Already wired in OfflineBanner component; no new usage in repos |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Firestore native offline persistence | Custom queue (e.g., react-native-offline) | Custom queue adds complexity with no benefit — Firestore already queues writes natively |
| Stack.Protected (Expo Router v5) | Redirect component with useEffect | Stack.Protected is declarative and handles back-press correctly; Redirect works but requires useEffect workaround (already noted in STATE.md) |
| Firestore batch writes (migration) | Sequential async writes | Batch writes are atomic and offline-safe; sequential writes risk partial state if interrupted mid-migration |

**Installation:** No new packages required. All libraries are already installed.

---

## Architecture Patterns

### Recommended Project Structure
```
src/
├── repositories/
│   ├── UserRepository.ts              # EXPAND: add onboarding fields to UserProfile
│   ├── FirestoreUserRepo.ts           # EXISTING: update createOrUpdateUser signature
│   ├── LocalUserRepo.ts               # EXISTING: update createOrUpdateUser signature
│   ├── OnboardingProfileRepo.ts       # NEW: interface + factory function
│   ├── FirestoreOnboardingProfileRepo.ts  # NEW
│   ├── LocalOnboardingProfileRepo.ts      # NEW
│   ├── WorkoutRepo.ts                 # NEW: interface + factory function (stub for Phase 4 UI)
│   ├── FirestoreWorkoutRepo.ts        # NEW: interface-complete stub
│   ├── LocalWorkoutRepo.ts            # NEW: interface-complete stub
│   ├── SettingsRepo.ts                # NEW: interface + factory function
│   ├── FirestoreSettingsRepo.ts       # NEW
│   ├── LocalSettingsRepo.ts           # NEW
│   ├── ReadinessRepo.ts               # NEW: interface + factory function
│   ├── FirestoreReadinessRepo.ts      # NEW
│   ├── LocalReadinessRepo.ts          # NEW
│   └── index.ts                       # NEW: barrel
├── firebase/
│   └── firestore.ts                   # UPDATE: add enableIndexedDbPersistence for web
└── app/
    ├── _layout.tsx                    # UPDATE: add onboarding gate logic
    ├── (onboarding)/
    │   ├── _layout.tsx                # NEW: Stack.Protected guard={!hasCompletedOnboarding}
    │   ├── step-name.tsx              # NEW
    │   ├── step-experience.tsx        # NEW
    │   ├── step-goal.tsx              # NEW
    │   ├── step-gender.tsx            # NEW
    │   └── step-cycle.tsx             # NEW: only rendered for female/other gender
    └── (app)/
        └── _layout.tsx                # UPDATE: add hasCompletedOnboarding check
```

### Pattern 1: Dual-Implementation Repository (established)
**What:** Interface file defines the contract; FirestoreXxxRepo implements for auth users; LocalXxxRepo implements for guests; factory function selects at runtime.
**When to use:** Every data domain in this phase.
**Example:**
```typescript
// OnboardingProfileRepo.ts
import { FirestoreOnboardingProfileRepo } from './FirestoreOnboardingProfileRepo';
import { LocalOnboardingProfileRepo } from './LocalOnboardingProfileRepo';

export interface OnboardingProfile {
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
  gender: Gender;
  cycleOptIn: boolean;
  hasCompletedOnboarding: boolean;
}

export interface OnboardingProfileRepository {
  saveProfile(uid: string, profile: OnboardingProfile): Promise<void>;
  getProfile(uid: string): Promise<OnboardingProfile | null>;
}

export function getOnboardingProfileRepo(isGuest: boolean): OnboardingProfileRepository {
  return isGuest
    ? new LocalOnboardingProfileRepo()
    : new FirestoreOnboardingProfileRepo();
}
```

### Pattern 2: Firestore Implementation (merge semantics)
**What:** Use `set(data, { merge: true })` to avoid overwriting unrelated fields in /users/{uid}.
**When to use:** All FirestoreXxxRepo implementations. Onboarding data extends /users/{uid}, not a separate collection.
**Example:**
```typescript
// FirestoreOnboardingProfileRepo.ts
// Source: established pattern in FirestoreUserRepo.ts
async saveProfile(uid: string, profile: OnboardingProfile): Promise<void> {
  const db = getFirestoreInstance();
  await db
    .collection('users')
    .doc(uid)
    .set(profile, { merge: true });
}
```

### Pattern 3: AsyncStorage Key Namespacing
**What:** Prefix all keys with `@sundee/` namespace to avoid collisions. Sub-namespace by domain.
**When to use:** All LocalXxxRepo implementations.
**Example:**
```typescript
// LocalOnboardingProfileRepo.ts
const ONBOARDING_KEY = '@sundee/onboarding_profile';

// LocalWorkoutRepo.ts
const WORKOUTS_KEY = '@sundee/workouts';

// LocalSettingsRepo.ts
const SETTINGS_KEY = '@sundee/settings';

// LocalReadinessRepo.ts
const READINESS_KEY = '@sundee/readiness_surveys';
```

### Pattern 4: Stack.Protected Onboarding Gate
**What:** Use Expo Router v5 Stack.Protected with guard prop. Guard evaluates hasCompletedOnboarding from UserProfile.
**When to use:** Root layout to route between onboarding and main app.
**Example:**
```typescript
// app/_layout.tsx (updated)
// hasCompletedOnboarding loaded from repo on auth state change
<Stack>
  <Stack.Protected guard={!hasCompletedOnboarding}>
    <Stack.Screen name="(onboarding)" options={{ headerShown: false }} />
  </Stack.Protected>
  <Stack.Protected guard={hasCompletedOnboarding}>
    <Stack.Screen name="(app)" options={{ headerShown: false }} />
  </Stack.Protected>
  <Stack.Screen name="sign-in" options={{ headerShown: false }} />
  <Stack.Screen name="verify-email" options={{ headerShown: false }} />
</Stack>
```

### Pattern 5: Guest Migration (batch writes)
**What:** On guest-to-auth upgrade, read all AsyncStorage keys, write to Firestore in a single batch, then clear AsyncStorage.
**When to use:** Guest sign-up flow (Phase 4+ feature, but migration helper lives in repositories).
**Example:**
```typescript
// repositories/migration.ts
export async function migrateGuestDataToFirestore(uid: string): Promise<void> {
  const db = getFirestoreInstance();
  const batch = db.batch();

  const profileRaw = await AsyncStorage.getItem('@sundee/onboarding_profile');
  if (profileRaw) {
    const profile = JSON.parse(profileRaw);
    batch.set(db.collection('users').doc(uid), profile, { merge: true });
  }

  const workoutsRaw = await AsyncStorage.getItem('@sundee/workouts');
  if (workoutsRaw) {
    const workouts: WorkoutRecord[] = JSON.parse(workoutsRaw);
    for (const w of workouts) {
      batch.set(db.collection('users').doc(uid).collection('workouts').doc(w.id), w);
    }
  }

  await batch.commit();
  await AsyncStorage.multiRemove(['@sundee/onboarding_profile', '@sundee/workouts', '@sundee/settings', '@sundee/readiness_surveys']);
}
```

### Pattern 6: Firestore Web Persistence (one-time setup)
**What:** The web Firestore branch in firestore.ts must call enableIndexedDbPersistence before any reads/writes.
**When to use:** Web platform only. Already handled by native SDK automatically.
**Example:**
```typescript
// firebase/firestore.ts — web branch update
import { enableIndexedDbPersistence } from 'firebase/firestore';

// After getFirestore(app), call once:
try {
  await enableIndexedDbPersistence(firestoreInstance);
} catch (err: unknown) {
  if ((err as { code?: string }).code === 'failed-precondition') {
    // Multiple tabs open — persistence available in one tab only
    console.warn('[Firestore] Persistence failed: multiple tabs open');
  }
  // 'unimplemented' = browser does not support IndexedDB — fail silently
}
```

### Pattern 7: Onboarding Step Navigation (multi-step linear flow)
**What:** Each step is a separate route in (onboarding)/. State accumulated in-memory via a hook or context until the final save on completion.
**When to use:** The 5-step onboarding sequence. No AsyncStorage writes mid-flow.
**Example:**
```typescript
// app/(onboarding)/OnboardingContext.tsx
interface OnboardingDraft {
  name: string;
  experienceLevel: ExperienceLevel | null;
  primaryGoal: PrimaryGoal | null;
  gender: Gender | null;
  cycleOptIn: boolean;
}

// Persisted all at once on step-cycle complete (or step-goal for male users):
const repo = getOnboardingProfileRepo(isGuest);
await repo.saveProfile(uid, { ...draft, hasCompletedOnboarding: true });
```

### Anti-Patterns to Avoid
- **Saving onboarding data per step:** The locked decision requires atomic save on completion. Per-step saves create inconsistent partial state in Firestore.
- **Direct AsyncStorage in components:** Always go through a LocalXxxRepo — keeps the factory abstraction intact and makes tests straightforward.
- **Real-time listeners on repositories:** Locked decision: async/await Promises only in Phase 3. No onSnapshot.
- **Import @react-native-firebase/firestore directly in feature code:** Always use `getFirestoreInstance()` from `src/firebase/firestore.ts`. Established pattern from Phase 1.
- **Partial guest migration:** If batch.commit() fails, do NOT clear AsyncStorage. Keep local data intact and surface an error for retry.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Offline write queuing | Custom queue with NetInfo + retry | Firestore native offline persistence | Firestore handles queueing, ordering, deduplication, and retry automatically |
| Conflict resolution | Custom merge logic | Firestore `{ merge: true }` | Last-write-wins merge is the locked decision; Firestore implements it correctly |
| Local persistence encryption | Custom encryption layer | None needed in Phase 3 | AsyncStorage is plain text; account-level data (name, goals) is low-sensitivity. Encryption is a v2 concern. |
| Multi-step form state management | Redux / Zustand | React context + useState | Onboarding is a linear, ephemeral, single-session flow. Context is sufficient and avoids adding a state management library. |
| Onboarding step routing guards | Custom useEffect redirect | Stack.Protected (Expo Router v5) | Stack.Protected handles back-press and transition correctly; already available in expo-router ~55.0.5 |
| Batch size management for migration | Chunking logic | Keep total < 500 operations | Onboarding profile + workouts + settings + readiness for a new guest user will be well under 500 documents. No chunking needed. |

**Key insight:** The entire offline guarantee is built into the native Firebase SDK. The repository layer's job is to route to the right storage engine, not to implement reliability primitives.

---

## Common Pitfalls

### Pitfall 1: Firestore Web Persistence Not Enabled
**What goes wrong:** Web users lose locally queued writes when the tab is closed while offline.
**Why it happens:** `enableIndexedDbPersistence()` is not called by default in the Firebase JS SDK (unlike native SDK which is always-on).
**How to avoid:** Add the `enableIndexedDbPersistence` call to the web branch of `getFirestoreInstance()` in `firebase/firestore.ts`. Must be called before any Firestore read/write.
**Warning signs:** Web smoke tests lose data after offline simulation; firestore.ts web branch has no persistence call.

### Pitfall 2: UserProfile Interface Drift
**What goes wrong:** FirestoreUserRepo and LocalUserRepo are updated with new onboarding fields but the TypeScript interface is not, or vice versa. Partial data written to Firestore.
**Why it happens:** UserProfile in UserRepository.ts is the single source of truth; it's easy to add fields to implementations and forget the interface.
**How to avoid:** Expand UserProfile in UserRepository.ts first. TypeScript will catch implementation divergence at compile time because both repos implement UserRepository.
**Warning signs:** TypeScript errors on `createOrUpdateUser` call sites; `hasCompletedOnboarding` missing from Firestore documents.

### Pitfall 3: Onboarding Re-shown After Completion
**What goes wrong:** User completes onboarding, but Stack.Protected re-routes them back to onboarding on next launch.
**Why it happens:** `hasCompletedOnboarding` is read from UserProfile, but the profile is not loaded before the Stack.Protected guard evaluates. Default value `false` sends user to onboarding.
**How to avoid:** Show a loading state (null return / splash) until user profile is loaded from repo. Only evaluate Stack.Protected guard once profile is known. Set initial state to `null` (unknown), not `false`.
**Warning signs:** "Onboarding flicker" — dashboard briefly visible before redirect to onboarding.

### Pitfall 4: Guest Migration Partial Write
**What goes wrong:** Network drops mid-migration. Some Firestore documents written, AsyncStorage cleared. Data lost.
**Why it happens:** Clear AsyncStorage called before confirming batch.commit() resolved successfully.
**How to avoid:** Always clear AsyncStorage in the `then()` callback after `await batch.commit()` resolves. If commit throws, catch and keep AsyncStorage intact.
**Warning signs:** "Setting up your account..." spinner visible, followed by empty history after sign-up.

### Pitfall 5: Cycle Step Shown for Male Users
**What goes wrong:** Male-identified users see the cycle opt-in step.
**Why it happens:** Step-skip logic omitted from onboarding navigator.
**How to avoid:** In the onboarding context/navigator, check `draft.gender === 'male'` after the gender step. Skip step-cycle and go directly to save. Stack.Protected guard is not needed here — step-skip is in-flow navigation, not route-level protection.
**Warning signs:** Integration test for ONBD-03 fails; manual test shows cycle step for male users.

### Pitfall 6: AsyncStorage multiGet Returns Sparse Array
**What goes wrong:** Migration reads `multiGet(['@sundee/workouts', '@sundee/settings'])` but guest never logged a workout — the key is null. JSON.parse(null) throws.
**Why it happens:** AsyncStorage.multiGet returns `[key, null]` pairs for missing keys.
**How to avoid:** Always null-check the value before parsing: `const raw = pairs[0][1]; if (raw) { ... }`.
**Warning signs:** Migration throws "JSON.parse: unexpected token 'n'" in error logs.

### Pitfall 7: @react-native-firebase/firestore Imported Directly in Tests
**What goes wrong:** Tests that import repository files fail because the native module tries to initialize.
**Why it happens:** The existing mock in `__mocks__/@react-native-firebase/firestore.ts` must be loaded via Jest automock; direct imports bypass it.
**How to avoid:** No action needed — Jest automock is already configured in the project. Follow the established pattern from FirestoreUserRepo.test.ts exactly.
**Warning signs:** Test output shows "NativeModule.RNFBFirestoreModule is null" or similar native module error.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### UserProfile Expansion (ONBD-01, ONBD-02)
```typescript
// Source: UserRepository.ts — expand to include onboarding fields
export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type PrimaryGoal = 'strength' | 'muscle' | 'endurance' | 'weightLoss' | 'general';

export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  isAnonymous: boolean;
  createdAt: string;
  lastSignInAt: string;
  authProvider: 'apple' | 'google' | 'email' | 'anonymous';
  // Onboarding fields (Phase 3)
  name?: string;
  experienceLevel?: ExperienceLevel;
  primaryGoal?: PrimaryGoal;
  gender?: Gender;
  cycleOptIn?: boolean;
  hasCompletedOnboarding?: boolean;
}
```

### ReadinessRepo Interface (ReadinessSurvey storage from Phase 2 domain)
```typescript
// ReadinessRepo.ts
import type { ReadinessResult } from '../domain/readiness/readiness-survey';

export interface ReadinessSurveyRecord {
  id: string;
  uid: string;
  date: string;          // ISO date 'yyyy-MM-dd'
  sleepQuality: number;
  stressLevel: number;
  sorenessLevel: number;
  result: ReadinessResult;
}

export interface ReadinessRepository {
  saveSurvey(record: ReadinessSurveyRecord): Promise<void>;
  getSurveyForDate(uid: string, date: string): Promise<ReadinessSurveyRecord | null>;
  getRecentSurveys(uid: string, limit: number): Promise<ReadinessSurveyRecord[]>;
}
```

### WorkoutRepo Interface (stub — UI in Phase 4)
```typescript
// WorkoutRepo.ts
import type { GeneratedWorkout } from '../domain/ai-workout/generated-workout';
import type { HistoryItem } from '../domain/history/history-item';

export interface WorkoutRecord {
  id: string;
  uid: string;
  completedAt: string;    // ISO 8601
  durationSeconds: number;
  source: 'ai' | 'program' | 'custom';
  workout: GeneratedWorkout;
}

export interface WorkoutRepository {
  saveWorkout(record: WorkoutRecord): Promise<void>;
  getWorkout(uid: string, workoutId: string): Promise<WorkoutRecord | null>;
  getHistory(uid: string, limit?: number): Promise<HistoryItem[]>;
  deleteWorkout(uid: string, workoutId: string): Promise<void>;
}
```

### Firestore WorkoutRepo Collection Path
```typescript
// FirestoreWorkoutRepo.ts — subcollection under /users/{uid}/workouts/{workoutId}
async saveWorkout(record: WorkoutRecord): Promise<void> {
  const db = getFirestoreInstance();
  await db
    .collection('users')
    .doc(record.uid)
    .collection('workouts')
    .doc(record.id)
    .set(record, { merge: true });
}
```

### SettingsRepo Interface
```typescript
// SettingsRepo.ts
export interface AppSettings {
  weightUnit: 'lb' | 'kg';
  notificationsEnabled: boolean;
}

export interface SettingsRepository {
  saveSettings(uid: string, settings: AppSettings): Promise<void>;
  getSettings(uid: string): Promise<AppSettings | null>;
}

// Default settings (used when getSettings returns null)
export const DEFAULT_SETTINGS: AppSettings = {
  weightUnit: 'lb',
  notificationsEnabled: true,
};
```

### Firestore Batch Write Mock (for migration tests)
```typescript
// The existing Firestore mock in __mocks__/@react-native-firebase/firestore.ts
// already stubs batch().set().commit() — use it directly in migration tests:
import firestore from '@react-native-firebase/firestore';

const mockBatch = firestore().batch();
// batch.set, batch.commit are already jest.fn() in existing mock
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `<Redirect>` + `useEffect` for onboarding gate | `Stack.Protected guard={condition}` | Expo Router v5 / SDK 53+ | Declarative, handles back-press correctly; no race condition with useEffect |
| `enablePersistence()` (deprecated) | `enableIndexedDbPersistence()` or `initializeFirestore` with `persistentLocalCache` | Firebase JS SDK v9+ | Must update web branch; native is unaffected |
| Manual offline detection + retry queue | Firestore native offline persistence | Firebase SDK default | No custom code needed for write queuing |

**Deprecated/outdated:**
- `firestore().enablePersistence()`: Removed in Firebase JS SDK v9+. Web branch must use `enableIndexedDbPersistence(firestoreInstance)` or `initializeFirestore(app, { localCache: persistentLocalCache() })`. Do NOT use the v8-style method.

---

## Firestore Document Schema (Claude's Discretion)

These schemas are recommended based on existing patterns and the data model.

### /users/{uid} — expanded (OnboardingProfileRepo merges here)
```
{
  uid: string,
  email: string | null,
  displayName: string | null,
  isAnonymous: boolean,
  createdAt: string,          // ISO 8601
  lastSignInAt: string,       // ISO 8601
  authProvider: string,
  // Onboarding additions:
  name: string,
  experienceLevel: string,    // 'beginner' | 'intermediate' | 'advanced'
  primaryGoal: string,        // 'strength' | 'muscle' | 'endurance' | 'weightLoss' | 'general'
  gender: string,             // 'female' | 'male' | 'other'
  cycleOptIn: boolean,
  hasCompletedOnboarding: boolean,
  // Settings (SettingsRepo merges here for simplicity):
  weightUnit: string,         // 'lb' | 'kg'
  notificationsEnabled: boolean
}
```

### /users/{uid}/workouts/{workoutId} — subcollection
```
{
  id: string,
  uid: string,
  completedAt: string,        // ISO 8601
  durationSeconds: number,
  source: 'ai' | 'program' | 'custom',
  workout: { ... GeneratedWorkout shape ... }
}
```

### /users/{uid}/readiness/{date} — subcollection, date as document ID
```
{
  id: string,
  uid: string,
  date: string,               // 'yyyy-MM-dd'
  sleepQuality: number,
  stressLevel: number,
  sorenessLevel: number,
  result: { score: number, tier: string }
}
```

**Design rationale:**
- Settings merged into /users/{uid} avoids an extra Firestore read on startup; settings are always needed alongside user profile.
- Workouts and readiness in subcollections keeps the user document small and supports per-collection security rules in Phase 4.

---

## AsyncStorage Key Conventions (Claude's Discretion)

All keys use `@sundee/` prefix + snake_case domain name. Recommended keys:

| Key | Content |
|-----|---------|
| `@sundee/user_profile` | UserProfile (already used in LocalUserRepo) |
| `@sundee/onboarding_profile` | OnboardingProfile draft and completed data |
| `@sundee/workouts` | WorkoutRecord[] JSON array |
| `@sundee/settings` | AppSettings JSON object |
| `@sundee/readiness_surveys` | ReadinessSurveyRecord[] JSON array |

Note: Existing LocalUserRepo uses `'user_profile'` (no prefix). The new repos should use the `@sundee/` prefix. LocalUserRepo should be updated to `'@sundee/user_profile'` for consistency, with a one-time migration check on app launch.

---

## Open Questions

1. **LocalUserRepo key migration**
   - What we know: LocalUserRepo currently uses `'user_profile'` key without the `@sundee/` prefix established for all new repos.
   - What's unclear: Whether updating the key is worth the complexity of a read-from-old-key fallback for users upgrading from Phase 2 builds.
   - Recommendation: Update to `'@sundee/user_profile'` and add a one-time migration: read `'user_profile'`, if found write to `'@sundee/user_profile'` and delete the old key. Keeps all keys consistent.

2. **Web Firestore persistence API version**
   - What we know: Firebase JS SDK v12 (installed) uses the modular API. `enableIndexedDbPersistence` is available but the newer approach is `initializeFirestore(app, { localCache: persistentLocalCache() })`.
   - What's unclear: Whether v12 still exports `enableIndexedDbPersistence` or whether `persistentLocalCache()` is now required.
   - Recommendation: Use `initializeFirestore` with `persistentLocalCache()` — it is the v9+ recommended approach and the documentation marks `enableIndexedDbPersistence` as legacy. Verify at implementation time via Firebase JS SDK v12 changelog.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30.3.0 + jest-expo 55.0.9 |
| Config file | `SundeeFundeeRN/jest.config.js` |
| Quick run command | `cd SundeeFundeeRN && npx jest --testPathPattern="repositories"` |
| Full suite command | `cd SundeeFundeeRN && npx jest --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBD-01 | saveProfile writes name/experienceLevel/primaryGoal/gender to Firestore with merge | unit | `npx jest --testPathPattern="OnboardingProfileRepo"` | ❌ Wave 0 |
| ONBD-01 | saveProfile writes onboarding fields to AsyncStorage under @sundee/onboarding_profile | unit | `npx jest --testPathPattern="LocalOnboardingProfileRepo"` | ❌ Wave 0 |
| ONBD-02 | saveProfile writes cycleOptIn and hasCompletedOnboarding correctly | unit | `npx jest --testPathPattern="OnboardingProfileRepo"` | ❌ Wave 0 |
| ONBD-03 | Onboarding navigator skips step-cycle when gender is 'male' | unit | `npx jest --testPathPattern="onboarding"` | ❌ Wave 0 |
| WORK-11 | WorkoutRepo.saveWorkout writes to /users/{uid}/workouts/{id} subcollection | unit | `npx jest --testPathPattern="WorkoutRepo"` | ❌ Wave 0 |
| WORK-11 | LocalWorkoutRepo.saveWorkout writes to @sundee/workouts AsyncStorage key | unit | `npx jest --testPathPattern="LocalWorkoutRepo"` | ❌ Wave 0 |
| AUTH-07 | getOnboardingProfileRepo(false) returns FirestoreOnboardingProfileRepo | unit | `npx jest --testPathPattern="factory"` | ❌ Wave 0 |
| AUTH-07 | getOnboardingProfileRepo(true) returns LocalOnboardingProfileRepo | unit | `npx jest --testPathPattern="factory"` | ❌ Wave 0 |
| ONBD-01 | UserProfile interface includes all onboarding fields (type-level, compile test) | type | `npx tsc --noEmit` | ❌ Wave 0 (types only) |

### Sampling Rate
- **Per task commit:** `cd SundeeFundeeRN && npx jest --testPathPattern="repositories" --passWithNoTests`
- **Per wave merge:** `cd SundeeFundeeRN && npx jest --coverage`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `src/repositories/__tests__/FirestoreOnboardingProfileRepo.test.ts` — covers ONBD-01, ONBD-02
- [ ] `src/repositories/__tests__/LocalOnboardingProfileRepo.test.ts` — covers ONBD-01, ONBD-02
- [ ] `src/repositories/__tests__/FirestoreWorkoutRepo.test.ts` — covers WORK-11
- [ ] `src/repositories/__tests__/LocalWorkoutRepo.test.ts` — covers WORK-11
- [ ] `src/repositories/__tests__/FirestoreSettingsRepo.test.ts` — covers settings persistence
- [ ] `src/repositories/__tests__/LocalSettingsRepo.test.ts` — covers settings persistence
- [ ] `src/repositories/__tests__/FirestoreReadinessRepo.test.ts` — covers readiness persistence
- [ ] `src/repositories/__tests__/LocalReadinessRepo.test.ts` — covers readiness persistence
- [ ] `src/repositories/__tests__/repoFactory.test.ts` — covers AUTH-07 factory routing
- [ ] `src/repositories/__tests__/migration.test.ts` — covers guest-to-auth migration

All test files follow the exact pattern established in `FirestoreUserRepo.test.ts` and `LocalUserRepo.test.ts`. The existing mocks in `__mocks__/@react-native-firebase/firestore.ts` and `__mocks__/@react-native-async-storage/async-storage.ts` cover all new repo tests with no additions needed.

---

## Sources

### Primary (HIGH confidence)
- `SundeeFundeeRN/src/repositories/` — existing dual-implementation pattern (UserRepository.ts, FirestoreUserRepo.ts, LocalUserRepo.ts)
- `SundeeFundeeRN/__mocks__/` — established Jest mock infrastructure
- `SundeeFundeeRN/src/firebase/firestore.ts` — platform-aware Firestore accessor
- `SundeeFundeeRN/app/_layout.tsx` — RootLayout repo factory pattern
- https://rnfirebase.io/firestore/usage — offline persistence enabled by default on native (confirmed)
- https://docs.expo.dev/router/advanced/protected/ — Stack.Protected guard prop (Expo Router v5, SDK 53+)

### Secondary (MEDIUM confidence)
- https://firebase.google.com/docs/firestore/manage-data/transactions — batch writes offline-safe, up to 500 operations
- https://expo.dev/blog/simplifying-auth-flows-with-protected-routes — Stack.Protected pattern for onboarding gating
- https://rnfirebase.io/reference/firestore/writebatch — WriteBatch API for migration

### Tertiary (LOW confidence)
- Firebase JS SDK v12 `persistentLocalCache()` vs `enableIndexedDbPersistence()` — verify at implementation time; research showed legacy status of `enableIndexedDbPersistence` but did not confirm removal in v12

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed and in use; no new dependencies
- Architecture: HIGH — all patterns directly derived from existing codebase (FirestoreUserRepo, LocalUserRepo) or official Expo Router docs (Stack.Protected)
- Firestore offline (native): HIGH — confirmed enabled by default in @react-native-firebase/firestore
- Firestore offline (web): MEDIUM — API variant (persistentLocalCache vs enableIndexedDbPersistence) needs verification at implementation time
- Pitfalls: HIGH — most derived from existing codebase decisions and established patterns
- Migration batch strategy: HIGH — batch writes confirmed offline-safe and correct approach for < 500 docs

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable libraries; Expo Router and Firebase SDK version-pinned in package.json)

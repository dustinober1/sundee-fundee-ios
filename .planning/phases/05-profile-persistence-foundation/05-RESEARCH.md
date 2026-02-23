# Phase 05 Research: Profile Persistence Foundation

Date: 2026-02-23
Phase: 05-profile-persistence-foundation

## Objective
Define a low-risk, production-ready implementation approach for onboarding and injury-profile persistence across sessions/devices in the existing Flutter + Riverpod + Firebase stack.

## Inputs Reviewed
- `.planning/ROADMAP.md` (Phase 05 goal, requirements, success criteria)
- `.planning/REQUIREMENTS.md` (ONB-01/02/03, INJ-01/02)
- `.planning/phases/05-profile-persistence-foundation/05-CONTEXT.md`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/lib/features/auth/providers.dart`
- `flutter_app/lib/domain/models/user_model.dart`
- `flutter_app/lib/app/router.dart`
- `firestore.rules`
- `flutter pub outdated --no-dev-dependencies` (run 2026-02-23; direct deps current)

## Standard Stack
Use this stack as the Phase 05 baseline (no platform churn):

1. Flutter + Dart current project versions.
2. Riverpod providers for auth/session/bootstrap orchestration.
3. Firebase Auth as identity source only.
4. Cloud Firestore as source of truth for onboarding and injury profile state.
5. Firestore snapshot metadata (`fromCache`, `hasPendingWrites`) for sync/conflict UX signals.
6. Firestore server timestamps (`FieldValue.serverTimestamp()`) for last-write reconciliation.
7. Firestore Security Rules with field-shape and owner validation.
8. Firebase Emulator Suite for rules/integration tests before deploy.

Rationale:
- This repo already uses Riverpod + Firebase Auth + Firestore heavily, so Phase 05 should extend current patterns, not introduce a new persistence layer.
- Firestore offline persistence and listener metadata already support the resume/retry semantics this phase needs.

## Architecture Patterns

### 1) Single canonical profile document under `/users/{uid}`
Prescriptive model for this phase:
- Keep a single root profile doc as source of truth for gating and persistence.
- Add explicit nested objects instead of scattered top-level fields.

Recommended shape:
```json
{
  "onboarding": {
    "completed": true,
    "version": 1,
    "completedAt": "<server timestamp>",
    "required": {
      "displayName": "...",
      "genderRaw": "female|male|preferNotToSay"
    }
  },
  "injuryProfile": {
    "activeInjuries": [
      {
        "id": "uuid",
        "location": "knee",
        "limitations": ["deep_knee_flexion"],
        "recoveryGoal": "return_to_squat",
        "status": "active",
        "updatedAt": "<server timestamp>",
        "resolvedAt": null
      }
    ],
    "lastReassessedAt": "<server timestamp>"
  },
  "profileUpdatedAt": "<server timestamp>",
  "schemaVersion": 2
}
```

Why:
- ONB and INJ gates read from one document snapshot.
- Atomic updates and consistent routing decisions are simpler.
- Safer migration from legacy fields (`onboardingComplete`, `displayName`, etc.) by dual-read then backfill.

### 2) Deterministic bootstrap state machine (Riverpod)
Implement a dedicated bootstrap provider that resolves once per app start:
- `loading` -> `needsOnboarding` | `needsInjuryRequiredFields` | `ready`.
- Evaluate required-field completeness using data validation, not just a boolean flag.
- If local and server snapshots disagree, pick latest by server timestamp field (`profileUpdatedAt`).

### 3) Merge strategy: timestamp-based last-write-wins
For profile edits:
- Every write must update `profileUpdatedAt` with server timestamp.
- Local edits can optimistically update UI, but reconciliation logic always compares authoritative timestamps from snapshots.
- Equal timestamp tie-breaker: keep server snapshot and emit a telemetry event.

### 4) Injury CRUD as soft-resolve, not hard delete
- Clearing injury context should mark injury entries `status=resolved` plus `resolvedAt`, not remove history.
- Maintain an `activeInjuries` projection for fast reads.
- This aligns with future adaptation and audit trails without Phase 05 rework.

### 5) Lazy migration with safe defaults at sign-in
For pre-v1.1 users:
- On first authenticated profile read, fill missing required structures with defaults.
- Write back using merge update; if write fails, continue app usage with in-memory defaults and queue retry.
- Track one-time migration notice flag in profile to avoid repetitive prompts.

### 6) Rules-first validation contract
Add rules that enforce:
- User can only write own profile doc.
- Required field presence/type for onboarding and injury substructures.
- Allowed enum values for constrained fields.
- Reject unknown top-level keys for this phase to avoid silent schema drift.

### 7) Verification-first rollout
Required verification gate before closing phase:
- Unit tests for bootstrap gate transitions and migration fallback behavior.
- Repository tests for injury create/update/resolve persistence behavior.
- Emulator rules tests for valid vs invalid profile payloads.
- End-to-end auth->bootstrap->onboarding bypass flow across app restart.

## Don't Hand-Roll
1. Do not build a custom offline queue; use Firestore SDK offline write queue and sync.
2. Do not build custom auth token/session persistence; use Firebase Auth persistence behavior.
3. Do not build custom conflict resolution protocol beyond timestamp-based merge for this phase.
4. Do not build a bespoke schema validation engine in app code as primary enforcement; enforce shape in Security Rules and mirror checks in Dart for UX.
5. Do not create a separate local database just for Phase 05 profile persistence.

## Common Pitfalls
1. Using `onboardingComplete` alone as truth.
   - Fix: gate by flag + required field validation.
2. Assuming Firestore transactions work offline.
   - They do not; use batched writes or merge writes for offline-friendly operations.
3. Ignoring listener metadata.
   - Leads to confusing UI when local pending writes differ from server state.
4. Relying on rules as query filters.
   - Rules are allow/deny checks, not post-query filtering.
5. Incomplete migration idempotency.
   - Migration logic must be safe to rerun and resilient to partial failure.
6. Mixing nullable/legacy field names without explicit normalization.
   - Add one normalization layer that maps old fields to current model.

## Code Examples

### A) Profile document converter with normalization
```dart
final userProfileRef = FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .withConverter<UserProfile>(
      fromFirestore: (snap, _) => UserProfile.fromFirestore(snap.data() ?? {}),
      toFirestore: (profile, _) => profile.toFirestore(),
    );
```

### B) Bootstrap gate decision
```dart
BootstrapState decideBootstrap(UserProfile profile) {
  final onboardingComplete = profile.onboarding.completed &&
      profile.onboarding.required.displayName.isNotEmpty;

  if (!onboardingComplete) return BootstrapState.needsOnboarding;

  final missingInjuryRequired = profile.injuryProfile.requiresAnswering;
  if (missingInjuryRequired) return BootstrapState.needsInjuryRequiredFields;

  return BootstrapState.ready;
}
```

### C) Offline-friendly profile update with server timestamp
```dart
await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'onboarding': {
    'completed': true,
    'required': {'displayName': name, 'genderRaw': gender.name},
    'completedAt': FieldValue.serverTimestamp(),
  },
  'profileUpdatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

### D) Metadata-aware listener for subtle sync status
```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots(includeMetadataChanges: true)
    .listen((doc) {
  final fromCache = doc.metadata.isFromCache;
  final hasPendingWrites = doc.metadata.hasPendingWrites;
  // Map these flags to compact UI status text/icon.
});
```

## Confidence by Area
- Existing stack fit (Flutter/Riverpod/Auth/Firestore): HIGH
- Offline and sync behavior guidance: HIGH
- Rules validation and emulator testing approach: HIGH
- Exact profile schema shape recommendation for this repo: MEDIUM-HIGH
- Timestamp tie-breaker policy (equal timestamps -> server wins): MEDIUM

## Sources
- Firebase Auth state persistence in Flutter: <https://firebase.google.com/docs/auth/flutter/manage-users>
- Firestore real-time listeners and metadata changes: <https://firebase.google.com/docs/firestore/query-data/listen>
- Firestore offline persistence behavior: <https://firebase.google.com/docs/firestore/manage-data/enable-offline>
- Firestore transactions/batched writes (including offline caveat): <https://firebase.google.com/docs/firestore/manage-data/transactions>
- Firestore add/update data and server timestamps: <https://firebase.google.com/docs/firestore/manage-data/add-data>
- Firestore data model guidance: <https://firebase.google.com/docs/firestore/data-model>
- Firestore Security Rules conditions + field validation patterns: <https://firebase.google.com/docs/firestore/security/rules-conditions>
- Security Rules are not filters: <https://firebase.google.com/docs/firestore/security/rules-query>
- Rules unit testing with Emulator Suite: <https://firebase.google.com/docs/firestore/security/test-rules-emulator>
- Riverpod docs: <https://riverpod.dev/>

## Recommended Next Step
Run `$gsd-plan-phase 5` so planning can convert these architecture decisions into executable wave/task plans.

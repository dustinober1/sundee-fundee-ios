# Phase 07 Research: Enrollment Cancellation Lifecycle

Date: 2026-02-24  
Phase: 07-enrollment-cancellation-lifecycle

## Objective
Define a low-risk, implementation-ready approach for explicit plan cancellation that preserves workout history, presents clear post-cancel status, and supports safe re-enrollment with stale-state auto-healing.

## Inputs Reviewed
- `.planning/ROADMAP.md` (Phase 7 goal, requirements, success criteria)
- `.planning/REQUIREMENTS.md` (PLN-01, PLN-02, PLN-03)
- `.planning/phases/07-enrollment-cancellation-lifecycle/07-CONTEXT.md`
- `.planning/STATE.md` (prior implementation decisions and conventions)
- `flutter_app/lib/domain/models/program_models.dart`
- `flutter_app/lib/domain/models/completed_workout_model.dart`
- `flutter_app/lib/features/programs/data/program_repository.dart`
- `flutter_app/lib/features/repositories/domain/repository_interfaces.dart`
- `flutter_app/lib/features/repositories/data/firestore_repositories.dart`
- `flutter_app/lib/features/programs/presentation/programs_screen.dart`
- `flutter_app/lib/features/workouts/presentation/workout_landing_screen.dart`
- `flutter_app/lib/features/dashboard/presentation/dashboard_screen.dart`
- `flutter_app/lib/features/workouts/presentation/workout_execution_providers.dart`
- `flutter_app/test/features/repositories/data/firestore_enrollment_repository_test.dart`
- `flutter_app/test/features/repositories/data/firestore_phase1_smoke_test.dart`
- `firestore.rules`
- `firestore.indexes.json`

## Summary
Use the current Flutter + Riverpod + Firestore stack and evolve the enrollment model from a single `isActive` flag to an explicit lifecycle model (`active`, `canceled`, `completed`) with timestamped lifecycle events. Implement cancellation with an offline-safe `WriteBatch` (update enrollment + append lifecycle event), and make active enrollment reads deterministic with explicit ordering and stale-state auto-healing.

No new libraries are required.

---

## Standard Stack

Use this baseline for Phase 7:

1. Flutter + Dart + existing app architecture (no framework changes).
2. Riverpod `StreamProvider` + derived providers for lifecycle UI state.
3. Cloud Firestore as source of truth for enrollments and lifecycle events.
4. Firestore server timestamps (`FieldValue.serverTimestamp()`) for lifecycle times.
5. Firestore `WriteBatch` for offline-friendly atomic cancellation writes.
6. Firestore Security Rules + Emulator tests for enrollment shape and transition safety.
7. Existing repository pattern (`ProgramRepository` + `EnrolledProgramRepository`) with additive methods, not a rewrite.

Why this is standard here:
- The codebase already uses repository interfaces and Riverpod streams for enrollment flow.
- Firestore already persists enrollment records and supports the required real-time state transitions.
- The existing UI already branches on `activeEnrollmentProvider`; cancellation is an extension of that architecture.

---

## Architecture Patterns

### 1) Explicit enrollment lifecycle state (replace implicit active/inactive semantics)
Current model cannot distinguish canceled vs completed once `isActive` becomes `false`. Add explicit lifecycle fields:

- `status: active | canceled | completed`
- `canceledAt: DateTime?`
- `completedAt: DateTime?` (already exists)
- `lastSyncedAt: DateTime` (always populated)

Backwards compatibility:
- Continue reading legacy docs that only have `isActive`.
- Derive status on read when `status` is missing:
  - `isActive == true` -> `active`
  - `isActive == false && completedAt != null` -> `completed`
  - otherwise -> `canceled`

### 2) Lifecycle event log for audit + post-cancel UX
Add `users/{uid}/enrollmentEvents/{eventId}` with:

- `eventType: enrolled | canceled | completed | restored | auto_healed`
- `enrollmentId`
- `programId`
- `occurredAt` (server timestamp)
- `metadata` (optional map)

Use this stream to power:
- Post-cancel status card content (`Canceled on ...`)
- Timeline/event surfaces
- Future diagnostics without scraping enrollment docs

### 3) Cancel as atomic batch write (offline-safe)
For user-initiated cancel, write in one `WriteBatch`:

1. Update enrollment doc:
   - `status = canceled`
   - `isActive = false`
   - `canceledAt = serverTimestamp`
   - `lastSyncedAt = serverTimestamp`
2. Create lifecycle event doc (`eventType = canceled`, same timestamp source)

Use batch, not transaction, for this specific write:
- No read-before-write dependency.
- Batched writes execute offline and sync later.

### 4) Deterministic active enrollment query + stale-state healing
Current `where(isActive == true).limit(1)` can return non-deterministic documents when duplicates exist. Move to:

- `where('status', isEqualTo: 'active')`
- `orderBy('lastSyncedAt', descending: true)`
- `limit(1)`

Add a healing pass when duplicates are detected:
- Query active enrollments ordered by `lastSyncedAt` descending.
- Keep newest active enrollment.
- Batch-cancel all additional active records with `eventType = auto_healed`.
- If healing fails, surface explicit fallback error and block re-enrollment action.

### 5) Re-enrollment flow with explicit restore-vs-new fork
When enrolling in a plan that has prior canceled enrollment(s), prompt:

1. `Restore prior canceled enrollment`
2. `Start new enrollment`

Implementation contract:
- Both paths start at `currentWeek=1`, `currentDay=1`, `completedWeeks=[]` (no progress carryover).
- Restore path reactivates selected canceled record (same `id`) and appends `restored` event.
- New path creates a new enrollment record and appends `enrolled` event.
- Run stale-state healer before either path commits.

### 6) History retention and canceled-plan marker
Never delete workout history on cancel.

To mark workouts as from canceled plan:
- Add optional `enrollmentId` to `CompletedWorkoutModel`.
- Write `enrollmentId` during workout save in `finishWorkout`.
- In history UI, join workout `enrollmentId` with enrollment status map and show marker chip when status is `canceled`.

This preserves aggregate metrics and PR logic because workout records remain intact.

### 7) UI state model: active vs canceled vs none
Introduce a derived provider, e.g. `enrollmentLifecycleStateProvider`, that combines:
- active enrollment stream
- latest lifecycle event stream

UI policy:
- `active`: show current plan controls + cancel action entry.
- `canceled` (no active + latest event canceled): show replacement card with cancellation date and CTAs (`Browse plans`, `Enroll in new plan`).
- `none` (never enrolled): show existing neutral empty state.

### 8) Security rules and validation contract
Harden enrollment writes:
- Validate allowed status enum values.
- Validate timestamp fields (`startDate`, `lastSyncedAt`, `canceledAt`, `completedAt`) types.
- Prevent illegal transitions (for example, directly changing `programId` of existing enrollment).
- Validate event document shape for `/enrollmentEvents`.

If enforcing cross-document invariants in one batch, use `getAfter()` in rules where needed.

---

## Don't Hand-Roll

1. Do not build a custom local cancellation queue; use Firestore SDK offline queueing.
2. Do not hard-delete enrollment records or completed workout history for cancellation.
3. Do not rely on client clock strings (`DateTime.now().toIso8601String()`) for authoritative lifecycle times.
4. Do not infer status only from missing fields; use explicit `status` going forward.
5. Do not keep `watchActiveEnrollment` as unordered `limit(1)` once lifecycle state expands.
6. Do not enforce schema/transitions only in UI; enforce in Firestore rules and tests.

---

## Common Pitfalls

1. Ambiguous inactive state (`isActive=false` means both completed and canceled).
2. Non-deterministic active record selection from unordered `limit(1)` queries.
3. Using transactions for simple cancel writes and degrading offline behavior.
4. Forgetting lifecycle event write, which breaks timeline/post-cancel context.
5. Adding `orderBy` on a field not guaranteed to exist (Firestore filters out docs missing that field).
6. Re-enrollment without duplicate-active healing, leaving conflicting artifacts.
7. Losing canceled-plan markers in workout history by not storing `enrollmentId` on workout records.
8. Assuming rules filter query results; they only allow/deny query execution.

---

## Code Examples

### A) Enrollment lifecycle model extension
```dart
enum EnrollmentStatus { active, canceled, completed }

class EnrolledProgramModel {
  EnrolledProgramModel({
    required this.id,
    required this.programId,
    required this.startDate,
    required this.currentWeek,
    required this.currentDay,
    this.status = EnrollmentStatus.active,
    this.canceledAt,
    this.completedAt,
    this.completedWeeks = const <int>[],
    this.lastSyncedAt,
  });

  final String id;
  final String programId;
  final DateTime startDate;
  final int currentWeek;
  final int currentDay;
  final EnrollmentStatus status;
  final DateTime? canceledAt;
  final DateTime? completedAt;
  final List<int> completedWeeks;
  final DateTime? lastSyncedAt;

  bool get isActive => status == EnrollmentStatus.active;
}
```

### B) Cancel enrollment with batch + lifecycle event
```dart
Future<void> cancelEnrollment({
  required String userId,
  required String enrollmentId,
  required String programId,
}) async {
  final batch = _firestore.batch();
  final enrollmentRef = _enrollmentsCollection(userId).doc(enrollmentId);
  final eventRef = _eventsCollection(userId).doc();

  batch.update(enrollmentRef, <String, Object?>{
    'status': 'canceled',
    'isActive': false, // temporary compatibility
    'canceledAt': FieldValue.serverTimestamp(),
    'lastSyncedAt': FieldValue.serverTimestamp(),
  });

  batch.set(eventRef, <String, Object?>{
    'eventType': 'canceled',
    'enrollmentId': enrollmentId,
    'programId': programId,
    'occurredAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
}
```

### C) Deterministic active enrollment read
```dart
Stream<EnrolledProgramModel?> watchActiveEnrollment({required String userId}) {
  return _enrollmentsCollection(userId)
      .where('status', isEqualTo: 'active')
      .orderBy('lastSyncedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return EnrolledProgramModel.fromJson(snapshot.docs.first.data());
  });
}
```

### D) Auto-heal duplicate active records before re-enrollment
```dart
Future<void> healDuplicateActiveEnrollments(String userId) async {
  final snapshot = await _enrollmentsCollection(userId)
      .where('status', isEqualTo: 'active')
      .orderBy('lastSyncedAt', descending: true)
      .get();

  if (snapshot.docs.length <= 1) return;

  final keep = snapshot.docs.first;
  final batch = _firestore.batch();
  for (final doc in snapshot.docs.skip(1)) {
    batch.update(doc.reference, <String, Object?>{
      'status': 'canceled',
      'isActive': false,
      'canceledAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
```

### E) Post-cancel UI state derivation
```dart
final enrollmentLifecycleStateProvider =
    Provider<EnrollmentLifecycleState>((ref) {
  final active = ref.watch(activeEnrollmentProvider).asData?.value;
  final latestEvent = ref.watch(latestEnrollmentEventProvider).asData?.value;

  if (active != null) return EnrollmentLifecycleState.active(active);
  if (latestEvent?.eventType == EnrollmentEventType.canceled) {
    return EnrollmentLifecycleState.canceled(latestEvent!.occurredAt);
  }
  return const EnrollmentLifecycleState.none();
});
```

---

## Confidence by Area
- Enrollment lifecycle data-model evolution: HIGH
- Repository/write-path strategy (batch + event log): HIGH
- Deterministic query + duplicate healing approach: MEDIUM-HIGH
- Post-cancel UI state composition in Riverpod: HIGH
- History marker strategy via `enrollmentId` on workouts: MEDIUM
- Rules transition-hardening design: MEDIUM

## Sources
- Firestore transactions and batched writes: <https://firebase.google.com/docs/firestore/manage-data/transactions>
- Firestore add/update data (`arrayUnion`, `serverTimestamp`): <https://firebase.google.com/docs/firestore/manage-data/add-data>
- Firestore ordering/limits (`orderBy` existence behavior): <https://firebase.google.com/docs/firestore/query-data/order-limit-data>
- Firestore offline persistence behavior: <https://firebase.google.com/docs/firestore/manage-data/enable-offline>
- Firestore Rules field validation and `diff()`: <https://firebase.google.com/docs/firestore/security/rules-fields>
- Firestore Rules conditions and `getAfter()`: <https://firebase.google.com/docs/firestore/security/rules-conditions>
- Firestore Rules are not filters: <https://firebase.google.com/docs/firestore/security/rules-query>
- Riverpod `StreamProvider` reference: <https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/StreamProvider-class.html>

## Recommended Next Step
Run `$gsd-plan-phase 7` to convert this research into executable implementation plans.

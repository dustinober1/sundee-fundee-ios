# Phase 13: Supabase Sync Parity (Optional Cloud) - Research

**Researched:** 2026-02-22
**Domain:** Flutter supabase_flutter v2.x, Drift local-first sync, Riverpod 3.x NotifierProvider
**Confidence:** HIGH

---

## Summary

Phase 13 adds optional Supabase auth and cloud sync to the Flutter app, matching the sync semantics already present in the v1.1 web app (`src/lib/sync/`, `src/contexts/user-context.tsx`). The Flutter app already has connectivity detection (`ConnectivityService`, `isOnlineProvider`) and an offline banner — the missing pieces are: (1) `supabase_flutter` integration, (2) a sync state machine (`SyncNotifier`), (3) a `SyncService` for push/pull/queue, and (4) a UUID bridge for the Drift integer ID → Supabase UUID mismatch.

The **critical architectural challenge** unique to Flutter (not present in v1.1) is that Drift uses integer auto-increment PKs while Supabase expects UUID PKs. The solution is to add nullable `syncId TEXT UNIQUE` columns to the five synced tables and populate them on first push. This requires a Drift schema migration to version 4.

The v1.1 pattern (push after workout, queue offline, drain queue on reconnect, pull on auth) translates cleanly to Flutter using Riverpod `NotifierProvider<SyncNotifier, SyncState>` and `SharedPreferences` for the queue. `supabase_flutter` v2.12.0 uses `shared_preferences` internally for session persistence — no additional secure storage package is needed since `shared_preferences` is already in `pubspec.yaml`.

**Primary recommendation:** Mirror v1.1's sync architecture in Flutter: SyncService (push/pull/queue), SyncNotifier (state machine), integration with `WorkoutSessionNotifier.completeWorkout()` and connectivity stream. Add Drift migration v4 for `syncId` UUID bridge columns before any sync logic.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `supabase_flutter` | 2.12.0 | Supabase client (auth + database) for Flutter | Official Flutter package, handles session persistence via shared_preferences |
| `uuid` | 4.5.3 | UUID v4 generation for syncId bridge columns | Standard Dart UUID library; needed because Drift uses integer IDs but Supabase needs UUIDs |
| `flutter_riverpod` | 3.2.1 *(already installed)* | State management for SyncNotifier | App-wide pattern; NotifierProvider for sync state machine |
| `connectivity_plus` | 7.0.0 *(already installed)* | Online/offline detection | Already wired as `isOnlineProvider` |
| `shared_preferences` | 2.5.4 *(already installed)* | Offline sync queue persistence | Same role as localStorage in v1.1; also used internally by supabase_flutter |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `drift` | 2.31.0 *(already installed)* | Local-first source of truth | Drift is the source of truth; cloud is a mirror |
| `drift_dev` | 2.31.0 *(already installed)* | Code generation after schema migration | Required after adding syncId columns to tables |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `syncId TEXT UNIQUE` columns | Deterministic UUID hashing | Hash approach avoids migration but creates silent collision risk; explicit syncId is clearer |
| `shared_preferences` for queue | SQLite queue table in Drift | Drift queue is more robust but over-engineered for small workout queues |
| Email/password auth | OTP / OAuth | OTP and OAuth are supported but add complexity; email+password matches v1.1 baseline |

### Installation

```bash
cd flutter_app
flutter pub add supabase_flutter
flutter pub add uuid
# Then run code gen after schema migration:
dart run build_runner build
```

---

## Architecture Patterns

### Recommended Project Structure

```
flutter_app/lib/
├── core/
│   └── connectivity/
│       └── connectivity_service.dart     # EXISTS — no change needed
├── data/
│   ├── database/
│   │   ├── app_database.dart             # MODIFY — add syncId columns, bump schemaVersion to 4
│   │   └── app_database.g.dart           # REGENERATE after schema change
│   └── repositories/
│       └── workout_repository.dart       # EXISTS — no change for sync (SyncService reads DB directly)
├── features/
│   ├── auth/
│   │   ├── auth_screen.dart              # NEW — email/password sign-in + sign-up form
│   │   └── auth_notifier.dart            # NEW — wraps supabase_flutter auth calls
│   ├── dashboard/
│   │   └── dashboard_screen.dart         # MODIFY — add SyncStatusBadge to AppBar actions
│   └── settings/
│       └── settings_screen.dart          # MODIFY (or create) — add Sign Out + last synced
├── shared/
│   ├── providers/
│   │   ├── connectivity_provider.dart    # EXISTS — no change
│   │   ├── sync_provider.dart            # NEW — SyncNotifier + syncStatusProvider
│   │   └── supabase_provider.dart        # NEW — SupabaseClient provider (nullable when unconfigured)
│   └── widgets/
│       ├── offline_banner.dart           # EXISTS — no change needed
│       └── sync_status_badge.dart        # NEW — icon badge showing sync state in AppBar
└── services/
    └── sync_service.dart                 # NEW — push/pull/queue/retry (mirrors src/lib/sync/)
```

### Pattern 1: Supabase Initialization (conditional)

`supabase_flutter` must be initialized in `main()` before `runApp`. The sync feature is optional — if env vars are absent, the client is null and all sync operations no-op.

```dart
// flutter_app/lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional Supabase: initialize only when env vars are present
  // In production, pass via --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // ...rest of runApp setup unchanged
}
```

**Why `String.fromEnvironment`**: Flutter's `--dart-define` pattern is the standard for injecting build-time secrets without committing them to source. Supabase URL and anon key are not truly secret (they're public), but this pattern is cleaner than hardcoding.

### Pattern 2: Nullable Supabase Client Provider

```dart
// flutter_app/lib/shared/providers/supabase_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the SupabaseClient if initialized, null if optional sync is disabled.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null; // Supabase.initialize() was not called
  }
});
```

### Pattern 3: SyncState Enum (v1.1 parity)

```dart
// flutter_app/lib/shared/providers/sync_provider.dart
enum SyncStatus {
  disabled,   // Supabase not configured
  offline,    // No network
  pending,    // Queued writes waiting for connectivity
  syncing,    // Push or pull in progress
  synced,     // Last sync successful
  error,      // Last sync failed
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final bool isAuthenticated;

  const SyncState({
    this.status = SyncStatus.disabled,
    this.lastSyncedAt,
    this.isAuthenticated = false,
  });

  SyncState copyWith({SyncStatus? status, DateTime? lastSyncedAt, bool? isAuthenticated}) =>
      SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}
```

### Pattern 4: SyncNotifier (Riverpod 3.x NotifierProvider)

Follows the `NotifierProvider` pattern already established in the app (see `OnboardingStatusNotifier`, `WorkoutSessionNotifier`):

```dart
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final supabase = ref.watch(supabaseClientProvider);
    if (supabase == null) return const SyncState(status: SyncStatus.disabled);

    // Listen to auth changes
    supabase.auth.onAuthStateChange.listen((data) {
      final isAuth = data.session != null;
      state = state.copyWith(isAuthenticated: isAuth);
      if (isAuth) _drainQueueAndPull();
    });

    // Listen to connectivity
    ref.listen(isOnlineProvider, (_, next) {
      next.whenData((isOnline) {
        if (!isOnline) {
          state = state.copyWith(status: SyncStatus.offline);
        } else if (state.isAuthenticated) {
          _drainQueueAndPull();
        }
      });
    });

    return const SyncState(status: SyncStatus.offline);
  }

  Future<void> syncAfterWorkout(int workoutId) async { ... }
  Future<void> _drainQueueAndPull() async { ... }
  Future<void> pullFromCloud() async { ... }
  Future<void> signIn(String email, String password) async { ... }
  Future<void> signOut() async { ... }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
```

**Critical**: Use `if (mounted)` (not `if (context.mounted)`) for async gaps in ConsumerState — but SyncNotifier is a `Notifier`, not a widget, so `mounted` is not directly applicable. Instead, store the subscription and cancel on dispose via `ref.onDispose`.

### Pattern 5: SyncService (push/pull/queue)

The SyncService mirrors v1.1's `sync-engine.ts` but adapted for Drift (integer IDs, `syncId` UUID bridge):

```dart
// flutter_app/lib/services/sync_service.dart
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  static const _queueKey = 'sync_pending_workout_ids';

  // Push single workout (and its sets) to Supabase
  Future<void> pushWorkout(int localWorkoutId) async {
    final userId = _supabase.auth.currentUser!.id;
    // 1. Fetch workout from Drift
    // 2. Ensure syncId is populated (generate UUID v4 if null, save back to Drift)
    // 3. Fetch completed sets
    // 4. Upsert to Supabase (completed_workouts, completed_sets)
    // 5. Use withRetry (3 attempts, exponential backoff)
  }

  // Pull all user's cloud data, merge into Drift via syncId matching
  Future<void> pullLatest() async { ... }

  // Upload all local data (first-time sync after sign-in)
  Future<void> uploadAllLocalData() async { ... }

  // Queue management (SharedPreferences)
  Future<void> enqueue(int workoutId) async { ... }
  Future<void> dequeue(int workoutId) async { ... }
  Future<List<int>> getQueue() async { ... }
  Future<void> clearQueue() async { ... }

  // Retry wrapper (mirrors v1.1 withRetry)
  Future<T> withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async { ... }
}
```

### Pattern 6: UUID Bridge — Drift Schema Migration v4

The Drift schema needs `syncId` columns on all tables that sync to Supabase. This requires a migration from v3 → v4:

```dart
// Additions to app_database.dart table definitions:
class CompletedWorkouts extends Table {
  // ... existing columns ...
  TextColumn get syncId => text().nullable().unique()(); // UUID for Supabase PK
}

class CompletedSets extends Table {
  // ... existing columns ...
  TextColumn get syncId => text().nullable().unique()();
}

class ActiveCycles extends Table {
  // ... existing columns ...
  TextColumn get syncId => text().nullable().unique()();
}

class OneRepMaxes extends Table {
  // ... existing columns ...
  TextColumn get syncId => text().nullable().unique()();
}

class PersonalRecords extends Table {
  // ... existing columns ...
  TextColumn get syncId => text().nullable().unique()();
}
// Note: Users table maps to auth.uid() — no syncId needed; user_id in Supabase IS auth.uid()

// In AppDatabase migration:
@override
int get schemaVersion => 4;

onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) { await m.createTable(activeCycles); }
  if (from < 3) {
    await m.createTable(completedWorkouts);
    await m.createTable(completedSets);
    await m.createTable(oneRepMaxes);
    await m.createTable(personalRecords);
  }
  if (from < 4) {
    // Add syncId columns for cloud sync bridge
    await m.addColumn(completedWorkouts, completedWorkouts.syncId);
    await m.addColumn(completedSets, completedSets.syncId);
    await m.addColumn(activeCycles, activeCycles.syncId);
    await m.addColumn(oneRepMaxes, oneRepMaxes.syncId);
    await m.addColumn(personalRecords, personalRecords.syncId);
  }
},
```

### Pattern 7: Supabase Transforms (Drift → Supabase rows)

Similar to v1.1 `toSupabaseRows` / `fromSupabaseRows`:

```dart
// Drift integer IDs → Supabase UUID PKs
Map<String, dynamic> workoutToSupabaseRow(
  CompletedWorkout w, String authUserId, String syncId) {
  return {
    'id': syncId,                         // UUID (syncId)
    'user_id': authUserId,                // auth.uid()
    'active_cycle_id': w.activeCycleSyncId, // FK to active_cycles.syncId
    'program_id': w.programId,
    'week': w.week,
    'day': w.day,
    'session_id': w.sessionId,
    'completed_at': w.completedAt.toIso8601String(),
    'duration': w.duration,
    'notes': w.notes,
    'updated_at': DateTime.now().toIso8601String(),
  };
}
```

**Key mapping**: Local integer FKs (`activeCycleId`) must be resolved to their `syncId` UUIDs before pushing. This means push order matters: cycles before workouts before sets.

### Pattern 8: Sync Status UI Badge

```dart
// flutter_app/lib/shared/widgets/sync_status_badge.dart
class SyncStatusBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    return switch (syncState.status) {
      SyncStatus.disabled => const SizedBox.shrink(),
      SyncStatus.offline  => const Icon(Icons.cloud_off, color: Colors.grey),
      SyncStatus.pending  => const Icon(Icons.cloud_upload, color: Colors.orange),
      SyncStatus.syncing  => const SizedBox(width: 20, height: 20,
                               child: CircularProgressIndicator(strokeWidth: 2)),
      SyncStatus.synced   => const Icon(Icons.cloud_done, color: Colors.green),
      SyncStatus.error    => const Icon(Icons.cloud_off, color: Colors.red),
    };
  }
}
```

### Anti-Patterns to Avoid

- **Don't expose `state` setter outside Notifier**: Riverpod 3.x marks `.state` as `@protected`. Expose `syncAfterWorkout()`, `signIn()`, `signOut()` as methods on `SyncNotifier` — callers use `ref.read(syncProvider.notifier).syncAfterWorkout(id)`.
- **Don't use `StateProvider` for sync state**: Legacy in Riverpod 3.x. Use `NotifierProvider<SyncNotifier, SyncState>`.
- **Don't push before ensuring syncId is populated**: Always generate + save syncId to Drift *before* calling Supabase upsert. If push fails, the syncId is already saved and will be reused on retry.
- **Don't pull FK-referenced tables out of order**: Pull order: users → active_cycles → completed_workouts → completed_sets → one_rep_maxes → personal_records.
- **Don't call `Supabase.instance.client` without try/catch**: If `Supabase.initialize()` was never called (sync disabled), this throws. Use the `supabaseClientProvider` nullable pattern instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session persistence | Custom secure token storage | `supabase_flutter` built-in (uses `shared_preferences`) | Already handled; re-implementing causes token duplication |
| UUID generation | Custom ID scheme | `uuid` package (v4) | UUID v4 is collision-safe; custom schemes aren't |
| Auth state streaming | Manual polling | `supabase.auth.onAuthStateChange` stream | Built into supabase_flutter, handles token refresh |
| Exponential backoff retry | Custom sleep/retry | Implement `withRetry<T>` utility (same pattern as v1.1) | Simple enough to own; no package needed |
| Offline queue | Custom DB table | `SharedPreferences` JSON list | Matches v1.1 localStorage approach; already in pubspec |
| Network detection | Platform channels | `connectivity_plus` (already installed) | `isOnlineProvider` already exists in codebase |

**Key insight:** `supabase_flutter` handles the hard parts (PKCE auth flow, token refresh, session persistence). The sync logic itself — push, pull, queue, retry — is a small amount of straightforward Dart code, as demonstrated by the v1.1 implementation in ~200 lines of TypeScript.

---

## Common Pitfalls

### Pitfall 1: Supabase.instance throws if not initialized
**What goes wrong:** Calling `Supabase.instance.client` before `Supabase.initialize()` throws a `StateError`. This happens in tests or when sync is disabled.
**Why it happens:** `supabase_flutter` uses a singleton that must be initialized first.
**How to avoid:** Use the `supabaseClientProvider` that wraps the call in try/catch and returns `null`. All sync operations null-check the client before proceeding.
**Warning signs:** `StateError: No Supabase instance has been created` in logs.

### Pitfall 2: Push FK ordering
**What goes wrong:** Pushing `completed_workouts` before the referenced `active_cycles` row exists in Supabase causes FK constraint violation.
**Why it happens:** Supabase schema has FK: `completed_workouts.active_cycle_id → active_cycles.id`. Push order matters.
**How to avoid:** Always push in dependency order: `active_cycles` → `completed_workouts` → `completed_sets`. The offline queue stores workout IDs; resolve their parent cycle syncId before push.
**Warning signs:** Supabase upsert error `violates foreign key constraint`.

### Pitfall 3: syncId null on re-push attempt
**What goes wrong:** If a push fails mid-way (workout pushed, sets fail), next retry generates a new UUID for the same workout, causing duplicate cloud rows.
**Why it happens:** syncId is generated fresh each time if not persisted first.
**How to avoid:** Write syncId to Drift *before* any Supabase call. If push fails, the persisted syncId is reused on retry. Supabase upsert (not insert) handles duplicates gracefully.

### Pitfall 4: integer FK not resolving to UUID FK
**What goes wrong:** `completed_workouts` row in Drift has `activeCycleId: 3` (integer). The Supabase `completed_workouts.active_cycle_id` expects a UUID. Pushing the integer FK causes type errors.
**Why it happens:** Drift integer IDs vs Supabase UUID PKs mismatch.
**How to avoid:** Before pushing a workout, look up the `activeCycle.syncId` from Drift and use that UUID in the Supabase row. If the parent cycle doesn't have a syncId yet, push it first.

### Pitfall 5: Auth state not available on app restart
**What goes wrong:** After restart, app shows `SyncStatus.offline` even when user was previously authenticated.
**Why it happens:** Riverpod provider rebuilds on start; supabase_flutter needs one async call to restore session from SharedPreferences.
**How to avoid:** In `SyncNotifier.build()`, call `supabase.auth.currentSession` synchronously (this is populated from SharedPreferences by supabase_flutter after `Supabase.initialize()`). Then listen to `onAuthStateChange` for future changes.

### Pitfall 6: Drift migration test setup
**What goes wrong:** Widget/unit tests using `NativeDatabase.memory()` fail after adding syncId columns because test setup creates tables via `onCreate` which runs `createAll()` — this is fine. But if tests create `CompletedWorkoutsCompanion` without `syncId`, the companion still works (nullable column).
**Why it happens:** No issue for existing tests since syncId is nullable.
**How to avoid:** Existing test `NativeDatabase.memory(setup: (rawDb) { rawDb.execute('PRAGMA foreign_keys = ON'); })` pattern is sufficient — no changes needed to existing tests.

### Pitfall 7: `if (mounted)` in async Notifier operations
**What goes wrong:** `SyncNotifier` is a Riverpod `Notifier`, not a `ConsumerState`. The `mounted` check pattern is for `ConsumerState` widgets.
**Why it happens:** Conflating widget lifecycle with Notifier lifecycle.
**How to avoid:** In `SyncNotifier`, use `ref.onDispose` to cancel stream subscriptions. Check that the notifier hasn't been disposed by catching `StateError` on `state =` assignments, or use `keepAlive` pattern with `ref.keepAlive()`.

---

## Code Examples

### Supabase Client Init + Provider

```dart
// Source: supabase_flutter docs + pub.dev/packages/supabase_flutter
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  runApp(ProviderScope(
    overrides: [
      onboardingCompleteProvider.overrideWith(
        () => OnboardingStatusNotifier(initialState: onboardingComplete),
      ),
    ],
    child: const SundeeFundeeApp(),
  ));
}
```

### Auth Sign-In

```dart
// Source: supabase_flutter v2.x API
Future<void> signIn(String email, String password) async {
  final supabase = ref.read(supabaseClientProvider);
  if (supabase == null) return;
  state = state.copyWith(status: SyncStatus.syncing);
  try {
    await supabase.auth.signInWithPassword(email: email, password: password);
    // onAuthStateChange fires automatically — SyncNotifier handles the rest
  } on AuthException catch (e) {
    state = state.copyWith(status: SyncStatus.error);
    rethrow;
  }
}
```

### Auth State Listener in Notifier

```dart
// Source: supabase_flutter onAuthStateChange pattern
@override
SyncState build() {
  final supabase = ref.watch(supabaseClientProvider);
  if (supabase == null) return const SyncState(status: SyncStatus.disabled);

  final subscription = supabase.auth.onAuthStateChange.listen((data) {
    final isAuth = data.session != null;
    if (isAuth != state.isAuthenticated) {
      state = state.copyWith(isAuthenticated: isAuth);
      if (isAuth) _drainQueueAndPull();
      if (!isAuth) state = state.copyWith(status: SyncStatus.offline);
    }
  });
  ref.onDispose(subscription.cancel);

  // Restore auth from persisted session (synchronously available post-initialize)
  final isAuth = supabase.auth.currentSession != null;
  return SyncState(
    status: isAuth ? SyncStatus.synced : SyncStatus.offline,
    isAuthenticated: isAuth,
  );
}
```

### SharedPreferences Queue

```dart
// Source: mirrors v1.1 sync-queue.ts using SharedPreferences
static const _queueKey = 'sync_pending_workout_ids';

Future<void> enqueue(int workoutId) async {
  final prefs = await SharedPreferences.getInstance();
  final queue = await getQueue();
  if (!queue.contains(workoutId)) {
    await prefs.setString(_queueKey, jsonEncode([...queue, workoutId]));
  }
}

Future<List<int>> getQueue() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_queueKey);
  if (raw == null) return [];
  return (jsonDecode(raw) as List).cast<int>();
}
```

### Supabase Upsert Pattern

```dart
// Source: supabase_flutter v2.x + Dart docs
// Push a workout to Supabase (upsert for idempotency)
Future<void> pushWorkout(int localWorkoutId) async {
  final supabase = _supabase;
  final userId = supabase.auth.currentUser!.id;

  // 1. Fetch from Drift
  final workout = await (_db.select(_db.completedWorkouts)
    ..where((w) => w.id.equals(localWorkoutId)))
    .getSingleOrNull();
  if (workout == null) throw Exception('Workout $localWorkoutId not found');

  // 2. Ensure syncId exists (generate + persist if null)
  final workoutSyncId = workout.syncId ?? const Uuid().v4();
  if (workout.syncId == null) {
    await (_db.update(_db.completedWorkouts)
      ..where((w) => w.id.equals(localWorkoutId)))
      .write(CompletedWorkoutsCompanion(syncId: Value(workoutSyncId)));
  }

  // 3. Resolve parent cycle's syncId (must exist)
  final cycle = await (_db.select(_db.activeCycles)
    ..where((c) => c.id.equals(workout.activeCycleId)))
    .getSingleOrNull();
  final cycleSyncId = cycle?.syncId ?? await _ensureCycleSyncId(workout.activeCycleId, userId);

  // 4. Build and upsert row
  await withRetry(() async {
    final result = await supabase.from('completed_workouts').upsert({
      'id': workoutSyncId,
      'user_id': userId,
      'active_cycle_id': cycleSyncId,
      'program_id': workout.programId,
      'week': workout.week,
      'day': workout.day,
      'session_id': workout.sessionId,
      'completed_at': workout.completedAt.toIso8601String(),
      'duration': workout.duration,
      'notes': workout.notes,
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (result.error != null) throw result.error!;
  });
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_secure_storage` for session tokens | `supabase_flutter` v2.x uses `shared_preferences` natively | supabase_flutter v2.0 | No extra package needed |
| `StateProvider` for sync state | `NotifierProvider<SyncNotifier, SyncState>` | Riverpod 3.x (app-wide decision) | Must expose mutations as Notifier methods |
| Manual PKCE auth callback route | supabase_flutter handles internally via `app_links` | supabase_flutter v2.x | No route handler needed in Flutter (unlike web) |

**Deprecated/outdated:**
- `StateProvider`: Legacy in Riverpod 3.x — already decided in STATE.md, do not use
- `supabase_flutter` v1.x auth pattern with `SupabaseAuth.initialize()`: Replaced in v2.x with `Supabase.initialize()`

---

## v1.1 Parity Mapping

| v1.1 Web Component | Flutter Equivalent | Notes |
|--------------------|-------------------|-------|
| `src/lib/sync/sync-engine.ts` | `lib/services/sync_service.dart` | Direct port; replace Dexie calls with Drift |
| `src/lib/sync/sync-queue.ts` | Part of `SyncService` (SharedPreferences) | localStorage → SharedPreferences |
| `src/lib/sync/sync-transforms.ts` | Part of `SyncService` (toSupabaseRow methods) | Add UUID bridge logic |
| `src/contexts/user-context.tsx` (sync parts) | `lib/shared/providers/sync_provider.dart` (SyncNotifier) | Riverpod NotifierProvider pattern |
| `src/lib/supabase/client.ts` | `lib/shared/providers/supabase_provider.dart` | Nullable client if not configured |
| `SyncStatus` type | `SyncStatus` enum | Same 5 states: offline, pending, syncing, synced, error (+ disabled) |
| `useOnlineStatus` hook | `isOnlineProvider` (StreamProvider) | Already exists in codebase |
| Sync nudge post-workout | `syncAfterWorkout(workoutId)` call in `WorkoutSessionNotifier.completeWorkout()` | Add one call after repo.saveWorkout() |

---

## Open Questions

1. **Auth UI scope**: Does Phase 13 need a full email+password auth screen with sign-up, or sign-in only? The v1.1 had magic-link + Google OAuth — for Flutter parity, email+password is simplest. No existing auth screen in Flutter app. **Recommendation**: Build minimal email+password auth screen (sign-in + create account) — parity goal doesn't specify auth method, just "user can optionally authenticate."

2. **Pull conflict resolution**: When cloud data (pulled from Supabase) has a record with the same `syncId` as local Drift data, which wins? v1.1 used `bulkPut` (cloud wins). **Recommendation**: Cloud wins on pull (matches v1.1 semantics). Local writes are always persisted first, then pushed — no concurrent writes scenario in mobile-first single-device use.

3. **Personal Records and `workout_id` FK**: `personal_records.workout_id` is a UUID FK in Supabase. This requires resolving the local `workoutId` (integer) to its `syncId` before push. Push order: cycles → workouts → sets/PRs/1RMs. **Recommendation**: Push PRs last, after workouts have syncIds.

4. **Users table sync**: Local `users` table uses integer PK; Supabase `users` uses `uuid PK + user_id = auth.uid()`. The Supabase `users.id` is not the local user ID — it's a separate UUID. **Recommendation**: Don't sync the users table the same way. Instead, on first auth, upsert the user profile to Supabase `users` using `auth.uid()` as `user_id`. No syncId needed for users — just check if a row exists for `user_id = auth.uid()`.

---

## Sources

### Primary (HIGH confidence)
- `pub.dev/packages/supabase_flutter` — v2.12.0, published 2025-12-11; dependency list confirmed
- `pub.dev/packages/uuid` — v4.5.3, published 2026-02-21
- `supabase.com/docs/reference/dart/initializing` — Official init pattern
- `supabase.com/docs/reference/dart/auth-onauthstatechange` — Auth stream pattern
- Codebase: `flutter_app/lib/data/database/app_database.dart` — Drift schema v3 (integer PKs)
- Codebase: `supabase/schema.sql` — Production Supabase schema (UUID PKs, RLS)
- Codebase: `src/lib/sync/` — v1.1 sync engine (TypeScript reference implementation)
- Codebase: `src/contexts/user-context.tsx` — v1.1 sync state machine and all 5 SyncStatus states
- Codebase: `flutter_app/lib/core/connectivity/` + `flutter_app/lib/shared/providers/connectivity_provider.dart` — Existing connectivity infrastructure

### Secondary (MEDIUM confidence)
- Codebase: `flutter_app/integration_test/helpers/fake_connectivity.dart` — Confirmed `MockPlatformInterfaceMixin` pattern for test mocking
- `pub.dev/api/packages/supabase_flutter` — confirmed `shared_preferences` is a direct dependency (not `flutter_secure_storage`)

### Tertiary (LOW confidence)
- Pattern for `String.fromEnvironment` + `--dart-define` for Supabase credentials: common Flutter convention, verified conceptually but not tested in this specific project setup

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified versions from pub.dev API; confirmed shared_preferences already in pubspec
- Architecture: HIGH — derived from existing codebase patterns (Riverpod 3.x NotifierProvider, connectivity_plus, Drift), v1.1 reference implementation, and Supabase official docs
- Pitfalls: HIGH — UUID/integer mismatch and FK ordering derived from direct schema inspection; other pitfalls from v1.1 production experience
- UUID bridge: HIGH — Drift integer PKs vs Supabase UUID PKs is a confirmed schema fact, not an assumption

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (supabase_flutter is active; Riverpod 3.x patterns are stable)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_provider.dart';
import 'database_provider.dart';
import 'supabase_provider.dart';
import '../../services/sync_service.dart';

// ---------------------------------------------------------------------------
// SyncStatus enum
// ---------------------------------------------------------------------------

/// Represents the current sync status of the app.
enum SyncStatus {
  /// Supabase is not configured (compile-time env vars absent).
  disabled,

  /// No network connection (or user is not authenticated).
  offline,

  /// Writes are queued locally waiting for connectivity + auth.
  pending,

  /// A push or pull is actively in progress.
  syncing,

  /// Last sync completed successfully.
  synced,

  /// Last sync attempt failed.
  error,
}

// ---------------------------------------------------------------------------
// SyncState — immutable value class
// ---------------------------------------------------------------------------

/// Immutable snapshot of sync state.
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final bool isAuthenticated;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.disabled,
    this.lastSyncedAt,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    bool? isAuthenticated,
    String? errorMessage,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ---------------------------------------------------------------------------
// SyncNotifier — reactive state machine
// ---------------------------------------------------------------------------

/// Reactive state machine for sync status.
///
/// Transitions:
///   - disabled   → Supabase not configured
///   - offline    → no network / not authenticated
///   - pending    → writes queued, waiting for online + auth
///   - syncing    → push or pull in progress
///   - synced     → last operation succeeded
///   - error      → last operation failed
///
/// Listens to:
///   - supabase.auth.onAuthStateChange (stream)
///   - isOnlineProvider (Riverpod stream provider)
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final supabase = ref.watch(supabaseClientProvider);

    // Supabase not configured — sync permanently disabled.
    if (supabase == null) return const SyncState(status: SyncStatus.disabled);

    // --- Auth state listener ---
    final authSub = supabase.auth.onAuthStateChange.listen((data) {
      final isAuth = data.session != null;
      if (isAuth != state.isAuthenticated) {
        _trySetState(state.copyWith(isAuthenticated: isAuth));
        if (isAuth) {
          _onAuthenticated();
        } else {
          _trySetState(
            state.copyWith(
              status: SyncStatus.offline,
              isAuthenticated: false,
            ),
          );
        }
      }
    });
    ref.onDispose(authSub.cancel);

    // --- Connectivity listener ---
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (_, next) {
      next.whenData((isOnline) {
        if (!isOnline) {
          _trySetState(state.copyWith(status: SyncStatus.offline));
        } else if (state.isAuthenticated) {
          _drainQueueIfNeeded();
        }
      });
    });

    // Seed state from current auth session (restored by supabase_flutter).
    final isAuth = supabase.auth.currentSession != null;
    return SyncState(
      status: isAuth ? SyncStatus.synced : SyncStatus.offline,
      isAuthenticated: isAuth,
    );
  }

  // ---------------------------------------------------------------------------
  // Public methods
  // ---------------------------------------------------------------------------

  /// Call after completing a local workout.
  ///
  /// - Online + authenticated → pushes immediately (syncing → synced / error).
  /// - Offline or unauthenticated → enqueues for later retry (→ pending).
  Future<void> syncAfterWorkout(int workoutId) async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) return;

    final isAuth = supabase.auth.currentSession != null;
    if (!isAuth) {
      final service = _createService();
      await service?.enqueue(workoutId);
      _trySetState(state.copyWith(status: SyncStatus.pending));
      return;
    }

    // Check connectivity via provider snapshot.
    final connectivityAsync = ref.read(isOnlineProvider);
    final isOnline = connectivityAsync.asData?.value ?? false;

    if (!isOnline) {
      final service = _createService();
      await service?.enqueue(workoutId);
      _trySetState(state.copyWith(status: SyncStatus.pending));
      return;
    }

    // Online + authenticated — push now.
    final service = _createService();
    if (service == null) return;

    _trySetState(state.copyWith(status: SyncStatus.syncing));
    try {
      await service.pushWorkout(workoutId);
      _trySetState(
        state.copyWith(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      // Enqueue for retry so it isn't lost.
      await service.enqueue(workoutId);
      _trySetState(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Public method to trigger a manual pull from cloud.
  Future<void> pullFromCloud() async {
    final service = _createService();
    if (service == null) return;
    _trySetState(state.copyWith(status: SyncStatus.syncing));
    try {
      await service.pullLatest();
      _trySetState(
        state.copyWith(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      _trySetState(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private methods
  // ---------------------------------------------------------------------------

  /// Called when the user signs in.  Uploads all local unsync'd data, pulls
  /// cloud, then drains the offline queue.
  Future<void> _onAuthenticated() async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final service = _createService();
    if (service == null) return;

    _trySetState(state.copyWith(status: SyncStatus.syncing));
    try {
      await service.uploadAllLocalData(userId);
      await service.pullLatest();
      await service.drainQueue();
      _trySetState(
        state.copyWith(
          status: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          errorMessage: null,
        ),
      );
    } catch (e) {
      _trySetState(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Drains the offline retry queue when we come back online.
  Future<void> _drainQueueIfNeeded() async {
    final service = _createService();
    if (service == null) return;

    final queue = await service.getQueue();
    if (queue.isEmpty) return;

    _trySetState(state.copyWith(status: SyncStatus.syncing));
    try {
      await service.drainQueue();
      final remaining = await service.getQueue();
      _trySetState(
        state.copyWith(
          status:
              remaining.isEmpty ? SyncStatus.synced : SyncStatus.pending,
          lastSyncedAt:
              remaining.isEmpty ? DateTime.now() : state.lastSyncedAt,
          errorMessage: null,
        ),
      );
    } catch (e) {
      _trySetState(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Convenience factory — returns null when Supabase is unconfigured.
  SyncService? _createService() {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) return null;
    final db = ref.read(databaseProvider);
    return SyncService(db: db, supabase: supabase);
  }

  /// Safe state setter that silently ignores [StateError] thrown when the
  /// notifier is disposed mid async-gap.
  void _trySetState(SyncState newState) {
    try {
      state = newState;
    } on StateError {
      // Notifier was disposed before we could update state — this is expected.
    }
  }
}

// ---------------------------------------------------------------------------
// Provider declaration
// ---------------------------------------------------------------------------

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

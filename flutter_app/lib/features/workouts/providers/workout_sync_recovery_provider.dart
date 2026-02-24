import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workout_sync_queue_store.dart';

class WorkoutSyncRecoveryState {
  const WorkoutSyncRecoveryState({
    required this.pendingWriteCount,
    required this.isSyncing,
    required this.blocking,
    this.message,
  });

  const WorkoutSyncRecoveryState.idle()
      : pendingWriteCount = 0,
        isSyncing = false,
        blocking = false,
        message = null;

  final int pendingWriteCount;
  final bool isSyncing;
  final bool blocking;
  final String? message;

  bool get hasPendingWrites => pendingWriteCount > 0;

  WorkoutSyncRecoveryState copyWith({
    int? pendingWriteCount,
    bool? isSyncing,
    bool? blocking,
    String? message,
  }) {
    return WorkoutSyncRecoveryState(
      pendingWriteCount: pendingWriteCount ?? this.pendingWriteCount,
      isSyncing: isSyncing ?? this.isSyncing,
      blocking: blocking ?? this.blocking,
      message: message,
    );
  }
}

final Provider<WorkoutSyncQueueStore> workoutSyncQueueStoreProvider =
    Provider<WorkoutSyncQueueStore>((Ref ref) {
  return WorkoutSyncQueueStore();
});

class WorkoutSyncRecoveryController extends Notifier<WorkoutSyncRecoveryState> {
  @override
  WorkoutSyncRecoveryState build() {
    unawaited(refreshFromQueue());
    return const WorkoutSyncRecoveryState.idle();
  }

  Future<void> refreshFromQueue() async {
    final List<PendingWorkoutWriteIntent> pending =
        await ref.read(workoutSyncQueueStoreProvider).readPendingWrites();
    state = state.copyWith(
      pendingWriteCount: pending.length,
      isSyncing: false,
      blocking: state.blocking && pending.isNotEmpty,
      message: pending.isEmpty ? null : state.message,
    );
  }

  void markSyncing() {
    state = state.copyWith(
      isSyncing: true,
      message: state.message,
    );
  }

  void markBlocking({required String message}) {
    state = state.copyWith(
      isSyncing: false,
      blocking: true,
      message: message,
    );
  }

  Future<void> queuePendingWrites(
    List<PendingWorkoutWriteIntent> writes, {
    required String message,
  }) async {
    await ref.read(workoutSyncQueueStoreProvider).enqueuePendingWrites(writes);
    final List<PendingWorkoutWriteIntent> pending =
        await ref.read(workoutSyncQueueStoreProvider).readPendingWrites();
    state = WorkoutSyncRecoveryState(
      pendingWriteCount: pending.length,
      isSyncing: false,
      blocking: true,
      message: message,
    );
  }

  Future<void> removeResolvedWrites(Set<String> ids) async {
    await ref.read(workoutSyncQueueStoreProvider).removePendingWriteIds(ids);
    final List<PendingWorkoutWriteIntent> pending =
        await ref.read(workoutSyncQueueStoreProvider).readPendingWrites();
    state = WorkoutSyncRecoveryState(
      pendingWriteCount: pending.length,
      isSyncing: false,
      blocking: pending.isNotEmpty,
      message: pending.isEmpty ? null : state.message,
    );
  }

  void clearBlocking() {
    state = state.copyWith(
      blocking: false,
      message: null,
    );
  }
}

final NotifierProvider<WorkoutSyncRecoveryController, WorkoutSyncRecoveryState>
    workoutSyncRecoveryProvider =
    NotifierProvider<WorkoutSyncRecoveryController, WorkoutSyncRecoveryState>(
  WorkoutSyncRecoveryController.new,
);

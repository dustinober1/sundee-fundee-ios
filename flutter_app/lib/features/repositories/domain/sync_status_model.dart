enum SyncFreshness {
  fresh,
  stale,
  unknown,
}

class SyncStatusModel {
  const SyncStatusModel({
    required this.fromCache,
    required this.pendingWrites,
    required this.lastSyncedAt,
    required this.freshness,
  });

  final bool fromCache;
  final bool pendingWrites;
  final DateTime? lastSyncedAt;
  final SyncFreshness freshness;

  factory SyncStatusModel.fromLastSynced({
    required bool fromCache,
    required bool pendingWrites,
    required DateTime? lastSyncedAt,
    DateTime? now,
    Duration staleAfter = const Duration(hours: 24),
  }) {
    final DateTime? timestamp = lastSyncedAt;
    final SyncFreshness freshness;
    if (timestamp == null) {
      freshness = SyncFreshness.unknown;
    } else {
      final DateTime clock = now ?? DateTime.now();
      freshness = clock.difference(timestamp) > staleAfter
          ? SyncFreshness.stale
          : SyncFreshness.fresh;
    }

    return SyncStatusModel(
      fromCache: fromCache,
      pendingWrites: pendingWrites,
      lastSyncedAt: timestamp,
      freshness: freshness,
    );
  }
}

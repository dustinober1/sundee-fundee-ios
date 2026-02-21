import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';

/// AppBar icon badge that reflects current sync status.
///
/// Renders [SizedBox.shrink] when sync is disabled (Supabase not configured),
/// making it invisible without disrupting the AppBar layout.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    return KeyedSubtree(
      key: const Key('sync-status-badge'),
      child: switch (syncState.status) {
        SyncStatus.disabled => const SizedBox.shrink(),
        SyncStatus.offline => const Icon(Icons.cloud_off, color: Colors.grey),
        SyncStatus.pending =>
          const Icon(Icons.cloud_upload, color: Colors.orange),
        SyncStatus.syncing => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        SyncStatus.synced => const Icon(Icons.cloud_done, color: Colors.green),
        SyncStatus.error => const Icon(Icons.cloud_off, color: Colors.red),
      },
    );
  }
}

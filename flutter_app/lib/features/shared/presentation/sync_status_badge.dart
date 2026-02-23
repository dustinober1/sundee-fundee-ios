import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../repositories/domain/sync_status_model.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  final SyncStatusModel status;

  @override
  Widget build(BuildContext context) {
    final String label = _label();
    final IconData icon = _icon();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    if (status.pendingWrites) {
      return Icons.sync;
    }
    if (status.fromCache) {
      return Icons.cloud_off;
    }
    if (status.freshness == SyncFreshness.stale) {
      return Icons.schedule;
    }
    return Icons.cloud_done;
  }

  String _label() {
    if (status.pendingWrites) {
      return 'Syncing changes';
    }
    if (status.fromCache) {
      return 'Offline cache';
    }
    if (status.lastSyncedAt == null) {
      return 'Not yet synced';
    }
    final String timestamp = DateFormat.yMMMd().add_jm().format(
          status.lastSyncedAt!.toLocal(),
        );
    if (status.freshness == SyncFreshness.stale) {
      return 'Stale ($timestamp)';
    }
    return 'Last synced $timestamp';
  }
}

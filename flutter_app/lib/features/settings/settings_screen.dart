import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../shared/providers/sync_provider.dart';

/// Minimal settings screen for sync-related settings.
///
/// Shows auth status, last synced time, and sign-out button when authenticated.
/// Shows sign-in prompt when not authenticated.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      key: const Key('settings-screen'),
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: authState.isAuthenticated
            ? _AuthenticatedContent(
                userEmail: authState.userEmail,
                lastSyncedAt: syncState.lastSyncedAt,
              )
            : const _UnauthenticatedContent(),
      ),
    );
  }
}

class _AuthenticatedContent extends ConsumerWidget {
  final String? userEmail;
  final DateTime? lastSyncedAt;

  const _AuthenticatedContent({
    required this.userEmail,
    required this.lastSyncedAt,
  });

  String _formatLastSynced(DateTime? dt) {
    if (dt == null) return 'Never';
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          key: const Key('settings-user-email'),
          userEmail ?? '',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          key: const Key('settings-last-synced'),
          'Last synced: ${_formatLastSynced(lastSyncedAt)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          key: const Key('settings-sign-out'),
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) context.go('/dashboard');
          },
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}

class _UnauthenticatedContent extends StatelessWidget {
  const _UnauthenticatedContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Not signed in',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/auth'),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}

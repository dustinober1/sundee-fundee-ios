import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Settings', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            const Text(
              'Firebase and account settings will be expanded in the next phase.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (ref.watch(authSessionStreamProvider).asData?.value.user?.email == 'dustinober@me.com')
              ElevatedButton.icon(
                onPressed: () => context.push('/admin/programs'),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin: Manage Programs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

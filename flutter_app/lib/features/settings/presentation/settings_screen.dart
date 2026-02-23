import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/enums.dart';
import '../../auth/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileStreamProvider).asData?.value;
    final bool isFemale = userProfile?.gender == Gender.female;

    return Scaffold(
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(userProfile?.name ?? 'User'),
            subtitle: Text(ref
                    .watch(authSessionStreamProvider)
                    .asData
                    ?.value
                    .user
                    ?.email ??
                'Logged in'),
          ),
          if (ref.watch(authSessionStreamProvider).asData?.value.user?.email ==
              'dustinober@me.com')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin: Manage Programs'),
              onTap: () => context.push('/admin/programs'),
              tileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.1),
            ),
          const Divider(),
          if (isFemale) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Cycle Tracking'),
              subtitle: const Text('Hormone-aware training recommendations'),
              value: userProfile?.cycleTrackingEnabled ?? false,
              onChanged: (bool value) {
                ref.read(authRepositoryProvider).updateCycleTracking(value);
              },
            ),
            const Divider(),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Edit Onboarding Answers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/onboarding-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined),
            title: const Text('Injury Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/injury-profile'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Support & Legal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal', extra: {'tabIndex': 0}),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal', extra: {'tabIndex': 1}),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Legal Disclaimer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal', extra: {'tabIndex': 2}),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Contact Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement Support link
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Sundee Fundee'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement About screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text(
                      'This action is permanent and will delete your profile. '
                      'Workout history and personal records will no longer be '
                      'associated with your email.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete Permanently'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true && context.mounted) {
                try {
                  await ref.read(authRepositoryProvider).deleteAccount();
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Sundee Fundee v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

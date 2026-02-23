import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/cycle_models.dart';
import '../../../domain/models/user_model.dart';
import '../../cycle/providers.dart';
import '../../repositories/providers.dart';
import '../../user/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Settings'),
            floating: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const _CycleCustomizationSection(),
              const _TrainingPreferencesSection(),
              const _ProfileManagementSection(),
              const _AppInfoSection(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CycleCustomizationSection extends ConsumerWidget {
  const _CycleCustomizationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleSettingsAsync = ref.watch(cycleSettingsProvider);
    final userId = ref.watch(cycleUserIdProvider);

    if (userId == null) return const SizedBox.shrink();

    return cycleSettingsAsync.when(
      data: (settings) {
        final currentSettings = settings ??
            CycleSettingsModel(
              id: 'cycle',
              userId: userId,
              averageCycleLength: 28,
              averagePeriodLength: 5,
              lutealPhaseLength: 14,
              enabledSymptomIds: [],
              notificationsEnabled: false,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Cycle Customization',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: const Text('Average Cycle Length'),
              subtitle: Text('${currentSettings.averageCycleLength} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showNumberPicker(
                context,
                ref,
                'Average Cycle Length',
                currentSettings.averageCycleLength,
                (val) => _saveSettings(
                  ref,
                  currentSettings.copyWith(averageCycleLength: val),
                ),
                min: 21,
                max: 35,
              ),
            ),
            ListTile(
              title: const Text('Period Length'),
              subtitle: Text('${currentSettings.averagePeriodLength} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showNumberPicker(
                context,
                ref,
                'Period Length',
                currentSettings.averagePeriodLength,
                (val) => _saveSettings(
                  ref,
                  currentSettings.copyWith(averagePeriodLength: val),
                ),
                min: 2,
                max: 10,
              ),
            ),
            ListTile(
              title: const Text('Luteal Phase Length'),
              subtitle: Text('${currentSettings.lutealPhaseLength} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showNumberPicker(
                context,
                ref,
                'Luteal Phase Length',
                currentSettings.lutealPhaseLength,
                (val) => _saveSettings(
                  ref,
                  currentSettings.copyWith(lutealPhaseLength: val),
                ),
                min: 10,
                max: 18,
              ),
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading settings: $e'),
    );
  }

  Future<void> _saveSettings(
    WidgetRef ref,
    CycleSettingsModel settings,
  ) async {
    await ref.read(cycleRepositoryProvider).saveCycleSettings(
      userId: settings.userId,
      settings: settings,
    );
  }

  void _showNumberPicker(
    BuildContext context,
    WidgetRef ref,
    String title,
    int initialValue,
    Function(int) onSave, {
    required int min,
    required int max,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedValue = initialValue.clamp(min, max);
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<int>(
                value: selectedValue,
                items:
                    List.generate(max - min + 1, (index) => min + index)
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e days'),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedValue = val);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(selectedValue);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _TrainingPreferencesSection extends ConsumerWidget {
  const _TrainingPreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Training Preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile(
              title: const Text('Use LBS'),
              subtitle: Text(
                user.weightUnit == WeightUnit.lbs ? 'Using LBS' : 'Using KG',
              ),
              value: user.weightUnit == WeightUnit.lbs,
              onChanged: (bool value) {
                _saveUser(
                  ref,
                  user.copyWith(
                    weightUnit: value ? WeightUnit.lbs : WeightUnit.kg,
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Rounding'),
              subtitle: Text('Round to nearest ${user.roundingValue}'),
              trailing: DropdownButton<double>(
                value: user.roundingValue,
                items: const [
                  DropdownMenuItem(value: 1.0, child: Text('1')),
                  DropdownMenuItem(value: 2.5, child: Text('2.5')),
                  DropdownMenuItem(value: 5.0, child: Text('5')),
                ],
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    _saveUser(ref, user.copyWith(roundingValue: newValue));
                  }
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading user settings: $e'),
    );
  }

  Future<void> _saveUser(WidgetRef ref, UserModel user) async {
    await ref.read(userRepositoryProvider).saveUser(user: user);
  }
}

class _ProfileManagementSection extends ConsumerWidget {
  const _ProfileManagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Profile Management',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: const Text('Display Name'),
              subtitle: Text(user.name.isEmpty ? 'Not set' : user.name),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _showEditNameDialog(context, ref, user);
              },
            ),
            ListTile(
              title: const Text('Gender'),
              subtitle: Text(user.gender.displayName),
              trailing: DropdownButton<Gender>(
                value: user.gender,
                items: Gender.values.map((Gender gender) {
                  return DropdownMenuItem<Gender>(
                    value: gender,
                    child: Text(gender.displayName),
                  );
                }).toList(),
                onChanged: (Gender? newValue) {
                  if (newValue != null) {
                    _saveUser(ref, user.copyWith(gender: newValue));
                  }
                },
              ),
            ),
            const Divider(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading user profile: $e'),
    );
  }

  void _showEditNameDialog(
      BuildContext context, WidgetRef ref, UserModel user) {
    final controller = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Display Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display Name'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _saveUser(ref, user.copyWith(name: controller.text.trim()));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUser(WidgetRef ref, UserModel user) async {
    await ref.read(userRepositoryProvider).saveUser(user: user);
  }
}

class _AppInfoSection extends StatelessWidget {
  const _AppInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'App Info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        const ListTile(
          title: Text('README'),
          subtitle: SelectableText(
            'https://github.com/sundee-fundee/sundee-fundee-flutter/blob/main/README.md',
          ),
        ),
        const Divider(),
      ],
    );
  }
}

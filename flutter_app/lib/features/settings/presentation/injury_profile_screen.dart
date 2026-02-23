import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/injury_profile_model.dart';
import '../../auth/providers.dart';
import '../../programs/providers/adapted_program_provider.dart';

class InjuryProfileScreen extends ConsumerStatefulWidget {
  const InjuryProfileScreen({super.key});

  @override
  ConsumerState<InjuryProfileScreen> createState() =>
      _InjuryProfileScreenState();
}

class _InjuryProfileScreenState extends ConsumerState<InjuryProfileScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _limitationsController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _locationController.dispose();
    _limitationsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveInjury() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).saveInjuryProfile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            location: _locationController.text.trim(),
            movementLimitations: _limitationsController.text.trim(),
            recoveryGoal: _goalController.text.trim(),
          );
      ref.invalidate(injuryAdaptedActiveProgramProvider);
      _locationController.clear();
      _limitationsController.clear();
      _goalController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Injury profile saved.')),
        );
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _resolveInjury(String injuryId) async {
    try {
      await ref.read(authRepositoryProvider).resolveInjuryProfile(injuryId);
      ref.invalidate(injuryAdaptedActiveProgramProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _retryPendingWrites() async {
    await ref.read(authRepositoryProvider).retryProfileWrites();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Retried pending profile saves.')));
  }

  @override
  Widget build(BuildContext context) {
    final injuries =
        ref.watch(userProfileStreamProvider).asData?.value?.injuryProfiles ??
            const <InjuryProfileModel>[];
    final pendingWrites =
        ref.read(authRepositoryProvider).pendingProfileWriteCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Injury Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Injury location'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitationsController,
            decoration:
                const InputDecoration(labelText: 'Movement limitations'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: 'Recovery goal'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _saveInjury,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Save injury profile'),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (pendingWrites > 0) ...<Widget>[
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.orange.withValues(alpha: 0.12),
              title: Text('$pendingWrites pending profile save(s)'),
              subtitle: const Text('Retry to sync failed writes.'),
              trailing: TextButton(
                onPressed: _retryPendingWrites,
                child: const Text('Retry'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Current injuries',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (injuries.isEmpty)
            const Text('No injuries recorded.')
          else
            ...injuries.map(
              (InjuryProfileModel injury) => ListTile(
                title: Text(injury.location),
                subtitle: Text(
                  '${injury.movementLimitations}\nGoal: ${injury.recoveryGoal}',
                ),
                isThreeLine: true,
                trailing: injury.status == InjuryStatus.resolved
                    ? const Text('Resolved')
                    : TextButton(
                        onPressed: () => _resolveInjury(injury.id),
                        child: const Text('Resolve'),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

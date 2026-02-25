import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../auth/providers.dart';

class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  Gender _gender = Gender.preferNotToSay;
  bool _cycleTrackingEnabled = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).completeOnboarding(
            name: _nameController.text.trim(),
            gender: _gender,
            cycleTrackingEnabled:
                _gender == Gender.female && _cycleTrackingEnabled,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileStreamProvider).asData?.value;
    if (profile != null && !_isSaving) {
      _nameController.text =
          _nameController.text.isEmpty ? profile.name : _nameController.text;
      _gender = _gender == Gender.preferNotToSay ? profile.gender : _gender;
      _cycleTrackingEnabled =
          _cycleTrackingEnabled || profile.cycleTrackingEnabled;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender>(
              // ignore: deprecated_member_use
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: Gender.values
                  .map(
                    (Gender value) => DropdownMenuItem<Gender>(
                      value: value,
                      child: Text(value.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (Gender? value) {
                if (value != null) {
                  setState(() {
                    _gender = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_gender == Gender.female)
              SwitchListTile(
                title: const Text('Enable cycle tracking'),
                value: _cycleTrackingEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _cycleTrackingEnabled = value;
                  });
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

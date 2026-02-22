import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  Gender _selectedGender = Gender.preferNotToSay;
  bool _enableCycleTracking = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final String trimmedName = _nameController.text.trim();
      if (trimmedName.isEmpty) {
        throw StateError('Please enter your name to complete onboarding.');
      }

      await ref.read(authRepositoryProvider).completeOnboarding(
            name: trimmedName,
            gender: _selectedGender,
            enableCycleTracking: _enableCycleTracking,
          );

      // The router watches authSessionStreamProvider, which is driven by
      // Firebase Auth state changes — NOT Firestore document changes. So
      // simply writing onboardingComplete=true to Firestore won't trigger a
      // route redirect on its own. Invalidating the provider forces it to
      // re-read the user document and emit AuthStatus.authenticated, which
      // causes GoRouter to navigate to '/'.
      ref.invalidate(authSessionStreamProvider);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Tell us a bit about yourself to finish setup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Gender>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Sex / Gender (for strength standards)',
                    border: OutlineInputBorder(),
                  ),
                  items: Gender.values.map((Gender gender) {
                    return DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(gender.displayName),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (Gender? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          }
                        },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sundee Fundee can optimize your strength program based on hormonal fluctuations. Do you want to enable menstrual cycle tracking?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable Cycle Tracking'),
                  contentPadding: EdgeInsets.zero,
                  value: _enableCycleTracking,
                  onChanged: _isSubmitting
                      ? null
                      : (bool value) {
                          setState(() {
                            _enableCycleTracking = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeOnboarding,
                  child: const Text('Complete onboarding'),
                ),
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

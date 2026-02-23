import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../domain/auth_state.dart';
import '../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  Gender _selectedGender = Gender.preferNotToSay;
  bool _cycleTrackingOptIn = false;
  bool _isSubmitting = false;
  bool _resumeDecisionTaken = false;
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
            cycleTrackingEnabled:
                _selectedGender == Gender.female && _cycleTrackingOptIn,
          );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _hydrateFromProfile() {
    final profile = ref.read(userProfileStreamProvider).asData?.value;
    if (profile == null) {
      return;
    }
    _nameController.text = profile.name;
    _selectedGender = profile.gender;
    _cycleTrackingOptIn = profile.cycleTrackingEnabled;
  }

  Future<void> _restartFromScratch() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).restartOnboarding();
      if (!mounted) {
        return;
      }
      setState(() {
        _nameController.clear();
        _selectedGender = Gender.preferNotToSay;
        _cycleTrackingOptIn = false;
        _resumeDecisionTaken = true;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
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
    final theme = Theme.of(context);
    final authSession = ref.watch(authSessionStreamProvider).asData?.value;
    final bool resumeRequired =
        authSession?.status == AuthStatus.resumeOnboarding;
    final bool injuryRequired =
        authSession?.status == AuthStatus.needsInjuryProfile;

    if (resumeRequired && !_resumeDecisionTaken) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resume Onboarding')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'We found partially completed onboarding. Resume where you left off or restart?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _hydrateFromProfile();
                          _resumeDecisionTaken = true;
                        });
                      },
                child: const Text('Resume onboarding'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting ? null : _restartFromScratch,
                child: const Text('Restart onboarding'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Sundee Fundee')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (injuryRequired) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Your injury profile needs a few more details before plan generation. Complete this form and include current limitations.',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Let\'s get started!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us a bit about yourself to personalize your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'What is your name?',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 24),

                // Sex Selection
                const Text(
                  'Biological Sex',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Female')),
                        selected: _selectedGender == Gender.female,
                        onSelected: _isSubmitting
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(
                                      () => _selectedGender = Gender.female);
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Male')),
                        selected: _selectedGender == Gender.male,
                        onSelected: _isSubmitting
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedGender = Gender.male;
                                    _cycleTrackingOptIn = false;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ChoiceChip(
                  label: const Center(child: Text('Prefer not to say')),
                  selected: _selectedGender == Gender.preferNotToSay,
                  onSelected: _isSubmitting
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _selectedGender = Gender.preferNotToSay;
                              _cycleTrackingOptIn = false;
                            });
                          }
                        },
                ),

                // Cycle Tracking Opt-in (Conditional)
                if (_selectedGender == Gender.female) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cycle Tracking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enable hormone-aware training recommendations based on your menstrual cycle?',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Opt-in for cycle tracking'),
                          value: _cycleTrackingOptIn,
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() => _cycleTrackingOptIn = value);
                                },
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Complete Onboarding',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
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

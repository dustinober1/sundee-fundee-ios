import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/providers/database_provider.dart';
import '../../shared/providers/onboarding_status_provider.dart';
import '../../data/database/app_database.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();

  /// Pre-selected to 'beginner' matching v1.1 defaults.
  String _selectedExperience = 'beginner';

  /// Pre-selected to 'strength' matching v1.1 defaults.
  String _selectedGoal = 'strength';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboarding-screen'),
      appBar: AppBar(title: const Text('Welcome to Sundee Fundee')),
      body: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return _buildStep0();
    }
  }

  Widget _buildStep0() {
    final isNameValid = _nameController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your name',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('onboarding-name-input'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('onboarding-next-button'),
            onPressed: isNameValid ? () => setState(() => _currentStep++) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select experience level',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            key: const Key('experience-beginner'),
            title: const Text('Beginner'),
            leading: Icon(
              _selectedExperience == 'beginner'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedExperience = 'beginner'),
          ),
          ListTile(
            key: const Key('experience-intermediate'),
            title: const Text('Intermediate'),
            leading: Icon(
              _selectedExperience == 'intermediate'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedExperience = 'intermediate'),
          ),
          ListTile(
            key: const Key('experience-advanced'),
            title: const Text('Advanced'),
            leading: Icon(
              _selectedExperience == 'advanced'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedExperience = 'advanced'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('onboarding-back-button'),
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  key: const Key('onboarding-next-button'),
                  onPressed: () => setState(() => _currentStep++),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your goal',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            key: const Key('goal-strength'),
            title: const Text('Build Strength'),
            leading: Icon(
              _selectedGoal == 'strength'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedGoal = 'strength'),
          ),
          ListTile(
            key: const Key('goal-hypertrophy'),
            title: const Text('Muscle Growth'),
            leading: Icon(
              _selectedGoal == 'hypertrophy'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedGoal = 'hypertrophy'),
          ),
          ListTile(
            key: const Key('goal-explosiveness'),
            title: const Text('Power & Speed'),
            leading: Icon(
              _selectedGoal == 'explosiveness'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => _selectedGoal = 'explosiveness'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('onboarding-back-button'),
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  key: const Key('onboarding-start-button'),
                  onPressed: _handleStart,
                  child: const Text('Start Training'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStart() async {
    final db = ref.read(databaseProvider);
    await db.into(db.users).insert(
      UsersCompanion.insert(
        name: _nameController.text.trim(),
        experienceLevel: _selectedExperience,
        goal: _selectedGoal,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    ref.read(onboardingCompleteProvider.notifier).setComplete();
    if (mounted) {
      context.go('/dashboard');
    }
  }
}

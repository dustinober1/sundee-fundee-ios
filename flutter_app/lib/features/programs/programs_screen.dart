import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('programs-screen'),
      appBar: AppBar(title: const Text('Programs')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('program-back-squat-complete-cycle'),
            title: const Text('Back Squat Complete Cycle'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () =>
                context.go('/workout/back-squat-complete-cycle'),
          ),
          ListTile(
            key: const Key('program-bench-press-program'),
            title: const Text('Bench Press Program'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.go('/workout/bench-press-program'),
          ),
          ListTile(
            key: const Key('program-5x5-stronglifts'),
            title: const Text('5x5 Stronglifts'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.go('/workout/5x5-stronglifts'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkoutScreen extends StatelessWidget {
  final String programId;

  const WorkoutScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('workout-screen'),
      appBar: AppBar(title: Text(programId.replaceAll('-', ' ').toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Program: $programId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Set logging area — coming in Phase 10',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              key: const Key('complete-workout-button'),
              onPressed: () => context.go('/dashboard'),
              child: const Text('Complete Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

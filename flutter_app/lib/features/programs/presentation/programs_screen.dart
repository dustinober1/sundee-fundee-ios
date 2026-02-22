import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/program_models.dart';
import '../data/program_repository.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProgramV2>> programsAsync = ref.watch(programsProvider);

    return programsAsync.when(
      data: (List<ProgramV2> programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No programs available.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          itemCount: programs.length,
          itemBuilder: (BuildContext context, int index) {
            final ProgramV2 program = programs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      program.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      program.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text('Enrollment coming soon!'),
                            ),
                          );
                        },
                        child: const Text('Enroll in Program'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

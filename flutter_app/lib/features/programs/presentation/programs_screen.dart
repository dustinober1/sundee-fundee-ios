import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../data/program_repository.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProgramV2>> programsAsync =
        ref.watch(programsProvider);
    final AsyncValue<EnrolledProgramModel?> activeEnrollmentAsync =
        ref.watch(activeEnrollmentProvider);

    final userId = ref.watch(authSessionStreamProvider).asData?.value.user?.uid;

    return programsAsync.when(
      data: (List<ProgramV2> programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No programs available.'));
        }
        return activeEnrollmentAsync.when(
          data: (enrolledProgram) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              itemCount: programs.length,
              itemBuilder: (BuildContext context, int index) {
                final ProgramV2 program = programs[index];
                final bool isEnrolled =
                    enrolledProgram?.programId == program.id;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              program.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            if (isEnrolled)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSecondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandSecondary,
                                  ),
                                ),
                              ),
                          ],
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
                            onPressed: isEnrolled || userId == null
                                ? null
                                : () async {
                                    try {
                                      await ref
                                          .read(programRepositoryProvider)
                                          .enrollUser(
                                            userId: userId,
                                            programId: program.id,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Enrolled in ${program.name}!'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Enrollment failed: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              isEnrolled
                                  ? 'Currently Enrolled'
                                  : 'Enroll in Program',
                            ),
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
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

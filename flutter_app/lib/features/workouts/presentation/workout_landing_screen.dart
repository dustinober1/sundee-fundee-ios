import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../programs/data/program_repository.dart';
import 'workout_execution_providers.dart';

class WorkoutLandingScreen extends ConsumerWidget {
  const WorkoutLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if there is an active workout
    final activeWorkoutState = ref.watch(workoutExecutionNotifierProvider);
    final isWorkoutActive = activeWorkoutState != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center,
                size: 80, color: AppColors.brandPrimary),
            const SizedBox(height: 32),
            if (isWorkoutActive) ...[
              const Text(
                'Workout in Progress',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pushNamed('workout'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('RESUME WORKOUT',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: AppColors.brandSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else ...[
              const Text(
                'Ready to crush it?',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 32),
              _buildNextSessionInfo(context, ref),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionInfo(BuildContext context, WidgetRef ref) {
    final enrollmentAsync = ref.watch(activeEnrollmentProvider);
    final programAsync = ref.watch(activeProgramProvider);

    return enrollmentAsync.when(
      data: (enrollment) {
        if (enrollment == null) {
          return const Column(
            children: [
              Icon(Icons.info_outline,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No active program enrollment.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Head over to the Programs tab to start one!',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        return programAsync.when(
          data: (program) {
            if (program == null) return const SizedBox.shrink();

            final week = program.weeks.firstWhere(
              (w) => w.week == enrollment.currentWeek,
              orElse: () => program.weeks.last,
            );
            final sessionIndex = enrollment.currentDay - 1;
            final session = sessionIndex < week.sessions.length
                ? week.sessions[sessionIndex]
                : week.sessions.last;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandPrimary,
                      AppColors.brandPrimary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      program.name,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Week ${enrollment.currentWeek}, Day ${enrollment.currentDay}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.sessionName,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => context.pushNamed('workout'),
                      icon: const Icon(Icons.flash_on),
                      label: const Text('START SESSION',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text('Error loading program: $e',
              style: const TextStyle(color: Colors.red)),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error loading enrollment: $e',
          style: const TextStyle(color: Colors.red)),
    );
  }
}

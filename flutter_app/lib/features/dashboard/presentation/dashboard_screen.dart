import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../migration/providers.dart';
import '../../programs/data/program_repository.dart';
import '../../repositories/providers.dart';
import 'cycle_insights_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthSession>>(authSessionStreamProvider, (
      AsyncValue<AuthSession>? previous,
      AsyncValue<AuthSession> next,
    ) {
      final String? userId = next.asData?.value.user?.uid;
      if (userId == null) {
        return;
      }

      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      unawaited(
        ref
            .read(legacyMigrationOrchestratorProvider)
            .migrateIfNeeded(userId: userId)
            .then((_) {})
            .catchError((Object error, StackTrace stackTrace) {
          messenger?.showSnackBar(
            SnackBar(content: Text('Legacy migration failed: $error')),
          );
        }),
      );
    });

    final AuthSession? session =
        ref.watch(authSessionStreamProvider).asData?.value;

    final String stateMessage;
    switch (session?.status) {
      case AuthStatus.guest:
        stateMessage = 'Guest mode active';
      case AuthStatus.authenticated:
        stateMessage = 'Signed in as ${session?.user?.email ?? 'user'}';
      case AuthStatus.needsOnboarding:
        stateMessage = 'Onboarding required';
      case AuthStatus.unauthenticated:
      case AuthStatus.loading:
      case null:
        stateMessage = 'Not signed in';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Next Workout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _NextWorkoutCard(),
            const SizedBox(height: 32),
            const CycleInsightsChart(),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Workout History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _WorkoutHistoryList(),
            const SizedBox(height: 32),
            Center(
              child: Text(
                stateMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutHistoryList extends ConsumerWidget {
  const _WorkoutHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionStreamProvider).asData?.value;
    final userId = session?.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view history.'));
    }

    final workoutsAsync =
        ref.watch(workoutRepositoryProvider).watchWorkouts(userId: userId);

    return StreamBuilder(
      stream: workoutsAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final workouts = snapshot.data ?? [];

        if (workouts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                Icon(Icons.history_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No workouts completed yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: workouts.map((workout) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.brandPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.brandPrimary, size: 20),
                ),
                title: Text(
                  '${workout.programId} - W${workout.week}D${workout.day}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${workout.completedAt.toString().split(' ')[0]} • ${workout.duration} mins',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NextWorkoutCard extends ConsumerWidget {
  const _NextWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentAsync = ref.watch(activeEnrollmentProvider);
    final programAsync = ref.watch(activeProgramProvider);

    return enrollmentAsync.when(
      data: (enrollment) {
        if (enrollment == null) {
          return const _NoActiveProgramCard();
        }

        return programAsync.when(
          data: (program) {
            if (program == null) return const SizedBox.shrink();

            final week = program.weeks.firstWhere(
              (w) => w.week == enrollment.currentWeek,
              orElse: () => program.weeks.last,
            );

            // For simplicity, we assume sessions are day 1, 2, 3...
            final sessionIndex = enrollment.currentDay - 1;
            final session = sessionIndex < week.sessions.length
                ? week.sessions[sessionIndex]
                : week.sessions.last;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            program.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.fitness_center,
                              color: Colors.white70, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Week ${enrollment.currentWeek}, Session ${enrollment.currentDay}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Focus: ${session.focus}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.pushNamed('workout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'START SESSION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const _LoadingCard(),
          error: (err, stack) => _ErrorCard(err.toString()),
        );
      },
      loading: () => const _LoadingCard(),
      error: (err, stack) => _ErrorCard(err.toString()),
    );
  }
}

class _NoActiveProgramCard extends StatelessWidget {
  const _NoActiveProgramCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.textSecondary, size: 32),
            const SizedBox(height: 8),
            const Text(
              'No active program enrollment.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Navigate to programs tab
              },
              child: const Text('EXPLORE PROGRAMS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard(this.error);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading next workout: $error'),
      ),
    );
  }
}

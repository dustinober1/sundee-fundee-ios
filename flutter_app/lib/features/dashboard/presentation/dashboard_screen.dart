import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../migration/providers.dart';
import '../../repositories/providers.dart';

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

    final AuthSession? session = ref
        .watch(authSessionStreamProvider)
        .asData
        ?.value;

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

    final workoutsAsync = ref.watch(workoutRepositoryProvider).watchWorkouts(userId: userId);

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
                Icon(Icons.history_outlined, size: 48, color: AppColors.textSecondary),
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
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.fitness_center, color: AppColors.brandPrimary, size: 20),
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

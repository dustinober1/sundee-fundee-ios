import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/exercise_definitions.dart';
import '../../auth/providers.dart';
import '../../repositories/providers.dart';

final workoutSummaryProvider =
    StreamProvider.family<CompletedWorkoutModel?, String>((ref, workoutId) {
  final session = ref.watch(authSessionStreamProvider).asData?.value;
  final userId = session?.user?.uid;
  if (userId == null) return Stream.value(null);

  return ref
      .watch(workoutRepositoryProvider)
      .watchWorkout(userId: userId, workoutId: workoutId);
});

final workoutSetsProvider =
    StreamProvider.family<List<CompletedSetModel>, String>((ref, workoutId) {
  final session = ref.watch(authSessionStreamProvider).asData?.value;
  final userId = session?.user?.uid;
  if (userId == null) return Stream.value([]);

  return ref
      .watch(workoutRepositoryProvider)
      .watchCompletedSets(userId: userId, workoutId: workoutId);
});

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  String _formatProgramId(String id) {
    if (id == 'squad-squat') return '12-Week Squad Squat Peak';
    return id
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionStreamProvider).asData?.value;
    final userId = session?.user?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text(
            'This will permanently remove this workout from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(workoutRepositoryProvider).deleteWorkout(
            userId: userId,
            workoutId: workoutId,
          );
      if (context.mounted) {
        context.pop(); // Back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutSummaryProvider(workoutId));
    final setsAsync = ref.watch(workoutSetsProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Workout',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found.'));
          }

          return setsAsync.when(
            data: (sets) => _buildSummary(context, workout, sets),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading sets: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading workout: $err')),
      ),
    );
  }

  Widget _buildSummary(
      BuildContext context, CompletedWorkoutModel workout, List<CompletedSetModel> sets) {
    // Group sets by exercise
    final Map<String, List<CompletedSetModel>> groupedSets = {};
    for (final set in sets) {
      groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(workout),
          const SizedBox(height: 16),
          _buildStats(workout, sets),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...groupedSets.entries.map((entry) => _buildExerciseCard(entry.key, entry.value)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(CompletedWorkoutModel workout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      color: AppColors.brandPrimary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatProgramId(workout.programId),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Week ${workout.week}, Day ${workout.day}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                workout.completedAt.toString().split(' ')[0],
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${workout.duration} mins',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(workout.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(CompletedWorkoutModel workout, List<CompletedSetModel> sets) {
    final totalVolume = sets.fold<double>(
        0, (sum, set) => sum + ((set.actualWeight ?? 0) * (set.actualReps ?? 0)));
    final totalReps = sets.fold<int>(0, (sum, set) => sum + (set.actualReps ?? 0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Sets', value: sets.length.toString()),
          _StatItem(label: 'Total Reps', value: totalReps.toString()),
          _StatItem(label: 'Volume', value: '${totalVolume.toInt()} lbs'),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(String exerciseId, List<CompletedSetModel> sets) {
    // Look up human-readable name from definitions
    final definition = Exercises.findById(exerciseId);
    final displayName = definition?.name ??
        exerciseId
            .split('-')
            .map((word) =>
                word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...sets.map((set) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                        child: Text(
                          '${set.setNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${set.actualWeight ?? 0} lbs x ${set.actualReps ?? 0} reps',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (set.rpe != null) ...[
                        const Spacer(),
                        Text(
                          'RPE ${set.rpe}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

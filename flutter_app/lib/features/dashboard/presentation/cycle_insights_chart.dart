import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/calculations/cycle_calculations.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../auth/providers.dart';
import '../../cycle/providers.dart';
import '../../repositories/providers.dart';

final cycleWorkoutsProvider =
    StreamProvider.family<List<CompletedWorkoutModel>, String>((ref, userId) {
  return ref.watch(workoutRepositoryProvider).watchWorkouts(userId: userId);
});

class CycleInsightsChart extends ConsumerWidget {
  const CycleInsightsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authSessionStreamProvider).asData?.value.user?.uid;
    if (userId == null) return const SizedBox.shrink();

    final workoutsAsync = ref.watch(cycleWorkoutsProvider(userId));
    final periodLogsAsync = ref.watch(periodLogsProvider);
    final settingsAsync = ref.watch(cycleSettingsProvider);

    if (workoutsAsync.isLoading ||
        periodLogsAsync.isLoading ||
        settingsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workoutsAsync.hasError ||
        periodLogsAsync.hasError ||
        settingsAsync.hasError) {
      final error = workoutsAsync.error ??
          periodLogsAsync.error ??
          settingsAsync.error;
      debugPrint('Error loading insights: $error');
      return Text('Error loading insights: $error');
    }

    final workouts = workoutsAsync.value ?? [];
    final periodLogs = periodLogsAsync.value ?? [];
    final settings = settingsAsync.value;

    if (workouts.isEmpty || periodLogs.isEmpty || settings == null) {
      // If no workouts or no cycle data, we can't show chart
      return const SizedBox.shrink();
    }

    // Aggregate Data
    final Map<CyclePhase, int> phaseCounts = {
      CyclePhase.menstrual: 0,
      CyclePhase.follicular: 0,
      CyclePhase.ovulation: 0,
      CyclePhase.luteal: 0,
    };

    // Calculate phase for each workout
    for (final workout in workouts) {
      // We pass the workout date as referenceDate
      final status = CycleCalculations.calculateCycleStatus(
        periodLogs: periodLogs,
        settings: settings,
        referenceDate: workout.completedAt,
      );

      if (status != null) {
        phaseCounts[status.currentPhase] =
            (phaseCounts[status.currentPhase] ?? 0) + 1;
      }
    }

    final values = phaseCounts.values.toList();
    final maxCount = values.isEmpty
        ? 0
        : values.reduce((a, b) => a > b ? a : b);
    final hasData = maxCount > 0;

    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Phase Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Workouts completed per phase',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: CyclePhase.values.map((phase) {
                  final count = phaseCounts[phase] ?? 0;
                  final heightFactor = maxCount > 0 ? (count / maxCount) : 0.0;

                  return _PhaseBar(
                    phase: phase,
                    count: count,
                    heightFactor: heightFactor,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseBar extends StatelessWidget {
  const _PhaseBar({
    required this.phase,
    required this.count,
    required this.heightFactor,
  });

  final CyclePhase phase;
  final int count;
  final double heightFactor;

  Color _getColor(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return Colors.redAccent;
      case CyclePhase.follicular:
        return Colors.blueAccent;
      case CyclePhase.ovulation:
        return Colors.purpleAccent;
      case CyclePhase.luteal:
        return Colors.orangeAccent;
    }
  }

  String _getLabel(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'M';
      case CyclePhase.follicular:
        return 'F';
      case CyclePhase.ovulation:
        return 'O';
      case CyclePhase.luteal:
        return 'L';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure min height for visibility if count > 0
    final effectiveHeight =
        count > 0 && heightFactor < 0.1 ? 0.1 : heightFactor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 24,
          height: 140 * effectiveHeight,
          decoration: BoxDecoration(
            color: _getColor(phase),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getLabel(phase),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/recommendations/calculations.dart';
import 'workout_repository_provider.dart';

/// A single data point on the 1RM trend chart.
class OneRmPoint {
  final String date;
  final double estimated1RM;

  const OneRmPoint({required this.date, required this.estimated1RM});
}

/// Loads 1RM trend data for a given [exerciseId] from Drift.
///
/// Groups completed sets by workout, calculates the best Epley 1RM
/// for each workout, and returns points sorted chronologically.
/// Returns an empty list when [exerciseId] is blank.
final oneRmProgressProvider =
    FutureProvider.family<List<OneRmPoint>, String>((ref, exerciseId) async {
  if (exerciseId.isEmpty) return [];

  final repo = ref.watch(workoutRepositoryProvider);
  final setsWithDate = await repo.getSetsForExercise(exerciseId);

  if (setsWithDate.isEmpty) return [];

  // Group sets by workoutId
  final byWorkout = <int, List<({double weight, int reps, DateTime date})>>{};
  for (final item in setsWithDate) {
    final workoutId = item.set.workoutId;
    byWorkout.putIfAbsent(workoutId, () => []);
    byWorkout[workoutId]!.add((
      weight: item.set.actualWeight,
      reps: item.set.actualReps,
      date: item.completedAt,
    ));
  }

  // Calculate max Epley 1RM per workout, sorted by date
  final points =
      byWorkout.entries.map((e) {
        final sets = e.value;
        final date = sets.first.date;
        final max1RM = sets
            .map((s) => epley(s.weight, s.reps))
            .reduce((a, b) => a > b ? a : b);
        return (date: date, estimated1RM: max1RM.roundToDouble());
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

  return points
      .map(
        (p) => OneRmPoint(
          date: DateFormat('MMM d').format(p.date),
          estimated1RM: p.estimated1RM,
        ),
      )
      .toList();
});

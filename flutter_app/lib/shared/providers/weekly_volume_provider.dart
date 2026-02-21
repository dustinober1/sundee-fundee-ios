import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'workout_repository_provider.dart';

/// A single data point on the weekly volume bar chart.
class WeeklyVolumePoint {
  final String week;
  final String weekKey; // yyyy-MM-dd of the Monday that starts the week
  final double volume;

  const WeeklyVolumePoint({
    required this.week,
    required this.weekKey,
    required this.volume,
  });
}

/// Returns the ISO Monday that starts [date]'s week as a yyyy-MM-dd string.
/// Flutter weekday: 1 = Monday, 7 = Sunday (matching v1.1 Monday-start logic).
String _weekKey(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return '${monday.year}-'
      '${monday.month.toString().padLeft(2, '0')}-'
      '${monday.day.toString().padLeft(2, '0')}';
}

/// Loads weekly volume data (weight × reps per week) from Drift.
///
/// Aggregates all completed sets into Monday-start calendar weeks,
/// sorts ascending, and returns the last 12 weeks.
final weeklyVolumeProvider = FutureProvider<List<WeeklyVolumePoint>>((
  ref,
) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final setsWithDate = await repo.getAllSetsWithWorkoutDate();

  // Aggregate volume per week
  final volumeByWeek = <String, double>{};
  for (final item in setsWithDate) {
    final weekKey = _weekKey(item.completedAt);
    final volume = item.set.actualWeight * item.set.actualReps;
    volumeByWeek[weekKey] = (volumeByWeek[weekKey] ?? 0) + volume;
  }

  // Sort ascending by week key, keep last 12 weeks
  final sorted =
      volumeByWeek.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  final last12 =
      sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;

  return last12.map((e) {
    final date = DateTime.parse('${e.key}T00:00:00');
    return WeeklyVolumePoint(
      week: DateFormat('MMM d').format(date),
      weekKey: e.key,
      volume: e.value.roundToDouble(),
    );
  }).toList();
});

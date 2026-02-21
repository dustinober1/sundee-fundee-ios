import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_repository_provider.dart';

/// A single cell in the 365-day activity heatmap.
class Activity {
  final String date; // yyyy-MM-dd
  final int count;
  final int level; // 0–4 intensity

  const Activity({required this.date, required this.count, required this.level});
}

/// Maps a raw workout count to a heatmap intensity level (0–4).
int _countToLevel(int count) {
  if (count == 0) return 0;
  if (count == 1) return 1;
  if (count == 2) return 2;
  if (count <= 4) return 3;
  return 4;
}

/// Loads 365-day activity grid data from Drift.
///
/// Returns one [Activity] per calendar day for the past year,
/// plus a [totalWorkouts] count for display.
final workoutFrequencyProvider =
    FutureProvider<({List<Activity> activities, int totalWorkouts})>((
  ref,
) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final countByDate = await repo.getWorkoutCountByDate();

  // Generate every calendar day in the last 365 days
  final today = DateTime.now();
  final yearAgo = today.subtract(const Duration(days: 365));

  final activities = <Activity>[];
  var current = yearAgo;
  while (!current.isAfter(today)) {
    final dateKey =
        '${current.year}-'
        '${current.month.toString().padLeft(2, '0')}-'
        '${current.day.toString().padLeft(2, '0')}';
    final count = countByDate[dateKey] ?? 0;
    activities.add(
      Activity(date: dateKey, count: count, level: _countToLevel(count)),
    );
    current = current.add(const Duration(days: 1));
  }

  final totalWorkouts = countByDate.values.fold(0, (sum, n) => sum + n);

  return (activities: activities, totalWorkouts: totalWorkouts);
});

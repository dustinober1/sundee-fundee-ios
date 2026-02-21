import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/exercises.dart';
import 'workout_repository_provider.dart';

/// Loads the list of exercises the user has previously logged.
///
/// Strips the `-\d+$` variant suffix from exercise IDs so that
/// `back-squat-1`, `back-squat-2` all collapse to `back-squat`.
/// Returns id + display name pairs, resolved from the EXERCISES catalogue.
final trackedExercisesProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final exerciseIds = await repo.getTrackedExerciseIds();

  // Strip trailing variant suffix: e.g. back-squat-1 → back-squat
  final baseIds =
      exerciseIds
          .map((id) => id.replaceFirst(RegExp(r'-\d+$'), ''))
          .toSet()
          .toList();

  return baseIds.map((id) {
    final metadata = getExerciseByName(id);
    return (id: id, name: metadata?.name ?? id);
  }).toList();
});

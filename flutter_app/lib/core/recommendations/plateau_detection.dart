import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import 'calculations.dart';

/// Warning returned when a plateau is detected for an exercise.
class PlateauWarning {
  final bool hasPlateau;
  final String message;
  final String recommendation;

  const PlateauWarning({
    required this.hasPlateau,
    this.message = '',
    this.recommendation = '',
  });

  /// Convenience constant for "no plateau detected".
  static const none = PlateauWarning(hasPlateau: false);
}

/// Detect per-exercise plateau by checking if the last 3 sessions for a specific
/// exercise ALL had at least one set where actualReps < prescribedReps.
///
/// Unlike weight-variance plateau detection, this checks rep completion failure —
/// the correct signal for a progressive overload plateau.
///
/// CRITICAL: Must be scoped to [activeCycleId] to avoid cross-cycle false positives.
///
/// Matches v1.1 detectPlateauForExercise() in plateau-detection.ts.
Future<PlateauWarning> detectPlateauForExercise({
  required AppDatabase db,
  required String exerciseId,
  required int activeCycleId,
}) async {
  // Get last 3 workouts for this cycle (most recent first)
  final workouts = await (db.select(db.completedWorkouts)
        ..where((t) => t.activeCycleId.equals(activeCycleId))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
        ..limit(3))
      .get();

  if (workouts.length < 3) return PlateauWarning.none;

  // Check if each workout had rep failures for this exercise
  final sessionFailures = <bool>[];
  for (final workout in workouts) {
    final sets = await (db.select(db.completedSets)
          ..where((t) => t.workoutId.equals(workout.id))
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();

    // No sets for this exercise in this workout = not a failure
    if (sets.isEmpty) {
      sessionFailures.add(false);
      continue;
    }

    // Session "failed" if ANY set had actualReps < prescribedReps
    final anyFailed = sets.any((s) => s.actualReps < s.prescribedReps);
    sessionFailures.add(anyFailed);
  }

  // Plateau only if ALL 3 sessions failed
  final hasPlateau = sessionFailures.every((failed) => failed);

  if (hasPlateau) {
    return const PlateauWarning(
      hasPlateau: true,
      message:
          "You've missed prescribed reps on this exercise for 3 sessions in a row.",
      recommendation: 'Recommended deload: reduce weight by 10% for next session.',
    );
  }

  return PlateauWarning.none;
}

/// Calculate deload weight: 10% reduction from current weight, rounded to nearest 5 lbs.
/// Used when plateau is detected to prescribe a recovery weight.
double getDeloadWeight(double currentWeight) {
  return roundToNearestFive(currentWeight * 0.9);
}

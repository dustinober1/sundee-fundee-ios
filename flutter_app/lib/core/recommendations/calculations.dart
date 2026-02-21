/// Pure Dart recommendation calculations.
/// Exact port of v1.1 src/lib/calculations.ts.
///
/// All functions are pure (no side effects, no DB access).
/// Used by plateau_detection.dart and coaching UI.

/// Round to nearest 5 lbs.
double roundToNearestFive(double value) {
  return (value / 5).round() * 5.0;
}

/// Epley formula for estimated 1RM.
/// Caps reps at 10 (higher reps are unreliable for 1RM estimation).
/// Matches v1.1: `weight * (1 + Math.min(reps, 10) / 30)`.
double epley(double weight, int reps) {
  if (reps <= 1) return weight;
  return weight * (1 + reps.clamp(1, 10) / 30);
}

/// Session result classification for recommendation engine.
enum SessionResult { success, failure, first }

/// Get next recommended working weight based on session result.
/// - first:   70% of 1RM (starting weight for a new exercise)
/// - success: +5 lbs from current weight
/// - failure: -5 lbs from current weight, floor at 50% of 1RM
/// All results are rounded to nearest 5 lbs.
double getNextRecommendedWeight(
  double currentWeight,
  SessionResult result,
  double oneRepMax,
) {
  switch (result) {
    case SessionResult.first:
      return roundToNearestFive(oneRepMax * 0.7);
    case SessionResult.success:
      return roundToNearestFive(currentWeight + 5);
    case SessionResult.failure:
      final floor = roundToNearestFive(oneRepMax * 0.5);
      return (roundToNearestFive(currentWeight - 5)).clamp(floor, double.infinity);
  }
}

/// Check if a single set was successfully completed.
/// A set is successful if actualReps >= prescribedReps AND
/// (if prescribedWeight is defined) actualWeight >= prescribedWeight.
bool wasSetSuccessful({
  required int actualReps,
  required int prescribedReps,
  required double actualWeight,
  double? prescribedWeight,
}) {
  final repsOk = actualReps >= prescribedReps;
  final weightOk = prescribedWeight == null || actualWeight >= prescribedWeight;
  return repsOk && weightOk;
}

/// Check if all sets in a session were successfully completed.
/// An empty list returns true (vacuously successful — matches v1.1).
bool wasSessionSuccessful(List<Map<String, dynamic>> sets) {
  return sets.every(
    (s) => wasSetSuccessful(
      actualReps: s['actualReps'] as int,
      prescribedReps: s['prescribedReps'] as int,
      actualWeight: s['actualWeight'] as double,
      prescribedWeight: s['prescribedWeight'] as double?,
    ),
  );
}

/// Check if a weight represents a new personal record.
bool isPersonalRecord(double weight, double previousMax) {
  return weight > previousMax;
}

/// Calculate volume load: weight × reps × sets.
double calculateVolumeLoad(double weight, int reps, int sets) {
  return weight * reps * sets;
}

/// Detect plateau: variance < 5 lbs in last 3 weights.
/// Returns false if fewer than 3 weights provided.
bool detectPlateau(List<double> weights) {
  if (weights.length < 3) return false;
  final lastThree = weights.sublist(weights.length - 3);
  final maxWeight = lastThree.reduce((a, b) => a > b ? a : b);
  final minWeight = lastThree.reduce((a, b) => a < b ? a : b);
  return maxWeight - minWeight < 5;
}

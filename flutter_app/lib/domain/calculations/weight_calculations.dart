enum SessionResult { first, success, failure }

class WeightCalculations {
  const WeightCalculations._();

  static double roundToNearestFive(double value) {
    return (value / 5.0).roundToDouble() * 5.0;
  }

  static double calculateTargetWeight({
    required double oneRepMax,
    required double percentage,
  }) {
    return roundToNearestFive(oneRepMax * percentage);
  }

  static double getNextRecommendedWeight({
    required double currentWeight,
    required SessionResult result,
    required double oneRepMax,
  }) {
    switch (result) {
      case SessionResult.first:
        return roundToNearestFive(oneRepMax * 0.7);
      case SessionResult.success:
        return roundToNearestFive(currentWeight + 5);
      case SessionResult.failure:
        final double floor = roundToNearestFive(oneRepMax * 0.5);
        return _max(roundToNearestFive(currentWeight - 5), floor);
    }
  }

  static bool wasSetSuccessful({
    required int actualReps,
    required int prescribedReps,
    required double actualWeight,
    required double? prescribedWeight,
  }) {
    final bool repsOk = actualReps >= prescribedReps;
    final bool weightOk =
        prescribedWeight == null || actualWeight >= prescribedWeight;
    return repsOk && weightOk;
  }

  static bool wasSessionSuccessful({
    required List<
            ({
              int actualReps,
              int prescribedReps,
              double actualWeight,
              double? prescribedWeight,
            })>
        sets,
  }) {
    return sets.every((
      ({
        int actualReps,
        int prescribedReps,
        double actualWeight,
        double? prescribedWeight,
      }) set,
    ) {
      return wasSetSuccessful(
        actualReps: set.actualReps,
        prescribedReps: set.prescribedReps,
        actualWeight: set.actualWeight,
        prescribedWeight: set.prescribedWeight,
      );
    });
  }

  static bool isPersonalRecord({
    required double weight,
    required double previousMax,
  }) {
    return weight > previousMax;
  }

  static double calculateVolumeLoad({
    required double weight,
    required int reps,
    required int sets,
  }) {
    return weight * reps * sets;
  }

  static bool detectPlateau({required List<double> weights}) {
    if (weights.length < 3) {
      return false;
    }

    final List<double> lastThree = weights.sublist(weights.length - 3);
    final double maxWeight = lastThree.reduce(_max);
    final double minWeight = lastThree.reduce(_min);

    return maxWeight - minWeight < 5;
  }

  static double _max(double a, double b) => a > b ? a : b;

  static double _min(double a, double b) => a < b ? a : b;
}

class PlateCalculation {
  const PlateCalculation._();

  static const List<double> availablePlates = [45, 25, 15, 10, 5, 2.5];

  /// Calculates the plates needed per side of the barbell.
  /// Returns a map where the key is the plate weight and the value is the count per side.
  static Map<double, int> calculatePlates({
    required double totalWeight,
    required double barbellWeight,
  }) {
    if (totalWeight <= barbellWeight) {
      return {};
    }

    final double weightOnSides = totalWeight - barbellWeight;
    double remainingWeightPerSide = weightOnSides / 2;
    final Map<double, int> breakdown = {};

    for (final double plate in availablePlates) {
      if (remainingWeightPerSide >= plate) {
        final int count = (remainingWeightPerSide / plate).floor();
        if (count > 0) {
          breakdown[plate] = count;
          remainingWeightPerSide -= count * plate;
        }
      }
    }

    return breakdown;
  }
}

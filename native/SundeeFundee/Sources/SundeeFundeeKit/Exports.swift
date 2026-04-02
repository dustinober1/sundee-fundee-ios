// SundeeFundeeKit - Public API Exports
//
// This file documents the public API surface of SundeeFundeeKit.
// All types and functions listed below are available for use by app targets.

// MARK: - Models

// Workout - Represents a complete training session
// - Properties: id, date, name, exercises, notes, duration, completedAt
// - Computed: totalVolume, isComplete

// Exercise - A single exercise within a workout
// - Properties: id, name, category, bodyweight, targetSets, notes, restMinutes

// ExerciseSet - A single set of an exercise
// - Properties: id, reps, prescribedWeight, type, completedWeight, actualReps, isComplete

// ExerciseType - The type of rep scheme
// - Cases: fixed, amrap, range(min, max), text(String)

// ExerciseCategory - Classification of exercise intensity
// - Cases: compound, isolation, accessory, warmup, cooldown

// MARK: - Calculations

// defaultPercentage(reps:) -> Double
// Maps rep count to percentage of 1RM (1 rep = 100%, 12 reps = 60%)

// calculatePrescribedWeight(max:reps:energyMultiplier:cycleMultiplier:) -> Double
// Calculates prescribed weight based on 1RM, reps, energy level, and cycle phase

// roundToNearest(_:increment:) -> Double
// Rounds a value to the nearest increment (e.g., 5 lbs)

// calculatePlates(targetWeight:barWeight:) -> [Plate]
// Calculates which plates to load on one side of a barbell

// MARK: - Unit Conversion

// lbsToKg(_:) -> Double
// Converts pounds to kilograms

// kgToLbs(_:) -> Double
// Converts kilograms to pounds

// MARK: - Supporting Types

// Plate - Represents a plate weight and count per side
// - Properties: weight (Double), count (Int)

// standardPlates - Array of standard plate sizes in lbs [45, 35, 25, 10, 5, 2.5]

import Foundation

// MARK: - SubstitutionRanker

/// Ranks substitute exercises by similarity, equipment match, and injury compatibility.
///
/// Given a target exercise the user cannot or does not want to perform,
/// plus their context (injuries, available equipment, time constraints),
/// returns a ranked list of alternatives from the exercise catalog.
///
/// Pure domain logic — no framework dependencies.
public enum SubstitutionRanker {

    // MARK: - Types

    /// A ranked substitute exercise.
    public struct RankedSubstitution: Sendable, Equatable {
        /// The substitute exercise name.
        public let exerciseName: String

        /// The category of the substitute.
        public let category: WeightliftingCategory

        /// Overall match score (0.0–1.0, higher is better).
        public let score: Double

        /// Why this exercise is a good substitute.
        public let reason: String
    }

    /// Available equipment context for filtering.
    public struct EquipmentContext: Sendable {
        /// Whether a barbell is available.
        public let hasBarbell: Bool
        /// Whether dumbbells are available.
        public let hasDumbbells: Bool
        /// Whether a pull-up bar is available.
        public let hasPullUpBar: Bool
        /// Whether machines/cables are available.
        public let hasMachines: Bool

        public init(hasBarbell: Bool = true, hasDumbbells: Bool = true,
                    hasPullUpBar: Bool = true, hasMachines: Bool = true) {
            self.hasBarbell = hasBarbell
            self.hasDumbbells = hasDumbbells
            self.hasPullUpBar = hasPullUpBar
            self.hasMachines = hasMachines
        }

        /// Full gym — everything available.
        public static let fullGym = EquipmentContext()

        /// Home with dumbbells only.
        public static let homeDumbbells = EquipmentContext(
            hasBarbell: false, hasDumbbells: true,
            hasPullUpBar: false, hasMachines: false
        )

        /// Bodyweight only.
        public static let bodyweightOnly = EquipmentContext(
            hasBarbell: false, hasDumbbells: false,
            hasPullUpBar: false, hasMachines: false
        )
    }

    // MARK: - Ranking

    /// Finds and ranks substitute exercises for a given target.
    ///
    /// - Parameters:
    ///   - target: The exercise to substitute.
    ///   - injuries: Current active injuries (used to filter out contraindicated exercises).
    ///   - equipment: Available equipment.
    ///   - limit: Maximum number of results (default 5).
    /// - Returns: Ranked substitutions, best first.
    public static func rank(
        substitutesFor target: String,
        injuries: [Injury] = [],
        equipment: EquipmentContext = .fullGym,
        limit: Int = 5
    ) -> [RankedSubstitution] {
        // Find the target's category
        guard let targetEntry = weightliftingExercises.first(where: { $0.id == target }) else {
            return []
        }
        let targetCategory = targetEntry.category

        // Get all exercises in the same category (excluding the target)
        let candidates = weightliftingExercises.filter {
            $0.id != target
        }

        var scored: [RankedSubstitution] = []

        for candidate in candidates {
            // Skip if contraindicated by injuries
            if !injuries.isEmpty {
                let contraindicated = InjuryAdaptationEngine.isContraindicated(
                    exerciseName: candidate.id,
                    exerciseCategory: nil,
                    injuries: injuries
                )
                if contraindicated { continue }
            }

            // Skip if equipment doesn't match
            if !matchesEquipment(candidate.id, equipment: equipment) {
                continue
            }

            // Calculate score
            var score = 0.0
            var reasons: [String] = []

            // Same category = strongest signal
            if candidate.category == targetCategory {
                score += 0.5
                reasons.append("same movement pattern")
            } else {
                // Adjacent categories get partial credit
                if areRelatedCategories(targetCategory, candidate.category) {
                    score += 0.25
                    reasons.append("related movement")
                }
            }

            // Similarity bonus based on name overlap
            let nameSimilarity = nameSimilarityScore(target, candidate.id)
            score += nameSimilarity * 0.3
            if nameSimilarity > 0.3 {
                reasons.append("similar exercise variant")
            }

            // Equipment simplicity bonus (dumbbells > barbells for substitutes)
            if isDumbbellExercise(candidate.id) && !isDumbbellExercise(target) {
                score += 0.1
                reasons.append("dumbbell alternative")
            }

            // Machine alternative bonus when injured
            if !injuries.isEmpty && isMachineExercise(candidate.id) {
                score += 0.1
                reasons.append("machine (more controlled)")
            }

            let reason = reasons.isEmpty ? "alternative option" : reasons.joined(separator: ", ")
            let capped = min(score, 1.0)

            scored.append(RankedSubstitution(
                exerciseName: candidate.id,
                category: candidate.category,
                score: capped,
                reason: reason.prefix(1).uppercased() + reason.dropFirst()
            ))
        }

        // Sort by score descending, take top N
        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }

    // MARK: - Private Helpers

    private static func matchesEquipment(_ exercise: String, equipment: EquipmentContext) -> Bool {
        let name = exercise.lowercased()

        if name.contains("barbell") || name.contains("bar ") {
            return equipment.hasBarbell
        }
        if name.contains("dumbbell") {
            return equipment.hasDumbbells
        }
        if name.contains("pull-up") || name.contains("chin-up") || name.contains("muscle-up") {
            return equipment.hasPullUpBar
        }
        if name.contains("cable") || name.contains("machine") || name.contains("lat pulldown")
            || name.contains("leg press") || name.contains("hack squat")
            || name.contains("leg extension") || name.contains("leg curl") {
            return equipment.hasMachines
        }

        // Default: assume it's available (bodyweight, kettlebell, etc.)
        return true
    }

    private static func areRelatedCategories(
        _ a: WeightliftingCategory,
        _ b: WeightliftingCategory
    ) -> Bool {
        let relatedPairs: Set<Set<WeightliftingCategory>> = [
            [.squat, .hipHinge],
            [.press, .olympicWeightlifting],
            [.pull, .olympicWeightlifting],
        ]
        return relatedPairs.contains([a, b])
    }

    private static func nameSimilarityScore(_ a: String, _ b: String) -> Double {
        let aWords = Set(a.lowercased().split(separator: " ").map(String.init))
        let bWords = Set(b.lowercased().split(separator: " ").map(String.init))
        let common = aWords.intersection(bWords)
        let total = aWords.union(bWords)
        guard !total.isEmpty else { return 0 }
        return Double(common.count) / Double(total.count)
    }

    private static func isDumbbellExercise(_ name: String) -> Bool {
        name.lowercased().contains("dumbbell")
    }

    private static func isMachineExercise(_ name: String) -> Bool {
        let keywords = ["machine", "cable", "lat pulldown", "leg press",
                        "hack squat", "leg extension", "leg curl"]
        let lower = name.lowercased()
        return keywords.contains(where: { lower.contains($0) })
    }
}

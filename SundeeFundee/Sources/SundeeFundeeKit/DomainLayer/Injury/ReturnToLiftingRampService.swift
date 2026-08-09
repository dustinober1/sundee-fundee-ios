import Foundation

// MARK: - Return-to-Lifting Ramp Recommendation

/// A load and set cap for a movement pattern based on pain/injury state.
public struct ReturnToLiftingRampRecommendation: Sendable, Equatable {
    public let movementPattern: WorkoutMovementPattern
    public let maxLoadPercent: Double
    public let maxWorkingSets: Int
    public let reason: String

    public init(
        movementPattern: WorkoutMovementPattern,
        maxLoadPercent: Double,
        maxWorkingSets: Int,
        reason: String
    ) {
        self.movementPattern = movementPattern
        self.maxLoadPercent = maxLoadPercent
        self.maxWorkingSets = maxWorkingSets
        self.reason = reason
    }
}

// MARK: - Return-to-Lifting Ramp Service

/// Pure domain service that computes ramp-back recommendations from pain logs,
/// injuries, and existing ramp records.
public enum ReturnToLiftingRampService {

    /// Maps body region engine keys to the movement patterns they affect.
    private static let regionPatternMap: [String: [WorkoutMovementPattern]] = [
        "knee":    [.squat],
        "back":    [.hinge],
        "shoulder":[.push],
        "hip":     [.squat, .hinge],
        "wrist":   [.push, .pull],
        "elbow":   [.push, .pull],
        "ankle":   [.squat, .conditioning],
        "neck":    [.push, .pull],
        "chest":   [.push],
    ]

    // MARK: - Recommendations

    /// Generate ramp recommendations for the current pain/injury state, and
    /// optionally for a return to training after a non-injury break.
    ///
    /// Priority:
    /// 1. Existing ramp records override computed recommendations.
    /// 2. Active severe/moderate pain computes conservative caps.
    /// 3. Resolved injuries start at 50–60% for their patterns.
    /// 4. A break reason, if given, applies to every movement pattern.
    ///
    /// Steps 1–3 are unchanged from the injury-only behavior. Step 4 runs last
    /// and is skipped entirely when `breakReason` is nil, so nothing about the
    /// injury path moves.
    ///
    /// - Parameter breakReason: Why the person is returning, when the return
    ///   is not injury-driven. Unlike an injury, a break has no affected body
    ///   region, so it caps every pattern rather than a mapped subset.
    public static func recommendations(
        painLogs: [DailyPainLog],
        injuries: [Injury],
        activeRamps: [ReturnToLiftingRampRecord],
        breakReason: TrainingBreakReason? = nil
    ) -> [ReturnToLiftingRampRecommendation] {
        var recommendations: [WorkoutMovementPattern: ReturnToLiftingRampRecommendation] = [:]

        // Step 1: Apply active ramp records first (they override computed values)
        for ramp in activeRamps {
            guard let pattern = ramp.movementPattern else { continue }
            recommendations[pattern] = ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: ramp.maxLoadPercent,
                maxWorkingSets: ramp.maxWorkingSets,
                reason: rampReason(for: pattern, loadPercent: ramp.maxLoadPercent)
            )
        }

        // Step 2: Compute from pain logs (moderate+ intensity only)
        // Ramp records already applied in Step 1; skip patterns with active ramps.
        let rampedPatterns = Set(activeRamps.compactMap { $0.movementPattern })
        let significantPainLogs = painLogs.filter { $0.intensity >= 4 }
        for log in significantPainLogs {
            let regions = log.bodyRegions
            for region in regions {
                guard let patterns = regionPatternMap[region.engineKey] else { continue }
                for pattern in patterns {
                    guard !rampedPatterns.contains(pattern) else { continue }
                    let computed = recommendationForPain(
                        intensity: log.intensity,
                        pattern: pattern
                    )
                    if let existing = recommendations[pattern] {
                        // Keep the more conservative of the two
                        if computed.maxLoadPercent < existing.maxLoadPercent {
                            recommendations[pattern] = computed
                        }
                    } else {
                        recommendations[pattern] = computed
                    }
                }
            }
        }

        // Step 3: Compute from resolved injuries
        let resolvedInjuries = injuries.filter { $0.recoveryPhase == .resolved }
        for injury in resolvedInjuries {
            let regions = injury.bodyRegions
            for region in regions {
                guard let patterns = regionPatternMap[region.engineKey] else { continue }
                for pattern in patterns {
                    if recommendations[pattern] != nil { continue } // Don't override existing
                    recommendations[pattern] = ReturnToLiftingRampRecommendation(
                        movementPattern: pattern,
                        maxLoadPercent: 0.55,
                        maxWorkingSets: 3,
                        reason: resolvedReason(for: pattern)
                    )
                }
            }
        }

        // Step 4: Apply a non-injury return across every movement pattern.
        if let breakReason {
            applyBreakReason(
                breakReason,
                to: &recommendations,
                skipping: rampedPatterns
            )
        }

        return Array(recommendations.values)
            .sorted { $0.movementPattern.rawValue < $1.movementPattern.rawValue }
    }

    // MARK: - Ramp Advancement

    /// Advance a ramp record by one week, increasing load and optionally sets.
    public static func advanceRamp(_ ramp: ReturnToLiftingRampRecord) -> ReturnToLiftingRampRecord {
        let weeklyIncrease = 0.07 // 7% per week, within 5-10% range
        let newLoad = min(1.0, ramp.maxLoadPercent + weeklyIncrease)

        // Advance working sets when load passes 70%
        let newSets: Int
        if newLoad >= 0.70 && ramp.maxWorkingSets < 4 {
            newSets = ramp.maxWorkingSets + 1
        } else if newLoad >= 0.85 && ramp.maxWorkingSets < 5 {
            newSets = ramp.maxWorkingSets + 1
        } else {
            newSets = ramp.maxWorkingSets
        }

        return ReturnToLiftingRampRecord(
            id: ramp.id,
            locationIds: ramp.locationIds,
            movementPatternRaw: ramp.movementPatternRaw,
            currentWeek: ramp.currentWeek + 1,
            maxLoadPercent: newLoad,
            maxWorkingSets: newSets,
            dateCreated: ramp.dateCreated,
            dateUpdated: Date()
        )
    }

    // MARK: - Private Helpers

    /// Caps every movement pattern for a non-injury return.
    ///
    /// Runs after the injury steps so their behavior is untouched. Patterns
    /// already governed by an active ramp record are skipped: that record
    /// tracks progress the person has already earned, and a newly-selected
    /// break reason should not walk it back.
    private static func applyBreakReason(
        _ breakReason: TrainingBreakReason,
        to recommendations: inout [WorkoutMovementPattern: ReturnToLiftingRampRecommendation],
        skipping rampedPatterns: Set<WorkoutMovementPattern>
    ) {
        for pattern in WorkoutMovementPattern.allCases where !rampedPatterns.contains(pattern) {
            let fromBreak = ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: breakReason.startingLoadPercent,
                maxWorkingSets: breakReason.startingWorkingSets,
                reason: breakReason.rampReason(for: pattern)
            )

            guard let existing = recommendations[pattern] else {
                recommendations[pattern] = fromBreak
                continue
            }

            // Both a break and current pain/injury apply here. Take the more
            // cautious value on each axis, and show the reason belonging to
            // whichever one set the load, so the explanation always matches
            // the number next to it.
            let breakIsMoreCautious = fromBreak.maxLoadPercent < existing.maxLoadPercent
            recommendations[pattern] = ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: min(existing.maxLoadPercent, fromBreak.maxLoadPercent),
                maxWorkingSets: min(existing.maxWorkingSets, fromBreak.maxWorkingSets),
                reason: breakIsMoreCautious ? fromBreak.reason : existing.reason
            )
        }
    }

    private static func recommendationForPain(
        intensity: Int,
        pattern: WorkoutMovementPattern
    ) -> ReturnToLiftingRampRecommendation {
        let painLevel = PainLevel.from(intensity: intensity)

        switch painLevel {
        case .extreme:
            return ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: 0.30,
                maxWorkingSets: 2,
                reason: extremePainReason(for: pattern)
            )
        case .severe:
            return ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: 0.40,
                maxWorkingSets: 3,
                reason: severePainReason(for: pattern)
            )
        case .moderate:
            return ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: 0.60,
                maxWorkingSets: 3,
                reason: moderatePainReason(for: pattern)
            )
        case .mild, .none:
            // Mild pain does not produce ramp recommendations
            return ReturnToLiftingRampRecommendation(
                movementPattern: pattern,
                maxLoadPercent: 1.0,
                maxWorkingSets: 5,
                reason: ""
            )
        }
    }

    // MARK: - Reason Copy (non-medical, ease-back-in language)

    private static func extremePainReason(for pattern: WorkoutMovementPattern) -> String {
        "Significant discomfort in \(pattern.displayName) movements. Ease back in with very light loading and minimal sets while things settle down."
    }

    private static func severePainReason(for pattern: WorkoutMovementPattern) -> String {
        "\(pattern.displayName) movements need a conservative approach right now. Reduce the load and keep sets low to ease back into training."
    }

    private static func moderatePainReason(for pattern: WorkoutMovementPattern) -> String {
        "\(pattern.displayName) pattern is feeling sensitive. Start light and gradually build back to your usual working loads."
    }

    private static func rampReason(for pattern: WorkoutMovementPattern, loadPercent: Double) -> String {
        let percentDisplay = Int(round(loadPercent * 100))
        if loadPercent < 0.5 {
            return "Continuing to ease back into \(pattern.displayName) movements at \(percentDisplay)% load. Gradual progress is the goal."
        } else if loadPercent < 0.8 {
            return "Building back up on \(pattern.displayName) movements at \(percentDisplay)% load. Keep progressing gradually."
        } else {
            return "Almost back to full capacity on \(pattern.displayName) at \(percentDisplay)%. Ease into your normal loads."
        }
    }

    private static func resolvedReason(for pattern: WorkoutMovementPattern) -> String {
        "Starting a gradual return to \(pattern.displayName) movements. Begin conservatively and build back up week by week."
    }
}

// MARK: - WorkoutMovementPattern Display

extension WorkoutMovementPattern {
    /// User-facing display name for movement patterns.
    public var displayName: String {
        switch self {
        case .squat:        return "squat"
        case .hinge:        return "hinge"
        case .push:         return "pushing"
        case .pull:         return "pulling"
        case .core:         return "core"
        case .carry:        return "carry"
        case .conditioning: return "conditioning"
        }
    }
}

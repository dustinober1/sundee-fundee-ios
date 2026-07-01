import Foundation

public enum BlockedStationKind: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case rack
    case bench
    case machine
    case cable
    case floorSpace

    public var displayName: String {
        switch self {
        case .rack: return "Rack"
        case .bench: return "Bench"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .floorSpace: return "Floor space"
        }
    }
}

public struct StationTakenSwapRequest: Sendable, Equatable {
    public let exerciseName: String
    public let blockedStation: BlockedStationKind
    public let equipment: EquipmentAccess
    public let painLogs: [DailyPainLog]

    public init(
        exerciseName: String,
        blockedStation: BlockedStationKind,
        equipment: EquipmentAccess,
        painLogs: [DailyPainLog]
    ) {
        self.exerciseName = exerciseName
        self.blockedStation = blockedStation
        self.equipment = equipment
        self.painLogs = painLogs
    }

    public static func == (lhs: StationTakenSwapRequest, rhs: StationTakenSwapRequest) -> Bool {
        lhs.exerciseName == rhs.exerciseName
            && lhs.blockedStation == rhs.blockedStation
            && lhs.equipment == rhs.equipment
            && lhs.painLogs.stationTakenComparableValue == rhs.painLogs.stationTakenComparableValue
    }
}

public enum StationTakenSwapService {
    public static func rankedSwaps(
        request: StationTakenSwapRequest
    ) -> [SubstitutionRanker.RankedSubstitution] {
        let equipmentContext = substitutionContext(for: request.equipment)
        let base = SubstitutionRanker.rank(
            substitutesFor: request.exerciseName,
            equipment: equipmentContext,
            limit: 24
        )
        guard !base.isEmpty else { return [] }

        let painAdjustedByName = painAdjustedCandidates(for: request)
        let targetPattern = movementPattern(for: request.exerciseName)

        let ranked = base.compactMap { candidate -> StationTakenCandidate? in
            guard !requires(candidate.exerciseName, station: request.blockedStation) else {
                return nil
            }

            let painAdjusted = painAdjustedByName[candidate.exerciseName]
            let effective = painAdjusted ?? candidate
            let candidatePattern = movementPattern(for: effective.exerciseName)
            let samePattern = candidatePattern == targetPattern
            let stationIndependent = !requiresAnyStation(effective.exerciseName)
            let adjustedScore = min(
                1.0,
                effective.score
                    + (samePattern ? 0.12 : 0)
                    + (stationIndependent ? 0.03 : 0)
            )
            let reason = reason(
                for: effective,
                blockedStation: request.blockedStation,
                samePattern: samePattern
            )
            let substitution = SubstitutionRanker.RankedSubstitution(
                exerciseName: effective.exerciseName,
                category: effective.category,
                score: adjustedScore,
                reason: reason
            )
            return StationTakenCandidate(
                substitution: substitution,
                samePattern: samePattern,
                stationIndependent: stationIndependent
            )
        }

        return ranked.sorted { lhs, rhs in
            if lhs.substitution.score != rhs.substitution.score {
                return lhs.substitution.score > rhs.substitution.score
            }
            if lhs.samePattern != rhs.samePattern {
                return lhs.samePattern
            }
            if lhs.stationIndependent != rhs.stationIndependent {
                return lhs.stationIndependent
            }
            return lhs.substitution.exerciseName < rhs.substitution.exerciseName
        }
        .prefix(8)
        .map(\.substitution)
    }

    private static func painAdjustedCandidates(
        for request: StationTakenSwapRequest
    ) -> [String: SubstitutionRanker.RankedSubstitution] {
        guard !request.painLogs.isEmpty else { return [:] }

        let adjusted = PainAwareSubstitutionService.rank(
            currentExercise: request.exerciseName,
            recentPainLogs: request.painLogs,
            injuries: [],
            equipment: request.equipment,
            limit: 24
        )
        return Dictionary(uniqueKeysWithValues: adjusted.map {
            ($0.substitution.exerciseName, $0.substitution)
        })
    }

    private static func substitutionContext(
        for equipment: EquipmentAccess
    ) -> SubstitutionRanker.EquipmentContext {
        switch equipment {
        case .fullGym:
            return .fullGym
        case .homeDumbbells:
            return .homeDumbbells
        case .resistanceBands:
            return .resistanceBands
        case .bodyweightOnly, .outdoor:
            return .bodyweightOnly
        case .kettlebellOnly:
            return .kettlebellOnly
        }
    }

    private static func reason(
        for substitution: SubstitutionRanker.RankedSubstitution,
        blockedStation: BlockedStationKind,
        samePattern: Bool
    ) -> String {
        let stationCopy = "Avoids the taken \(blockedStation.displayName.lowercased())."
        guard samePattern else {
            return "\(stationCopy) \(substitution.reason)"
        }
        return "\(stationCopy) Keeps the same movement pattern."
    }

    private static func requiresAnyStation(_ exerciseName: String) -> Bool {
        BlockedStationKind.allCases.contains {
            requires(exerciseName, station: $0)
        }
    }

    private static func requires(
        _ exerciseName: String,
        station: BlockedStationKind
    ) -> Bool {
        let lower = exerciseName.lowercased()
        let tags = Set(trainingExerciseCatalog.first {
            $0.id.compare(exerciseName, options: [.caseInsensitive]) == .orderedSame
        }?.equipmentTags ?? [])

        switch station {
        case .rack:
            if lower.contains("goblet") || lower.contains("air squat") || lower.contains("band") {
                return false
            }
            return lower.contains("back squat")
                || lower.contains("front squat")
                || lower.contains("safety bar squat")
                || lower.contains("box squat")
                || lower.contains("pause squat")
                || lower.contains("strict press")
                || lower.contains("push press")
                || lower.contains("yoke")
        case .bench:
            return lower.contains("bench")
                || lower.contains("incline press")
                || lower.contains("decline press")
                || lower.contains("floor press")
        case .machine:
            return tags.contains(.machine)
                || tags.contains(.cardio)
                || lower.contains("machine")
                || lower.contains("leg press")
                || lower.contains("hack squat")
                || lower.contains("leg extension")
                || lower.contains("leg curl")
                || lower.contains("lat pulldown")
                || lower.contains("row")
                    && (lower.contains("calories") || lower.contains("meter"))
                || lower.contains("bike")
                || lower.contains("skierg")
        case .cable:
            return tags.contains(.cable)
                || lower.contains("cable")
                || lower.contains("face pull")
        case .floorSpace:
            return tags.contains(.bodyweight)
                || lower.contains("push-up")
                || lower.contains("sit-up")
                || lower.contains("plank")
                || lower.contains("burpee")
                || lower.contains("v-up")
                || lower.contains("l-sit")
                || lower.contains("dead bug")
                || lower.contains("wall walk")
        }
    }

    private static func movementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        if let definition = trainingExerciseCatalog.first(where: {
            $0.id.compare(exerciseName, options: [.caseInsensitive]) == .orderedSame
        }) {
            return definition.movementPattern
        }

        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") || lower.contains("swing") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") || lower.contains("dip") {
            return .push
        }
        if lower.contains("row") || lower.contains("pull") || lower.contains("curl") {
            return .pull
        }
        if lower.contains("plank") || lower.contains("core") || lower.contains("dead bug") {
            return .core
        }
        if lower.contains("carry") {
            return .carry
        }
        return .conditioning
    }
}

private struct StationTakenCandidate: Sendable, Equatable {
    let substitution: SubstitutionRanker.RankedSubstitution
    let samePattern: Bool
    let stationIndependent: Bool
}

extension Array where Element == DailyPainLog {
    fileprivate var stationTakenComparableValue: [String] {
        map { log in
            [
                log.id,
                log.locationIds,
                "\(log.intensity)",
                log.painType.rawValue,
                "\(log.date.timeIntervalSince1970)",
                log.notes ?? ""
            ].joined(separator: "|")
        }
    }
}

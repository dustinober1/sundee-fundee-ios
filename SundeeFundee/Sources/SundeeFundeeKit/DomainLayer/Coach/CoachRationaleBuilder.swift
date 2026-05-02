import Foundation

public enum CoachRationaleBuilder {
    public static func rationale(from packet: CoachDecisionPacket) -> WorkoutRationale {
        let reasons = packet.reasonCodes
            .filter { !$0.isCaution }
            .sorted { $0.priority < $1.priority }
            .map(\.defaultUserText)
        let cautions = packet.cautionCodes
            .sorted { $0.priority < $1.priority }
            .map(\.defaultUserText)
        let headline = packet.reasonCodes.first?.shortLabel ?? "Built for today"
        return WorkoutRationale(
            headline: headline,
            reasons: Array(reasons.prefix(4)),
            cautions: Array(cautions.prefix(2))
        )
    }
}

import Foundation

public enum CoachCopyTemplates {
    public static func summary(from packet: CoachDecisionPacket) -> String {
        let base = packet.deterministicSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.isEmpty { return base }

        let labels = packet.reasonCodes.prefix(2).map(\.shortLabel)
        if labels.isEmpty { return "Your workout is built from today's training context." }
        return "Your workout is built around \(labels.joined(separator: " and ").lowercased())."
    }

    public static func tips(from packet: CoachDecisionPacket, limit: Int = 3) -> [String] {
        let existing = packet.deterministicTips
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !existing.isEmpty { return Array(existing.prefix(limit)) }
        return Array(packet.reasonCodes.map(\.defaultUserText).prefix(limit))
    }

    public static func fallbackCopy(from packet: CoachDecisionPacket) -> (summary: String, tips: [String]) {
        (summary(from: packet), tips(from: packet))
    }
}

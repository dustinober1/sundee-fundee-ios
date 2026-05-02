import Foundation

public enum CoachCopyFallback {
    public static func workoutResponse(
        base: CoachWorkoutResponse,
        packet: CoachDecisionPacket,
        source: CoachCopySource
    ) -> CoachWorkoutResponse {
        let copy = CoachCopyTemplates.fallbackCopy(from: packet)
        return base.replacingCopy(summary: copy.summary, tips: copy.tips, packet: packet, source: source)
    }
}

import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor ChallengeInviteService {
    public init() {}

    public func template(from challenge: Challenge, userID: String? = nil) -> ChallengeShareTemplate {
        ChallengeShareTemplate(
            challengeType: challenge.type,
            title: challenge.title,
            targetVolumeLbs: challenge.tiers.last?.targetVolumeLbs,
            exerciseName: challenge.exerciseName,
            createdByUserID: userID
        )
    }

    public func inviteText(template: ChallengeShareTemplate, inviteToken: String? = nil) -> String {
        let context = ShareContext(
            surface: .challenge,
            sourceID: template.id,
            title: template.title,
            referralCode: inviteToken
        )
        var details = [template.title]
        if let target = template.targetVolumeLbs {
            details.append("Target: \(formatVolume(target)) lbs")
        }
        if let exercise = template.exerciseName {
            details.append("Exercise: \(exercise)")
        }
        if let inviteToken {
            details.append("Join code: \(inviteToken)")
        }
        details.append(GrowthLinkService.caption(for: context))
        return details.joined(separator: "\n")
    }

    public func makeInviteToken(length: Int = 8) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000 {
            return "\(Int(volume / 1_000))K"
        }
        return "\(Int(volume))"
    }
}

import Foundation

public struct ChallengeShareTemplate: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let challengeType: ChallengeType
    public let title: String
    public let targetVolumeLbs: Double?
    public let exerciseName: String?
    public let createdByUserID: String?
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        challengeType: ChallengeType,
        title: String,
        targetVolumeLbs: Double? = nil,
        exerciseName: String? = nil,
        createdByUserID: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.challengeType = challengeType
        self.title = title
        self.targetVolumeLbs = targetVolumeLbs
        self.exerciseName = exerciseName
        self.createdByUserID = createdByUserID
        self.dateCreated = dateCreated
    }
}

public struct ChallengeInvite: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let inviteToken: String
    public let template: ChallengeShareTemplate
    public let createdByUserID: String?
    public let dateCreated: Date
    public let expiresAt: Date?

    public init(
        id: String = UUID().uuidString,
        inviteToken: String,
        template: ChallengeShareTemplate,
        createdByUserID: String? = nil,
        dateCreated: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.inviteToken = inviteToken
        self.template = template
        self.createdByUserID = createdByUserID
        self.dateCreated = dateCreated
        self.expiresAt = expiresAt
    }
}

public struct ChallengeParticipant: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let inviteToken: String
    public let userID: String
    public let displayName: String?
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        inviteToken: String,
        userID: String,
        displayName: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.inviteToken = inviteToken
        self.userID = userID
        self.displayName = displayName
        self.dateCreated = dateCreated
    }
}

public struct ChallengeReaction: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let inviteToken: String
    public let userID: String
    public let reaction: String
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        inviteToken: String,
        userID: String,
        reaction: String,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.inviteToken = inviteToken
        self.userID = userID
        self.reaction = reaction
        self.dateCreated = dateCreated
    }
}

public struct SocialChallengeProgressSnapshot: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let inviteToken: String
    public let userID: String
    public let accumulatedVolumeLbs: Double
    public let percentComplete: Double
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        inviteToken: String,
        userID: String,
        accumulatedVolumeLbs: Double,
        percentComplete: Double,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.inviteToken = inviteToken
        self.userID = userID
        self.accumulatedVolumeLbs = accumulatedVolumeLbs
        self.percentComplete = percentComplete
        self.dateCreated = dateCreated
    }
}

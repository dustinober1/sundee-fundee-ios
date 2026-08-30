import CloudKit
import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor SocialChallengeService {
    private let publicClient: DataClientProtocol

    public init(
        publicClient: DataClientProtocol = CloudKitClient(
            containerIdentifier: "iCloud.com.sundeefundee.app",
            databaseScope: .public
        )
    ) {
        self.publicClient = publicClient
    }

    public func createInvite(
        template: ChallengeShareTemplate,
        userID: String?,
        expiresAt: Date? = nil
    ) async throws -> ChallengeInvite {
        let token = await ChallengeInviteService().makeInviteToken()
        let invite = ChallengeInvite(
            inviteToken: token,
            template: template,
            createdByUserID: userID,
            expiresAt: expiresAt
        )
        try await publicClient.save(invite, recordType: "ChallengeInvite")
        return invite
    }

    public func fetchInvite(token: String) async throws -> ChallengeInvite? {
        let predicate = NSPredicate(format: "inviteToken == %@", token.uppercased())
        let invites: [ChallengeInvite] = try await publicClient.fetch(
            recordType: "ChallengeInvite",
            predicate: predicate,
            sortDescriptors: nil
        )
        return invites.first
    }

    public func join(inviteToken: String, userID: String, displayName: String?) async throws -> ChallengeParticipant {
        let participant = ChallengeParticipant(
            inviteToken: inviteToken.uppercased(),
            userID: userID,
            displayName: displayName
        )
        try await publicClient.save(participant, recordType: "ChallengeParticipant")
        return participant
    }

    public func saveProgressSnapshot(_ snapshot: SocialChallengeProgressSnapshot) async throws {
        try await publicClient.save(snapshot, recordType: "SocialChallengeProgressSnapshot")
    }

    public func saveReaction(_ reaction: ChallengeReaction) async throws {
        try await publicClient.save(reaction, recordType: "ChallengeReaction")
    }

    /// Reactions left on a shared challenge invite, newest first.
    ///
    /// `saveReaction` has had no caller anywhere in the app; this is its
    /// missing read counterpart. No UI reads this yet — displaying it needs
    /// a stable invite token recorded on the local `Challenge`, which today
    /// only exists as a short-lived local variable at share and join time.
    public func fetchReactions(inviteToken: String) async throws -> [ChallengeReaction] {
        let predicate = NSPredicate(format: "inviteToken == %@", inviteToken.uppercased())
        let reactions: [ChallengeReaction] = try await publicClient.fetch(
            recordType: "ChallengeReaction",
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: false)]
        )
        return reactions
    }

    /// Progress snapshots participants have posted for a shared challenge
    /// invite, most recent first. See `fetchReactions` for the same caveat:
    /// nothing writes these outside of tests today, and no UI reads them.
    public func fetchProgressSnapshots(inviteToken: String) async throws -> [SocialChallengeProgressSnapshot] {
        let predicate = NSPredicate(format: "inviteToken == %@", inviteToken.uppercased())
        let snapshots: [SocialChallengeProgressSnapshot] = try await publicClient.fetch(
            recordType: "SocialChallengeProgressSnapshot",
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: false)]
        )
        return snapshots
    }
}

import CloudKit
import Testing
@testable import SundeeFundeeKit

@Suite("Social challenge reads")
struct SocialChallengeServiceReadTests {

    @Test("fetchReactions returns only reactions for the requested invite token")
    func fetchReactionsFiltersByToken() async throws {
        let matching = ChallengeReaction(inviteToken: "ABCDEFGH", userID: "user-1", reaction: "🎉")
        let other = ChallengeReaction(inviteToken: "ZZZZZZZZ", userID: "user-2", reaction: "💪")
        let client = PredicateFilteringPublicClient(reactions: [matching, other])
        let service = SocialChallengeService(publicClient: client)

        let result = try await service.fetchReactions(inviteToken: "abcdefgh")

        #expect(result.count == 1)
        #expect(result.first?.userID == "user-1")
    }

    @Test("fetchReactions returns an empty array when nothing matches")
    func fetchReactionsEmptyWhenNoMatch() async throws {
        let other = ChallengeReaction(inviteToken: "ZZZZZZZZ", userID: "user-2", reaction: "💪")
        let client = PredicateFilteringPublicClient(reactions: [other])
        let service = SocialChallengeService(publicClient: client)

        let result = try await service.fetchReactions(inviteToken: "ABCDEFGH")

        #expect(result.isEmpty)
    }

    @Test("fetchProgressSnapshots returns only snapshots for the requested invite token")
    func fetchProgressSnapshotsFiltersByToken() async throws {
        let matching = SocialChallengeProgressSnapshot(
            inviteToken: "ABCDEFGH", userID: "user-1", accumulatedVolumeLbs: 5_000, percentComplete: 0.5
        )
        let other = SocialChallengeProgressSnapshot(
            inviteToken: "ZZZZZZZZ", userID: "user-2", accumulatedVolumeLbs: 1_000, percentComplete: 0.1
        )
        let client = PredicateFilteringPublicClient(snapshots: [matching, other])
        let service = SocialChallengeService(publicClient: client)

        let result = try await service.fetchProgressSnapshots(inviteToken: "ABCDEFGH")

        #expect(result.count == 1)
        #expect(result.first?.percentComplete == 0.5)
    }
}

/// Mocks CloudKit's predicate filtering closely enough to test the token
/// matching, by checking the token appears in the predicate's format string
/// (`NSPredicate(format: "inviteToken == %@", token)` substitutes the value
/// in) rather than re-implementing full KVC predicate evaluation for plain
/// Swift structs.
private actor PredicateFilteringPublicClient: DataClientProtocol {
    private let reactions: [ChallengeReaction]
    private let snapshots: [SocialChallengeProgressSnapshot]

    init(reactions: [ChallengeReaction] = [], snapshots: [SocialChallengeProgressSnapshot] = []) {
        self.reactions = reactions
        self.snapshots = snapshots
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        switch recordType {
        case "ChallengeReaction":
            return reactions.filter { predicate.predicateFormat.contains($0.inviteToken) } as? [T] ?? []
        case "SocialChallengeProgressSnapshot":
            return snapshots.filter { predicate.predicateFormat.contains($0.inviteToken) } as? [T] ?? []
        default:
            return []
        }
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {}

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}

    func deleteAllData() async throws {}
}

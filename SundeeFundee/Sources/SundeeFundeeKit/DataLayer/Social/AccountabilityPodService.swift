import Foundation
import os.log

private let podLogger = Logger(subsystem: "com.sundeefundee.app", category: "AccountabilityPod")

public enum PodError: Error, LocalizedError, Sendable, Equatable {
    case podNotFound
    case podFull
    case alreadyMember
    case rateLimitExceeded
    case invalidInviteCode

    public var errorDescription: String? {
        switch self {
        case .podNotFound: return "Accountability pod not found."
        case .podFull: return "This pod has reached its maximum of 8 members."
        case .alreadyMember: return "You are already a member of this pod."
        case .rateLimitExceeded: return "Daily nudge limit reached (max 3 per day)."
        case .invalidInviteCode: return "Invalid invite code. Check the code and try again."
        }
    }
}

// MARK: - AccountabilityPodService

public actor AccountabilityPodService {
    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    // MARK: - Pod Queries

    public func fetchUserPod(userID: String) async -> AccountabilityPod? {
        do {
            let pods: [AccountabilityPod] = try await dataClient.fetchAll(recordType: AccountabilityPod.recordType)
            return pods.first { pod in
                pod.members.contains { $0.id == userID }
            }
        } catch {
            podLogger.error("fetchUserPod failed: \(error.localizedDescription)")
            return nil
        }
    }

    public func fetchPod(byInviteCode code: String) async -> AccountabilityPod? {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCode.isEmpty else { return nil }

        do {
            let pods: [AccountabilityPod] = try await dataClient.fetchAll(recordType: AccountabilityPod.recordType)
            return pods.first { $0.inviteCode == cleanCode }
        } catch {
            podLogger.error("fetchPod by invite code failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Pod Mutations

    public func createPod(
        name: String,
        creatorID: String,
        creatorDisplayName: String,
        targetWorkouts: Int = 16
    ) async throws -> AccountabilityPod {
        let code = Self.generateInviteCode()
        let initialMember = PodMember(
            id: creatorID,
            displayName: creatorDisplayName,
            weeklyWorkoutsCompleted: 0,
            currentStreakDays: 0,
            joinedDate: Date()
        )
        let weekStart = Calendar.current.startOfDay(for: Date())
        let pod = AccountabilityPod(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            creatorID: creatorID,
            members: [initialMember],
            weeklyGoal: PodWeeklyGoal(targetWorkouts: targetWorkouts, weekStartDate: weekStart),
            inviteCode: code
        )

        try await dataClient.save(pod, recordType: AccountabilityPod.recordType)
        return pod
    }

    public func joinPod(
        inviteCode: String,
        memberID: String,
        displayName: String
    ) async throws -> AccountabilityPod {
        guard let pod = await fetchPod(byInviteCode: inviteCode) else {
            throw PodError.podNotFound
        }

        guard pod.canAddMember else {
            throw PodError.podFull
        }

        guard !pod.members.contains(where: { $0.id == memberID }) else {
            throw PodError.alreadyMember
        }

        let newMember = PodMember(
            id: memberID,
            displayName: displayName,
            weeklyWorkoutsCompleted: 0,
            currentStreakDays: 0,
            joinedDate: Date()
        )

        guard let updated = pod.addingMember(newMember) else {
            throw PodError.podFull
        }

        try await dataClient.save(updated, recordType: AccountabilityPod.recordType)
        return updated
    }

    public func leavePod(podID: String, memberID: String) async throws -> AccountabilityPod? {
        let pods: [AccountabilityPod] = (try? await dataClient.fetchAll(recordType: AccountabilityPod.recordType)) ?? []
        guard let pod = pods.first(where: { $0.id == podID }) else {
            throw PodError.podNotFound
        }

        let updated = pod.removingMember(memberID: memberID)
        if updated.members.isEmpty {
            // Delete empty pod
            try? await dataClient.delete(recordIDs: [], recordType: AccountabilityPod.recordType)
            return nil
        } else {
            try await dataClient.save(updated, recordType: AccountabilityPod.recordType)
            return updated
        }
    }

    public func syncMemberProgress(
        podID: String,
        memberID: String,
        weeklyCompleted: Int,
        streakDays: Int
    ) async throws -> AccountabilityPod {
        let pods: [AccountabilityPod] = (try? await dataClient.fetchAll(recordType: AccountabilityPod.recordType)) ?? []
        guard let pod = pods.first(where: { $0.id == podID }) else {
            throw PodError.podNotFound
        }

        let updated = pod.updatingMemberProgress(
            memberID: memberID,
            weeklyCompleted: weeklyCompleted,
            streakDays: streakDays
        )
        try await dataClient.save(updated, recordType: AccountabilityPod.recordType)
        return updated
    }

    // MARK: - Encouragements

    public func sendNudge(
        podID: String,
        senderID: String,
        senderName: String,
        recipientID: String? = nil,
        nudgeType: NudgeType
    ) async throws -> PodEncouragement {
        let nudges = await fetchRecentNudges(podID: podID)
        guard EncouragementRateLimiter.canSendNudge(senderID: senderID, podID: podID, existingEncouragements: nudges) else {
            throw PodError.rateLimitExceeded
        }

        let encouragement = PodEncouragement(
            podID: podID,
            senderID: senderID,
            senderName: senderName,
            recipientID: recipientID,
            nudgeType: nudgeType
        )

        try await dataClient.save(encouragement, recordType: PodEncouragement.recordType)
        return encouragement
    }

    public func fetchRecentNudges(podID: String) async -> [PodEncouragement] {
        do {
            let nudges: [PodEncouragement] = try await dataClient.fetchAll(recordType: PodEncouragement.recordType)
            return nudges
                .filter { $0.podID == podID }
                .sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            return []
        }
    }

    // MARK: - Helpers

    public static func generateInviteCode() -> String {
        let alphabet = Array("23456789ABCDEFGHJKLMNPQRSTUVWXYZ")
        return String((0..<6).compactMap { _ in alphabet.randomElement() })
    }
}

import Foundation

// MARK: - PodMember

public struct PodMember: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public var weeklyWorkoutsCompleted: Int
    public var currentStreakDays: Int
    public let joinedDate: Date

    public init(
        id: String,
        displayName: String,
        weeklyWorkoutsCompleted: Int = 0,
        currentStreakDays: Int = 0,
        joinedDate: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.weeklyWorkoutsCompleted = max(0, weeklyWorkoutsCompleted)
        self.currentStreakDays = max(0, currentStreakDays)
        self.joinedDate = joinedDate
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case weeklyWorkoutsCompleted
        case currentStreakDays
        case joinedDate
    }
}

// MARK: - PodWeeklyGoal

public struct PodWeeklyGoal: Codable, Sendable, Equatable {
    public var targetWorkouts: Int
    public var weekStartDate: Date

    public init(targetWorkouts: Int, weekStartDate: Date) {
        self.targetWorkouts = max(1, targetWorkouts)
        self.weekStartDate = weekStartDate
    }

    private enum CodingKeys: String, CodingKey {
        case targetWorkouts
        case weekStartDate
    }
}

// MARK: - AccountabilityPod

/// Micro-pod of 1 to 8 members for private workout accountability.
public struct AccountabilityPod: Codable, Sendable, Identifiable, Equatable {
    public static let maxMembers = 8
    public static let recordType = "AccountabilityPodRecord"

    public let id: String
    public var name: String
    public let creatorID: String
    public var members: [PodMember]
    public var weeklyGoal: PodWeeklyGoal
    public let inviteCode: String
    public let dateCreated: Date
    public var dateUpdated: Date

    public var canAddMember: Bool {
        members.count < Self.maxMembers
    }

    public var totalWorkoutsCompleted: Int {
        members.reduce(0) { $0 + $1.weeklyWorkoutsCompleted }
    }

    public init(
        id: String = "pod-\(UUID().uuidString.prefix(8).lowercased())",
        name: String,
        creatorID: String,
        members: [PodMember],
        weeklyGoal: PodWeeklyGoal,
        inviteCode: String,
        dateCreated: Date = Date(),
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.creatorID = creatorID
        self.members = members
        self.weeklyGoal = weeklyGoal
        self.inviteCode = inviteCode.uppercased()
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }

    public func addingMember(_ member: PodMember) -> AccountabilityPod? {
        guard canAddMember, !members.contains(where: { $0.id == member.id }) else {
            return nil
        }
        var updatedMembers = members
        updatedMembers.append(member)
        return AccountabilityPod(
            id: id,
            name: name,
            creatorID: creatorID,
            members: updatedMembers,
            weeklyGoal: weeklyGoal,
            inviteCode: inviteCode,
            dateCreated: dateCreated,
            dateUpdated: Date()
        )
    }

    public func removingMember(memberID: String) -> AccountabilityPod {
        let updatedMembers = members.filter { $0.id != memberID }
        return AccountabilityPod(
            id: id,
            name: name,
            creatorID: creatorID,
            members: updatedMembers,
            weeklyGoal: weeklyGoal,
            inviteCode: inviteCode,
            dateCreated: dateCreated,
            dateUpdated: Date()
        )
    }

    public func updatingMemberProgress(memberID: String, weeklyCompleted: Int, streakDays: Int) -> AccountabilityPod {
        var updatedMembers = members
        if let idx = updatedMembers.firstIndex(where: { $0.id == memberID }) {
            var updated = updatedMembers[idx]
            updated.weeklyWorkoutsCompleted = max(0, weeklyCompleted)
            updated.currentStreakDays = max(0, streakDays)
            updatedMembers[idx] = updated
        }
        return AccountabilityPod(
            id: id,
            name: name,
            creatorID: creatorID,
            members: updatedMembers,
            weeklyGoal: weeklyGoal,
            inviteCode: inviteCode,
            dateCreated: dateCreated,
            dateUpdated: Date()
        )
    }

    public func updatingWeeklyGoal(targetWorkouts: Int) -> AccountabilityPod {
        var updatedGoal = weeklyGoal
        updatedGoal.targetWorkouts = max(1, targetWorkouts)
        return AccountabilityPod(
            id: id,
            name: name,
            creatorID: creatorID,
            members: members,
            weeklyGoal: updatedGoal,
            inviteCode: inviteCode,
            dateCreated: dateCreated,
            dateUpdated: Date()
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case creatorID
        case members
        case weeklyGoal
        case inviteCode
        case dateCreated
        case dateUpdated
    }
}

import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Accountability Pods & Social Layer")
struct AccountabilityPodTests {

    // MARK: - SocialSnapshotBuilder

    @Test("SocialSnapshotBuilder computes weekly workouts and presence streak")
    func snapshotBuilderComputesWeeklyMetrics() {
        let now = Date()
        let calendar = Calendar.current

        let completedWorkout = Workout(
            date: now,
            name: "Upper Body",
            exercises: [],
            completedAt: now
        )
        let incompleteWorkout = Workout(
            date: now,
            name: "Incomplete",
            exercises: [],
            completedAt: nil
        )

        let presence = DailyPresenceRecord(
            dayKey: "2026-09-29",
            timeZoneIdentifier: "UTC",
            firstOpenDate: now,
            mostRecentOpenDate: now,
            participationLevel: .acted,
            status: .trained
        )

        let snapshot = SocialSnapshotBuilder.build(
            userID: "user-123",
            displayName: "Sarah",
            workouts: [completedWorkout, incompleteWorkout],
            presenceRecords: [presence],
            weeklyGoalTarget: 4,
            referenceDate: now,
            calendar: calendar
        )

        #expect(snapshot.id == "user-123")
        #expect(snapshot.displayName == "Sarah")
        #expect(snapshot.weeklyCompletedWorkouts == 1)
        #expect(snapshot.currentStreakDays >= 1)
        #expect(snapshot.weeklyGoalTarget == 4)
    }

    @Test("SocialSnapshotBuilder sanitizes empty display name")
    func snapshotBuilderSanitizesEmptyName() {
        let snapshot = SocialSnapshotBuilder.build(
            userID: "u1",
            displayName: "   ",
            workouts: [],
            presenceRecords: []
        )
        #expect(snapshot.displayName == "Lifter")
    }

    // MARK: - AccountabilityPod Model

    @Test("AccountabilityPod caps membership at 8 members")
    func podCapsMembershipAtEight() {
        let creator = PodMember(id: "creator", displayName: "Creator")
        var pod = AccountabilityPod(
            name: "Power Squad",
            creatorID: "creator",
            members: [creator],
            weeklyGoal: PodWeeklyGoal(targetWorkouts: 20, weekStartDate: Date()),
            inviteCode: "ABCDEF"
        )

        #expect(pod.canAddMember)

        // Add 7 more members (total 8)
        for i in 1...7 {
            let member = PodMember(id: "m\(i)", displayName: "Member \(i)")
            pod = pod.addingMember(member)!
        }

        #expect(pod.members.count == 8)
        #expect(!pod.canAddMember)

        // Attempting to add 9th member must return nil
        let ninth = PodMember(id: "m9", displayName: "Ninth")
        #expect(pod.addingMember(ninth) == nil)
    }

    @Test("AccountabilityPod rejects duplicate member")
    func podRejectsDuplicateMember() {
        let member = PodMember(id: "user-1", displayName: "Alex")
        let pod = AccountabilityPod(
            name: "Duo",
            creatorID: "user-1",
            members: [member],
            weeklyGoal: PodWeeklyGoal(targetWorkouts: 8, weekStartDate: Date()),
            inviteCode: "XYZ123"
        )

        let duplicate = PodMember(id: "user-1", displayName: "Alex Duplicate")
        #expect(pod.addingMember(duplicate) == nil)
    }

    @Test("AccountabilityPod computes total completed workouts across members")
    func podComputesTotalWorkouts() {
        let m1 = PodMember(id: "1", displayName: "A", weeklyWorkoutsCompleted: 3)
        let m2 = PodMember(id: "2", displayName: "B", weeklyWorkoutsCompleted: 4)
        let pod = AccountabilityPod(
            name: "Duo",
            creatorID: "1",
            members: [m1, m2],
            weeklyGoal: PodWeeklyGoal(targetWorkouts: 10, weekStartDate: Date()),
            inviteCode: "CODE01"
        )

        #expect(pod.totalWorkoutsCompleted == 7)
    }

    // MARK: - GroupGoalEvaluator

    @Test("GroupGoalEvaluator transitions through milestones correctly")
    func groupGoalEvaluatorMilestones() {
        var m1 = PodMember(id: "1", displayName: "A", weeklyWorkoutsCompleted: 2)
        var pod = AccountabilityPod(
            name: "Pod",
            creatorID: "1",
            members: [m1],
            weeklyGoal: PodWeeklyGoal(targetWorkouts: 10, weekStartDate: Date()),
            inviteCode: "GOAL01"
        )

        // 2/10 = 20% -> .started
        var progress = GroupGoalEvaluator.evaluate(pod: pod)
        #expect(progress.milestone == .started)
        #expect(!progress.isCompleted)
        #expect(progress.remainingNeeded == 8)

        // 5/10 = 50% -> .halfway
        m1.weeklyWorkoutsCompleted = 5
        pod = pod.updatingMemberProgress(memberID: "1", weeklyCompleted: 5, streakDays: 2)
        progress = GroupGoalEvaluator.evaluate(pod: pod)
        #expect(progress.milestone == .halfway)
        #expect(progress.fractionComplete == 0.5)

        // 8/10 = 80% -> .almostThere
        pod = pod.updatingMemberProgress(memberID: "1", weeklyCompleted: 8, streakDays: 3)
        progress = GroupGoalEvaluator.evaluate(pod: pod)
        #expect(progress.milestone == .almostThere)

        // 10/10 = 100% -> .goalCrushed
        pod = pod.updatingMemberProgress(memberID: "1", weeklyCompleted: 10, streakDays: 4)
        progress = GroupGoalEvaluator.evaluate(pod: pod)
        #expect(progress.milestone == .goalCrushed)
        #expect(progress.isCompleted)
        #expect(progress.remainingNeeded == 0)
    }

    // MARK: - EncouragementRateLimiter

    @Test("EncouragementRateLimiter enforces 3 nudges per day limit")
    func rateLimiterEnforcesDailyLimit() {
        let now = Date()
        let podID = "pod-1"
        let senderID = "user-1"

        var nudges: [PodEncouragement] = [
            PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .crushedIt, dateCreated: now.addingTimeInterval(-1000)),
            PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .showedUp, dateCreated: now.addingTimeInterval(-500))
        ]

        #expect(EncouragementRateLimiter.canSendNudge(senderID: senderID, podID: podID, existingEncouragements: nudges, now: now))
        #expect(EncouragementRateLimiter.remainingNudges(senderID: senderID, podID: podID, existingEncouragements: nudges, now: now) == 1)

        // Add 3rd nudge
        nudges.append(PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .restUp, dateCreated: now.addingTimeInterval(-100)))

        #expect(!EncouragementRateLimiter.canSendNudge(senderID: senderID, podID: podID, existingEncouragements: nudges, now: now))
        #expect(EncouragementRateLimiter.remainingNudges(senderID: senderID, podID: podID, existingEncouragements: nudges, now: now) == 0)

        // Nudges older than 24 hours do not count against budget
        let oldNudges: [PodEncouragement] = [
            PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .crushedIt, dateCreated: now.addingTimeInterval(-25 * 3600)),
            PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .showedUp, dateCreated: now.addingTimeInterval(-26 * 3600)),
            PodEncouragement(podID: podID, senderID: senderID, senderName: "User", nudgeType: .restUp, dateCreated: now.addingTimeInterval(-27 * 3600))
        ]
        #expect(EncouragementRateLimiter.canSendNudge(senderID: senderID, podID: podID, existingEncouragements: oldNudges, now: now))
    }

    // MARK: - AccountabilityPodService

    @Test("AccountabilityPodService creates, joins, nudges, and leaves pod")
    func podServiceLifecycle() async throws {
        let mock = MockCloudKitClient()
        let service = AccountabilityPodService(dataClient: mock)

        // 1. Create pod
        let created = try await service.createPod(
            name: "Dawn Patrol",
            creatorID: "creator-1",
            creatorDisplayName: "Alex",
            targetWorkouts: 12
        )
        #expect(created.name == "Dawn Patrol")
        #expect(created.members.count == 1)
        #expect(created.inviteCode.count == 6)

        // 2. Fetch by creator
        let fetched = await service.fetchUserPod(userID: "creator-1")
        #expect(fetched?.id == created.id)

        // 3. Join with code
        let joined = try await service.joinPod(
            inviteCode: created.inviteCode,
            memberID: "joiner-2",
            displayName: "Jordan"
        )
        #expect(joined.members.count == 2)

        // 4. Send nudge
        let nudge = try await service.sendNudge(
            podID: created.id,
            senderID: "joiner-2",
            senderName: "Jordan",
            nudgeType: .crushedIt
        )
        #expect(nudge.nudgeType == .crushedIt)

        let nudges = await service.fetchRecentNudges(podID: created.id)
        #expect(nudges.count == 1)

        // 5. Leave pod
        let afterLeave = try await service.leavePod(podID: created.id, memberID: "joiner-2")
        #expect(afterLeave?.members.count == 1)
        #expect(afterLeave?.members.first?.id == "creator-1")
    }
}

import Foundation
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class AccountabilityPodViewModel: ObservableObject {
    @Published public private(set) var pod: AccountabilityPod?
    @Published public private(set) var recentNudges: [PodEncouragement] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showingCreateJoinSheet: Bool = false
    @Published public var showingPodDetail: Bool = false

    private let podService: AccountabilityPodService

    public var goalProgress: PodGoalProgress? {
        guard let pod else { return nil }
        return GroupGoalEvaluator.evaluate(pod: pod)
    }

    public init(podService: AccountabilityPodService = AccountabilityPodService()) {
        self.podService = podService
    }

    // MARK: - Load

    public func load(userID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let fetchedPod = await podService.fetchUserPod(userID: userID)
        self.pod = fetchedPod

        if let fetchedPod {
            self.recentNudges = await podService.fetchRecentNudges(podID: fetchedPod.id)
        } else {
            self.recentNudges = []
        }
    }

    // MARK: - Actions

    public func createPod(
        name: String,
        targetWorkouts: Int,
        userID: String,
        displayName: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let created = try await podService.createPod(
                name: name,
                creatorID: userID,
                creatorDisplayName: displayName,
                targetWorkouts: targetWorkouts
            )
            self.pod = created
            HapticFeedback.success()
            return true
        } catch {
            errorMessage = "We couldn't create your pod. Check your connection and try again."
            HapticFeedback.warning()
            return false
        }
    }

    public func joinPod(
        inviteCode: String,
        userID: String,
        displayName: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let joined = try await podService.joinPod(
                inviteCode: inviteCode,
                memberID: userID,
                displayName: displayName
            )
            self.pod = joined
            self.recentNudges = await podService.fetchRecentNudges(podID: joined.id)
            HapticFeedback.success()
            return true
        } catch {
            errorMessage = "We couldn't join that pod. Check the code and your connection, then try again."
            HapticFeedback.warning()
            return false
        }
    }

    public func leavePod(userID: String) async {
        guard let pod else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let updated = try await podService.leavePod(podID: pod.id, memberID: userID)
            self.pod = updated
            self.recentNudges = []
            HapticFeedback.light()
        } catch {
            errorMessage = "We couldn't leave your pod. Check your connection and try again."
            HapticFeedback.warning()
        }
    }

    public func sendNudge(
        nudgeType: NudgeType,
        userID: String,
        displayName: String
    ) async -> Bool {
        guard let pod else { return false }

        do {
            let nudge = try await podService.sendNudge(
                podID: pod.id,
                senderID: userID,
                senderName: displayName,
                nudgeType: nudgeType
            )
            self.recentNudges.insert(nudge, at: 0)
            HapticFeedback.success()
            return true
        } catch {
            errorMessage = "We couldn't send that nudge. Check your connection and try again."
            HapticFeedback.warning()
            return false
        }
    }

    public func syncProgress(
        userID: String,
        displayName: String,
        workouts: [Workout],
        presenceRecords: [DailyPresenceRecord]
    ) async {
        guard let pod else { return }

        let snapshot = SocialSnapshotBuilder.build(
            userID: userID,
            displayName: displayName,
            workouts: workouts,
            presenceRecords: presenceRecords
        )

        if let updated = try? await podService.syncMemberProgress(
            podID: pod.id,
            memberID: userID,
            weeklyCompleted: snapshot.weeklyCompletedWorkouts,
            streakDays: snapshot.currentStreakDays
        ) {
            self.pod = updated
        }
    }
}

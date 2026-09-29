import SwiftUI

// MARK: - AccountabilityPodDetailSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct AccountabilityPodDetailSheet: View {
    @ObservedObject var viewModel: AccountabilityPodViewModel
    let userID: String
    let displayName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirm = false
    @State private var nudgeConfirmation: String?

    public init(
        viewModel: AccountabilityPodViewModel,
        userID: String,
        displayName: String
    ) {
        self.viewModel = viewModel
        self.userID = userID
        self.displayName = displayName
    }

    public var body: some View {
        NavigationStack {
            List {
                if let pod = viewModel.pod, let progress = viewModel.goalProgress {
                    goalSection(pod: pod, progress: progress)
                    membersSection(pod: pod)
                    nudgesActionSection(pod: pod)
                    if !viewModel.recentNudges.isEmpty {
                        recentNudgesSection
                    }
                    podInfoSection(pod: pod)
                } else {
                    Text("No active pod found.")
                        .foregroundStyle(AppTheme.Text.secondary)
                }
            }
            .navigationTitle(viewModel.pod?.name ?? "Pod Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Leave Pod?",
                isPresented: $showLeaveConfirm,
                titleVisibility: .visible
            ) {
                Button("Leave Pod", role: .destructive) {
                    Task {
                        await viewModel.leavePod(userID: userID)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to leave this accountability pod?")
            }
        }
    }

    // MARK: - Goal Section

    private func goalSection(pod: AccountabilityPod, progress: PodGoalProgress) -> some View {
        Section("Cooperative Weekly Goal") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("\(progress.totalCompleted) of \(progress.target) Workouts")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundStyle(AppTheme.Text.primary)

                    Spacer()

                    Text(progress.milestone.badgeTitle)
                        .font(AppTheme.Typography.labelMedium.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(progress.isCompleted ? AppTheme.Recovery.green.opacity(0.2) : AppTheme.Accent.orange.opacity(0.15))
                        .foregroundStyle(progress.isCompleted ? AppTheme.Recovery.green : AppTheme.Accent.orange)
                        .clipShape(Capsule())
                }

                ProgressView(value: progress.fractionComplete)
                    .tint(progress.isCompleted ? AppTheme.Recovery.green : AppTheme.Accent.orange)

                Text(progress.headline)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundStyle(AppTheme.Text.secondary)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
    }

    // MARK: - Members Section

    private func membersSection(pod: AccountabilityPod) -> some View {
        Section("Members (\(pod.members.count)/\(AccountabilityPod.maxMembers))") {
            ForEach(pod.members) { member in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(String(member.displayName.prefix(1)))
                        .font(AppTheme.Typography.labelMedium.bold())
                        .frame(width: 32, height: 32)
                        .background(AppTheme.Background.navy)
                        .foregroundStyle(AppTheme.Text.cream)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(member.displayName)
                                .font(AppTheme.Typography.headlineSmall)
                                .foregroundStyle(AppTheme.Text.primary)
                            if member.id == userID {
                                Text("(You)")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundStyle(AppTheme.Text.secondary)
                            }
                        }

                        Text("\(member.weeklyWorkoutsCompleted) workouts this week")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundStyle(AppTheme.Text.secondary)
                    }

                    Spacer()

                    if member.currentStreakDays > 0 {
                        HStack(spacing: 2) {
                            Text("\(member.currentStreakDays)")
                                .font(AppTheme.Typography.labelMedium.bold())
                            Text("🔥")
                        }
                        .foregroundStyle(AppTheme.Accent.orange)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Nudges Section

    private func nudgesActionSection(pod: AccountabilityPod) -> some View {
        let remaining = EncouragementRateLimiter.remainingNudges(
            senderID: userID,
            podID: pod.id,
            existingEncouragements: viewModel.recentNudges
        )

        return Section("Encourage the Pod (\(remaining)/\(EncouragementRateLimiter.maxNudgesPerDay) remaining)") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(NudgeType.allCases, id: \.self) { nudge in
                            Button {
                                Task {
                                    let success = await viewModel.sendNudge(
                                        nudgeType: nudge,
                                        userID: userID,
                                        displayName: displayName
                                    )
                                    if success {
                                        nudgeConfirmation = "Sent: \(nudge.displayText)"
                                    }
                                }
                            } label: {
                                Text(nudge.displayText)
                                    .font(AppTheme.Typography.bodySmall.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.Background.navy.opacity(0.08))
                                    .foregroundStyle(AppTheme.Text.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(remaining == 0)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let confirmation = nudgeConfirmation {
                    Text(confirmation)
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundStyle(AppTheme.Semantic.success)
                }
            }
        }
    }

    // MARK: - Recent Nudges Section

    private var recentNudgesSection: some View {
        Section("Recent Activity") {
            ForEach(viewModel.recentNudges.prefix(5)) { nudge in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(nudge.nudgeType.emoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(nudge.senderName): \(nudge.nudgeType.title)")
                            .font(AppTheme.Typography.bodyMedium.bold())
                            .foregroundStyle(AppTheme.Text.primary)

                        Text(nudge.dateCreated.formatted(.relative(presentation: .numeric)))
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundStyle(AppTheme.Text.secondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Pod Info & Actions

    private func podInfoSection(pod: AccountabilityPod) -> some View {
        Section("Invite & Settings") {
            HStack {
                Text("Invite Code")
                    .font(AppTheme.Typography.bodyMedium)
                Spacer()
                Text(pod.inviteCode)
                    .font(AppTheme.Typography.monoMedium.bold())
                    .foregroundStyle(AppTheme.Accent.orange)
            }

            ShareLink(
                item: "Join my Sundee Fundee workout pod with code: \(pod.inviteCode)",
                subject: Text("Workout Pod Invite"),
                message: Text("Join our accountability pod in Sundee Fundee!")
            ) {
                Label("Share Invite Code", systemImage: "square.and.arrow.up")
                    .foregroundStyle(AppTheme.Accent.orange)
            }

            Button(role: .destructive) {
                showLeaveConfirm = true
            } label: {
                Label("Leave Pod", systemImage: "arrow.right.square")
            }
        }
    }
}

import SwiftUI

// MARK: - AccountabilityPodCard
//
// Card on Today tab displaying active accountability pod progress or prompt to join.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct AccountabilityPodCard: View {
    @ObservedObject var viewModel: AccountabilityPodViewModel
    let userID: String
    let displayName: String

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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            headerRow

            if let pod = viewModel.pod, let progress = viewModel.goalProgress {
                podProgressContent(pod: pod, progress: progress)
            } else {
                emptyPodContent
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Background.card)
        .cornerRadius(AppTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(AppTheme.Accent.gold.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.Accent.orange)

            Text(viewModel.pod?.name ?? "Accountability Pod")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundStyle(AppTheme.Text.primary)

            Spacer()

            if let progress = viewModel.goalProgress {
                Text(progress.milestone.badgeEmoji)
                    .font(.body)
            }
        }
    }

    // MARK: - Active Pod Content

    private func podProgressContent(pod: AccountabilityPod, progress: PodGoalProgress) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(progress.totalCompleted)")
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundStyle(AppTheme.Accent.orange)
                Text("/ \(progress.target) workouts")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundStyle(AppTheme.Text.secondary)

                Spacer()

                Text("\(Int(progress.fractionComplete * 100))%")
                    .font(AppTheme.Typography.labelMedium.bold())
                    .foregroundStyle(AppTheme.Accent.gold)
            }

            ProgressView(value: progress.fractionComplete)
                .tint(progress.isCompleted ? AppTheme.Recovery.green : AppTheme.Accent.orange)

            Text(progress.headline)
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(AppTheme.Text.secondary)

            // Member avatar bubbles
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(pod.members) { member in
                    HStack(spacing: 3) {
                        Text(String(member.displayName.prefix(1)))
                            .font(AppTheme.Typography.labelMedium.bold())
                            .frame(width: 24, height: 24)
                            .background(AppTheme.Background.navy)
                            .foregroundStyle(AppTheme.Text.cream)
                            .clipShape(Circle())

                        if member.currentStreakDays > 0 {
                            Text("\(member.currentStreakDays)🔥")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundStyle(AppTheme.Accent.orange)
                        }
                    }
                    .padding(.trailing, 4)
                }

                Spacer()

                Button {
                    viewModel.showingPodDetail = true
                } label: {
                    Text("Pod Details")
                        .font(AppTheme.Typography.labelMedium.bold())
                        .foregroundStyle(AppTheme.Accent.orange)
                }
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
        .sheet(isPresented: $viewModel.showingPodDetail) {
            AccountabilityPodDetailSheet(viewModel: viewModel, userID: userID, displayName: displayName)
        }
    }

    // MARK: - Empty Pod Content

    private var emptyPodContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Pair with a workout buddy or micro-pod (up to 8 members). 100% private CloudKit sharing with zero algorithmic noise.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(AppTheme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.showingCreateJoinSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create or Join Pod")
                }
                .font(AppTheme.Typography.bodyMedium.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Accent.orange)
            .padding(.top, AppTheme.Spacing.xs)
        }
        .sheet(isPresented: $viewModel.showingCreateJoinSheet) {
            CreateOrJoinPodSheet(viewModel: viewModel, userID: userID, displayName: displayName)
        }
    }
}

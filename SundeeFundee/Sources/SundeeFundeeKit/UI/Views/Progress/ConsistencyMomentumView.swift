import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ConsistencyMomentumView: View {
    @Environment(\.dismiss) private var dismiss

    private let summary: ConsistencyMomentumSummary

    public init(summary: ConsistencyMomentumSummary) {
        self.summary = summary
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            Text(summary.supportiveHeadline)
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundStyle(AppTheme.Text.primary)

                            weeklyBars

                            HStack(spacing: AppTheme.Spacing.md) {
                                total(
                                    value: totalCheckIns,
                                    label: "Check-ins",
                                    systemImage: "checkmark.bubble"
                                )
                                total(
                                    value: totalActionDays,
                                    label: "Action days",
                                    systemImage: "figure.strengthtraining.traditional"
                                )
                            }
                        }
                    }

                    if !summary.achievements.isEmpty {
                        achievementsSection
                    }

                    Text("Every week can look different. Opening Today, checking in, resting, and training all support your momentum.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Background.cream.ignoresSafeArea())
            .navigationTitle("4-Week Momentum")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var weeklyBars: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.md) {
            ForEach(Array(summary.rollingWeeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: AppTheme.Spacing.sm) {
                    GeometryReader { geometry in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(AppTheme.Accent.gold)
                                .frame(
                                    height: week.daysPresent == 0
                                        ? 0
                                        : max(
                                            AppTheme.Spacing.xs,
                                            geometry.size.height
                                                * min(Double(week.daysPresent) / 7.0, 1)
                                        )
                                )
                        }
                    }

                    Text(weekLabel(for: week.weekStart))
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundStyle(AppTheme.Text.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Week of \(accessibleWeekLabel(for: week.weekStart))")
                .accessibilityValue("\(week.daysPresent) of 7 days present")
            }
        }
        .frame(height: 180)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Background.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .accessibilityLabel("Four-week presence chart")
    }

    private var achievementsSection: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Label {
                    Text("Achievements")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundStyle(AppTheme.Text.primary)
                } icon: {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Accent.gold)
                }

                ForEach(earnedAchievements, id: \.self) { achievement in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                        Image(systemName: achievement.systemImage)
                            .font(.title3)
                            .foregroundStyle(AppTheme.Accent.gold)
                            .frame(width: AppTheme.Spacing.xl)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(achievement.title)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundStyle(AppTheme.Text.primary)

                            Text(achievement.supportiveDescription)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundStyle(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var earnedAchievements: [ConsistencyAchievement] {
        ConsistencyAchievement.allCases.filter(summary.achievements.contains)
    }

    private func total(value: Int, label: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppTheme.Accent.gold)
                .accessibilityHidden(true)

            Text("\(value)")
                .font(AppTheme.Typography.monoLarge)
                .foregroundStyle(AppTheme.Text.primary)

            Text(label)
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    private var totalCheckIns: Int {
        summary.rollingWeeks.reduce(0) { $0 + $1.checkInDays }
    }

    private var totalActionDays: Int {
        summary.rollingWeeks.reduce(0) { $0 + $1.actionDays }
    }

    private func weekLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func accessibleWeekLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day().year())
    }
}

extension ConsistencyAchievement {
    var title: String {
        switch self {
        case .firstConsistentWeek: "A steady week"
        case .welcomeBack: "Welcome back"
        case .plannedWorkoutCompleted: "Workout complete"
        case .recoveryChoice: "Recovery supported"
        }
    }

    var supportiveDescription: String {
        switch self {
        case .firstConsistentWeek:
            "You showed up on three days in one week."
        case .welcomeBack:
            "You returned after time away. That counts."
        case .plannedWorkoutCompleted:
            "You followed through on a planned workout."
        case .recoveryChoice:
            "You made space for intentional recovery."
        }
    }

    var systemImage: String {
        switch self {
        case .firstConsistentWeek: "calendar.badge.checkmark"
        case .welcomeBack: "heart.circle.fill"
        case .plannedWorkoutCompleted: "checkmark.seal.fill"
        case .recoveryChoice: "leaf.circle.fill"
        }
    }
}

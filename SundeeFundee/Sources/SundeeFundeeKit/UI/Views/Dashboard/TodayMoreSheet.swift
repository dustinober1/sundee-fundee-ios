import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TodayMoreSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sections: [TodaySecondarySection]
    @ObservedObject var viewModel: DashboardViewModel
    let onStartWorkout: () -> Void
    let onStartQuickWorkout: () -> Void
    let onOpenCoachPlan: () -> Void
    let onOpenQuickCheckIn: () -> Void
    let onOpenLogMax: () -> Void
    let onOpenPainLog: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Starts") {
                    Button("Start Workout", action: onStartWorkout)
                    Button("Best Next 20 Min", action: onStartQuickWorkout)
                    Button("Build Coach Plan", action: onOpenCoachPlan)
                    Button("Quick Check-In", action: onOpenQuickCheckIn)
                    Button("Log Max", action: onOpenLogMax)
                    Button("Pain Log", action: onOpenPainLog)
                }

                if sections.isEmpty {
                    Section {
                        Text("Nothing else needs your attention today.")
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }

                ForEach(sections, id: \.self) { section in
                    sectionContent(section)
                }
            }
            .navigationTitle("More Today")
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

    @ViewBuilder
    private func sectionContent(_ section: TodaySecondarySection) -> some View {
        switch section {
        case .weeklyPlan:
            Section("This Week") {
                if let progress = viewModel.weeklyPlanProgress {
                    Text(progress.displayText)
                    Button("Start This Workout", action: onStartWorkout)
                }
            }
        case .missedWorkoutPlan:
            Section("Schedule") {
                if let plan = viewModel.missedWorkoutRecoveryPlan {
                    Text(plan.userSummary)
                    Button(plan.actionTitle) {
                        Task { await viewModel.applyMissedWorkoutRecovery() }
                    }
                }
            }
        case .firstWeekChecklist:
            Section("First Week") {
                ForEach(viewModel.firstWeekChecklist) { item in
                    Text(item.isComplete ? "\(item.title): Done" : "\(item.title): \(item.actionTitle)")
                }
            }
        case .activeChallenge:
            Section("Challenge") {
                if let data = viewModel.activeChallengeData {
                    Text(data.0.title)
                    Text(data.1.currentTierName)
                }
            }
        case .coachInsights:
            Section("Coach") {
                if let summary = viewModel.insightsSummary {
                    Text(summary)
                }
                ForEach(viewModel.insightsActions.prefix(2), id: \.self) { action in
                    Text(action)
                }
            }
        case .recentWins:
            Section("Recent Wins") {
                ForEach(viewModel.recentWins.prefix(3), id: \.self) { win in
                    Text(win)
                }
            }
        }
    }
}

import AppIntents
import Foundation
import SwiftUI

// MARK: - TodayWorkoutSummaryIntent
//
// Siri / Shortcuts intent summarizing today's workout, active session, or training recommendation.

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public struct TodayWorkoutSummaryIntent: AppIntent {
    public static let title: LocalizedStringResource = "Today's Workout Summary"
    public static let description = IntentDescription("Summarizes today's workout plan or active training session in Sundee Fundee.")
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // 1. Check if there's an ongoing active workout
        if let activeState = SharedSnapshotStore.readActiveWorkoutState(), activeState.status != .completed {
            let workoutName = activeState.current?.exerciseName ?? "Active Workout"
            let progress = "\(activeState.progress.completedSets) of \(activeState.progress.totalSets) sets"
            let dialog = "You have an active workout in progress: \(workoutName). \(progress) completed."
            return .result(
                dialog: IntentDialog(stringLiteral: dialog),
                view: WorkoutSummarySnippetView(
                    headline: "Active Session",
                    title: workoutName,
                    detail: "\(progress) completed",
                    statusIcon: "flame.fill",
                    statusColor: AppTheme.Accent.orange
                )
            )
        }

        // 2. Check today's logged workouts
        let client = DataClientFactory.shared.client
        let calendar = Calendar.current
        var workouts: [Workout] = []
        do {
            workouts = try await client.fetchAll(recordType: "Workout")
        } catch {
            // CloudKit error or local fallback
        }

        let todayWorkouts = workouts.filter { calendar.isDateInToday($0.date) }

        if let completedWorkout = todayWorkouts.first(where: { $0.completedAt != nil }) {
            let dialog = "You've already finished today's workout: \(completedWorkout.name)! Great work keeping up your momentum."
            return .result(
                dialog: IntentDialog(stringLiteral: dialog),
                view: WorkoutSummarySnippetView(
                    headline: "Completed Today",
                    title: completedWorkout.name,
                    detail: "\(completedWorkout.exercises.count) exercises completed",
                    statusIcon: "checkmark.circle.fill",
                    statusColor: AppTheme.Semantic.success
                )
            )
        }

        if let pendingWorkout = todayWorkouts.first(where: { $0.completedAt == nil }) {
            let exerciseNames = pendingWorkout.exercises.prefix(3).map(\.name).joined(separator: ", ")
            let moreText = pendingWorkout.exercises.count > 3 ? " and \(pendingWorkout.exercises.count - 3) more" : ""
            let dialog = "Today's scheduled session is \(pendingWorkout.name) with \(pendingWorkout.exercises.count) exercises: \(exerciseNames)\(moreText)."
            return .result(
                dialog: IntentDialog(stringLiteral: dialog),
                view: WorkoutSummarySnippetView(
                    headline: "Scheduled Today",
                    title: pendingWorkout.name,
                    detail: "\(pendingWorkout.exercises.count) exercises: \(exerciseNames)\(moreText)",
                    statusIcon: "figure.strengthtraining.traditional",
                    statusColor: AppTheme.Accent.orange
                )
            )
        }

        // 3. Fallback to daily readiness advice
        let readiness = SharedSnapshotStore.readReadiness()
        if let readiness {
            let advice: String
            switch readiness.stateRaw {
            case "primed":
                advice = "No workout logged yet today. With your readiness at \(readiness.totalScore) (Primed), today is ideal for heavy compounds or volume!"
            case "recovering":
                advice = "No workout logged yet today. Your readiness is at \(readiness.totalScore) (Recovering), so active recovery or a rest day is advised."
            default:
                advice = "No workout logged yet today. Your readiness is at \(readiness.totalScore). Open Sundee Fundee to select your session."
            }
            return .result(
                dialog: IntentDialog(stringLiteral: advice),
                view: WorkoutSummarySnippetView(
                    headline: "Readiness Guidance",
                    title: "Score \(readiness.totalScore) • \(readiness.stateRaw.capitalized)",
                    detail: advice,
                    statusIcon: "bolt.heart.fill",
                    statusColor: AppTheme.recoveryColor(for: readiness.totalScore)
                )
            )
        }

        let fallbackMessage = "No workout scheduled yet today. Open Sundee Fundee to pick today's session."
        return .result(
            dialog: IntentDialog(stringLiteral: fallbackMessage),
            view: WorkoutSummarySnippetView(
                headline: "Today in Sundee Fundee",
                title: "Ready to Train",
                detail: fallbackMessage,
                statusIcon: "figure.run",
                statusColor: AppTheme.Accent.orange
            )
        )
    }
}

// MARK: - Snippet View

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
private struct WorkoutSummarySnippetView: View {
    let headline: String
    let title: String
    let detail: String
    let statusIcon: String
    let statusColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(headline, systemImage: statusIcon)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundStyle(statusColor)
                Spacer()
            }

            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundStyle(AppTheme.Text.primary)

            Text(detail)
                .font(AppTheme.Typography.bodySmall)
                .foregroundStyle(AppTheme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}

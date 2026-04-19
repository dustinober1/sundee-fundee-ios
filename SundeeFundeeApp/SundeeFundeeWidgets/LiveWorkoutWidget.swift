import ActivityKit
import SwiftUI
import WidgetKit
import SundeeFundeeKit

@main
struct SundeeFundeeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LiveWorkoutWidget()
        RecoveryScoreWidget()
        CyclePhaseWidget()
    }
}

struct LiveWorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveWorkoutActivityAttributes.self) { context in
            LiveWorkoutLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.current?.exerciseName ?? context.attributes.workoutName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.current?.setDisplayText ?? progressText(context.state.progress))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(elapsedText(context.state.elapsedSeconds))
                            .font(.headline.monospacedDigit())
                        if let rest = context.state.rest {
                            Text("Rest \(rest.remainingSeconds)s")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(progressText(context.state.progress))
                            .font(.caption)
                        if let nextUp = context.state.nextUp {
                            Text("Next: \(nextUp.exerciseName) • \(nextUp.prescribedRepsText)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            } compactLeading: {
                Text(String(context.state.current?.exerciseName.prefix(1) ?? context.attributes.workoutName.prefix(1)))
                    .font(.headline)
            } compactTrailing: {
                Text(elapsedText(context.state.elapsedSeconds))
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: iconName(for: context.state.status))
            }
        }
    }

    private func progressText(_ progress: LiveWorkoutActivityAttributes.ProgressSummary) -> String {
        "\(progress.completedSets)/\(progress.totalSets) sets"
    }

    private func elapsedText(_ elapsedSeconds: Int) -> String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func iconName(for status: LiveWorkoutActivityAttributes.Status) -> String {
        switch status {
        case .active:
            return "figure.strengthtraining.traditional"
        case .resting:
            return "timer"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

private struct LiveWorkoutLockScreenView: View {
    let attributes: LiveWorkoutActivityAttributes
    let state: LiveWorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(attributes.workoutName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(elapsedText(state.elapsedSeconds))
                    .font(.headline.monospacedDigit())
            }

            Text(state.current?.exerciseName ?? fallbackHeadline)
                .font(.title3.weight(.semibold))
                .lineLimit(1)

            HStack(spacing: 12) {
                Text(state.current?.setDisplayText ?? progressText(state.progress))
                if let current = state.current {
                    Text("\(current.prescribedRepsText) @ \(Int(current.prescribedWeight))")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let rest = state.rest {
                Text("Rest \(rest.remainingSeconds)s remaining")
                    .font(.subheadline.weight(.medium))
            } else if let nextUp = state.nextUp {
                Text("Next: \(nextUp.exerciseName) • \(nextUp.prescribedRepsText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            ProgressView(value: state.progress.fractionComplete)
        }
        .padding()
    }

    private var fallbackHeadline: String {
        switch state.status {
        case .active, .resting:
            return attributes.workoutName
        case .completed:
            return "Workout Complete"
        }
    }

    private func progressText(_ progress: LiveWorkoutActivityAttributes.ProgressSummary) -> String {
        "\(progress.completedSets)/\(progress.totalSets) sets"
    }

    private func elapsedText(_ elapsedSeconds: Int) -> String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

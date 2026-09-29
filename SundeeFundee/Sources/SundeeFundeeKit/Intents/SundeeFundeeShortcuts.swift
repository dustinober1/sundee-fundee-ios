import AppIntents

// MARK: - SundeeFundeeShortcuts
//
// Auto-registered at launch so Siri and the Shortcuts app surface these
// phrases without the user having to add them manually.

@available(iOS 18.0, *)
public struct SundeeFundeeShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWorkoutSetIntent(),
            phrases: [
                "Log a set in \(.applicationName)",
                "Quick log in \(.applicationName)"
            ],
            shortTitle: "Log a set",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start my workout in \(.applicationName)",
                "Open \(.applicationName) workouts"
            ],
            shortTitle: "Start workout",
            systemImageName: "figure.strengthtraining.traditional"
        )

        AppShortcut(
            intent: CheckReadinessIntent(),
            phrases: [
                "Check my readiness in \(.applicationName)",
                "What's my readiness in \(.applicationName)",
                "What's my recovery in \(.applicationName)",
                "Check recovery in \(.applicationName)"
            ],
            shortTitle: "Check readiness",
            systemImageName: "bolt.heart.fill"
        )

        AppShortcut(
            intent: TodayWorkoutSummaryIntent(),
            phrases: [
                "What's my workout today in \(.applicationName)",
                "Today's workout in \(.applicationName)",
                "What am I lifting today in \(.applicationName)"
            ],
            shortTitle: "Today's workout",
            systemImageName: "figure.run"
        )

        AppShortcut(
            intent: LogDailyStatusIntent(),
            phrases: [
                "Log daily status in \(.applicationName)",
                "Check in for today in \(.applicationName)"
            ],
            shortTitle: "Log daily status",
            systemImageName: "checkmark.circle"
        )
    }
}

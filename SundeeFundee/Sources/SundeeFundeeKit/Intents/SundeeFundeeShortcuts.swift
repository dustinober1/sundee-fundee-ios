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
    }
}

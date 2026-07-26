#if canImport(UserNotifications)
import SwiftUI
import UserNotifications

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutRemindersSettingsView: View {
    @State private var settings = WorkoutReminderSettings()
    @State private var permissionGranted = false
    @State private var pendingCount = 0
    @State private var errorMessage: String?
    @State private var weeklyTarget = 3
    @State private var selectedWeekdays: Set<Int> = [2, 4, 6]
    @State private var cycleAwarePlanningEnabled = false
    private let service: ReminderService
    private let updateCoordinator: ReminderSettingsUpdateCoordinator
    private let weeklyPlanService = WeeklyPlanService()

    public init() {
        let service = ReminderService()
        self.service = service
        self.updateCoordinator = ReminderSettingsUpdateCoordinator(boundary: service)
    }

    public var body: some View {
        Form {
            Section {
                Button {
                    let previousSettings = settings
                    settings.isEnabled.toggle()
                    Task { await saveAndReconcile(previousSettings: previousSettings) }
                } label: {
                    HStack {
                        Text(settings.isEnabled ? "Disable reminders" : "Enable reminders")
                            .foregroundColor(AppTheme.Text.primary)
                        Spacer()
                        Text(settings.isEnabled ? "On" : "Off")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(settings.isEnabled ? "Disable reminders" : "Enable reminders")

                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!settings.isEnabled)

                Text("\(pendingCount) reminder\(pendingCount == 1 ? "" : "s") scheduled")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            } header: {
                Text("Workout Reminders")
            } footer: {
                Text("Permission is requested only when you enable reminders.")
            }

            Section {
                Toggle("Daily plan", isOn: dailyPlanEnabledBinding)

                DatePicker(
                    "Daily plan time",
                    selection: dailyPlanTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!settings.dailyPlanEnabled)
            } header: {
                Text("Daily Plan")
            } footer: {
                Text("A private reminder to open today’s plan. Notification details do not include health information.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(AppTheme.Semantic.warning)
                }
            }

            Section("Weekly Plan Preferences") {
                Stepper("Target workouts: \(weeklyTarget)", value: $weeklyTarget, in: 1...6)

                ForEach(weekdayOptions, id: \.weekday) { option in
                    Toggle(option.label, isOn: Binding(
                        get: { selectedWeekdays.contains(option.weekday) },
                        set: { isSelected in
                            if isSelected {
                                selectedWeekdays.insert(option.weekday)
                            } else {
                                selectedWeekdays.remove(option.weekday)
                            }
                        }
                    ))
                }

                Toggle("Use cycle-aware planning", isOn: $cycleAwarePlanningEnabled)

                Button("Save Weekly Plan Preferences") {
                    Task { await saveWeeklyPlanPreferences() }
                }
            }
        }
        .navigationTitle("Workout Reminders")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            settings = await service.loadSettings()
            await refreshPendingCount()
            await loadWeeklyPlanPreferences()
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding {
            var components = DateComponents()
            components.hour = settings.hour
            components.minute = settings.minute
            return Calendar.current.date(from: components) ?? Date()
        } set: { date in
            let previousSettings = settings
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            settings.hour = components.hour ?? 9
            settings.minute = components.minute ?? 0
            Task { await saveAndReconcile(previousSettings: previousSettings) }
        }
    }

    private var dailyPlanEnabledBinding: Binding<Bool> {
        Binding {
            settings.dailyPlanEnabled
        } set: { isEnabled in
            let previousSettings = settings
            settings.dailyPlanEnabled = isEnabled
            Task { await saveAndReconcile(previousSettings: previousSettings) }
        }
    }

    private var dailyPlanTimeBinding: Binding<Date> {
        Binding {
            var components = DateComponents()
            components.hour = settings.dailyPlanHour
            components.minute = settings.dailyPlanMinute
            return Calendar.current.date(from: components) ?? Date()
        } set: { date in
            let previousSettings = settings
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            settings.dailyPlanHour = components.hour ?? 8
            settings.dailyPlanMinute = components.minute ?? 0
            Task { await saveAndReconcile(previousSettings: previousSettings) }
        }
    }

    private func saveAndReconcile(previousSettings: WorkoutReminderSettings) async {
        errorMessage = nil
        let requiresAuthorization = ReminderService.requiresAuthorization(
            from: previousSettings,
            to: settings
        )
        if requiresAuthorization {
            do {
                permissionGranted = try await service.requestAuthorization()
            } catch {
                restoreEnabledSettings(from: previousSettings)
                errorMessage = "Could not check notification access. Please try again."
                return
            }
            guard permissionGranted else {
                let enabledDailyPlan = !previousSettings.dailyPlanEnabled && settings.dailyPlanEnabled
                restoreEnabledSettings(from: previousSettings)
                errorMessage = enabledDailyPlan
                    ? "Notifications are off. You can still use your daily plan, or enable reminders in Settings."
                    : "Notifications are disabled. Enable them in Settings to schedule workout reminders."
                return
            }
        }

        settings.dateUpdated = Date()
        let result = await updateCoordinator.apply(
            updated: settings,
            previous: previousSettings
        )
        settings = result.settings
        errorMessage = result.errorMessage
        await refreshPendingCount()
    }

    private func restoreEnabledSettings(from previousSettings: WorkoutReminderSettings) {
        settings.isEnabled = previousSettings.isEnabled
        settings.dailyPlanEnabled = previousSettings.dailyPlanEnabled
    }

    private func refreshPendingCount() async {
        pendingCount = await service.pendingReminderCount()
    }

    private func loadWeeklyPlanPreferences() async {
        guard let plan = await weeklyPlanService.currentPlan() else { return }
        weeklyTarget = plan.targetWorkoutCount
        selectedWeekdays = Set(plan.preferredWeekdays)
        cycleAwarePlanningEnabled = plan.cycleAwarePlanningEnabled ?? false
    }

    private func saveWeeklyPlanPreferences() async {
        let weekdays = Array(selectedWeekdays).sorted()
        guard !weekdays.isEmpty else {
            errorMessage = "Select at least one preferred training day."
            return
        }

        var timeAvailability: [String: Int] = [:]
        for weekday in weekdays {
            timeAvailability[String(weekday)] = 45
        }

        do {
            _ = try await weeklyPlanService.createOrUpdateCurrentPlan(
                targetWorkoutCount: weeklyTarget,
                preferredWeekdays: weekdays,
                timeAvailableMinutesByWeekdayRaw: timeAvailability,
                cycleAwarePlanningEnabled: cycleAwarePlanningEnabled
            )
            errorMessage = nil
        } catch {
            errorMessage = "Could not save weekly planning preferences."
        }
    }

    private var weekdayOptions: [(weekday: Int, label: String)] {
        [
            (2, "Monday"),
            (3, "Tuesday"),
            (4, "Wednesday"),
            (5, "Thursday"),
            (6, "Friday"),
            (7, "Saturday"),
            (1, "Sunday"),
        ]
    }
}
#endif

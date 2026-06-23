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
    private let service = ReminderService()
    private let weeklyPlanService = WeeklyPlanService()

    public init() {}

    public var body: some View {
        Form {
            Section {
                Button {
                    settings.isEnabled.toggle()
                    Task { await saveAndReconcile() }
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
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            settings.hour = components.hour ?? 9
            settings.minute = components.minute ?? 0
            Task { await saveAndReconcile() }
        }
    }

    private func saveAndReconcile() async {
        errorMessage = nil
        do {
            if settings.isEnabled {
                permissionGranted = try await service.requestAuthorization()
                guard permissionGranted else {
                    settings.isEnabled = false
                    errorMessage = "Notifications are disabled. Enable them in Settings to schedule workout reminders."
                    return
                }
            }
            settings.dateUpdated = Date()
            try await service.saveSettings(settings)
            try await service.reconcileSchedule(settings: settings)
            await refreshPendingCount()
        } catch {
            errorMessage = "Could not update reminders right now."
        }
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

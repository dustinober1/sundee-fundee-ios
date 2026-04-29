#if canImport(UserNotifications)
import SwiftUI
import UserNotifications

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutRemindersSettingsView: View {
    @State private var settings = WorkoutReminderSettings()
    @State private var permissionGranted = false
    @State private var pendingCount = 0
    @State private var errorMessage: String?
    private let service = ReminderService()

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle("Enable reminders", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { _, _ in
                        Task { await saveAndReconcile() }
                    }

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
        }
        .navigationTitle("Workout Reminders")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            settings = await service.loadSettings()
            await refreshPendingCount()
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
}
#endif

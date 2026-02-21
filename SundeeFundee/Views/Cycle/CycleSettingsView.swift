import SwiftUI
import SwiftData

struct CycleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var allSettings: [CycleSettings]

    private var userId: String { users.first?.id ?? "" }

    private var settings: CycleSettings? {
        allSettings.first { $0.userId == userId }
    }

    // Local editable state
    @State private var cycleLength: Int = 28
    @State private var periodLength: Int = 5
    @State private var lutealLength: Int = 14
    @State private var notificationsEnabled: Bool = false
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                Stepper("Cycle length: \(cycleLength) days", value: $cycleLength, in: 21...45)
                Stepper("Period length: \(periodLength) days", value: $periodLength, in: 2...10)
                Stepper("Luteal phase: \(lutealLength) days", value: $lutealLength, in: 10...16)
            } header: {
                Text("Cycle Lengths")
            } footer: {
                Text("These averages are used to predict your cycle phases.")
                    .font(.caption)
            }

            Section("Notifications") {
                Toggle("Cycle reminders", isOn: $notificationsEnabled)
            }
        }
        .navigationTitle("Cycle Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSettings() }
        .onChange(of: cycleLength)          { saveSettings() }
        .onChange(of: periodLength)         { saveSettings() }
        .onChange(of: lutealLength)         { saveSettings() }
        .onChange(of: notificationsEnabled) { saveSettings() }
    }

    private func loadSettings() {
        guard !loaded else { return }
        if let s = settings {
            cycleLength = s.averageCycleLength
            periodLength = s.averagePeriodLength
            lutealLength = s.lutealPhaseLength
            notificationsEnabled = s.notificationsEnabled
        }
        loaded = true
    }

    private func saveSettings() {
        guard loaded else { return }
        if let s = settings {
            s.averageCycleLength = cycleLength
            s.averagePeriodLength = periodLength
            s.lutealPhaseLength = lutealLength
            s.notificationsEnabled = notificationsEnabled
        } else {
            let newSettings = CycleSettings(
                userId: userId,
                averageCycleLength: cycleLength,
                averagePeriodLength: periodLength,
                lutealPhaseLength: lutealLength,
                notificationsEnabled: notificationsEnabled
            )
            modelContext.insert(newSettings)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        CycleSettingsView()
            .modelContainer(for: [User.self, CycleSettings.self], inMemory: true)
    }
}

import SwiftUI
import SwiftData

struct CycleTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationViewModel.self) private var authViewModel
    @Query private var users: [User]
    @Query(sort: \PeriodLog.startDate, order: .reverse) private var periodLogs: [PeriodLog]
    @Query private var allSettings: [CycleSettings]

    @State private var showLogPeriod = false

    private var userId: String { authViewModel.currentUser?.id ?? users.first?.id ?? "" }

    private var userPeriodLogs: [PeriodLog] {
        periodLogs.filter { $0.userId == userId }
    }

    private var cycleSettings: CycleSettings? {
        allSettings.first { $0.userId == userId }
    }

    private var currentPhaseInfo: (phase: CyclePhase, day: Int)? {
        guard let lastLog = userPeriodLogs.first else { return nil }
        let settings = cycleSettings
        let result = CyclePhaseCalculator.currentPhase(
            lastPeriodStart: lastLog.startDate,
            cycleLength: settings?.averageCycleLength ?? 28,
            periodLength: settings?.averagePeriodLength ?? 5,
            lutealPhaseLength: settings?.lutealPhaseLength ?? 14
        )
        return (phase: result.phase, day: result.dayOfCycle)
    }

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                ScrollView {
                    VStack(spacing: 20) {
                        CycleHeaderLogo()
                            .padding(.top, 4)

                        if let info = currentPhaseInfo {
                            CyclePhaseCard(phase: info.phase, dayOfCycle: info.day)
                        } else {
                            NoPeriodDataCard()
                        }

                        Button {
                            showLogPeriod = true
                        } label: {
                            Label("Log Period", systemImage: "drop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal)

                        if !userPeriodLogs.isEmpty {
                            PeriodHistorySection(logs: Array(userPeriodLogs.prefix(6)))
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Cycle Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: CycleSettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showLogPeriod) {
                LogPeriodSheet(userId: userId, onSave: { log in
                    modelContext.insert(log)
                    try? modelContext.save()
                })
            }
        }
    }
}

// MARK: - Header Logo

private struct CycleHeaderLogo: View {

    var body: some View {
        Image("SharkWeekLogo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .accessibilityLabel("Shark Week")
    }
}

// MARK: - Phase Card

private struct CyclePhaseCard: View {
    let phase: CyclePhase
    let dayOfCycle: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: CyclePhaseCalculator.phaseIcon(phase))
                    .font(.title2)
                Text(phase.rawValue.capitalized)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("Day \(dayOfCycle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(CyclePhaseCalculator.phaseDescription(phase))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - No Data Card

private struct NoPeriodDataCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.circle")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)
            Text("No cycle data yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Log your first period to start tracking your cycle phases.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Period History

private struct PeriodHistorySection: View {
    let logs: [PeriodLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period History")
                .font(.headline)
                .padding(.horizontal)

            ForEach(logs, id: \.id) { log in
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(Brand.danger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.startDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let end = log.endDate {
                            Text("Ended \(end, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(log.flowLevel.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Brand.danger.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Log Period Sheet

private struct LogPeriodSheet: View {
    let userId: String
    let onSave: (PeriodLog) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = .now
    @State private var endDate: Date = .now
    @State private var hasEndDate = false
    @State private var flowLevel: FlowLevel = .medium
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Period Start") {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section("Period End") {
                    Toggle("Period ended", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }

                Section("Flow Level") {
                    Picker("Flow", selection: $flowLevel) {
                        ForEach(FlowLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes (optional)") {
                    TextField("Any notes…", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Log Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = PeriodLog(
                            userId: userId,
                            startDate: startDate,
                            endDate: hasEndDate ? endDate : nil,
                            flowLevel: flowLevel,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSave(log)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CycleTrackerView()
        .modelContainer(for: [User.self, PeriodLog.self, CycleSettings.self], inMemory: true)
}


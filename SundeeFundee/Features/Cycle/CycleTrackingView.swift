import SwiftUI
import SwiftData

/// Cycle tracking — period log, symptom log, phase view, settings.
struct CycleTrackingView: View {
    @State private var viewModel = CycleTrackingViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                // Phase status header
                if let status = viewModel.cycleStatus {
                    PhaseStatusHeader(status: status)
                        .padding(AppTheme.Spacing.md)
                }

                // Segment picker
                Picker("Section", selection: $selectedTab) {
                    Text("Period Log").tag(0)
                    Text("Symptoms").tag(1)
                    Text("Settings").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.sm)

                // Content
                switch selectedTab {
                case 0:
                    PeriodLogSection(viewModel: viewModel)
                case 1:
                    SymptomLogSection(viewModel: viewModel)
                default:
                    CycleSettingsSection(viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Cycle")
        .toolbar {
            if selectedTab == 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.showAddPeriodLog = true } label: {
                        Image(systemName: "plus")
                    }
                }
            } else if selectedTab == 1 {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.showAddSymptomLog = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddPeriodLog) {
            AddPeriodLogSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showAddSymptomLog) {
            AddSymptomLogSheet(viewModel: viewModel)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - Phase Status Header

struct PhaseStatusHeader: View {
    let status: CycleStatusResult

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(phaseEmoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(status.currentPhase.displayName)
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(phaseColor)
                Text("Day \(status.cycleDay) • \(status.daysUntilNextPhase) days until next phase")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private var phaseEmoji: String {
        switch status.currentPhase {
        case .menstrual:  return "🩸"
        case .follicular: return "🌱"
        case .ovulation:  return "☀️"
        case .luteal:     return "🌙"
        }
    }

    private var phaseColor: Color {
        switch status.currentPhase {
        case .menstrual:  return Color(red: 0.75, green: 0.15, blue: 0.20)
        case .follicular: return Color(red: 0.20, green: 0.55, blue: 0.40)
        case .ovulation:  return AppTheme.Colors.accentOrange
        case .luteal:     return Color(red: 0.50, green: 0.35, blue: 0.65)
        }
    }
}

// MARK: - Period Log Section

struct PeriodLogSection: View {
    @Bindable var viewModel: CycleTrackingViewModel

    var body: some View {
        List {
            if viewModel.periodLogs.isEmpty {
                ContentUnavailableView(
                    "No Period Logs",
                    systemImage: "calendar",
                    description: Text("Tap + to log your period start date.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.periodLogs) { log in
                    PeriodLogRow(log: log)
                }
                .onDelete { idx in
                    viewModel.deletePeriodLogs(at: idx)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct PeriodLogRow: View {
    let log: PeriodLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.startDate, style: .date)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Spacer()
                Text(log.flowLevel.rawValue.capitalized)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
            if let endDate = log.endDate {
                Text("Ended \(endDate.formatted(.dateTime.month().day()))")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Symptom Log Section

struct SymptomLogSection: View {
    @Bindable var viewModel: CycleTrackingViewModel

    var body: some View {
        List {
            if viewModel.symptomLogs.isEmpty {
                ContentUnavailableView(
                    "No Symptoms Logged",
                    systemImage: "note.text",
                    description: Text("Track how you feel to improve training recommendations.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.symptomLogs) { log in
                    SymptomLogRow(log: log)
                }
                .onDelete { idx in
                    viewModel.deleteSymptomLogs(at: idx)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct SymptomLogRow: View {
    let log: SymptomLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.symptomID.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(log.date, style: .date)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            Spacer()
            SeverityDots(severity: log.severity)
        }
    }
}

struct SeverityDots: View {
    let severity: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= severity ? AppTheme.Colors.accentOrange : AppTheme.Colors.separator)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Cycle Settings Section

struct CycleSettingsSection: View {
    @Bindable var viewModel: CycleTrackingViewModel

    var body: some View {
        Form {
            Section("Cycle Length") {
                Stepper(
                    "Average: \(viewModel.avgCycleLength) days",
                    value: $viewModel.avgCycleLength,
                    in: 21...45
                )
                Stepper(
                    "Period length: \(viewModel.avgPeriodLength) days",
                    value: $viewModel.avgPeriodLength,
                    in: 2...10
                )
                Stepper(
                    "Luteal phase: \(viewModel.lutealPhaseLength) days",
                    value: $viewModel.lutealPhaseLength,
                    in: 10...18
                )
            }
            Section("Adaptation") {
                Toggle("Cycle-aware training", isOn: $viewModel.adaptationEnabled)
                    .tint(AppTheme.Colors.accentOrange)
            }
            Section {
                Button("Save Settings") {
                    Task { await viewModel.saveSettings() }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Add Period Log Sheet

struct AddPeriodLogSheet: View {
    @Bindable var viewModel: CycleTrackingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var endDate: Date? = nil
    @State private var flowLevel = FlowLevel.medium
    @State private var hasEndDate = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Period ended", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End Date", selection: Binding(
                        get: { endDate ?? startDate },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                }
                Picker("Flow Level", selection: $flowLevel) {
                    Text("Light").tag(FlowLevel.light)
                    Text("Medium").tag(FlowLevel.medium)
                    Text("Heavy").tag(FlowLevel.heavy)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Log Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addPeriodLog(
                            startDate: startDate,
                            endDate: hasEndDate ? endDate : nil,
                            flowLevel: flowLevel
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Symptom Log Sheet

struct AddSymptomLogSheet: View {
    @Bindable var viewModel: CycleTrackingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var symptomID = "fatigue"
    @State private var severity = 3
    @State private var date = Date()
    @State private var notes = ""

    private let symptoms = ["fatigue", "cramps", "bloating", "mood_changes", "headache",
                            "breast_tenderness", "back_pain", "nausea", "spotting"]

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Symptom", selection: $symptomID) {
                    ForEach(symptoms, id: \.self) { s in
                        Text(s.capitalized.replacingOccurrences(of: "_", with: " ")).tag(s)
                    }
                }
                Section("Severity (1–5)") {
                    Stepper("\(severity)", value: $severity, in: 1...5)
                }
                Section("Notes (optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addSymptomLog(
                            symptomID: symptomID,
                            severity: severity,
                            date: date,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

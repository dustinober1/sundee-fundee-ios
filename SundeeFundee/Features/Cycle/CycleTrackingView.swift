import SwiftUI
import SwiftData

/// Cycle tracking — period log, symptom log, phase view, settings.
struct CycleTrackingView: View {
    @State private var viewModel = CycleTrackingViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    
    enum SectionTab: Int {
        case periodLog = 0
        case symptoms = 1
        case settings = 2
    }
    
    static func sectionTab(for index: Int) -> SectionTab {
        SectionTab(rawValue: index) ?? .settings
    }
    
    @ViewBuilder
    static func sectionView(for index: Int, viewModel: CycleTrackingViewModel) -> some View {
        switch sectionTab(for: index) {
        case .periodLog:
            PeriodLogSection(viewModel: viewModel)
        case .symptoms:
            SymptomLogSection(viewModel: viewModel)
        case .settings:
            CycleSettingsSection(viewModel: viewModel)
        }
    }
    
    static func primaryAction(for index: Int, viewModel: CycleTrackingViewModel) -> (() -> Void)? {
        switch sectionTab(for: index) {
        case .periodLog:
            { viewModel.showAddPeriodLog = true }
        case .symptoms:
            { viewModel.showAddSymptomLog = true }
        case .settings:
            nil
        }
    }
    
    static func periodSheetContent(viewModel: CycleTrackingViewModel) -> () -> AddPeriodLogSheet {
        { AddPeriodLogSheet(viewModel: viewModel) }
    }
    
    static func symptomSheetContent(viewModel: CycleTrackingViewModel) -> () -> AddSymptomLogSheet {
        { AddSymptomLogSheet(viewModel: viewModel) }
    }

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
                Self.sectionView(for: selectedTab, viewModel: viewModel)
            }
        }
        .navigationTitle("Cycle")
        .toolbar {
            if let action = Self.primaryAction(for: selectedTab, viewModel: viewModel) {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: action) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddPeriodLog, content: Self.periodSheetContent(viewModel: viewModel))
        .sheet(isPresented: $viewModel.showAddSymptomLog, content: Self.symptomSheetContent(viewModel: viewModel))
        .onAppear {
            Task { @MainActor in
                await viewModel.load(modelContext: modelContext, userID: appState.currentUserID ?? "")
            }
        }
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
    
    static func deleteAction(viewModel: CycleTrackingViewModel) -> (IndexSet) -> Void {
        { idx in
            viewModel.deletePeriodLogs(at: idx)
        }
    }

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
                .onDelete(perform: Self.deleteAction(viewModel: viewModel))
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
    
    static func deleteAction(viewModel: CycleTrackingViewModel) -> (IndexSet) -> Void {
        { idx in
            viewModel.deleteSymptomLogs(at: idx)
        }
    }

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
                .onDelete(perform: Self.deleteAction(viewModel: viewModel))
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
    
    static func saveSettingsAction(viewModel: CycleTrackingViewModel) -> () -> Void {
        {
            Task { await viewModel.saveSettings() }
        }
    }

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
                Button("Save Settings", action: Self.saveSettingsAction(viewModel: viewModel))
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

    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var flowLevel: FlowLevel
    @State private var hasEndDate: Bool
    
    init(
        viewModel: CycleTrackingViewModel,
        startDate: Date = Date(),
        endDate: Date? = nil,
        flowLevel: FlowLevel = .medium,
        hasEndDate: Bool = false
    ) {
        self.viewModel = viewModel
        _startDate = State(initialValue: startDate)
        _endDate = State(initialValue: endDate)
        _flowLevel = State(initialValue: flowLevel)
        _hasEndDate = State(initialValue: hasEndDate)
    }
    
    static func endDateBinding(startDate: Date, endDate: Binding<Date?>) -> Binding<Date> {
        Binding(
            get: { endDate.wrappedValue ?? startDate },
            set: { endDate.wrappedValue = $0 }
        )
    }
    
    static func resolvedEndDate(hasEndDate: Bool, endDate: Date?) -> Date? {
        hasEndDate ? endDate : nil
    }
    
    static func saveAction(
        viewModel: CycleTrackingViewModel,
        startDate: Date,
        endDate: Date?,
        hasEndDate: Bool,
        flowLevel: FlowLevel,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            viewModel.addPeriodLog(
                startDate: startDate,
                endDate: Self.resolvedEndDate(hasEndDate: hasEndDate, endDate: endDate),
                flowLevel: flowLevel
            )
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Period ended", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker(
                        "End Date",
                        selection: Self.endDateBinding(startDate: startDate, endDate: $endDate),
                        displayedComponents: .date
                    )
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
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        startDate: startDate,
                        endDate: endDate,
                        hasEndDate: hasEndDate,
                        flowLevel: flowLevel,
                        dismiss: dismiss.callAsFunction
                    ))
                }
            }
        }
    }
}

// MARK: - Add Symptom Log Sheet

struct AddSymptomLogSheet: View {
    @Bindable var viewModel: CycleTrackingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var symptomID: String
    @State private var severity: Int
    @State private var date: Date
    @State private var notes: String

    private let symptoms: [String]
    
    static let defaultSymptoms = ["fatigue", "cramps", "bloating", "mood_changes", "headache",
                                  "breast_tenderness", "back_pain", "nausea", "spotting"]
    
    init(
        viewModel: CycleTrackingViewModel,
        symptomID: String = "fatigue",
        severity: Int = 3,
        date: Date = Date(),
        notes: String = "",
        symptoms: [String] = Self.defaultSymptoms
    ) {
        self.viewModel = viewModel
        _symptomID = State(initialValue: symptomID)
        _severity = State(initialValue: severity)
        _date = State(initialValue: date)
        _notes = State(initialValue: notes)
        self.symptoms = symptoms
    }
    
    static func normalizedNotes(_ notes: String) -> String? {
        notes.isEmpty ? nil : notes
    }
    
    static func saveAction(
        viewModel: CycleTrackingViewModel,
        symptomID: String,
        severity: Int,
        date: Date,
        notes: String,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            viewModel.addSymptomLog(
                symptomID: symptomID,
                severity: severity,
                date: date,
                notes: Self.normalizedNotes(notes)
            )
            dismiss()
        }
    }

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
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        symptomID: symptomID,
                        severity: severity,
                        date: date,
                        notes: notes,
                        dismiss: dismiss.callAsFunction
                    ))
                }
            }
        }
    }
}

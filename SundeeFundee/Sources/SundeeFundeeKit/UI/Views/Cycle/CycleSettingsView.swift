import SwiftUI

// MARK: - CycleSettingsView
//
// Manages cycle length, start/end of current period, past period logs.
// Extracted from SettingsView.swift in v1.4 when Cycle became its own tab.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CycleSettingsView: View {
    @State private var cycleLength: Double = 28
    @State private var periodStartDate: Date = Date()
    @State private var periodEndDate: Date = Date()
    @State private var loggedPeriods: [PeriodLogRecord] = []
    @State private var isSaving: Bool = false
    @State private var isLogging: Bool = false
    @State private var isEndingPeriod: Bool = false
    @State private var errorMessage: String?
    @State private var loadTrigger: Int = 0
    @State private var editingPeriod: PeriodLogRecord?

    @EnvironmentObject var cyclePhaseCache: CyclePhaseCache

    private let dataClient: DataClientProtocol = DataClientFactory.shared.client

    /// Whether there is an active period (started but not ended).
    private var activePeriod: PeriodLogRecord? {
        loggedPeriods.first(where: { $0.isActive })
    }

    var body: some View {
        Form {
            // Cycle Length
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Cycle Length")
                            .font(AppTheme.Typography.headlineMedium)
                        Spacer()
                        Text("\(Int(cycleLength)) days")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    Slider(value: $cycleLength, in: 21...35, step: 1) {
                        Text("\(Int(cycleLength)) days")
                    }
                    .accessibilityLabel("Cycle length, \(Int(cycleLength)) days")

                    Text("Average menstrual cycle length")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }

            Section {
                Button {
                    Task { await saveCycleSettings() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Cycle Length")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }

            // Active Period / Start Period
            if let active = activePeriod {
                Section {
                    Button {
                        editingPeriod = active
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Period started")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Text.primary)
                                Text(formatDate(active.startDate))
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                            Spacer()
                            Text("\u{1F988} Active")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(.red)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Edit start date")

                    Button {
                        Task { await endActivePeriod() }
                    } label: {
                        HStack {
                            Spacer()
                            if isEndingPeriod {
                                ProgressView()
                            } else {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("End Period")
                                }
                                .font(AppTheme.Typography.labelLarge)
                                .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isEndingPeriod)
                } header: {
                    Text("Current Period")
                }
            } else {
                Section {
                    DatePicker("Start Date", selection: $periodStartDate, in: ...Date(), displayedComponents: .date)

                    Button {
                        Task { await startPeriod() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLogging {
                                ProgressView()
                            } else {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "drop.fill")
                                    Text("Start Period")
                                }
                                .font(AppTheme.Typography.labelLarge)
                                .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLogging)
                } header: {
                    Text("Log Period")
                } footer: {
                    Text("You can end it later, or log a past period with start and end dates below.")
                }

                // Log a past period (with both dates) — only show when there are previous periods
                if !loggedPeriods.isEmpty {
                    Section {
                        DatePicker("Start Date", selection: $periodStartDate, in: ...Date(), displayedComponents: .date)
                        DatePicker("End Date", selection: $periodEndDate, in: ...Date(), displayedComponents: .date)

                        Button {
                            Task { await logPastPeriod() }
                        } label: {
                            HStack {
                                Spacer()
                                if isLogging {
                                    ProgressView()
                                } else {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Log Past Period")
                                    }
                                    .font(AppTheme.Typography.labelLarge)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isLogging || periodEndDate < periodStartDate)
                    } header: {
                        Text("Log Past Period")
                    } footer: {
                        if periodEndDate < periodStartDate {
                            Text("End date must be on or after start date.")
                                .foregroundColor(AppTheme.Semantic.error)
                        }
                    }
                }
            }

            // Logged Periods (completed ones only)
            let completedPeriods = loggedPeriods.filter { !$0.isActive }
            if !completedPeriods.isEmpty {
                Section {
                    ForEach(completedPeriods) { period in
                        Button {
                            editingPeriod = period
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatDate(period.startDate))
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Text.primary)
                                    if let endDate = period.endDate {
                                        Text("to \(formatDate(endDate))")
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(AppTheme.Text.secondary)
                                    }
                                }
                                Spacer()
                                if let endDate = period.endDate {
                                    Text("\(daysBetween(period.startDate, endDate)) days")
                                        .font(AppTheme.Typography.labelMedium)
                                        .foregroundColor(AppTheme.Accent.gold)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .accessibilityHint("Edit period dates")
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { completedPeriods[$0].id }
                        Task { await deletePeriods(ids: ids) }
                    }
                } header: {
                    Text("Past Periods")
                } footer: {
                    Text("Tap a period to edit its dates. Swipe left to delete.")
                }
            }
        }
        .navigationTitle("Cycle Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: loadTrigger) {
            await loadData()
        }
        .onAppear {
            loadTrigger += 1
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(item: $editingPeriod) { period in
            EditPeriodSheet(period: period) { updated in
                Task { await updatePeriod(updated) }
            }
        }
    }

    // MARK: - Data

    private func loadData() async {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "CycleSettings"
            ) as [CycleSettingsRecord]

            if let settings = records.first {
                cycleLength = Double(settings.averageCycleLengthDays)
            }
        } catch {
            // Use defaults
        }

        do {
            loggedPeriods = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            loggedPeriods.sort { $0.startDate > $1.startDate }
        } catch {
            // No logged periods yet
        }
    }

    private func saveCycleSettings() async {
        isSaving = true
        let lastStart = loggedPeriods.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
        let record = CycleSettingsRecord(
            averageCycleLengthDays: Int(cycleLength),
            lastPeriodStart: lastStart
        )
        do {
            try await dataClient.save(record, recordType: "CycleSettings")
            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func startPeriod() async {
        isLogging = true
        let startOfDay = Calendar.current.startOfDay(for: periodStartDate)
        let record = PeriodLogRecord(startDate: startOfDay, endDate: nil)
        do {
            try await dataClient.save(record, recordType: "PeriodLogRecord")
            loggedPeriods.insert(record, at: 0)

            let settingsRecord = CycleSettingsRecord(
                averageCycleLengthDays: Int(cycleLength),
                lastPeriodStart: startOfDay
            )
            try await dataClient.save(settingsRecord, recordType: "CycleSettings")

            cyclePhaseCache.markPeriodStarted()
            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            periodStartDate = Date()
        } catch {
            errorMessage = "Failed to start period: \(error.localizedDescription)"
        }
        isLogging = false
    }

    private func endActivePeriod() async {
        guard let active = activePeriod else { return }
        isEndingPeriod = true
        let endOfDay = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))
            ?? Calendar.current.startOfDay(for: Date())
        let updated = PeriodLogRecord(id: active.id, startDate: active.startDate, endDate: endOfDay)
        do {
            try await dataClient.save(updated, recordType: "PeriodLogRecord")
            if let idx = loggedPeriods.firstIndex(where: { $0.id == active.id }) {
                loggedPeriods[idx] = updated
            }
            cyclePhaseCache.markPeriodEnded()
            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
        } catch {
            errorMessage = "Failed to end period: \(error.localizedDescription)"
        }
        isEndingPeriod = false
    }

    private func logPastPeriod() async {
        isLogging = true
        let startOfDay = Calendar.current.startOfDay(for: periodStartDate)
        let endOfDay = Calendar.current.startOfDay(for: periodEndDate)
        let record = PeriodLogRecord(startDate: startOfDay, endDate: endOfDay)
        do {
            try await dataClient.save(record, recordType: "PeriodLogRecord")
            loggedPeriods.insert(record, at: 0)

            let settingsRecord = CycleSettingsRecord(
                averageCycleLengthDays: Int(cycleLength),
                lastPeriodStart: startOfDay
            )
            try await dataClient.save(settingsRecord, recordType: "CycleSettings")

            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            periodStartDate = Date()
            periodEndDate = Date()
        } catch {
            errorMessage = "Failed to log period: \(error.localizedDescription)"
        }
        isLogging = false
    }

    private func updatePeriod(_ updated: PeriodLogRecord) async {
        let startOfDay = Calendar.current.startOfDay(for: updated.startDate)
        let endOfDay = updated.endDate.map { Calendar.current.startOfDay(for: $0) }
        let normalized = PeriodLogRecord(id: updated.id, startDate: startOfDay, endDate: endOfDay)
        do {
            try await dataClient.save(normalized, recordType: "PeriodLogRecord")
            if let idx = loggedPeriods.firstIndex(where: { $0.id == normalized.id }) {
                loggedPeriods[idx] = normalized
            }
            loggedPeriods.sort { $0.startDate > $1.startDate }

            // If this edit changed the most-recent period start, update CycleSettings so
            // phase predictions recompute from the corrected date.
            if let mostRecentStart = loggedPeriods.first?.startDate {
                let settingsRecord = CycleSettingsRecord(
                    averageCycleLengthDays: Int(cycleLength),
                    lastPeriodStart: mostRecentStart
                )
                try? await dataClient.save(settingsRecord, recordType: "CycleSettings")
            }

            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
        } catch {
            errorMessage = "Failed to update period: \(error.localizedDescription)"
        }
    }

    private func deletePeriods(ids: [String]) async {
        loggedPeriods.removeAll { ids.contains($0.id) }
        if loggedPeriods.first(where: { $0.isActive }) == nil {
            cyclePhaseCache.markPeriodEnded()
        }
        for id in ids {
            do {
                try await dataClient.delete(recordType: "PeriodLogRecord", id: id)
            } catch {
                // Best effort
            }
        }
        NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: end)).day ?? 0
        return days + 1
    }
}

// MARK: - EditPeriodSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct EditPeriodSheet: View {
    let period: PeriodLogRecord
    let onSave: (PeriodLogRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    init(period: PeriodLogRecord, onSave: @escaping (PeriodLogRecord) -> Void) {
        self.period = period
        self.onSave = onSave
        _startDate = State(initialValue: period.startDate)
        _hasEndDate = State(initialValue: period.endDate != nil)
        _endDate = State(initialValue: period.endDate ?? period.startDate)
    }

    private var isValid: Bool {
        !hasEndDate || endDate >= startDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                } footer: {
                    Text("Correcting the start date will update your cycle predictions.")
                }

                Section {
                    Toggle("Has End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker(
                            "End Date",
                            selection: $endDate,
                            in: startDate...Date(),
                            displayedComponents: .date
                        )
                    }
                } footer: {
                    if !hasEndDate {
                        Text("Leave off if this period is still active.")
                    } else if endDate < startDate {
                        Text("End date must be on or after start date.")
                            .foregroundColor(AppTheme.Semantic.error)
                    }
                }
            }
            .navigationTitle("Edit Period")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = PeriodLogRecord(
                            id: period.id,
                            startDate: startDate,
                            endDate: hasEndDate ? endDate : nil
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
                #else
                ToolbarItem {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem {
                    Button("Save") {
                        let updated = PeriodLogRecord(
                            id: period.id,
                            startDate: startDate,
                            endDate: hasEndDate ? endDate : nil
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
                #endif
            }
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExportView
//
// Data export screen showing record category counts, export progress,
// and ShareLink for delivering the JSON file via the system share sheet.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()
    #if canImport(UIKit)
    @State private var shareFileURL: ShareFileURL?
    #endif

    public init() {}

    public var body: some View {
        List {
            dataCategoriesSection
            #if canImport(UIKit)
            coachReportSection
            #endif
            exportSection
            if let error = viewModel.errorMessage {
                errorSection(error)
            }
        }
        .navigationTitle("Export My Data")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        #if canImport(UIKit)
        .sheet(item: $shareFileURL) { item in
            SystemShareSheet(activityItems: [item.url])
        }
        #endif
        .task {
            await viewModel.loadCategoryCountsIfNeeded()
        }
    }

    // MARK: - Data Categories Section

    private var dataCategoriesSection: some View {
        Section("Your Data") {
            ForEach(categoryItems, id: \.name) { item in
                HStack {
                    Label(item.name, systemImage: item.icon)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    Text("\(viewModel.categoryCounts[item.name] ?? 0)")
                        .font(AppTheme.Typography.monoMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Background.cream)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
    }

    // MARK: - Coach Report Section

    #if canImport(UIKit)
    private var coachReportSection: some View {
        Section {
            Picker("Time period", selection: $viewModel.reportRange) {
                ForEach(TrainingReportRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .accessibilityHint("Choose how far back the report covers")

            Toggle(isOn: $viewModel.includeCycleDetailInReport) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Include cycle details")
                        .foregroundColor(AppTheme.Text.primary)
                    Text("Adds cycle phase patterns and symptom notes. Off by default.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
            .accessibilityHint("Cycle phase and symptom information is left out unless you turn this on")

            Button {
                Task {
                    if let fileURL = await viewModel.generateReportPDF() {
                        shareFileURL = ShareFileURL(url: fileURL)
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isGeneratingReport {
                        ProgressView()
                            .padding(.trailing, AppTheme.Spacing.sm)
                            .accessibilityLabel("Preparing report")
                    }
                    Text(viewModel.isGeneratingReport ? "Preparing..." : "Share Training Report")
                        .font(AppTheme.Typography.labelLarge)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .disabled(viewModel.isGeneratingReport)
            .accessibilityHint("Generate a PDF summary to share with a coach or clinician")
        } header: {
            Text("Coach Report")
        } footer: {
            Text("A plain-language PDF summary of your training, for a coach, trainer, or clinician. "
                + "Nothing is generated or sent until you tap share.")
        }
    }
    #endif

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.loadExportData()
                    #if canImport(UIKit)
                    if let fileURL = viewModel.generateJSONFile() {
                        await MainActor.run {
                            shareFileURL = ShareFileURL(url: fileURL)
                        }
                    }
                    #endif
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                            .padding(.trailing, AppTheme.Spacing.sm)
                            .accessibilityLabel("Exporting data")
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Export My Data")
                        .font(AppTheme.Typography.labelLarge)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .disabled(viewModel.isExporting)
            .accessibilityHint("Generate a JSON file of all your data")
        }
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.Semantic.error)
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Semantic.error)
            }
        }
    }
}

#if canImport(UIKit)
private struct ShareFileURL: Identifiable {
    let id = UUID()
    let url: URL
}
#endif

// MARK: - Category Display Items

/// Maps category names from ExportedData.categoryCounts to display icons.
private struct CategoryDisplayItem {
    let name: String
    let icon: String
}

private let categoryItems: [CategoryDisplayItem] = [
    CategoryDisplayItem(name: "Workouts", icon: "dumbbell"),
    CategoryDisplayItem(name: "One Rep Maxes", icon: "trophy"),
    CategoryDisplayItem(name: "Completed Workouts", icon: "checkmark.circle"),
    CategoryDisplayItem(name: "Cycle Phases", icon: "calendar"),
    CategoryDisplayItem(name: "Cycle Settings", icon: "slider.horizontal.3"),
    CategoryDisplayItem(name: "Benchmarks", icon: "chart.bar"),
    CategoryDisplayItem(name: "Injuries", icon: "bandage"),
    CategoryDisplayItem(name: "Pain Logs", icon: "waveform.path.ecg"),
    CategoryDisplayItem(name: "Celebrations", icon: "party.popper"),
    CategoryDisplayItem(name: "Programs", icon: "list.clipboard"),
    CategoryDisplayItem(name: "Weekly Plans", icon: "calendar.badge.clock"),
]

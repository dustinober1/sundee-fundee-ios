import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExportView
//
// Data export screen showing record category counts, export progress,
// and ShareLink for delivering the JSON file via the system share sheet.
// Gated behind SubscriptionTier.hasExportShare (Pro only).

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()

    public init() {}

    public var body: some View {
        List {
            if !viewModel.canExport {
                upgradeSection
            } else {
                dataCategoriesSection
                exportSection
                if viewModel.exportedData != nil {
                    shareSection
                }
                if let error = viewModel.errorMessage {
                    errorSection(error)
                }
            }
        }
        .navigationTitle("Export My Data")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $viewModel.showingSubscription) {
            SubscriptionView()
        }
        .task {
            await viewModel.checkSubscription()
        }
    }

    // MARK: - Upgrade Section

    private var upgradeSection: some View {
        Section {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Accent.gold)

                Text("Export My Data")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Export all your training data as a JSON file. This feature is available on the Pro plan.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.showingSubscription = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Accent.gold)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .padding(.vertical, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
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

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                Task { await viewModel.loadExportData() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                            .padding(.trailing, AppTheme.Spacing.sm)
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Export My Data")
                        .font(AppTheme.Typography.labelLarge)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .disabled(viewModel.isExporting)
        }
    }

    // MARK: - Share Section

    private var shareSection: some View {
        Section {
            if let fileURL = viewModel.generateJSONFile() {
                ShareLink(
                    item: fileURL,
                    preview: SharePreview(
                        "SundeeFundee-Export.json",
                        image: Image(systemName: "doc.fill")
                    )
                ) {
                    Label("Share Export File", systemImage: "square.and.arrow.up")
                        .foregroundColor(AppTheme.Accent.gold)
                }
            }
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
    CategoryDisplayItem(name: "Benchmarks", icon: "chart.bar"),
    CategoryDisplayItem(name: "Injuries", icon: "bandage"),
    CategoryDisplayItem(name: "Pain Logs", icon: "waveform.path.ecg"),
    CategoryDisplayItem(name: "Celebrations", icon: "party.popper"),
    CategoryDisplayItem(name: "Programs", icon: "list.clipboard"),
]

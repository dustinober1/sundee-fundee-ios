import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct DataTrustCenterView: View {
    @State private var summary: DataInventorySummary?
    @State private var isLoading = false
    @State private var showDeleteConfirm = false
    @EnvironmentObject private var authViewModel: AuthViewModel

    public init() {}

    public var body: some View {
        List {
            Section("Storage") {
                if isLoading && summary == nil {
                    ProgressView("Loading data inventory…")
                } else if let summary {
                    ForEach(summary.items) { item in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            HStack {
                                Text(item.title)
                                    .font(AppTheme.Typography.headlineSmall)
                                    .foregroundColor(AppTheme.Text.primary)
                                Spacer()
                                if let count = item.count {
                                    Text("\(count)")
                                        .font(AppTheme.Typography.monoMedium)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            }

                            Text(item.storage)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)

                            Text(item.notes)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                } else {
                    Text("No inventory available yet.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }

            Section("Actions") {
                NavigationLink {
                    ExportView()
                } label: {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete All Data & Account", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Data Trust Center")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadInventory()
        }
        .refreshable {
            await loadInventory()
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and app data.")
        }
    }

    private func loadInventory() async {
        isLoading = true
        let service = DataInventoryService()
        summary = await service.loadInventory()
        isLoading = false
    }
}

import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct DataTrustCenterView: View {
    @State private var summary: DataInventorySummary?
    @State private var isLoading = false
    @State private var showDeleteConfirm = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject private var diagnostics = SyncQueueDiagnosticsService.shared

    public init() {}

    public var body: some View {
        List {
            syncStatusSection

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

    // MARK: - Sync Status Section

    private var currentSyncStatus: SyncStatus {
        SyncStatusService.status(
            isGuest: authViewModel.isGuest,
            pendingMutationCount: diagnostics.pendingCount,
            stuckMutationCount: diagnostics.stuckCount
        )
    }

    @ViewBuilder
    private var syncStatusSection: some View {
        let status = currentSyncStatus
        // Show all statuses except "synced" silently (synced is the happy path)
        if status.kind == .synced {
            EmptyView()
        } else {
            Section("Sync Status") {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: status.systemImage)
                        .font(.title3)
                        .foregroundColor(syncStatusColor(for: status.kind))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(status.title)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(status.message)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    private func syncStatusColor(for kind: SyncStatusKind) -> Color {
        switch kind {
        case .localOnly: return AppTheme.Accent.gold
        case .synced: return AppTheme.Recovery.green
        case .queued: return AppTheme.Accent.orange
        case .needsAttention: return AppTheme.Semantic.warning
        }
    }

    private func loadInventory() async {
        isLoading = true
        let service = DataInventoryService()
        summary = await service.loadInventory()
        isLoading = false
    }
}

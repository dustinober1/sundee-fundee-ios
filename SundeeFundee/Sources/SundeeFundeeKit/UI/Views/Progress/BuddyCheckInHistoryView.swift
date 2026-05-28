import SwiftUI

// MARK: - BuddyCheckInHistoryView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct BuddyCheckInHistoryView: View {
    @State private var checkIns: [BuddyCheckInRecord] = []
    @State private var isLoading = false
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        Group {
            if isLoading {
                VStack(spacing: AppTheme.Spacing.md) {
                    ProgressView()
                    Text("Loading check-ins...")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let loadError {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(.largeTitle))
                        .foregroundColor(AppTheme.Accent.orange)
                    Text(loadError)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await loadCheckIns() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .artDecoButton(style: .secondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xxl)
            } else if checkIns.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "person.2.checkmark")
                        .font(.system(.largeTitle))
                        .foregroundColor(AppTheme.Accent.gold)
                    Text("No Check-Ins Yet")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)
                    Text("Check in with your workout buddy to stay accountable.")
                        .font(AppTheme.Typography.bodyLarge)
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, AppTheme.Spacing.xxl)
            } else {
                List {
                    ForEach(checkIns) { checkIn in
                        checkInRow(checkIn)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Buddy Check-Ins")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await loadCheckIns()
        }
    }

    private func checkInRow(_ checkIn: BuddyCheckInRecord) -> some View {
        ArtDecoCard {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(checkIn.displayName)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    if let message = checkIn.message {
                        Text(message)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .lineLimit(2)
                    }

                    Text(formatDate(checkIn.checkInDate))
                        .font(AppTheme.Typography.monoSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                statusBadge(checkIn.status)
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: AppTheme.Spacing.xs, leading: AppTheme.Spacing.md, bottom: AppTheme.Spacing.xs, trailing: AppTheme.Spacing.md))
    }

    private func statusBadge(_ status: BuddyCheckInStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(status == .completed ? AppTheme.Text.cream : AppTheme.Text.primary)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(status == .completed ? AppTheme.Background.navy : AppTheme.Background.cream)
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(AppTheme.Background.navy.opacity(0.15), lineWidth: 1)
            )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func loadCheckIns() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let records: [BuddyCheckInRecord] = try await DataClientFactory.shared.client.fetchAll(
                recordType: "BuddyCheckInRecord"
            )
            checkIns = records.sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            loadError = "Could not load check-ins. Please try again."
        }
    }
}

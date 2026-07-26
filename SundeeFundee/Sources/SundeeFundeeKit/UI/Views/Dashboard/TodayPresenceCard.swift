import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct TodayPresenceCard: View {
    private struct MomentumRoute: Identifiable {
        let summary: ConsistencyMomentumSummary
        let id = "four-week-momentum"
    }

    private let today: DailyPresenceRecord?
    private let summary: ConsistencyMomentumSummary?
    private let message: String?
    private let syncState: PresenceSyncState
    private let isUpdating: Bool
    private let onSelect: (DailyPresenceStatus) -> Void
    private let onRetrySync: () -> Void

    @State private var momentumRoute: MomentumRoute?

    public init(
        today: DailyPresenceRecord?,
        summary: ConsistencyMomentumSummary?,
        message: String? = nil,
        syncState: PresenceSyncState = .synced,
        isUpdating: Bool = false,
        onSelect: @escaping (DailyPresenceStatus) -> Void,
        onRetrySync: @escaping () -> Void = {}
    ) {
        self.today = today
        self.summary = summary
        self.message = message
        self.syncState = syncState
        self.isUpdating = isUpdating
        self.onSelect = onSelect
        self.onRetrySync = onRetrySync
    }

    public var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(summary?.supportiveHeadline ?? "Showing up counts")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundStyle(AppTheme.Text.primary)

                    Text("Opening Today already counted as showing up")
                        .font(.body)
                        .foregroundStyle(AppTheme.Text.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(DailyPresenceStatus.allCases, id: \.self) { status in
                            statusButton(status)
                        }
                    }
                }

                if let message {
                    Text(message)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundStyle(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Momentum update: \(message)")
                }

                if syncState.status != .synced {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                        Text(syncMessage)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundStyle(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: AppTheme.Spacing.sm)

                        Button("Retry", action: onRetrySync)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundStyle(AppTheme.Accent.orange)
                            .disabled(isUpdating || syncState.status == .retrying)
                    }
                    .accessibilityElement(children: .combine)
                }

                if let summary {
                    Button {
                        momentumRoute = MomentumRoute(summary: summary)
                    } label: {
                        Label("View 4-week momentum", systemImage: "chart.bar")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .ghost)
                    .accessibilityHint("Shows weekly presence, check-ins, and action days")
                }
            }
        }
        .sheet(item: $momentumRoute) { route in
            ConsistencyMomentumView(summary: route.summary)
        }
    }

    private var syncMessage: String {
        switch syncState.status {
        case .synced:
            ""
        case .pending:
            syncState.pendingCount == 1
                ? "1 momentum update is safely waiting to sync."
                : "\(syncState.pendingCount) momentum updates are safely waiting to sync."
        case .retrying:
            "Refreshing your private momentum…"
        case .actionRequired:
            "Momentum is saved here. Check iCloud access, then try again."
        }
    }

    private func statusButton(_ status: DailyPresenceStatus) -> some View {
        let isSelected = today?.status == status

        return Button {
            onSelect(status)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: status.systemImage)
                    .font(.title3)
                    .accessibilityHidden(true)

                Text(status.displayName)
                    .font(.body)
            }
            .foregroundStyle(isSelected ? AppTheme.Background.navy : AppTheme.Text.secondary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? AppTheme.Accent.orange : AppTheme.Background.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isSelected ? AppTheme.Accent.orange : AppTheme.Accent.goldLight,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdating)
        .accessibilityLabel("\(status.displayName) check-in")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Updates today's private status")
    }
}

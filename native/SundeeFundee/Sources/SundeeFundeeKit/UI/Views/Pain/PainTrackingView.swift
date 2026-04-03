import SwiftUI

// MARK: - Pain Tracking View

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct PainTrackingView: View {
    @StateObject private var viewModel = PainTrackingViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.painLogs.isEmpty {
                    ProgressView("Loading...")
                } else {
                    contentView
                }
            }
            .navigationTitle("Pain & Injuries")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadPainLogs()
                await viewModel.loadInjuries()
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if !viewModel.activeInjuries.isEmpty {
                    activeInjuriesBanner
                }

                logPainCard

                if !viewModel.painLogs.isEmpty {
                    Text("Recent Pain Logs")
                        .font(AppTheme.Typography.headlineMedium)
                }

                ForEach(viewModel.painLogs.prefix(5)) { log in
                    PainLogRow(log: log)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    private var activeInjuriesBanner: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Active Injuries")
                    .font(AppTheme.Typography.headlineMedium)

                ForEach(viewModel.activeInjuries) { injury in
                    HStack {
                        Text(injury.name)
                            .font(AppTheme.Typography.bodyMedium)
                        Spacer()
                        Text(injury.recoveryPhase.displayName)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }

    private var logPainCard: some View {
        ArtDecoCard {
            Text("Log Pain")
                .font(AppTheme.Typography.headlineMedium)
        }
    }
}

struct PainLogRow: View {
    let log: DailyPainLog

    var body: some View {
        ArtDecoCard {
            HStack {
                Text("\(log.intensity)")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(.red)

                VStack(alignment: .leading) {
                    Text(log.date, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                    Text(log.painType.displayName)
                        .font(AppTheme.Typography.bodySmall)
                }
            }
        }
    }
}

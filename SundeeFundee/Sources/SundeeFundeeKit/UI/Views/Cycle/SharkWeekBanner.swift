import SwiftUI

// MARK: - SharkWeekBanner
//
// Pulsing red banner shown on every screen when the user is in the menstrual phase.
// Displayed as an overlay from MainTabView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SharkWeekBanner: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("\u{1F988}")
                .font(.system(size: 20))

            Text("Shark Week")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.red)
        )
        .opacity(isPulsing ? 0.7 : 1.0)
        .scaleEffect(isPulsing ? 0.97 : 1.0)
        .shadow(color: Color.red.opacity(isPulsing ? 0.3 : 0.5), radius: isPulsing ? 4 : 8, y: 2)
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
        .accessibilityLabel("Shark Week — menstrual phase active")
    }
}

// MARK: - SharkWeekMonitor
//
// Lightweight observable that checks if the current cycle phase is menstrual.
// Reads from both HealthKit and manual PeriodLogRecords.
// Listens for cycleDataUpdated notifications to refresh.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class SharkWeekMonitor: ObservableObject {
    @Published var isSharkWeek: Bool = false

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    func check() async {
        // Try HealthKit first
        if healthClient.isAvailable {
            do {
                try? await healthClient.requestStandardAuthorization()
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo,
                    endDate: nil,
                    limit: 100
                )
                if let status = CyclePhaseHelper.calculatePhase(from: cycles) {
                    isSharkWeek = status.currentPhase == .menstrual
                    return
                }
            } catch {
                // Fall through to manual logs
            }
        }

        // Fallback: manual period logs
        await checkManualLogs()
    }

    private func checkManualLogs() async {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]

            guard !records.isEmpty else {
                isSharkWeek = false
                return
            }

            let periodLogs = records.map { $0.toPeriodLog() }

            // Load cycle settings for calculation
            var settings = CycleSettings()
            if let settingsRecords = try? await dataClient.fetchAll(
                recordType: "CycleSettings"
            ) as [CycleSettingsRecord], let first = settingsRecords.first {
                settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
            }

            if let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) {
                isSharkWeek = status.currentPhase == .menstrual
            } else {
                isSharkWeek = false
            }
        } catch {
            // Data unavailable — degrade gracefully
        }
    }
}

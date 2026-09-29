import AppIntents
import Foundation

// MARK: - DailyStatusAppEnum

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public enum DailyStatusAppEnum: String, AppEnum, Sendable {
    case trained
    case resting
    case ready
    case sore
    case tired

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Daily Status")
    public static let caseDisplayRepresentations: [DailyStatusAppEnum: DisplayRepresentation] = [
        .trained: DisplayRepresentation(title: "Trained", subtitle: "Completed a workout session"),
        .resting: DisplayRepresentation(title: "Resting", subtitle: "Taking a scheduled rest day"),
        .ready: DisplayRepresentation(title: "Ready", subtitle: "Primed to train today"),
        .sore: DisplayRepresentation(title: "Sore", subtitle: "Recovering from muscular soreness"),
        .tired: DisplayRepresentation(title: "Tired", subtitle: "Low energy or sleep deficit")
    ]
}

// MARK: - LogDailyStatusIntent

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public struct LogDailyStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log Daily Status"
    public static let description = IntentDescription("Log your daily training presence or rest status in Sundee Fundee.")
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Status")
    public var status: DailyStatusAppEnum

    public init() {}

    public init(status: DailyStatusAppEnum) {
        self.status = status
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let session = DataClientFactory.shared.session
        let service = DailyPresenceService(
            ownerID: session.ownerID,
            localStore: PresenceLocalStore(ownerID: session.ownerID),
            dataClient: session.client
        )

        let domainStatus: DailyPresenceStatus
        switch status {
        case .trained: domainStatus = .trained
        case .resting: domainStatus = .resting
        case .ready: domainStatus = .ready
        case .sore: domainStatus = .sore
        case .tired: domainStatus = .tired
        }

        let resolvedEvidence: DailyPresenceActionEvidence?
        let level: DailyParticipationLevel
        switch domainStatus {
        case .trained:
            resolvedEvidence = .trained
            level = .acted
        case .resting:
            resolvedEvidence = .rested
            level = .acted
        case .ready, .sore, .tired:
            resolvedEvidence = nil
            level = .checkedIn
        }

        _ = try await service.promoteToday(
            to: level,
            status: domainStatus,
            action: resolvedEvidence,
            at: Date(),
            calendar: .current
        )

        return .result(
            dialog: "Logged your daily status as \(domainStatus.displayName) in Sundee Fundee."
        )
    }
}

import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class WorkoutCompletionCheckInViewModel: ObservableObject {
    @Published public var sessionRPE: Int?
    @Published public var soreness: Int = 0
    @Published public var pain: Int = 0
    @Published public var wasRightForToday: Bool = true
    @Published public var isSaving = false

    private let workoutID: String
    private let dataClient: DataClientProtocol

    public init(workoutID: String, dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.workoutID = workoutID
        self.dataClient = dataClient
    }

    public func submit() async {
        isSaving = true
        defer { isSaving = false }

        let record = WorkoutCompletionCheckInRecord(
            workoutID: workoutID,
            sessionRPE: sessionRPE,
            soreness: soreness,
            pain: pain,
            wasRightForToday: wasRightForToday
        )
        try? await dataClient.save(record, recordType: "WorkoutCompletionCheckIn")
        await GrowthAnalyticsService(dataClient: dataClient).track(
            "post_workout_check_in_completed",
            source: "active_workout",
            properties: ["right_for_today": wasRightForToday ? "true" : "false"]
        )
    }
}

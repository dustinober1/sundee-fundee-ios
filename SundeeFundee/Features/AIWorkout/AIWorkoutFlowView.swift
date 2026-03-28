import SwiftUI
import SwiftData

struct AIWorkoutFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    let userID: String
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    @State private var generatedWorkout: GeneratedWorkout?
    @State private var workoutToStart: GeneratedWorkout?

    init(
        userID: String,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) {
        self.userID = userID
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
    }

    var body: some View {
        let onDeviceService = AppleIntelligenceWorkoutService(modelContext: modelContext)
        let cloudService = CloudAIWorkoutService(modelContext: modelContext)
        QuestionnaireView(
            userID: userID,
            subscriptionTier: appState.subscriptionTier,
            onDeviceService: onDeviceService,
            cloudService: cloudService,
            onWorkoutGenerated: { workout in
                generatedWorkout = workout
            }
        )
        .navigationDestination(item: $generatedWorkout) { workout in
            WorkoutPreviewView(
                viewModel: WorkoutPreviewViewModel(workout: workout, aiService: onDeviceService),
                userID: userID,
                onStartWorkout: { workout in
                    workoutToStart = workout
                },
                onRegenerate: {
                    generatedWorkout = nil
                }
            )
        }
        .navigationDestination(item: $workoutToStart) { workout in
            WorkoutExecutionView(
                viewModel: WorkoutExecutionViewModel(
                    generatedWorkout: workout,
                    barbellWeightKg: barbellWeightKg,
                    weightUnit: weightUnit
                )
            )
        }
    }
}

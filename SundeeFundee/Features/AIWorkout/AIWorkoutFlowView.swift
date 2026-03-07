import SwiftUI
import SwiftData

struct AIWorkoutFlowView: View {
    @Environment(\.modelContext) private var modelContext
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
        let aiService = SwiftDataAIWorkoutService(
            modelContext: modelContext,
            sharedRepository: CloudKitSharedWorkoutRepository(modelContext: modelContext)
        )
        QuestionnaireView(
            userID: userID,
            aiService: aiService,
            onWorkoutGenerated: { workout in
                generatedWorkout = workout
            }
        )
        .navigationDestination(item: $generatedWorkout) { workout in
            WorkoutPreviewView(
                viewModel: WorkoutPreviewViewModel(workout: workout, aiService: aiService),
                userID: userID,
                weightUnit: weightUnit,
                onStartWorkout: { started in
                    workoutToStart = started
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

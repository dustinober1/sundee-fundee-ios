import SwiftUI
import SwiftData

struct AIWorkoutFlowView: View {
    @Environment(\.modelContext) private var modelContext
    let userID: String
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    @State private var path = NavigationPath()
    @State private var generatedWorkout: GeneratedWorkout?

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
        let aiService = SwiftDataAIWorkoutService(modelContext: modelContext)
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
                onStartWorkout: { _ in
                    // Navigate to workout execution — handled by parent
                },
                onRegenerate: {
                    generatedWorkout = nil
                }
            )
        }
    }
}

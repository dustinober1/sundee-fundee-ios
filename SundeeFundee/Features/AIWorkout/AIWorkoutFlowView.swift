import SwiftUI
import SwiftData

struct AIWorkoutFlowView: View {
    @Environment(\.modelContext) private var modelContext
    let userID: String
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    @State private var path = NavigationPath()
    @State private var generatedWorkout: GeneratedWorkout?

    private let aiService: any AIWorkoutServiceProtocol

    init(
        userID: String,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds,
        aiService: any AIWorkoutServiceProtocol = FirebaseAIWorkoutService()
    ) {
        self.userID = userID
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        self.aiService = aiService
    }

    var body: some View {
        QuestionnaireView(
            userID: userID,
            onWorkoutGenerated: { workout in
                generatedWorkout = workout
            }
        )
        .navigationDestination(item: $generatedWorkout) { workout in
            WorkoutPreviewView(
                viewModel: WorkoutPreviewViewModel(workout: workout, aiService: aiService),
                userID: userID,
                onStartWorkout: { finalWorkout in
                    // Navigate to workout execution — handled by parent
                },
                onRegenerate: {
                    generatedWorkout = nil
                }
            )
        }
    }
}

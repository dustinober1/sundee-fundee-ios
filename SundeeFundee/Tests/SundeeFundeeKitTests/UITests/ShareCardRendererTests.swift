#if canImport(UIKit)
import Testing
import Foundation
import UIKit
@testable import SundeeFundeeKit

// MARK: - ShareCardRendererTests

@available(iOS 18.0, *)
@Suite("ShareCardRenderer")
@MainActor
struct ShareCardRendererTests {

    @Test("Renders completedWorkout variant for both aspects")
    func rendersCompletedWorkoutAllAspects() async {
        let workout = Workout(
            date: Date(),
            name: "Push Day",
            exercises: [
                Exercise(
                    id: "1",
                    name: "Bench Press",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(
                            reps: 5,
                            prescribedWeight: 185,
                            type: .fixed,
                            completedWeight: 185,
                            actualReps: 5,
                            isComplete: true
                        )
                    ]
                )
            ],
            duration: 42,
            completedAt: Date()
        )

        for aspect in ShareCardAspect.allCases {
            let image = await ShareCardRenderer.render(
                .completedWorkout(workout: workout, personalRecords: ["Bench Press"]),
                aspect: aspect
            )
            #expect(image != nil, "Expected non-nil image for \(aspect)")
            #expect(image?.size.width ?? 0 > 0)
            #expect(image?.size.height ?? 0 > 0)
        }
    }

    @Test("Renders newPR variant with and without previous best")
    func rendersNewPR() async {
        let withPrev = await ShareCardRenderer.render(
            .newPR(exerciseName: "Squat", weight: 315, unit: "lb", previousBest: 305),
            aspect: .story
        )
        let withoutPrev = await ShareCardRenderer.render(
            .newPR(exerciseName: "Squat", weight: 225, unit: "lb", previousBest: nil),
            aspect: .square
        )
        #expect(withPrev != nil)
        #expect(withoutPrev != nil)
    }

    @Test("Renders cycleInsight for all phases")
    func rendersCycleInsightAllPhases() async {
        let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]
        for phase in phases {
            let image = await ShareCardRenderer.render(
                .cycleInsight(phase: phase, cycleDay: 7, insight: "Build & rise."),
                aspect: .story
            )
            #expect(image != nil, "Expected non-nil image for phase \(phase.rawValue)")
        }
    }

    @Test("Aspect point sizes follow 9:16 and 1:1")
    func aspectSizesMatchRatios() {
        let story = ShareCardAspect.story.size
        let square = ShareCardAspect.square.size
        #expect(story.width < story.height, "Story should be portrait")
        #expect(square.width == square.height, "Square should be 1:1")
        let storyRatio = story.height / story.width
        #expect(abs(storyRatio - (16.0 / 9.0)) < 0.01)
    }
}
#endif

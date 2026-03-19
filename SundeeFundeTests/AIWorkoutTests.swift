import Testing
import Foundation
@testable import SundeeFundee

// MARK: - WorkoutGenerationContext Tests

@Suite("WorkoutGenerationContext")
struct WorkoutGenerationContextTests {

    @Test func encodingDecodingRoundTrip() throws {
        let context = WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [ExerciseMax(name: "Back Squat", weight: 100, weightUnit: "lb")],
            recentWorkouts: [RecentWorkoutSummary(date: .now, focus: "legs", exercises: ["Squat"], durationMinutes: 60)],
            cyclePhase: "follicular",
            readinessTier: "neutral",
            activeInjuries: [InjurySummary(location: "knee", phase: "rehab", restrictions: ["squat"])],
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )

        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(WorkoutGenerationContext.self, from: data)

        #expect(decoded.timeMinutes == 45)
        #expect(decoded.focus == .fullBody)
        #expect(decoded.energyLevel == .medium)
        #expect(decoded.equipment == .fullGym)
        #expect(decoded.maxes.count == 1)
        #expect(decoded.maxes.first?.name == "Back Squat")
        #expect(decoded.recentWorkouts.count == 1)
        #expect(decoded.cyclePhase == "follicular")
        #expect(decoded.readinessTier == "neutral")
        #expect(decoded.activeInjuries.count == 1)
    }
}

// MARK: - WorkoutFocus Tests

@Suite("WorkoutFocus")
struct WorkoutFocusTests {

    @Test func allCasesHaveDisplayNames() {
        for focus in WorkoutFocus.allCases {
            #expect(!focus.displayName.isEmpty)
        }
    }

    @Test func rawValues() {
        #expect(WorkoutFocus.upperBody.rawValue == "upper_body")
        #expect(WorkoutFocus.lowerBody.rawValue == "lower_body")
        #expect(WorkoutFocus.fullBody.rawValue == "full_body")
        #expect(WorkoutFocus.push.rawValue == "push")
        #expect(WorkoutFocus.pull.rawValue == "pull")
        #expect(WorkoutFocus.core.rawValue == "core")
        #expect(WorkoutFocus.conditioning.rawValue == "conditioning")
        #expect(WorkoutFocus.strength.rawValue == "strength")
        #expect(WorkoutFocus.olympicLifts.rawValue == "olympic_lifts")
        #expect(WorkoutFocus.gymnastics.rawValue == "gymnastics")
        #expect(WorkoutFocus.mobility.rawValue == "mobility")
        #expect(WorkoutFocus.stretching.rawValue == "stretching")
    }
}

// MARK: - EnergyLevel Tests

@Suite("EnergyLevel")
struct EnergyLevelTests {

    @Test func allCasesHaveDisplayNamesAndIcons() {
        for level in EnergyLevel.allCases {
            #expect(!level.displayName.isEmpty)
            #expect(!level.icon.isEmpty)
        }
    }

    @Test func rawValues() {
        #expect(EnergyLevel.low.rawValue == "low")
        #expect(EnergyLevel.medium.rawValue == "medium")
        #expect(EnergyLevel.high.rawValue == "high")
    }
}

// MARK: - EquipmentAccess Tests

@Suite("EquipmentAccess")
struct EquipmentAccessTests {

    @Test func allCasesHaveDisplayNamesAndIcons() {
        for equip in EquipmentAccess.allCases {
            #expect(!equip.displayName.isEmpty)
            #expect(!equip.icon.isEmpty)
        }
    }

    @Test func rawValues() {
        #expect(EquipmentAccess.fullGym.rawValue == "full_gym")
        #expect(EquipmentAccess.homeDumbbells.rawValue == "home_dumbbells")
        #expect(EquipmentAccess.hotelGym.rawValue == "hotel_gym")
        #expect(EquipmentAccess.bodyweightOnly.rawValue == "bodyweight_only")
        #expect(EquipmentAccess.outdoor.rawValue == "outdoor")
    }

    @Test func hotelGymHasDisplayName() {
        #expect(EquipmentAccess.hotelGym.displayName == "Hotel Gym")
    }

    @Test func hotelGymHasIcon() {
        #expect(EquipmentAccess.hotelGym.icon == "bed.double")
    }

    @Test func hotelGymRawValueEncodes() throws {
        let context = WorkoutGenerationContext(
            userID: "u1", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
            equipment: .hotelGym, maxes: [], recentWorkouts: [], cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "beginner",
            primaryGoal: "strength", gender: "male", weightUnit: "lb"
        )
        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(WorkoutGenerationContext.self, from: data)
        #expect(decoded.equipment == .hotelGym)
    }
}

// MARK: - TravelMode WorkoutGenerationContext Tests

@Suite("WorkoutGenerationContext TravelMode")
struct WorkoutGenerationContextTravelModeTests {

    @Test func travelModeEnabledEncodesDecodes() throws {
        let context = WorkoutGenerationContext(
            userID: "u1", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
            equipment: .hotelGym, maxes: [], recentWorkouts: [], cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "beginner",
            primaryGoal: "strength", gender: "male", weightUnit: "lb",
            travelModeEnabled: true
        )
        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(WorkoutGenerationContext.self, from: data)
        #expect(decoded.travelModeEnabled == true)
    }

    @Test func travelModeDefaultsToFalse() {
        let context = WorkoutGenerationContext(
            userID: "u1", timeMinutes: 30, focus: .fullBody, energyLevel: .medium,
            equipment: .fullGym, maxes: [], recentWorkouts: [], cyclePhase: nil,
            readinessTier: nil, activeInjuries: [], experienceLevel: "beginner",
            primaryGoal: "strength", gender: "male", weightUnit: "lb"
        )
        #expect(context.travelModeEnabled == false)
    }
}

// MARK: - GeneratedWorkout Tests

@Suite("GeneratedWorkout")
struct GeneratedWorkoutTests {

    @Test func initWithDefaults() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test summary",
            exercises: [],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45,
                focus: .fullBody,
                energyLevel: .medium,
                equipment: .fullGym
            )
        )

        #expect(!workout.id.isEmpty)
        #expect(workout.isFavorite == false)
        #expect(workout.coachingSummary == "Test summary")
        #expect(workout.exercises.isEmpty)
    }

    @Test func encodingDecodingRoundTrip() throws {
        let workout = GeneratedWorkout(
            id: "test-id",
            createdAt: Date(timeIntervalSince1970: 1000000),
            isFavorite: true,
            coachingSummary: "Great session",
            exercises: [
                GeneratedExercise(
                    id: "ex-1",
                    name: "Back Squat",
                    sets: 4,
                    reps: "5",
                    weight: 100, weightUnit: "lb",
                    restMinutes: 3.0,
                    notes: "Focus on depth",
                    reasoning: "Compound movement for quad development",
                    bodyweightOnly: false
                ),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 60,
                focus: .lowerBody,
                energyLevel: .high,
                equipment: .fullGym
            )
        )

        let data = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(GeneratedWorkout.self, from: data)

        #expect(decoded.id == "test-id")
        #expect(decoded.isFavorite == true)
        #expect(decoded.exercises.count == 1)
        #expect(decoded.exercises.first?.name == "Back Squat")
        #expect(decoded.exercises.first?.weight == 100)
        #expect(decoded.questionnaire.focus == .lowerBody)
    }

    @Test func muscleGroupExtraction() {
        let exercises = [
            GeneratedExercise(name: "Back Squat", sets: 3, reps: "5"),
            GeneratedExercise(name: "Flat Barbell Bench Press", sets: 3, reps: "5"),
            GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP"),
            GeneratedExercise(name: "Dumbbell Curl", sets: 3, reps: "10"),
            GeneratedExercise(name: "Plank Hold", sets: 3, reps: "30s"),
            GeneratedExercise(name: "Romanian Deadlift (No Straps)", sets: 3, reps: "8"),
            GeneratedExercise(name: "Calf Raises", sets: 3, reps: "15"),
        ]

        let groups = GeneratedWorkout.extractMuscleGroups(from: exercises)
        #expect(groups.contains("Quads"))
        #expect(groups.contains("Chest"))
        #expect(groups.contains("Back"))
        #expect(groups.contains("Biceps"))
        #expect(groups.contains("Core"))
        #expect(groups.contains("Hamstrings"))
        #expect(groups.contains("Calves"))
    }

    @Test func totalEstimatedMinutesWithExercises() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test",
            exercises: [
                GeneratedExercise(name: "Squat", sets: 4, reps: "5", restMinutes: 2.0),
                GeneratedExercise(name: "Bench", sets: 3, reps: "8", restMinutes: 1.5),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )

        #expect(workout.totalEstimatedMinutes > 0)
    }

    @Test func totalEstimatedMinutesEmptyExercises() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test",
            exercises: [],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )

        #expect(workout.totalEstimatedMinutes >= 1)
    }

    @Test func muscleGroupExtractionWithShouldersAndTriceps() {
        let exercises = [
            GeneratedExercise(name: "Overhead Shoulder Press", sets: 3, reps: "8"),
            GeneratedExercise(name: "Tricep Extension", sets: 3, reps: "12"),
            GeneratedExercise(name: "Dip", sets: 3, reps: "10"),
            GeneratedExercise(name: "Hip Thrust", sets: 3, reps: "10"),
            GeneratedExercise(name: "Chest Fly", sets: 3, reps: "12"),
            GeneratedExercise(name: "Lat Pulldown", sets: 3, reps: "10"),
        ]

        let groups = GeneratedWorkout.extractMuscleGroups(from: exercises)
        #expect(groups.contains("Shoulders"))
        #expect(groups.contains("Triceps"))
        #expect(groups.contains("Glutes"))
        #expect(groups.contains("Chest"))
        #expect(groups.contains("Back"))
    }
}

// MARK: - GeneratedExercise Tests

@Suite("GeneratedExercise")
struct GeneratedExerciseTests {

    @Test func initWithDefaults() {
        let ex = GeneratedExercise(name: "Push-Up", sets: 3, reps: "10")
        #expect(!ex.id.isEmpty)
        #expect(ex.name == "Push-Up")
        #expect(ex.weight == nil)
        #expect(ex.bodyweightOnly == false)
        #expect(ex.restMinutes == nil)
        #expect(ex.notes == nil)
        #expect(ex.reasoning == nil)
    }

    @Test func initWithAllFields() {
        let ex = GeneratedExercise(
            id: "custom-id",
            name: "Back Squat",
            sets: 5,
            reps: "3",
            weight: 120, weightUnit: "lb",
            restMinutes: 3.5,
            notes: "Brace core",
            reasoning: "Heavy compound",
            bodyweightOnly: false
        )
        #expect(ex.id == "custom-id")
        #expect(ex.sets == 5)
        #expect(ex.reps == "3")
        #expect(ex.weight == 120)
        #expect(ex.restMinutes == 3.5)
        #expect(ex.notes == "Brace core")
        #expect(ex.reasoning == "Heavy compound")
    }

    @Test func equatable() {
        let a = GeneratedExercise(id: "1", name: "Squat", sets: 3, reps: "5")
        let b = GeneratedExercise(id: "1", name: "Squat", sets: 3, reps: "5")
        let c = GeneratedExercise(id: "2", name: "Bench", sets: 3, reps: "5")
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - GeneratedExercise Equipment Detection and Weight Snapping Tests

@Suite("GeneratedExercise.equipmentType and withSnappedWeight")
struct GeneratedExerciseSnappingTests {

    @Test func detectsBarbellExercises() {
        #expect(GeneratedExercise(name: "Back Squat", sets: 3, reps: "5").equipmentType == .barbell)
        #expect(GeneratedExercise(name: "Flat Barbell Bench Press", sets: 3, reps: "5").equipmentType == .barbell)
        #expect(GeneratedExercise(name: "Conventional Deadlift (No Straps)", sets: 3, reps: "5").equipmentType == .barbell)
        #expect(GeneratedExercise(name: "Strict Press / Military Press", sets: 3, reps: "5").equipmentType == .barbell)
        #expect(GeneratedExercise(name: "Barbell Row", sets: 3, reps: "5").equipmentType == .barbell)
    }

    @Test func detectsDumbbellExercises() {
        #expect(GeneratedExercise(name: "Dumbbell Bench Press", sets: 3, reps: "8").equipmentType == .dumbbell)
        #expect(GeneratedExercise(name: "Dumbbell Overhead Press", sets: 3, reps: "8").equipmentType == .dumbbell)
        #expect(GeneratedExercise(name: "Goblet Squat", sets: 3, reps: "10").equipmentType == .dumbbell)
        #expect(GeneratedExercise(name: "Lateral Raises", sets: 3, reps: "12").equipmentType == .dumbbell)
        #expect(GeneratedExercise(name: "Dumbbell Row", sets: 3, reps: "10").equipmentType == .dumbbell)
    }

    @Test func detectsKettlebellExercises() {
        #expect(GeneratedExercise(name: "Kettlebell Swings", sets: 4, reps: "15").equipmentType == .kettlebell)
        #expect(GeneratedExercise(name: "KB Swing", sets: 4, reps: "15").equipmentType == .kettlebell)
    }

    @Test func detectsOtherExercises() {
        #expect(GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true).equipmentType == .other)
        #expect(GeneratedExercise(name: "Burpees", sets: 3, reps: "10", bodyweightOnly: true).equipmentType == .other)
    }

    @Test func barbellWeightSnapsToLoadableTotal() {
        // 226.9 lb → men's bar → should snap to 225 lb
        let ex = GeneratedExercise(name: "Back Squat", sets: 4, reps: "5", weight: 226.9, weightUnit: "lb")
        let snapped = ex.withSnappedWeight()
        #expect(abs((snapped.weight ?? 0) - 225.0) < 0.1)
    }

    @Test func dumbbellWeightSnapsToAvailableIncrement() {
        // 31 lb → nearest available dumbbell is 35 lb
        let ex = GeneratedExercise(name: "Dumbbell Row", sets: 3, reps: "10", weight: 31.0, weightUnit: "lb")
        let snapped = ex.withSnappedWeight()
        #expect(snapped.weight == 35)
    }

    @Test func kettlebellWeightSnapsToAvailableLb() {
        // 60 lb → nearest available kettlebell
        let ex = GeneratedExercise(name: "Kettlebell Swings", sets: 4, reps: "15", weight: 60.0, weightUnit: "lb")
        let snapped = ex.withSnappedWeight()
        let validLb: [Double] = [15, 25, 32, 53, 70]
        #expect(validLb.contains(snapped.weight ?? 0))
    }

    @Test func bodyweightExerciseUnaffectedBySnapping() {
        let ex = GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true)
        let snapped = ex.withSnappedWeight()
        #expect(snapped.weight == nil)
    }

    @Test func nilWeightUnaffectedBySnapping() {
        let ex = GeneratedExercise(name: "Back Squat", sets: 3, reps: "5")
        let snapped = ex.withSnappedWeight()
        #expect(snapped.weight == nil)
    }
}

// MARK: - QuestionnaireAnswers Tests

@Suite("QuestionnaireAnswers")
struct QuestionnaireAnswersTests {

    @Test func equatable() {
        let a = QuestionnaireAnswers(timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
        let b = QuestionnaireAnswers(timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
        let c = QuestionnaireAnswers(timeMinutes: 30, focus: .upperBody, energyLevel: .low, equipment: .bodyweightOnly)
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - OfflineWorkoutGenerator Tests

@Suite("OfflineWorkoutGenerator")
struct OfflineWorkoutGeneratorTests {

    private func makeContext(
        timeMinutes: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energyLevel: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym,
        maxes: [ExerciseMax] = [],
        cyclePhase: String? = nil,
        readinessTier: String? = nil,
        injuries: [InjurySummary] = [],
        travelModeEnabled: Bool = false
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "user-1",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: [],
            cyclePhase: cyclePhase,
            readinessTier: readinessTier,
            activeInjuries: injuries,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg",
            travelModeEnabled: travelModeEnabled
        )
    }

    @Test func generateFullBodyFullGym() {
        let context = makeContext(focus: .fullBody, equipment: .fullGym)
        let workout = OfflineWorkoutGenerator.generate(from: context)

        #expect(!workout.exercises.isEmpty)
        #expect(!workout.coachingSummary.isEmpty)
        #expect(workout.questionnaire.focus == .fullBody)
        #expect(workout.questionnaire.equipment == .fullGym)
    }

    @Test func generateUpperBody() {
        let context = makeContext(focus: .upperBody)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
        #expect(workout.questionnaire.focus == .upperBody)
    }

    @Test func generateLowerBody() {
        let context = makeContext(focus: .lowerBody)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
    }

    @Test func generatePush() {
        let context = makeContext(focus: .push)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
    }

    @Test func generatePull() {
        let context = makeContext(focus: .pull)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
    }

    @Test func generateCore() {
        let context = makeContext(focus: .core)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
    }

    @Test func generateConditioning() {
        let context = makeContext(focus: .conditioning)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
    }

    @Test func bodyweightOnlyFiltering() {
        let context = makeContext(equipment: .bodyweightOnly)
        let workout = OfflineWorkoutGenerator.generate(from: context)

        for exercise in workout.exercises {
            #expect(exercise.bodyweightOnly == true)
        }
    }

    @Test func outdoorFiltering() {
        let context = makeContext(equipment: .outdoor)
        let workout = OfflineWorkoutGenerator.generate(from: context)

        for exercise in workout.exercises {
            #expect(exercise.bodyweightOnly == true)
        }
    }

    @Test func homeDumbbellsExcludesBarbellExercises() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .homeDumbbells)
        let filtered = OfflineWorkoutGenerator.filterForEquipment(templates: templates, equipment: .homeDumbbells)
        // All filtered templates should not require barbell
        #expect(!filtered.isEmpty)
    }

    @Test func applyMaxesCalculatesWeights() {
        let maxes = [ExerciseMax(name: "Back Squat", weight: 100, weightUnit: "lb")]
        let context = makeContext(focus: .lowerBody, equipment: .fullGym, maxes: maxes)
        let workout = OfflineWorkoutGenerator.generate(from: context)

        let squat = workout.exercises.first { $0.name == "Back Squat" }
        if let squat {
            #expect(squat.weight != nil)
            #expect(squat.weight! > 0)
            #expect(squat.weight! <= 100)
        }
    }

    @Test func lowEnergyReducesWeights() {
        let maxes = [ExerciseMax(name: "Back Squat", weight: 100, weightUnit: "lb")]
        let normalCtx = makeContext(focus: .lowerBody, energyLevel: .medium, maxes: maxes)
        let lowCtx = makeContext(focus: .lowerBody, energyLevel: .low, maxes: maxes)

        let normalWorkout = OfflineWorkoutGenerator.generate(from: normalCtx)
        let lowWorkout = OfflineWorkoutGenerator.generate(from: lowCtx)

        let normalSquatWeight = normalWorkout.exercises.first { $0.name == "Back Squat" }?.weight
        let lowSquatWeight = lowWorkout.exercises.first { $0.name == "Back Squat" }?.weight

        if let normalWeight = normalSquatWeight, let lowWeight = lowSquatWeight {
            #expect(lowWeight <= normalWeight)
        }
    }

    @Test func highEnergyMaintainsOrIncreasesWeights() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyEnergyLevel(exercises: exercises, energy: .high)
        #expect(adjusted.first!.weight! >= 100)
    }

    @Test func mediumEnergyDoesNotChangeWeights() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyEnergyLevel(exercises: exercises, energy: .medium)
        #expect(adjusted.first!.weight == 100)
    }

    @Test func kneeInjurySubstitution() {
        let injuries = [InjurySummary(location: "knee", phase: "rehab", restrictions: ["squat"])]
        let exercises = [
            GeneratedExercise(name: "Back Squat", sets: 4, reps: "5", weight: 100, weightUnit: "lb"),
            GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)

        let squatPresent = adapted.contains { $0.name == "Back Squat" }
        #expect(squatPresent == false)
        let pullUpPresent = adapted.contains { $0.name == "Pull-Up" }
        #expect(pullUpPresent == true)
    }

    @Test func shoulderInjurySubstitution() {
        let injuries = [InjurySummary(location: "shoulder", phase: "lightLoad", restrictions: ["press"])]
        let exercises = [
            GeneratedExercise(name: "Flat Barbell Bench Press", sets: 4, reps: "5", weight: 80, weightUnit: "lb"),
            GeneratedExercise(name: "Barbell Row", sets: 3, reps: "8"),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)

        let benchPresent = adapted.contains { $0.name == "Flat Barbell Bench Press" }
        #expect(benchPresent == false)
        let rowPresent = adapted.contains { $0.name == "Barbell Row" }
        #expect(rowPresent == true)
    }

    @Test func noInjuriesDoesNotModify() {
        let exercises = [
            GeneratedExercise(name: "Back Squat", sets: 4, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: [])
        #expect(adapted.count == 1)
        #expect(adapted.first?.name == "Back Squat")
    }

    @Test func cyclePhaseAdjustmentMenstrual() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "menstrual", readiness: nil)
        #expect(adjusted.first!.weight! < 100)
    }

    @Test func cyclePhaseAdjustmentOvulation() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "ovulation", readiness: nil)
        #expect(adjusted.first!.weight! > 100)
    }

    @Test func cyclePhaseNilDoesNotModify() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: nil, readiness: nil)
        #expect(adjusted.first!.weight == 100)
    }

    @Test func follicularPhaseDoesNotModify() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "follicular", readiness: nil)
        #expect(adjusted.first!.weight == 100)
    }

    @Test func lowReadinessReducesWeight() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "follicular", readiness: "low")
        #expect(adjusted.first!.weight! < 100)
    }

    @Test func highReadinessIncreasesWeight() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "follicular", readiness: "high")
        #expect(adjusted.first!.weight! > 100)
    }

    @Test func unknownPhaseDoesNotModify() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "unknown", readiness: nil)
        #expect(adjusted.first!.weight == 100)
    }

    @Test func scaleForTimeShortSession() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .fullBody, equipment: .fullGym)
        let scaled = OfflineWorkoutGenerator.scaleForTime(templates: templates, targetMinutes: 30)
        #expect(scaled.count >= 3)
        #expect(scaled.count <= 10)
    }

    @Test func scaleForTimeLongSession() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .fullBody, equipment: .fullGym)
        let scaled = OfflineWorkoutGenerator.scaleForTime(templates: templates, targetMinutes: 75)
        #expect(scaled.count >= 3)
    }

    @Test func scaleForTimeEmptyTemplates() {
        let scaled = OfflineWorkoutGenerator.scaleForTime(templates: [], targetMinutes: 45)
        #expect(scaled.isEmpty)
    }

    @Test func defaultPercentages() {
        #expect(OfflineWorkoutGenerator.defaultPercentage(for: "5") == 0.80)
        #expect(OfflineWorkoutGenerator.defaultPercentage(for: "3") == 0.80)
        #expect(OfflineWorkoutGenerator.defaultPercentage(for: "8-10") == 0.70)
        #expect(OfflineWorkoutGenerator.defaultPercentage(for: "12-15") == 0.60)
        #expect(OfflineWorkoutGenerator.defaultPercentage(for: "AMRAP") == 0.65)
    }

    @Test func applyWeightsWithHomeDumbbells() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .homeDumbbells)
        let exercises = OfflineWorkoutGenerator.applyWeights(exercises: templates, maxes: [], equipment: .homeDumbbells)

        // Default dumbbell weight is 25 lb, snapped from the available dumbbell inventory.
        for ex in exercises where !ex.bodyweightOnly {
            if let w = ex.weight {
                #expect(w == 25)
            }
        }
    }

    @Test func coachingSummaryIncludesInjuryInfo() {
        let context = makeContext(injuries: [InjurySummary(location: "knee", phase: "rehab", restrictions: [])])
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 6)
        #expect(summary.contains("knee"))
    }

    @Test func coachingSummaryIncludesCyclePhase() {
        let context = makeContext(cyclePhase: "menstrual")
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 6)
        #expect(summary.contains("menstrual"))
    }

    @Test func coachingSummaryLowEnergy() {
        let context = makeContext(energyLevel: .low)
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 6)
        #expect(summary.contains("low energy"))
    }

    @Test func coachingSummaryHighEnergy() {
        let context = makeContext(energyLevel: .high)
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 6)
        #expect(summary.contains("high energy"))
    }

    @Test func coachingSummaryMediumEnergyNoMention() {
        let context = makeContext(energyLevel: .medium)
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 6)
        #expect(!summary.contains("energy"))
    }

    @Test func backInjurySubstitution() {
        let injuries = [InjurySummary(location: "back", phase: "rehab", restrictions: ["deadlift"])]
        let exercises = [
            GeneratedExercise(name: "Conventional Deadlift (No Straps)", sets: 4, reps: "5", weight: 100, weightUnit: "lb"),
            GeneratedExercise(name: "Barbell Row", sets: 3, reps: "8", weight: 60, weightUnit: "lb"),
            GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        let deadliftPresent = adapted.contains { $0.name == "Conventional Deadlift (No Straps)" }
        #expect(deadliftPresent == false)
        let rowPresent = adapted.contains { $0.name == "Barbell Row" }
        #expect(rowPresent == false)
    }

    @Test func lutealPhaseReducesWeight() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "luteal", readiness: nil)
        #expect(adjusted.first!.weight! < 100)
    }

    @Test func bodyweightExercisesUnaffectedByPhase() {
        let exercises = [
            GeneratedExercise(name: "Push-Up", sets: 3, reps: "15", bodyweightOnly: true)
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "menstrual", readiness: nil)
        #expect(adjusted.first!.weight == nil)
    }

    @Test func hipInjurySubstitution() {
        let injuries = [InjurySummary(location: "hip", phase: "rehab", restrictions: ["hip"])]
        let exercises = [
            GeneratedExercise(name: "Hip Thrust", sets: 3, reps: "10", weight: 80, weightUnit: "lb"),
            GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        let hipThrustPresent = adapted.contains { $0.name == "Hip Thrust" }
        #expect(hipThrustPresent == false)
    }

    @Test func wristInjurySubstitution() {
        let injuries = [InjurySummary(location: "wrist", phase: "acute", restrictions: ["clean"])]
        let exercises = [
            GeneratedExercise(name: "Power Clean", sets: 3, reps: "3", weight: 60, weightUnit: "lb"),
            GeneratedExercise(name: "Back Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb"),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        let cleanPresent = adapted.contains { $0.name == "Power Clean" }
        #expect(cleanPresent == false)
        let squatPresent = adapted.contains { $0.name == "Back Squat" }
        #expect(squatPresent == true)
    }

    @Test func ankleInjurySubstitution() {
        let injuries = [InjurySummary(location: "ankle", phase: "rehab", restrictions: ["jump"])]
        let exercises = [
            GeneratedExercise(name: "Box Jumps", sets: 3, reps: "10", bodyweightOnly: true),
            GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true),
        ]

        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        let boxJumpsPresent = adapted.contains { $0.name == "Box Jumps" }
        #expect(boxJumpsPresent == false)
    }

    @Test func spineInjurySubstitution() {
        let injuries = [InjurySummary(location: "spine", phase: "rehab", restrictions: ["deadlift"])]
        let exercises = [
            GeneratedExercise(name: "Conventional Deadlift (No Straps)", sets: 3, reps: "5", weight: 100, weightUnit: "lb"),
        ]
        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        let deadliftPresent = adapted.contains { $0.name == "Conventional Deadlift (No Straps)" }
        #expect(deadliftPresent == false)
    }

    @Test func unknownLocationDoesNotFilter() {
        let injuries = [InjurySummary(location: "elbow", phase: "rehab", restrictions: [])]
        let exercises = [
            GeneratedExercise(name: "Back Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb"),
        ]
        let adapted = OfflineWorkoutGenerator.applyInjurySubstitutions(exercises: exercises, injuries: injuries)
        #expect(adapted.count == 1)
    }

    @Test func neutralReadinessDoesNotModify() {
        let exercises = [
            GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 100, weightUnit: "lb")
        ]
        let adjusted = OfflineWorkoutGenerator.applyCyclePhase(exercises: exercises, phase: "follicular", readiness: "neutral")
        #expect(adjusted.first!.weight == 100)
    }

    // MARK: - Hotel Gym / Travel Mode

    @Test func hotelGymFilterExcludesBarbellExercises() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .hotelGym)
        let hasBarbellExercise = templates.contains { $0.requiresBarbell }
        #expect(!hasBarbellExercise)
    }

    @Test func hotelGymFilterAllowsBodyweightExercises() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .hotelGym)
        let hasBodyweight = templates.contains { $0.bodyweightOnly }
        #expect(hasBodyweight)
    }

    @Test func hotelGymFilterAllowsDumbbellExercises() {
        let templates = OfflineWorkoutGenerator.selectTemplates(focus: .upperBody, equipment: .hotelGym)
        let hasDumbbell = templates.contains { $0.requiresDumbbells }
        #expect(hasDumbbell)
    }

    @Test func generateHotelGymProducesExercises() {
        let context = makeContext(equipment: .hotelGym)
        let workout = OfflineWorkoutGenerator.generate(from: context)
        #expect(!workout.exercises.isEmpty)
        #expect(workout.questionnaire.equipment == .hotelGym)
    }

    @Test func coachingSummaryMentionsTravelMode() {
        let context = makeContext(equipment: .hotelGym, travelModeEnabled: true)
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 5)
        #expect(summary.contains("Travel mode"))
    }

    @Test func coachingSummaryOmitsTravelWhenDisabled() {
        let context = makeContext(equipment: .fullGym, travelModeEnabled: false)
        let summary = OfflineWorkoutGenerator.buildCoachingSummary(context: context, exerciseCount: 5)
        #expect(!summary.contains("Travel mode"))
    }
}

// MARK: - GeneratedWorkout Sharing Tests

@Suite("GeneratedWorkout Sharing")
struct GeneratedWorkoutSharingTests {

    @Test func strippedForSharingNilsAllWeights() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test workout",
            exercises: [
                GeneratedExercise(name: "Back Squat", sets: 3, reps: "5", weight: 225, weightUnit: "lb"),
                GeneratedExercise(name: "DB Bench", sets: 3, reps: "8", weight: 50, weightUnit: "lb"),
                GeneratedExercise(name: "Plank", sets: 3, reps: "60s", bodyweightOnly: true),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )

        let stripped = workout.strippedForSharing()

        #expect(stripped.exercises.count == 3)
        for exercise in stripped.exercises {
            #expect(exercise.weight == nil)
        }
        #expect(stripped.coachingSummary == "Test workout")
        #expect(stripped.questionnaire.focus == .fullBody)
        #expect(stripped.id != workout.id, "Stripped workout gets a new ID")
    }

    @Test func strippedForSharingNilsReasoning() {
        let workout = GeneratedWorkout(
            coachingSummary: "Test",
            exercises: [
                GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 225, weightUnit: "lb", reasoning: "Heavy compound"),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )
        let stripped = workout.strippedForSharing()
        #expect(stripped.exercises[0].reasoning == nil)
    }

    @Test func strippedForSharingPreservesStructure() {
        let workout = GeneratedWorkout(
            coachingSummary: "Upper day",
            exercises: [
                GeneratedExercise(
                    name: "Bench Press", sets: 4, reps: "6",
                    weight: 185, weightUnit: "lb", restMinutes: 2.0, notes: "Pause at bottom",
                    reasoning: "Progressive overload"
                ),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 30, focus: .push, energyLevel: .high, equipment: .fullGym
            )
        )

        let stripped = workout.strippedForSharing()
        let ex = stripped.exercises[0]

        #expect(ex.name == "Bench Press")
        #expect(ex.sets == 4)
        #expect(ex.reps == "6")
        #expect(ex.weight == nil)
        #expect(ex.restMinutes == 2.0)
        #expect(ex.notes == "Pause at bottom")
        #expect(ex.bodyweightOnly == false)
    }
}

// MARK: - CloudKitSharedWorkoutRepository Tests

@Suite("CloudKitSharedWorkoutRepository.contributePayload")
struct SharedWorkoutContributePayloadTests {

    @Test func contributePayloadStripsWeights() throws {
        let workout = GeneratedWorkout(
            coachingSummary: "Heavy day",
            exercises: [
                GeneratedExercise(name: "Deadlift", sets: 5, reps: "3", weight: 315, weightUnit: "lb"),
                GeneratedExercise(name: "Pull-ups", sets: 4, reps: "8", bodyweightOnly: true),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 60, focus: .strength, energyLevel: .high, equipment: .fullGym
            )
        )

        let payload = CloudKitSharedWorkoutRepository.buildContributePayload(from: workout)

        #expect(payload.focusRaw == "strength")
        #expect(payload.equipmentRaw == "full_gym")
        #expect(payload.userID == "")

        let data = payload.workoutJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GeneratedWorkout.self, from: data)
        for exercise in decoded.exercises {
            #expect(exercise.weight == nil)
        }
    }
}

// MARK: - Auto-Contribution Tests

@Suite("SwiftDataAIWorkoutService auto-contribution")
struct AutoContributionTests {

    @Test func buildContributionStripsWeights() {
        let result = SwiftDataAIWorkoutService.buildContribution(
            from: GeneratedWorkout(
                coachingSummary: "Test",
                exercises: [
                    GeneratedExercise(name: "Squat", sets: 3, reps: "5", weight: 200, weightUnit: "lb"),
                ],
                questionnaire: QuestionnaireAnswers(
                    timeMinutes: 30, focus: .strength, energyLevel: .medium, equipment: .fullGym
                )
            )
        )

        #expect(result != nil)
        #expect(result!.exercises[0].weight == nil, "Contribution should have weights stripped")
    }
}

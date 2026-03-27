import Foundation
import SwiftData
import FoundationModels

// MARK: - AIWorkoutServiceError

enum AIWorkoutServiceError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case networkError(Int)
    case noContent
}

// MARK: - AppleIntelligenceWorkoutService

@MainActor
final class AppleIntelligenceWorkoutService: AIWorkoutServiceProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout: GeneratedWorkout

        if await supportsOnDeviceGeneration() {
            do {
                workout = try await generateWithFoundationModels(context: context)
            } catch {
                print("Foundation Models generation failed: \(error). Using offline generator.")
                workout = OfflineWorkoutGenerator.generate(from: context)
            }
        } else {
            workout = OfflineWorkoutGenerator.generate(from: context)
        }

        guard let record = GeneratedWorkoutRecord.from(workout, userID: context.userID) else {
            throw AIWorkoutServiceError.encodingFailed
        }
        modelContext.insert(record)
        try? modelContext.save()
        return workout
    }

    // MARK: - Foundation Models

    private func supportsOnDeviceGeneration() async -> Bool {
        SystemLanguageModel.default.isAvailable
    }

    private func generateWithFoundationModels(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let prompt = Self.buildPrompt(context: context)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: AIWorkoutOutput.self)
        let output = response.content

        guard !output.exercises.isEmpty else {
            return OfflineWorkoutGenerator.generate(from: context)
        }

        return WorkoutPostProcessor.process(raw: output, context: context)
    }

    static func buildPrompt(context: WorkoutGenerationContext) -> String {
        let exerciseCount = exerciseCountRange(for: context.timeMinutes)

        var parts: [String] = [
            "Design a \(context.timeMinutes)-minute \(context.focus.displayName) workout.",
            "Include \(exerciseCount) exercises.",
            equipmentConstraint(for: context.equipment),
            focusConstraint(for: context.focus),
            experienceConstraint(for: context.experienceLevel),
            energyConstraint(for: context.energyLevel),
            "Goal: \(context.primaryGoal).",
            "Specify exact rep counts for each exercise as a single integer (e.g. 8, not 8-10). Use 0 for AMRAP.",
            "Set bodyweightOnly to true ONLY for exercises that need zero equipment."
        ]

        if let phase = context.cyclePhase {
            parts.append(cyclePhaseGuidance(for: phase))
        }

        if !context.recentWorkouts.isEmpty {
            let recentFocuses = context.recentWorkouts.prefix(5).map(\.focus).joined(separator: ", ")
            parts.append("Recent workouts focused on: \(recentFocuses). Vary the exercise selection to avoid repetition.")
        }

        if !context.activeInjuries.isEmpty {
            let injuryNotes = context.activeInjuries.map {
                "\($0.location) (\($0.phase)): \($0.restrictions.joined(separator: ", "))"
            }
            parts.append("IMPORTANT — Active injuries, do NOT prescribe exercises that aggravate these: \(injuryNotes.joined(separator: "; "))")
        }

        return parts.joined(separator: " ")
    }

    static func exerciseCountRange(for minutes: Int) -> String {
        switch minutes {
        case ...30: return "4-6"
        case 31...45: return "5-8"
        case 46...60: return "6-9"
        default: return "8-12"
        }
    }

    static func focusConstraint(for focus: WorkoutFocus) -> String {
        switch focus {
        case .upperBody:
            return "ONLY upper body exercises — chest, back, shoulders, arms. NO squats, NO lunges, NO deadlifts, NO leg exercises."
        case .lowerBody:
            return "ONLY lower body exercises — quads, hamstrings, glutes, calves. NO bench press, NO rows, NO shoulder press, NO arm exercises."
        case .push:
            return "ONLY push exercises — bench press, overhead press, push-ups, dips, tricep work. NO pulling movements."
        case .pull:
            return "ONLY pull exercises — rows, pull-ups, deadlifts, curls. NO pressing movements."
        case .core:
            return "ONLY core and abdominal exercises — planks, crunches, leg raises, rotational work. NO heavy compound lifts."
        case .conditioning:
            return "ONLY conditioning and cardio exercises — burpees, sprints, jump rope, kettlebell swings, box jumps. Focus on heart rate, not strength."
        case .fullBody:
            return "Mix of upper body, lower body, and core exercises for a balanced full-body session."
        }
    }

    static func experienceConstraint(for level: String) -> String {
        switch level.lowercased() {
        case "beginner":
            return "Beginner-friendly exercises only — basic movements, no Olympic lifts, no muscle-ups, no pistol squats, no advanced gymnastics."
        case "intermediate":
            return "Intermediate exercises — compound movements welcome, moderate complexity."
        case "advanced":
            return "Advanced exercises allowed — complex movements, Olympic lifts, and high-skill work are fine."
        default:
            return "Moderate difficulty exercises."
        }
    }

    static func energyConstraint(for energy: EnergyLevel) -> String {
        switch energy {
        case .low:
            return "Low energy day: favor lighter isolation work, fewer sets (2-3), longer rest. Avoid heavy compound lifts. Keep intensity moderate."
        case .medium:
            return "Medium energy: standard training session with a mix of compound and accessory work."
        case .high:
            return "High energy day: prioritize heavy compounds, higher volume (4-5 sets), shorter rest. Push intensity."
        }
    }

    static func cyclePhaseGuidance(for phase: String) -> String {
        switch phase.lowercased() {
        case "menstrual":
            return "Menstrual phase: reduce intensity, favor lighter weights, include mobility. Avoid maximal effort lifts."
        case "follicular":
            return "Follicular phase: great time for progressive overload and heavier compound lifts."
        case "ovulation":
            return "Ovulation phase: peak strength window. Include heavy compounds and power movements."
        case "luteal":
            return "Luteal phase: slightly reduce volume, maintain intensity. Favor steady-state over explosive work."
        default:
            return ""
        }
    }

    static func equipmentConstraint(for equipment: EquipmentAccess) -> String {
        switch equipment {
        case .bodyweightOnly:
            return "CRITICAL: Only bodyweight exercises — NO barbells, NO dumbbells, NO kettlebells, NO machines, NO weighted equipment of any kind. No deadlifts, no squats with weight, no bench press, no rows with weight. Every exercise must use only the person's body."
        case .homeDumbbells:
            return "CRITICAL: Only dumbbells and bodyweight — NO barbells, NO machines, NO cable machines, NO squat racks. No barbell deadlifts, no barbell squats, no barbell bench press."
        case .outdoor:
            return "CRITICAL: Only bodyweight exercises suitable for outdoors — NO barbells, NO dumbbells, NO machines, NO gym equipment of any kind. Think: push-ups, lunges, sprints, burpees, planks, bear crawls."
        case .fullGym:
            return "Full gym access including barbells, dumbbells, machines, and bodyweight exercises."
        }
    }

    // MARK: - History & Favorites

    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }

    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.id == workoutID }
        )
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isFavorite = isFavorite
        try? modelContext.save()
    }

    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
            predicate: #Predicate { $0.userID == userID && $0.isFavorite == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        return records.compactMap { $0.toGeneratedWorkout() }
    }
}

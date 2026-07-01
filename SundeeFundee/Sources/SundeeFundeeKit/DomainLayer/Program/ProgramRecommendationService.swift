import Foundation

public enum ProgramRecommendationKind: Equatable, Sendable {
    case program(ProgramTemplate)
    case coachPlan(equipment: EquipmentAccess)
}

public struct ProgramRecommendation: Equatable, Identifiable, Sendable {
    public let kind: ProgramRecommendationKind
    public let title: String
    public let subtitle: String
    public let reason: String
    public let score: Int

    public var id: String {
        switch kind {
        case .program(let template): return "program-\(template.stableID)"
        case .coachPlan(let equipment): return "coach-plan-\(equipment.rawValue)"
        }
    }

    public init(
        kind: ProgramRecommendationKind,
        title: String,
        subtitle: String,
        reason: String,
        score: Int
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.reason = reason
        self.score = score
    }
}

public enum ProgramRecommendationService {
    public static func recommend(
        goal: PrimaryGoal,
        experience: ExperienceLevel,
        daysPerWeek: Int,
        equipment: EquipmentAccess
    ) -> [ProgramRecommendation] {
        if equipment == .resistanceBands {
            return [
                ProgramRecommendation(
                    kind: .coachPlan(equipment: .resistanceBands),
                    title: "Bands Only Coach Plan",
                    subtitle: "\(clampedDays(daysPerWeek)) days/week",
                    reason: "Coach Plans can build around bands and bodyweight without forcing a barbell-heavy template.",
                    score: 100
                ),
                templateRecommendation(
                    .glutesCoreConditioning,
                    score: 62,
                    reason: "Closest fixed program theme, but review equipment before starting."
                )
            ]
        }

        var results = ProgramTemplate.allCases.map { template in
            templateRecommendation(
                template,
                score: score(template: template, goal: goal, experience: experience, daysPerWeek: daysPerWeek, equipment: equipment),
                reason: reason(template: template, goal: goal, experience: experience, daysPerWeek: daysPerWeek, equipment: equipment)
            )
        }

        if equipment == .bodyweightOnly || equipment == .kettlebellOnly {
            results.append(ProgramRecommendation(
                kind: .coachPlan(equipment: equipment),
                title: "\(equipment.displayName) Coach Plan",
                subtitle: "\(clampedDays(daysPerWeek)) days/week",
                reason: "A Coach Plan can honor your equipment more reliably than the fixed program library.",
                score: 92
            ))
        }

        return results.sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.title < rhs.title }
            return lhs.score > rhs.score
        }
    }

    private static func templateRecommendation(
        _ template: ProgramTemplate,
        score: Int,
        reason: String
    ) -> ProgramRecommendation {
        let defaults = templateDefaults[template]
        let subtitle: String
        if let defaults {
            subtitle = "\(defaults.durationWeeks) weeks, \(defaults.sessionsPerWeek) days/week"
        } else {
            subtitle = "Structured program"
        }
        return ProgramRecommendation(
            kind: .program(template),
            title: template.displayName,
            subtitle: subtitle,
            reason: reason,
            score: score
        )
    }

    private static func score(
        template: ProgramTemplate,
        goal: PrimaryGoal,
        experience: ExperienceLevel,
        daysPerWeek: Int,
        equipment: EquipmentAccess
    ) -> Int {
        var score = 50
        score += equipmentScore(template: template, equipment: equipment)
        score += goalScore(template: template, goal: goal)
        score += experienceScore(template: template, experience: experience)

        if let defaults = templateDefaults[template] {
            score -= abs(defaults.sessionsPerWeek - clampedDays(daysPerWeek)) * 4
        }

        return score
    }

    private static func equipmentScore(template: ProgramTemplate, equipment: EquipmentAccess) -> Int {
        switch (template, equipment) {
        case (.hundredPushUps, .bodyweightOnly):
            return 46
        case (.dumbbellStrength, .homeDumbbells):
            return 45
        case (.hundredPushUps, .fullGym), (.hundredPushUps, .homeDumbbells):
            return 10
        case (.beginnerStrength, .fullGym):
            return 22
        case (.glutesCoreConditioning, .fullGym), (.firstMargarita, .fullGym):
            return 14
        case (.russianSquat, .fullGym):
            return 8
        case (.russianSquat, _):
            return -32
        case (.firstMargarita, _):
            return equipment == .bodyweightOnly ? -24 : -4
        default:
            return equipment == .kettlebellOnly || equipment == .bodyweightOnly ? -14 : 0
        }
    }

    private static func goalScore(template: ProgramTemplate, goal: PrimaryGoal) -> Int {
        switch (template, goal) {
        case (.beginnerStrength, .strength), (.dumbbellStrength, .strength), (.russianSquat, .strength):
            return 14
        case (.hundredPushUps, .endurance):
            return 22
        case (.glutesCoreConditioning, .hypertrophy), (.glutesCoreConditioning, .endurance), (.glutesCoreConditioning, .weightLoss):
            return 14
        case (.firstMargarita, .strength), (.firstMargarita, .hypertrophy):
            return 8
        default:
            return 0
        }
    }

    private static func experienceScore(template: ProgramTemplate, experience: ExperienceLevel) -> Int {
        switch (template, experience) {
        case (.beginnerStrength, .beginner):
            return 22
        case (.dumbbellStrength, .beginner):
            return 6
        case (.hundredPushUps, .intermediate):
            return 18
        case (.hundredPushUps, .beginner):
            return 4
        case (.russianSquat, .advanced):
            return 22
        case (.russianSquat, .beginner):
            return -35
        case (.firstMargarita, .intermediate), (.firstMargarita, .advanced):
            return 8
        default:
            return 0
        }
    }

    private static func reason(
        template: ProgramTemplate,
        goal: PrimaryGoal,
        experience: ExperienceLevel,
        daysPerWeek: Int,
        equipment: EquipmentAccess
    ) -> String {
        if template == .dumbbellStrength && equipment == .homeDumbbells {
            return "Best match for dumbbell access, strength work, and a \(clampedDays(daysPerWeek))-day week."
        }
        if template == .hundredPushUps && equipment == .bodyweightOnly {
            return "Best match for bodyweight access, upper-body endurance, and a \(clampedDays(daysPerWeek))-day week."
        }
        if template == .hundredPushUps {
            return "Good fit for building push-up volume without max testing or gym equipment."
        }
        if template == .beginnerStrength && experience == .beginner {
            return "Best match for building the main patterns without advanced loading."
        }
        if template == .russianSquat {
            return "Strong barbell-specific plan for advanced squat focus."
        }
        if template == .glutesCoreConditioning {
            return "Good fit for conditioning, hypertrophy, and lower-body emphasis."
        }
        return "Matches part of your goal, experience, and schedule."
    }

    private static func clampedDays(_ days: Int) -> Int {
        min(max(days, 1), 7)
    }
}

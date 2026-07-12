import Foundation

public enum ReadinessAssessmentService {
    public static let modelVersion = "readiness-v1"

    public static func assess(_ context: DailyTrainingContext) -> ReadinessAssessment? {
        let groups: [(ReadinessScoreGroup, Int?)] = [
            (.physiological, physiologicalScore(context.physiological)),
            (.subjective, subjectiveScore(context.subjective)),
            (.training, trainingScore(context.training)),
            (.symptomsAndPain, symptomsAndPainScore(context.subjective, pain: context.pain))
        ]
        let present = groups.compactMap { group, score in score.map { (group, $0) } }
        guard !present.isEmpty else { return nil }

        let presentWeight = present.reduce(0.0) { $0 + $1.0.weight }
        let weighted = present.reduce(0.0) { $0 + Double($1.1) * $1.0.weight }
        let total = ReadinessBaselineNormalizer.clamp(Int((weighted / presentWeight).rounded()))
        let signalState = ReadinessState.from(score: total)
        let painCap: ReadinessState = (context.pain?.intensity ?? 0) >= 7 ? .recover : .ready
        let confidence = confidence(for: context)
        let confidenceAdjusted: ReadinessState = confidence == .low ? .maintain : signalState
        let state = ReadinessState.stricter(confidenceAdjusted, painCap)
        let signals = signalAvailability(context)
        let reasons = reasonCodes(context)

        return ReadinessAssessment(assessmentDate: context.assessmentDate, state: state, totalScore: total,
                                   confidence: confidence, subScores: Dictionary(uniqueKeysWithValues: present),
                                   availableSignals: signals.available, missingSignals: signals.missing,
                                   staleSignals: signals.stale, positiveReasons: reasons.positive,
                                   cautionReasons: reasons.caution, modelVersion: modelVersion)
    }

    private static func physiologicalScore(_ value: PhysiologicalReadinessSnapshot) -> Int? {
        var scores: [Int] = []
        if let sleep = value.sleepHours { scores.append(ReadinessBaselineNormalizer.sleepScore(hours: sleep.currentValue, history: sleep.baselineValues)) }
        if let hrv = value.hrvMilliseconds, let score = ReadinessBaselineNormalizer.personalScore(hrv, direction: .higherIsBetter) { scores.append(score) }
        if let rhr = value.restingHeartRateBPM, let score = ReadinessBaselineNormalizer.personalScore(rhr, direction: .lowerIsBetter) { scores.append(score) }
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func subjectiveScore(_ value: SubjectiveReadinessSnapshot) -> Int? {
        let scores = [value.energy.map { $0 * 10 }, value.fatigue.map { (10 - $0) * 10 }, value.soreness.map { (10 - $0) * 10 }, value.stress.map { (10 - $0) * 10 }, value.perceivedReadiness.map { $0 * 10 }]
            .compactMap { $0 }.map(ReadinessBaselineNormalizer.clamp)
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func trainingScore(_ value: TrainingReadinessSnapshot) -> Int? {
        guard value.completedWorkoutsInLast28Days >= 4 else { return nil }
        var scores: [Int] = []
        if let ratio = value.weeklyLoadRatio { scores.append(ReadinessBaselineNormalizer.clamp(ratio <= 1 ? 80 : ratio < 1.5 ? Int((80 - (ratio - 1) * 100).rounded()) : 20)) }
        if let rpe = value.averageSessionRPE { scores.append(ReadinessBaselineNormalizer.clamp(Int((100 - max(0, rpe - 5) * 15).rounded()))) }
        if let rate = value.rightForTodayRate { scores.append(ReadinessBaselineNormalizer.clamp(Int((rate * 100).rounded()))) }
        return ReadinessBaselineNormalizer.mean(scores)
    }

    private static func symptomsAndPainScore(_ subjective: SubjectiveReadinessSnapshot, pain: PainReadinessSnapshot?) -> Int? {
        ReadinessBaselineNormalizer.mean([subjective.cramps.map { (10 - $0) * 10 }, pain.map { (10 - $0.intensity) * 10 }].compactMap { $0 }.map(ReadinessBaselineNormalizer.clamp))
    }
}

extension ReadinessAssessmentService {
    private static func confidence(for context: DailyTrainingContext) -> ReadinessConfidence {
        // HRV and resting heart rate are only score-contributing once their
        // personal baselines have learned enough observations.  Keep them out
        // of coverage while learning, even though their presence still keeps
        // the confidence from being considered fully mature below.
        let physiologicalCount = [
            context.physiological.sleepHours.map { _ in true },
            context.physiological.hrvMilliseconds.map { $0.baselineValues.count >= ReadinessBaselineNormalizer.minimumPersonalObservations },
            context.physiological.restingHeartRateBPM.map { $0.baselineValues.count >= ReadinessBaselineNormalizer.minimumPersonalObservations }
        ].compactMap { $0 }.filter { $0 }.count
        let subjectiveCount = [context.subjective.energy, context.subjective.fatigue, context.subjective.soreness, context.subjective.stress, context.subjective.perceivedReadiness].compactMap { $0 }.count
        let trainingCount = [context.training.weeklyLoadRatio, context.training.averageSessionRPE, context.training.rightForTodayRate].compactMap { $0 }.count
        let symptomsCount = [context.subjective.cramps, context.pain?.intensity].compactMap { $0 }.count
        let coverage = 0.30 * Double(physiologicalCount) / 3 + 0.30 * Double(subjectiveCount) / 5 + 0.25 * Double(trainingCount) / 3 + 0.15 * Double(symptomsCount) / 2
        let learning = [context.physiological.sleepHours, context.physiological.hrvMilliseconds, context.physiological.restingHeartRateBPM].compactMap { $0 }.contains { $0.baselineValues.count < ReadinessBaselineNormalizer.minimumPersonalObservations }
        if coverage >= 0.75 && physiologicalCount > 0 && subjectiveCount > 0 && !learning {
            return context.training.completedWorkoutsInLast28Days >= 4 ? .high : .medium
        }
        if coverage >= 0.45 && physiologicalCount > 0 && subjectiveCount > 0 { return .medium }
        return .low
    }

    private static func signalAvailability(_ context: DailyTrainingContext) -> (available: [ReadinessSignalID], missing: [ReadinessSignalID], stale: [ReadinessSignalID]) {
        let trainingHistoryMature = context.training.completedWorkoutsInLast28Days >= 4
        let pairs: [(ReadinessSignalID, Bool)] = [(.sleep, context.physiological.sleepHours != nil), (.hrv, context.physiological.hrvMilliseconds != nil), (.restingHeartRate, context.physiological.restingHeartRateBPM != nil), (.energy, context.subjective.energy != nil), (.fatigue, context.subjective.fatigue != nil), (.stress, context.subjective.stress != nil), (.soreness, context.subjective.soreness != nil), (.perceivedReadiness, context.subjective.perceivedReadiness != nil), (.trainingLoad, trainingHistoryMature && context.training.weeklyLoadRatio != nil), (.sessionRPE, trainingHistoryMature && context.training.averageSessionRPE != nil), (.rightForToday, trainingHistoryMature && context.training.rightForTodayRate != nil), (.cramps, context.subjective.cramps != nil), (.pain, context.pain != nil)]
        let available = pairs.filter { $0.1 }.map { $0.0 }, missing = pairs.filter { !$0.1 }.map { $0.0 }
        let stale = (physiologicalSignals(context) + painSignals(context))
            .filter { context.assessmentDate.timeIntervalSince($0.1) > 48 * 60 * 60 }
            .map { $0.0 }
        return (available.sorted { $0.rawValue < $1.rawValue }, missing.sorted { $0.rawValue < $1.rawValue }, stale.sorted { $0.rawValue < $1.rawValue })
    }

    private static func physiologicalSignals(_ context: DailyTrainingContext) -> [(ReadinessSignalID, Date)] {
        [(.sleep, context.physiological.sleepHours?.observedAt), (.hrv, context.physiological.hrvMilliseconds?.observedAt), (.restingHeartRate, context.physiological.restingHeartRateBPM?.observedAt)].compactMap { id, date in date.map { (id, $0) } }
    }

    private static func painSignals(_ context: DailyTrainingContext) -> [(ReadinessSignalID, Date)] {
        context.pain.map { [(.pain, $0.observedAt)] } ?? []
    }

    private static func reasonCodes(_ context: DailyTrainingContext) -> (positive: [ReadinessReasonCode], caution: [ReadinessReasonCode]) {
        var positive: [ReadinessReasonCode] = [], caution: [ReadinessReasonCode] = []
        if let sleep = context.physiological.sleepHours { let score = ReadinessBaselineNormalizer.sleepScore(hours: sleep.currentValue, history: sleep.baselineValues); if score >= 75 { positive.append(.goodSleep) }; if score < 60 { caution.append(.sleepBelowBaseline) } }
        if let hrv = context.physiological.hrvMilliseconds, let score = ReadinessBaselineNormalizer.personalScore(hrv, direction: .higherIsBetter) { if score >= 75 { positive.append(.hrvAtOrAboveBaseline) }; if score < 60 { caution.append(.hrvBelowBaseline) } }
        if let rhr = context.physiological.restingHeartRateBPM, let score = ReadinessBaselineNormalizer.personalScore(rhr, direction: .lowerIsBetter) { if score >= 75 { positive.append(.restingHeartRateNormal) }; if score < 60 { caution.append(.restingHeartRateElevated) } }
        if let energy = context.subjective.energy, energy <= 3 { caution.append(.lowEnergy) }; if let energy = context.subjective.energy, energy >= 7 { positive.append(.highEnergy) }
        if let fatigue = context.subjective.fatigue, fatigue >= 7 { caution.append(.highFatigue) }; if let stress = context.subjective.stress, stress >= 7 { caution.append(.highStress) }; if let soreness = context.subjective.soreness, soreness >= 7 { caution.append(.highSoreness) }
        if context.training.completedWorkoutsInLast28Days >= 4 {
            if let ratio = context.training.weeklyLoadRatio, (0.8...1.2).contains(ratio) { positive.append(.balancedTrainingLoad) }
            if let ratio = context.training.weeklyLoadRatio, ratio >= 1.3 { caution.append(.highTrainingLoad) }
        }
        if let pain = context.pain, pain.intensity >= 7 { caution.append(.highPain) }
        if !signalAvailability(context).missing.isEmpty { caution.append(.missingSignals) }; if confidence(for: context) != .high { caution.append(.stillLearning) }
        return (Array(Set(positive)).sorted { $0.rawValue < $1.rawValue }, Array(Set(caution)).sorted { $0.rawValue < $1.rawValue })
    }
}

// SundeeFundeeKit - Public API Exports
//
// This file documents the public API surface of SundeeFundeeKit.
// All types and functions listed below are available for use by app targets.

// MARK: - Models

// Workout - Represents a complete training session
// - Properties: id, date, name, exercises, notes, duration, completedAt
// - Computed: totalVolume, isComplete

// Exercise - A single exercise within a workout
// - Properties: id, name, category, bodyweight, targetSets, notes, restMinutes

// ExerciseSet - A single set of an exercise
// - Properties: id, reps, prescribedWeight, type, completedWeight, actualReps, isComplete

// ExerciseType - The type of rep scheme
// - Cases: fixed, amrap, range(min, max), text(String)

// ExerciseCategory - Classification of exercise intensity
// - Cases: compound, isolation, accessory, warmup, cooldown

// ExerciseValue - Discriminated union for flexible rep/set values
// - Cases: fixed(Int), amrap, range(Int, Int), text(String)
// - Computed: description
// - Conformance: Equatable, Codable, Sendable

// MARK: - Calculations

// defaultPercentage(reps:) -> Double
// Maps rep count to percentage of 1RM (1 rep = 100%, 12 reps = 60%)

// calculatePrescribedWeight(max:reps:energyMultiplier:cycleMultiplier:) -> Double
// Calculates prescribed weight based on 1RM, reps, energy level, and cycle phase

// roundToNearest(_:increment:) -> Double
// Rounds a value to the nearest increment (e.g., 5 lbs)

// calculatePlates(targetWeight:barWeight:) -> [Plate]
// Calculates which plates to load on one side of a barbell

// MARK: - Unit Conversion

// lbsToKg(_:) -> Double
// Converts pounds to kilograms

// kgToLbs(_:) -> Double
// Converts kilograms to pounds

// MARK: - Supporting Types

// Plate - Represents a plate weight and count per side
// - Properties: weight (Double), count (Int)

// standardPlates - Array of standard plate sizes in lbs [45, 35, 25, 10, 5, 2.5]

// MARK: - Cycle Phase & Calculations

// CyclePhase - The four phases of the menstrual cycle
// - Cases: menstrual, follicular, ovulation, luteal
// - Conformance: String, Codable, Sendable

// CycleSettings - Settings for cycle phase calculations
// - Properties: averageCycleLengthDays (default: 28), averagePeriodLengthDays (default: 5), lutealPhaseLengthDays (default: 14)
// - Conformance: Codable, Sendable

// PeriodLog - A period log entry
// - Properties: startDate, endDate (optional)
// - Conformance: Codable, Sendable

// PhaseBoundary - Boundary days within a cycle (1-indexed)
// - Properties: start, end
// - Conformance: Sendable

// CycleStatusResult - Result of cycle status calculation
// - Properties: currentPhase, cycleDay, daysUntilNextPhase, predictedNextPeriod, phaseStartDate, phaseEndDate
// - Conformance: Sendable

// PhaseRecommendation - Training recommendation for a cycle phase
// - Properties: phase, title, description, trainingFocus, intensityRecommendation, exercisesToEmphasize, exercisesToAvoid
// - Conformance: Sendable

// getPhaseBoundaries(settings:) -> [CyclePhase: PhaseBoundary]
// Calculate phase day boundaries for given cycle settings

// calculateCycleStatus(periodLogs:settings:referenceDate:) -> CycleStatusResult?
// Calculate current cycle status from period logs and settings

// getPhaseRecommendation(phase:) -> PhaseRecommendation
// Get training recommendation for a cycle phase

// MARK: - Cycle Calendar

// getPhaseForDay(_:settings:) -> CyclePhase
// Get cycle phase for a specific cycle day

// getPhaseAdjustmentSummary(_:) -> String
// Get adjustment summary text for a phase

// getPhaseExplanation(_:) -> String
// Get detailed explanation text for a phase

// CalendarDayData - Data for a single calendar day
// - Properties: day, date, phase (optional), isToday, isPeriodDay, phaseColor
// - Conformance: Sendable

// getCycleCalendarData(periodLogs:settings:month:year:) -> [CalendarDayData]
// Generate calendar data for a month with cycle phase overlays

// MARK: - Cycle Adaptation Policy

// AdaptationReadinessTier - Readiness tier from score
// - Cases: low, neutral, high
// - Conformance: String, Sendable

// AdaptationConfidence - Confidence level from cycle data availability
// - Cases: low, medium, high
// - Conformance: String, Sendable

// PhaseMultipliers - Phase-specific multipliers for load, sets, reps
// - Properties: load, sets, reps (all Double)
// - Conformance: Sendable

// phaseMultipliers - Dictionary mapping CyclePhase to PhaseMultipliers
// - menstrual: 0.90/0.90/0.90, follicular: 1.0/1.0/1.0, ovulation: 1.12/1.05/0.95, luteal: 0.97/0.95/0.92

// resolveReadinessTier(score:) -> AdaptationReadinessTier
// Resolve readiness tier from a 0-10 score

// resolveConfidence(currentPhase:lastKnownPhase:periodLogCount:lastPeriodStart:referenceDate:) -> AdaptationConfidence
// Resolve confidence level from cycle data availability

// applyPhaseAdjustment(sets:reps:percent1RM:phase:readinessTier:confidence:) -> (sets: ExerciseValue, reps: ExerciseValue, percent1RM: Double?)
// Apply cycle phase adjustment to exercise parameters

// MARK: - Benchmark Models

// BenchmarkIntensity - Intensity level (1-5)
// - Cases: one, two, three, four, five
// - Conformance: Int, Codable, Sendable

// BenchmarkScoringType - How a benchmark is scored
// - Cases: time, roundsAndReps, load, reps, calories, distance
// - Conformance: String, Codable, Sendable

// ReadinessTier - Readiness tier for attempting a benchmark
// - Cases: peak, moderate, recovery
// - Conformance: String, Codable, Sendable

// BenchmarkCategory - Category of benchmark
// - Cases: sundeeFundee, classicWODs, strength, endurance, gymnastics, generalFitness
// - Conformance: String, Codable, Sendable, CaseIterable

// BenchmarkDefinition - A predefined or custom benchmark
// - Properties: id, name, category, workoutDescription, scoringType, isPredefined, sortOrder, intensity?, movementTags?, equipment?, timeDomain?, coachNotes?
// - Conformance: Codable, Sendable, Identifiable

// BenchmarkResult - Result of a benchmark attempt
// - Properties: id, benchmarkId, benchmarkName, score, notes?, date, cyclePhase?
// - Conformance: Codable, Sendable, Identifiable

// BenchmarkReadiness - Readiness assessment for attempting a benchmark
// - Properties: tier, reason, recommendation, phaseMultiplier, emoji, color
// - Conformance: Codable, Sendable

// AttemptWindow - Best attempt window based on cycle
// - Properties: startDate, endDate, reason
// - Conformance: Codable, Sendable

// MARK: - Benchmark Catalog

// BenchmarkCatalog - Static catalog of all benchmark definitions
// - static allBenchmarks: [BenchmarkDefinition]
// - static func benchmarks(in category: String) -> [BenchmarkDefinition]
// - static func benchmark(id: String) -> BenchmarkDefinition?
// - static let categories: [String]

// MARK: - Benchmark Readiness

// BenchmarkReadinessCalculator
// - static func calculateReadiness(phase:benchmarkIntensity:movementTags:) -> BenchmarkReadiness
// - static func getBestAttemptWindow(averageCycleLength:lastPeriodStart:) -> AttemptWindow

// MARK: - Body Location & Recovery Phase

// BodyRegion - Body region for injury/pain tracking
// - Properties: id, displayName, engineKey
// - Conformance: Codable, Sendable, Identifiable, Hashable

// BodyRegions - All supported body regions
// - static let allRegions: [BodyRegion] (17 regions)
// - static func region(id:) -> BodyRegion?
// - static func parseRegions(_:) -> [BodyRegion] (comma-separated string)
// - static func encodeRegions(_:) -> String (back to comma-separated)

// RecoveryPhase - Recovery phase for an injury (canonical ordering)
// - Cases: acute, rehab, lightLoad, returnToPlay, resolved
// - Properties: displayName, orderValue
// - Conformance: String, Codable, Sendable, CaseIterable, Comparable

// MARK: - Injury Models

// Injury - An injury or chronic condition
// - Properties: id, locationIds, name, recoveryPhase, dateCreated, phaseUpdated, notes?
// - Computed: bodyRegions
// - Conformance: Codable, Sendable, Identifiable

// DailyPainLog - Pain log entry
// - Properties: id, locationIds, intensity, painType, date, notes?
// - Computed: bodyRegions, isValidIntensity
// - Conformance: Codable, Sendable, Identifiable

// PainType - Type/category of pain
// - Cases: acute, chronic, soreness, stiffness, sharp, dull, aching, other
// - Properties: displayName, color
// - Conformance: String, Codable, Sendable, CaseIterable

// PainLevel - Pain level category for display
// - Cases: none, mild, moderate, severe, extreme
// - static func from(intensity:) -> PainLevel
// - Properties: displayName, color
// - Conformance: String, Codable, Sendable

// MARK: - Injury Support

// LoadMultipliers - Load, sets, reps multipliers for injury adaptation
// - Properties: load, sets, reps
// - Conformance: Sendable

// loadMultipliers - Dictionary mapping RecoveryPhase to LoadMultipliers

// adjustExerciseValueByMultiplier(_:multiplier:) -> ExerciseValue
// Adjust an ExerciseValue by a multiplier

// adjustLoad(_:multiplier:) -> Double?
// Adjust a load percentage by a multiplier

// PainLog - Pain log for trend analysis
// - Properties: id, injuryId, intensity, recordedAt
// - Conformance: Codable, Sendable

// TrendResult - Result of pain trend analysis
// - Properties: direction, average, recentAverage, delta
// - Conformance: Sendable

// analyzePainTrend(logs:windowSize:) -> TrendResult
// Analyze pain trend over a window of logs

// hasRecentLog(logs:referenceDate:withinHours:) -> Bool
// Check if a recent pain log exists

// sparklineData(logs:count:) -> [Int]
// Get sparkline data for pain visualization

// TransitionSuggestion - Suggestion for recovery phase transition
// - Properties: currentPhase, suggestedPhase
// - Conformance: Sendable

// evaluateTransition(injuryId:currentPhase:painLogs:) -> TransitionSuggestion?
// Evaluate if an injury is ready for phase transition

// MARK: - Injury Adaptation Engine

// InjuryAdaptationEngine - Modifies workouts based on active injuries
// - static func isContraindicated(exerciseName:exerciseCategory:injuries:) -> Bool
// - static func getRegressions(exerciseName:injuries:) -> [String]
// - static func calculateLoadMultiplier(baseLoad:injuries:) -> Double
// - static func getRecommendedExercises(for:) -> [String]
// - static func getContraindicatedKeywords(for:) -> [String]

// MARK: - Exercise Catalog

// WeightliftingCategory - Categories of weightlifting exercises
// - Cases: squat, hinge, press, pull, olympic, accessory
// - Conformance: String, Codable, Sendable, CaseIterable

// WeightliftingEntry - A weightlifting exercise entry
// - Properties: id, name, category, isPrimary, aliases, defaultSets, defaultReps
// - Conformance: Sendable, Identifiable

// weightliftingExercises - Array of 59 weightlifting exercises

// isWeightliftingExercise(_:) -> Bool
// Check if an exercise ID is a weightlifting exercise

// ConditioningScoringType - How a conditioning exercise is scored
// - Cases: time, reps, calories, distance, rounds, weight
// - Conformance: String, Codable, Sendable

// ConditioningEntry - A conditioning exercise entry
// - Properties: id, name, scoringType, defaultDuration, description
// - Conformance: Sendable, Identifiable

// conditioningExercises - Array of 31 conditioning exercises

// isConditioningExercise(_:) -> Bool
// Check if an exercise ID is a conditioning exercise

// conditioningScoringType(for:) -> ConditioningScoringType?
// Get scoring type for a conditioning exercise

// formatConditioningValue(_:type:) -> String
// Format a conditioning score for display

// isBetterConditioningScore(newValue:existingValue:type:) -> Bool
// Compare conditioning scores (lower time = better, higher everything else = better)

// MARK: - Celebration Events

// CelebrationEvent - Types of achievements that trigger celebrations
// - Cases: firstWorkout, personalRecord(exerciseName, weight), streakMilestone(days), programComplete(programName),
//          benchmarkPR(benchmarkName, score), consistencyStreak(weeks), totalVolumeRecord(volume)
// - Conformance: Sendable

// celebrationTitle(_:) -> String
// Get display title for a celebration event

// celebrationSubtitle(_:unit:) -> String
// Get display subtitle for a celebration event

// MARK: - AI Workout

// WorkoutFocus - Focus area for AI workout generation
// - Cases: strength, hypertrophy, endurance, power, conditioning
// - Conformance: String, Codable, Sendable

// EnergyLevel - User's current energy level
// - Cases: low, medium, high
// - Conformance: String, Codable, Sendable

// EquipmentAccess - Available equipment
// - Cases: full, limited, bodyweight
// - Conformance: String, Codable, Sendable

// QuestionnaireAnswers - AI workout generation parameters
// - Properties: focus, energyLevel, equipmentAccess, targetDuration, injuries
// - Conformance: Codable, Sendable

// GeneratedExercise - An AI-generated exercise
// - Properties: id, name, sets, reps, prescribedWeight, restMinutes, notes, isBodyweight
// - Conformance: Codable, Sendable, Identifiable

// GeneratedWorkout - An AI-generated workout
// - Properties: id, name, exercises, notes, estimatedMinutes, focus
// - Conformance: Codable, Sendable, Identifiable

// ExerciseMax - A user's 1RM for an exercise
// - Properties: exerciseName, weight
// - Conformance: Sendable

// extractMuscleGroups(_:) -> [String]
// Extract muscle groups targeted by exercises

// aiDefaultPercentage(reps:) -> Double
// Map rep string to percentage of 1RM for AI workouts

// assignRestMinutes(bodyweight:reps:) -> Double
// Assign rest time based on exercise type and rep range

// totalEstimatedMinutes(_:) -> Int
// Estimate total workout duration

// energyMultiplier(_:) -> Double
// Get load multiplier for energy level (low: 0.85, medium: 1.0, high: 1.05)

// aiCyclePhaseMultiplier(_:) -> Double
// Get load multiplier for cycle phase

// applyWeights(exercises:maxes:energyMult:cycleMult:) -> [GeneratedExercise]
// Calculate prescribed weights from 1RM data

// findMatchingMax(_:maxes:) -> ExerciseMax?
// Fuzzy match exercise name to user's 1RM data

// MARK: - Program Template Generator

// ProgramTemplate - Available program templates
// - Cases: strengthBasics, hypertrophyPhase1, powerbuilding, cycleAwareStrength, beginnerFullBody
// - Conformance: String, Codable, Sendable, CaseIterable

// TemplateDefaults - Default configuration for a program template
// - Properties: durationWeeks, sessionsPerWeek, difficulty, description
// - Conformance: Sendable

// templateDefaults - Dictionary mapping ProgramTemplate to TemplateDefaults

// GeneratedProgramExercise - Exercise in a generated program
// - Properties: name, sets, reps, percent1RM, restMinutes, notes
// - Conformance: Sendable

// GeneratedProgramSession - A single training session
// - Properties: name, exercises
// - Conformance: Sendable

// GeneratedProgramWeek - A week of training sessions
// - Properties: weekNumber, sessions
// - Conformance: Sendable

// GeneratedProgramPhase - A training phase (e.g., hypertrophy, strength)
// - Properties: name, weeks
// - Conformance: Sendable

// GeneratedProgram - A complete generated program
// - Properties: name, template, durationWeeks, sessionsPerWeek, difficulty, description, phases
// - Conformance: Sendable

// generateProgram(template:name:durationWeeks:sessionsPerWeek:) -> GeneratedProgram
// Generate a complete program from a template

// MARK: - Data Layer Protocols

// DataClientProtocol - Protocol for data persistence operations
// - fetch<T>(recordType: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
// - save<T>(_ records: [T], recordType: String) async throws
// - delete(recordIDs: [CKRecord.ID], recordType: String) async throws
// Default extensions: fetchAll, save (single), delete (single)
// Conformance: Sendable

// DataError - Errors from data layer operations
// - Cases: recordNotFound(recordID: CKRecord.ID), networkError(underlying: Error?),
//          permissionDenied, invalidData(description: String)
// - Conformance: Error, LocalizedError, Sendable

// HealthClientProtocol - Protocol for HealthKit operations
// - isAvailable: Bool
// - requestAuthorization(readTypes: Set<HKObjectType>, writeTypes: Set<HKSampleType>) async throws
// - fetchWorkouts(startDate: Date?, endDate: Date?, limit: Int?) async throws -> [HKWorkout]
// - fetchMenstrualCycles(startDate: Date?, endDate: Date?, limit: Int?) async throws -> [HKCategorySample]
// - fetchActiveEnergy(startDate: Date?, endDate: Date?, limit: Int?) async throws -> [HKQuantitySample]
// - fetchRestingHeartRate(startDate: Date?, endDate: Date?, limit: Int?) async throws -> [HKQuantitySample]
// - fetchHeartRateVariability(startDate: Date?, endDate: Date?, limit: Int?) async throws -> [HKQuantitySample]
// - saveWorkout(startDate: Date, endDate: Date, totalEnergyBurned: Double?, exercises: [String]?) async throws
// Conformance: Sendable

// HealthError - Errors from HealthKit operations
// - Cases: notAvailable, authorizationDenied, noData(type: String),
//          queryFailed(underlying: Error?), saveFailed(underlying: Error?)
// - Conformance: Error, LocalizedError, Sendable

// MARK: - Data Layer Clients

// CloudKitClient - Actor-based CloudKit data client
// - init(containerIdentifier: String)
// - Methods from DataClientProtocol
// Thread-safe via actor isolation

// MockCloudKitClient - In-memory mock for testing
// - init()
// - seed(recordType: String, records: [T]) - Pre-populate test data
// - Methods from DataClientProtocol
// Thread-safe via serial queue

// HealthKitClient - Actor-based HealthKit client
// - init(healthStore: HKHealthStore? = nil)
// - standardReadTypes: Set<HKObjectType> - Standard read permissions
// - standardWriteTypes: Set<HKSampleType> - Standard write permissions
// - Methods from HealthClientProtocol
// Thread-safe via actor isolation

// MockHealthKitClient - In-memory mock for testing
// - init()
// - seedWorkouts(_ workouts: [HKWorkout]) - Pre-populate test workouts
// - seedCycles(_ cycles: [HKCategorySample]) - Pre-populate menstrual cycles
// - seedSamples(_ samples: [HKSample]) - Pre-populate quantity samples
// - Methods from HealthClientProtocol
// Thread-safe via serial queue

// WorkoutConfiguration - Configuration for saving workouts to HealthKit
// - Properties: activityType, startDate, endDate, totalEnergyBurned, totalDistance, metadata

// MARK: - Authentication

// AppleAuthClientProtocol - Protocol for Sign in with Apple
// - signIn(scopes: AppleAuthScope) async throws -> AppleAuthResult
// - getCredentialState(forUserID: String) async throws -> AppleCredentialState
// - signOut() async
// Conformance: Sendable

// AppleAuthClient - Actor-based Sign in with Apple client
// - init(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding? = nil)
// - setPresentationContextProvider(_ provider:) - Set UI context
// - credentialRevokedNotification: Notification.Name - Observe for credential revocation
// - Methods from AppleAuthClientProtocol
// Thread-safe via actor isolation

// AppleAuthResult - Result from successful Sign in with Apple
// - Properties: userID, email, fullName, identityToken, authorizationCode, authorizedScopes
// - Computed: givenName, familyName, identityTokenString, authorizationCodeString,
//             displayName, hasEmailScope, hasFullNameScope
// - Conformance: Sendable, Equatable

// AppleAuthScope - Option set for authorization scopes
// - Options: none, email, fullName, all
// - Conformance: OptionSet, Sendable, Equatable

// AppleCredentialState - State of user's Apple credential
// - Cases: authorized, revoked, notFound, transferred
// - Conformance: Sendable, Equatable

// MARK: - Subscription

// SubscriptionTier - Available subscription tiers
// - Cases: free, plus, premium
// - Properties: maxLifts, maxInjuries, maxHistoryDays, dailyAIGenerations,
//              hasCustomBenchmarks, hasPainTrends, hasRehabSessions, hasAICoachMemory, hasPlateauDetection
// - Conformance: String, Sendable, Equatable, Codable, CaseIterable

// SubscriptionStatus - Current status of a subscription
// - Cases: active, pastDue, paused, cancelled, expired
// - Property: hasAccess (Bool)
// - Conformance: String, Sendable, Equatable, Codable

// SubscriptionInfo - Complete subscription information
// - Properties: tier, status, startDate, expiryDate, willRenew, entitlementId, originalTransactionId
// - Computed: hasAccess, daysUntilExpiry
// - Conformance: Sendable, Equatable, Codable

// SubscriptionError - Errors from subscription operations
// - Cases: notSubscribed, subscriptionExpired(expiryDate: Date?), purchaseFailed(underlying: Error?),
//          purchaseCancelled, restoreFailed(underlying: Error?), noPurchasesToRestore,
//          productUnavailable(productId: String), storeNotAvailable, networkError(underlying: Error?),
//          invalidReceipt
// - Conformance: Error, LocalizedError, Sendable, Equatable

// SubscriptionClientProtocol - Protocol for subscription management
// - currentSubscription: SubscriptionInfo? { get async }
// - getSubscriptionInfo() async throws -> SubscriptionInfo
// - purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo
// - restorePurchases() async throws -> SubscriptionInfo
// - presentManageSubscriptions() async throws
// - isTierAvailable(_ tier:) async -> Bool
// - getPrice(for tier:) async -> String?
// Conformance: Sendable

// RevenueCatClient - Actor-based RevenueCat subscription client (stub)
// - init(apiKey: String)
// - identify(userId: String) async - Associate user with RevenueCat
// - logout() async - Clear user association
// - Methods from SubscriptionClientProtocol
// Thread-safe via actor isolation
// Note: Full implementation requires RevenueCat SDK dependency

// MockSubscriptionClient - Actor-based mock for testing
// - init(subscription: SubscriptionInfo? = nil)
// - seedSubscription(_ subscription: SubscriptionInfo?) async - Set subscription state
// - setAvailableTiers(_ tiers: [SubscriptionTier: String]) async - Set available tiers/prices
// - setSimulatePurchaseFailure(_ value: Bool) async - Simulate purchase failures
// - setSimulateRestoreFailure(_ value: Bool) async - Simulate restore failures
// - setSimulatedError(_ error: SubscriptionError) async - Set error to throw
// - Methods from SubscriptionClientProtocol
// Convenience factories: .plus(), .premium(), .expired(tier:)
// Thread-safe via actor isolation

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

// MARK: - Data Layer Protocols

// DataClientProtocol - Protocol for data persistence operations
// - fetch<T>(recordType: String, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [T]
// - fetch<T>(recordType: String, recordID: String) async throws -> T
// - save<T>(recordType: String, recordID: String?, data: T) async throws -> String
// - delete(recordType: String, recordID: String) async throws
// Conformance: Sendable

// DataError - Errors from data layer operations
// - Cases: recordNotFound(recordID: CKRecord.ID), networkError(underlying: Error?),
//          permissionDenied, invalidData(description: String)
// - Conformance: Error, LocalizedError, Sendable

// HealthClientProtocol - Protocol for HealthKit operations
// - isAvailable: Bool
// - requestAuthorization(readTypes: Set<HKObjectType>, writeTypes: Set<HKSampleType>) async throws
// - fetchWorkouts(limit: Int?) async throws -> [HKWorkout]
// - fetchMenstrualCycles(limit: Int?) async throws -> [HKCategorySample]
// - fetchActiveEnergy(days: Int, limit: Int?) async throws -> [HKQuantitySample]
// - fetchRestingHeartRate(days: Int, limit: Int?) async throws -> [HKQuantitySample]
// - fetchHeartRateVariability(days: Int, limit: Int?) async throws -> [HKQuantitySample]
// - saveWorkout(_ configuration: WorkoutConfiguration) async throws -> HKWorkout
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

//
// SubscriptionTier - Available subscription tiers
// - Cases: free, plus, premium
// - Properties: maxLifts, maxInjuries, maxHistoryDays, dailyAIGenerations, hasCustomBenchmarks, hasPainTrends
//                 hasRehabSessions, hasAICoachMemory, hasPlateauDetection
//
// SubscriptionStatus - State of a subscription
// - Cases: active, pastDue, paused, cancelled, expired
// - Computed: hasAccess
//
// SubscriptionInfo - Complete subscription information
// - Properties: tier, status, startDate, expiryDate, willRenew, entitlementId, originalTransactionId
// - Computed: hasAccess, daysUntilExpiry
// - Conformance: Sendable, Equatable, Codable
//
// SubscriptionClientProtocol - Protocol for subscription management
// - currentSubscription: SubscriptionInfo?
// - getSubscriptionInfo() async throws -> SubscriptionInfo
// - purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo
// - restorePurchases() async throws -> SubscriptionInfo
// - presentManageSubscriptions() async throws
// - isTierAvailable(_ tier: SubscriptionTier) async -> Bool
// - getPrice(for tier: SubscriptionTier) async -> String?
// Conformance: Sendable
//
// SubscriptionError - Errors from subscription operations
// - Cases: notSubscribed, subscriptionExpired(expiryDate: Date?), purchaseFailed(underlying: Error?),
//          purchaseCancelled, restoreFailed(underlying: Error?), noPurchasesToRestore,
//          productUnavailable(productId: String), storeNotAvailable, networkError(underlying: Error?),
//          invalidReceipt
// - Conformance: Error, LocalizedError, Sendable, Equatable
//
// RevenueCatClient - Actor-based RevenueCat subscription client (STUB - requires RevenueCat SDK)
// - init(apiKey: String)
// - identify(userId: String) async - Associate user with subscription data
// - logout() async - Clear user data
// - Methods from SubscriptionClientProtocol
// Thread-safe via actor isolation
//
// MockSubscriptionClient - Actor-based mock for testing
// - init(subscription: SubscriptionInfo? = nil)
// - seedSubscription(_ subscription: SubscriptionInfo?) - Set test data
// - setAvailableTiers(_ tiers: [SubscriptionTier: String]) - Set prices
// - setSimulatePurchaseFailure(_ value: Bool) - Simulate failures
// - setSimulateRestoreFailure(_ value: Bool) - Simulate failures
// - setSimulatedError(_ error: SubscriptionError) - Set error to throw
// - Methods from SubscriptionClientProtocol
// Convenience factories: .plus(), .premium(), .expired(tier:) - Pre-configured mock clients


// MARK: - Subscription Layer

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

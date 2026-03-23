# Android Native App Plan - Sundee Fundee

## Overview

Building a native Android version of the Sundee Fundee iOS app, which is a hormonal-cycle-aware strength training tracker. The Android app will provide feature parity with the iOS version using native Android technologies.

## Architecture Mapping (iOS → Android)

| iOS Component | Android Equivalent |
|---------------|-------------------|
| SwiftUI | Jetpack Compose |
| SwiftData | Room Database |
| CloudKit | Firebase Cloud Firestore |
| Sign in with Apple | Google Sign-In + Firebase Auth |
| StoreKit | Google Play Billing |
| HealthKit | Google Health Connect |
| XcodeGen | Gradle (Kotlin DSL) |
| @Observable | StateFlow/Compose State |

## Tech Stack

- **Language**: Kotlin 2.0
- **UI Framework**: Jetpack Compose with Material 3
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 35
- **Architecture**: Clean Architecture + MVVM
- **DI**: Hilt
- **Async**: Kotlin Coroutines + Flow
- **Local DB**: Room
- **Cloud**: Firebase (Auth, Firestore, Crashlytics)
- **Payments**: Google Play Billing
- **Health**: Google Health Connect

---

## Phase 1: Project Setup

### 1.1 Create Android Project Structure
```
android/
├── app/
│   └── src/main/
│       ├── java/com/sundeefundee/
│       │   ├── App.kt
│       │   ├── MainActivity.kt
│       │   ├── di/                    # Hilt modules
│       │   ├── data/
│       │   │   ├── local/             # Room entities, DAOs
│       │   │   ├── remote/            # Firebase services
│       │   │   └── repository/        # Repository implementations
│       │   ├── domain/
│       │   │   ├── model/             # Domain models (shared with iOS logic)
│       │   │   ├── repository/        # Repository interfaces
│       │   │   └── usecase/           # Business logic
│       │   ├── ui/
│       │   │   ├── theme/
│       │   │   ├── navigation/
│       │   │   ├── components/
│       │   │   └── features/
│       │   │       ├── auth/
│       │   │       ├── onboarding/
│       │   │       ├── dashboard/
│       │   │       ├── programs/
│       │   │       ├── workouts/
│       │   │       ├── cycle/
│       │   │       ├── maxes/
│       │   │       ├── benchmarks/
│       │   │       └── settings/
│       │   └── util/
│       └── res/
├── build.gradle.kts
└── settings.gradle.kts
```

### 1.2 Configure Gradle Dependencies
- Jetpack Compose BOM
- Room Database
- Hilt for DI
- Firebase BOM (Auth, Firestore, Crashlytics)
- Google Play Billing
- Google Health Connect
- Kotlin Coroutines
- Navigation Compose

### 1.3 Setup Firebase Project
- Create Android app in Firebase Console
- Add `google-services.json` to project
- Enable Authentication (Google Sign-In provider)
- Enable Cloud Firestore
- Configure Crashlytics

---

## Phase 2: Data Layer

### 2.1 Create Room Entities (from iOS SwiftData models)
Convert these iOS models to Android Room entities:
- `User` → `UserEntity`
- `Benchmark`, `BenchmarkDefinition` → `BenchmarkEntity`, `BenchmarkDefinitionEntity`
- `CompletedWorkout` → `CompletedWorkoutEntity`
- `Maxes` → `MaxEntity`
- `InjuryProfile` → `InjuryProfileEntity`
- `PainLog` → `PainLogEntity`
- `ActiveCycle` → `ActiveCycleEntity`
- `EnrolledProgram` → `EnrolledProgramEntity`
- `GeneratedWorkoutRecord` → `GeneratedWorkoutRecordEntity`
- `PeriodLog` → `PeriodLogEntity`
- `CycleSettings` → `CycleSettingsEntity`

### 2.2 Create DAOs
For each entity, create Room DAOs with:
- `getAll()`, `getById()`, `insert()`, `update()`, `delete()`
- Query methods for specific use cases

### 2.3 Setup Firestore Collections
Mirror the CloudKit schema to Firestore:
- `users/{userId}` - User data
- `users/{userId}/completedWorkouts/{workoutId}`
- `users/{userId}/maxes/{maxId}`
- `programs/{programId}` - Public programs
- `benchmarks/{benchmarkId}` - Public benchmarks

### 2.4 Implement Repository Layer
Create repository interfaces and implementations:
- `UserRepository` - CRUD for user data
- `WorkoutRepository` - CRUD for workouts
- `ProgramRepository` - Fetch programs (Firestore + bundled JSON fallback)
- `BenchmarkRepository` - Fetch benchmarks
- `MaxRepository` - CRUD for max lifts
- `CycleRepository` - Cycle tracking data
- `HealthRepository` - Health Connect integration

---

## Phase 3: Domain Layer

### 3.1 Translate iOS Domain Logic to Kotlin
The following iOS domain classes have pure Swift logic that can be directly translated:
- `CycleCalculations` → `CycleCalculations.kt`
- `CycleAdaptationPolicy` → `CycleAdaptationPolicy.kt`
- `InjuryAdaptationEngine` → `InjuryAdaptationEngine.kt`
- `PainTrendAnalyzer` → `PainTrendAnalyzer.kt`
- `PhaseTransitionAdvisor` → `PhaseTransitionAdvisor.kt`
- `WeightCalculations` → `WeightCalculations.kt`
- `PlateCalculation` → `PlateCalculation.kt`
- `BenchmarkCatalog` → `BenchmarkCatalog.kt`
- `CycleProgramGenerator` → `CycleProgramGenerator.kt`
- `RehabSessionGenerator` → `RehabSessionGenerator.kt`
- `OfflineWorkoutGenerator` → `OfflineWorkoutGenerator.kt`
- `LoadAdjustmentPolicy` → `LoadAdjustmentPolicy.kt`

### 3.2 Create Use Cases
For each feature, create use cases:
- `GetDashboardUseCase`
- `LogWorkoutUseCase`
- `CalculateCyclePhaseUseCase`
- `GenerateWorkoutUseCase`
- `UpdateMaxesUseCase`
- `ManageSubscriptionUseCase`

---

## Phase 4: Authentication

### 4.1 Implement Google Sign-In
- Configure Google Sign-In in Firebase Console
- Add `credentials.json` (OAuth client)
- Implement `GoogleSignInClient` in Android
- Handle sign-in flow in `AuthViewModel`

### 4.2 Create Auth State Management
- `AuthState` - sealed class (Loading, SignedIn, SignedOut, Guest)
- `AuthRepository` - handle auth state
- `AuthViewModel` - manage auth UI state

### 4.3 Keychain/Secure Storage
- Use `EncryptedSharedPreferences` for storing auth tokens
- Implement `SecureStorage` interface for platform abstraction

---

## Phase 5: UI Layer

### 5.1 Setup Compose Theme
Match iOS Art Deco theme:
- Primary: Navy (#1B365D)
- Secondary: Cream (#F5F1E6)
- Accent: Orange (#E67E22)
- Typography: Custom fonts matching iOS

### 5.2 Navigation Structure
```
BottomNav
├── Dashboard
├── Programs
├── Workouts
├── Cycle
└── Profile (Settings, Maxes, Benchmarks)
```

### 5.3 Screen Implementations

#### Auth Screens
- `SignInScreen` - Google Sign-In button
- `OnboardingScreen` - Multi-step onboarding flow

#### Main Screens
- `DashboardScreen` - Today's workout, cycle status, streak
- `ProgramsScreen` - Program list with enrollment
- `ProgramDetailScreen` - Program details, WODs
- `WorkoutExecutionScreen` - WOD timer, exercise list
- `WorkoutSummaryScreen` - Post-workout logging
- `CycleTrackingScreen` - Period logging, phase visualization
- `MaxesScreen` - Lift tracking with PRs
- `BenchmarksScreen` - Benchmark list and logging
- `BenchmarkDetailScreen` - Benchmark history, scoring
- `SettingsScreen` - Profile, units, notifications, subscription

### 5.4 Shared Components
- `SpicyRatingView` → `SpicyRatingComponent`
- `CelebrationOverlayView` → `CelebrationOverlay`
- `PremiumBadge` → `PremiumBadge`
- `BodyMapView` → `BodyMapScreen`

---

## Phase 6: Subscriptions (Google Play Billing)

### 6.1 Setup Google Play Billing
- Create products in Google Play Console (same IDs as App Store)
  - `com.sundeefundee.sub.plus.monthly`
  - `com.sundeefundee.sub.plus.annual`
  - `com.sundeefundee.sub.premium.monthly`
  - `com.sundeefundee.sub.premium.annual`
- Add `BillingClient` to app
- Implement `BillingClientStateListener`
- Handle purchases with `PurchasesUpdatedListener`

### 6.2 Subscription UI
- `PaywallScreen` - Subscription tiers display
- `ManageSubscriptionScreen` - Current subscription management

### 6.3 Entitlement Checks
- Cache entitlement status locally
- Verify with backend (Firebase Function) for secure checks

---

## Phase 7: Health Connect Integration

### 7.1 Setup Health Connect
- Add Health Connect permissions to manifest
- Request permissions at runtime
- Declare data types: Exercise, Workout, Body Metrics

### 7.2 Read/Write Data
- `ReadWorkoutsUseCase` - Fetch workouts from Health Connect
- `WriteWorkoutUseCase` - Log completed workouts
- Sync readiness score based on HRV/resting heart rate

---

## Phase 8: Notifications

### 8.1 Firebase Cloud Messaging
- Add `google-services.json` with FCM enabled
- Implement `FirebaseMessagingService`
- Handle push token registration

### 8.2 Local Notifications
- WorkManager for scheduling
- Notification channel setup
- Workout reminders, cycle phase alerts

---

## Phase 9: CI/CD

### 9.1 GitHub Actions Workflow
```yaml
name: Android CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - uses: gradle/gradle-build-action@v2
      - run: ./gradlew assembleDebug
      - run: ./gradlew test
```

### 9.2 Google Play Publishing
- Setup Play App Signing
- Create release signing key
- Configure fastlane or Gradle Play Publisher

---

## Key Implementation Notes

### iOS ↔ Android Feature Parity Checklist
- [ ] Sign in with Apple → Google Sign-In
- [ ] SwiftData → Room
- [ ] CloudKit → Firestore
- [ ] StoreKit → Google Play Billing
- [ ] HealthKit → Health Connect
- [ ] Keychain → EncryptedSharedPreferences
- [ ] Onboarding flow (5+ screens)
- [ ] Dashboard with cycle awareness
- [ ] Program enrollment and tracking
- [ ] WOD execution with timer
- [ ] Benchmark logging and history
- [ ] Max lifts PR tracking
- [ ] Pain/injury logging
- [ ] Subscription paywall
- [ ] Crash reporting (Crashlytics)

### Shared Business Logic
The domain layer (`CycleCalculations`, `WeightCalculations`, etc.) is pure logic that should be:
1. Extracted from iOS app
2. Placed in a shared module (`sundee-fundee-domain`)
3. Used by both iOS (via Swift Package) and Android (via Kotlin library)

### Data Model Differences
- iOS uses `String` raw values for enums (CloudKit requirement)
- Android/Room can use proper enum types
- Firestore documents use `Map<String, Any>` - needs careful mapping

---

## Execution Order

1. **Project Setup** - Gradle, Firebase config, shell project builds
2. **Auth** - Google Sign-In, basic navigation
3. **Data Layer** - Room entities, DAOs, repositories
4. **Domain Layer** - Kotlin translations of iOS business logic
5. **Core Features** - Dashboard, Programs, Workouts, Cycle tracking
6. **Secondary Features** - Maxes, Benchmarks, Settings
7. **Integrations** - Health Connect, Notifications
8. **Subscriptions** - Google Play Billing, Paywall
9. **Polish** - Animations, accessibility, performance
10. **CI/CD** - Build automation, testing

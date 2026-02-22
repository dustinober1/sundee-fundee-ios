# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Install dependencies
cd flutter_app && flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/domain/weight_calculations_test.dart

# Run the app (guest mode / no Firebase)
flutter run

# Run the app with Firebase enabled
flutter run --dart-define=ENABLE_FIREBASE=true

# Build release artifacts
flutter build web --release
flutter build appbundle --release
flutter build ipa --release --no-codesign
```

## Overview

Cross-platform strength training app with hormonal cycle awareness. Built with Flutter and Firebase for iOS, Android, and Web. Key features:
- Periodized training programs with 1RM-based weight prescriptions
- Menstrual cycle phase tracking with training recommendations
- Set-by-set workout logging with PR detection
- Guest mode for offline-first usage

**Requirements**: Flutter 3.41+, Dart 3.11+, Firebase CLI, FlutterFire CLI

## Tech Stack
- **UI**: Flutter (iOS, Android, Web)
- **Data**: Cloud Firestore (with offline persistence)
- **Auth**: Firebase Auth (Apple, Google, Email/Password, Guest)
- **State**: Riverpod
- **Routing**: GoRouter
- **Analytics**: Firebase Analytics & Crashlytics

## Project Structure

```
flutter_app/lib/
├── main.dart                     # Entry point
├── bootstrap.dart                # Firebase init & app startup
├── firebase_options.dart         # Generated Firebase config
├── app/                          # App shell, router, theme
├── domain/                       # Core business logic
│   ├── enums.dart                # Shared enumerations
│   ├── models/                   # Data models (Firestore serialization)
│   └── calculations/             # WeightCalculations, CycleCalculations
├── features/                     # Feature modules
│   ├── auth/                     # Firebase Auth + guest mode
│   │   ├── data/                 # AuthRepository, GuestModeStore
│   │   ├── domain/               # AuthState, AuthSession
│   │   ├── presentation/         # SignInScreen, OnboardingScreen, LoadingScreen
│   │   └── providers.dart        # Riverpod providers
│   ├── dashboard/                # Dashboard UI
│   ├── repositories/             # Firestore repositories
│   │   ├── data/                 # FirestoreWorkoutRepository, etc.
│   │   ├── domain/               # Repository interfaces
│   │   └── providers.dart        # Riverpod providers
│   ├── migration/                # Legacy data migration
│   ├── observability/            # TelemetryService (Analytics/Crashlytics)
│   ├── settings/                 # User settings
│   ├── shell/                    # Main tab navigation
│   ├── shared/                   # Shared widgets
│   └── storage/                  # Firebase Cloud Storage
└── firebase/                     # Firebase bootstrap
```

## Auth Flow

GoRouter redirects based on `authSessionStreamProvider`:
1. **loading** → LoadingScreen
2. **unauthenticated** → SignInScreen (Apple / Google / Guest)
3. **needsOnboarding** → OnboardingScreen (name, experience level, goals)
4. **authenticated / guest** → MainShellScreen

## Key Patterns

### Data Models
Plain Dart classes with Firestore serialization:
```dart
class UserModel {
  final String id;
  final String name;
  // ...
  factory UserModel.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}
```

### Riverpod Providers
Feature modules expose providers for DI:
```dart
final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});
```

### Firebase Feature Flag
Firebase is gated behind a compile-time flag:
```dart
const bool firebaseEnabled = bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: false);
```
When disabled, all Firebase providers return `null` and the app runs in guest mode.

### Calculation Namespaces
Pure business logic in `domain/calculations/`:
- `WeightCalculations` — roundToNearestFive, calculateTargetWeight, getNextRecommendedWeight
- `CycleCalculations` — calculateCycleStatus, getPhaseBoundaries, getPhaseRecommendation

### Repositories
Firestore access is abstracted behind interfaces:
- `WorkoutRepository` / `FirestoreWorkoutRepository`
- `CycleRepository` / `FirestoreCycleRepository`
- `LiftRepository` / `FirestoreLiftRepository`
- `RecordRepository` / `FirestoreRecordRepository`
- `CustomProgramRepository` / `FirestoreCustomProgramRepository`

## Firebase Backend (Root Level)

| File | Purpose |
|------|---------|
| `firebase.json` | Firestore, Storage, Hosting config |
| `.firebaserc` | Project alias (`sundee-fundee`) |
| `firestore.rules` | Security rules (user-scoped) |
| `firestore.indexes.json` | Composite indexes |
| `storage.rules` | Storage security rules |

## Firestore Data Schema

- `users/{userId}` — User profile and settings
- `users/{userId}/workouts/{workoutId}` — Workout logs
- `users/{userId}/completedSets/{setId}` — Completed sets
- `users/{userId}/maxLifts/{liftId}` — 1RM data
- `users/{userId}/oneRepMaxes/{ormId}` — ORM history
- `users/{userId}/records/{recordId}` — Personal records
- `users/{userId}/cycles/{cycleDoc}` — Cycle tracking data
- `users/{userId}/customPrograms/{programDoc}` — Custom programs
- `programCatalog/{programId}` — Public program catalog (read-only)

## Cycle-Based Training Recommendations

`CycleCalculations.getPhaseRecommendation(phase)` returns training guidance per menstrual phase:
- **menstrual**: Low intensity, recovery focus
- **follicular**: Moderate, building strength
- **ovulation**: Peak intensity, PR attempts
- **luteal**: Maintenance, technique work

## Where to Start

| Task | Entry Point |
|------|-------------|
| Weight calculation logic | `lib/domain/calculations/weight_calculations.dart` |
| Cycle tracking features | `lib/domain/calculations/cycle_calculations.dart` |
| Data models | `lib/domain/models/` |
| Auth changes | `lib/features/auth/` |
| Add new Firestore repository | `lib/features/repositories/` |
| UI views | `lib/features/*/presentation/` |
| Firebase config | `firebase/firebase_bootstrap.dart`, root `firebase.json` |

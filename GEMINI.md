# Sundee-Fundee Project Context

**Sundee-Fundee** is a cross-platform strength training application designed with hormonal cycle awareness. It integrates menstrual cycle data with structured training programs to provide optimized recommendations. Built with Flutter and Firebase, it targets iOS, Android, and Web.

## Project Overview
- **Platforms**: iOS, Android, Web
- **Language**: Dart 3.11+
- **Framework**: Flutter 3.41+
- **State Management**: Riverpod
- **Database**: Cloud Firestore (with offline persistence)
- **Authentication**: Firebase Auth (Apple, Google, Email/Password)
- **Architecture**: Feature-first Clean Architecture with Riverpod providers
- **Key Feature**: Periodized strength training programs synchronized with the user's menstrual cycle phases.

## Tech Stack & Architecture
- **UI**: Flutter with Material Design and GoRouter for navigation.
- **State Management**: Riverpod providers for dependency injection and reactive state.
- **Data Persistence**: Cloud Firestore with offline persistence enabled.
- **Authentication**: Firebase Auth with Sign in with Apple, Google Sign-In, and guest mode.
- **Observability**: Firebase Analytics and Crashlytics via `TelemetryService`.
- **CI/CD**: GitHub Actions (`flutter-release.yml`) for analysis, testing, and multi-platform release builds.

## Building and Running

### Prerequisites
- Flutter 3.41+
- Firebase CLI
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Key Commands
```bash
# Install dependencies
cd flutter_app && flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Run the app (guest mode / no Firebase)
flutter run

# Run the app with Firebase enabled
flutter run --dart-define=ENABLE_FIREBASE=true

# Build web release
flutter build web --release

# Build Android release
flutter build appbundle --release

# Build iOS release (unsigned)
flutter build ipa --release --no-codesign
```

## Project Structure
- `flutter_app/lib/main.dart`: Entry point.
- `flutter_app/lib/bootstrap.dart`: Firebase initialization and app startup.
- `flutter_app/lib/app/`: Root app widget, GoRouter, and theme.
- `flutter_app/lib/domain/models/`: Data models with `fromJson`/`toJson` for Firestore serialization.
- `flutter_app/lib/domain/calculations/`: Pure business logic (`WeightCalculations`, `CycleCalculations`).
- `flutter_app/lib/domain/enums.dart`: Shared enumerations.
- `flutter_app/lib/features/auth/`: Authentication (Firebase Auth, guest mode, providers).
- `flutter_app/lib/features/repositories/`: Firestore data repositories (Workout, Cycle, Lift, Record, CustomProgram).
- `flutter_app/lib/features/dashboard/`: Dashboard UI.
- `flutter_app/lib/features/settings/`: User settings UI.
- `flutter_app/lib/features/migration/`: Legacy data migration utilities.
- `flutter_app/lib/features/observability/`: Firebase Analytics & Crashlytics.
- `flutter_app/lib/features/shell/`: Main tab shell navigation.
- `flutter_app/lib/features/storage/`: Firebase Cloud Storage.
- `flutter_app/lib/firebase/`: Firebase bootstrap and feature flag.
- `flutter_app/test/`: Unit and widget tests.

## Firebase Configuration (Root Level)
- `firebase.json`: Firestore, Storage, and Hosting config.
- `.firebaserc`: Firebase project alias.
- `firestore.rules`: Security rules (user-scoped data isolation).
- `firestore.indexes.json`: Composite indexes for queries.
- `storage.rules`: Cloud Storage security rules.

## Development Conventions

### Data Modeling (Firestore)
- Models are plain Dart classes in `lib/domain/models/`.
- Each model implements `fromJson(Map<String, dynamic>)` and `toJson()` for Firestore serialization.
- Enum values are stored as strings and converted using `enumFromString()` from `enums.dart`.

### State Management (Riverpod)
- Use Riverpod `Provider`, `StreamProvider`, and `StateProvider` for all state.
- Feature modules expose providers in a `providers.dart` file at the feature root.
- Repositories abstract Firestore calls behind interfaces (e.g., `WorkoutRepository`, `CycleRepository`).
- The UI layer only accesses data through Riverpod providers—never directly through Firestore.

### Firebase Feature Flag
- Firebase is gated behind `--dart-define=ENABLE_FIREBASE=true`.
- When disabled, the app runs in guest/offline mode.
- All Firebase-dependent providers check the flag and return `null` or throw `StateError` when disabled.

### Logic & Calculations
- Keep business logic (weight rounding, 1RM percentages, cycle phase mapping) in static methods within `lib/domain/calculations/`.
- Always add unit tests for new calculation logic in `flutter_app/test/`.

## Testing
- **Unit Tests**: Located in `flutter_app/test/domain/`, using `flutter_test`.
- **Widget Tests**: Located in `flutter_app/test/`, using `flutter_test`.
- Run all tests: `flutter test` from `flutter_app/`.

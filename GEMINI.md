# Sundee Fundee - AI Context

Sundee Fundee is a hormonal-aware strength training tracker built with Flutter and Firebase. It helps users follow structured periodized programs while incorporating menstrual cycle phase data for optimized training recommendations.

## Project Overview

- **Core Purpose:** Cross-platform strength training tracker that adapts to the user's menstrual cycle.
- **Tech Stack:**
  - **Language:** Dart 3.11+
  - **Framework:** Flutter 3.41+
  - **State Management:** Riverpod
  - **Backend:** Firebase (Firestore, Auth, Storage, Analytics, Crashlytics)
  - **Routing:** GoRouter
  - **Hosting:** Firebase Hosting (for Web)
- **Architecture:** Feature-first Clean Architecture (`lib/domain`, `lib/features`, `lib/repositories`).

## Key Directories

- `flutter_app/lib/app`: App shell, routing (`router.dart`), and theme (`theme.dart`).
- `flutter_app/lib/domain`: Core business logic, models, and calculations (e.g., `cycle_calculations.dart`).
- `flutter_app/lib/features`: UI and logic for specific features (auth, cycle, dashboard, maxes, etc.).
- `flutter_app/lib/repositories`: Data access layer for Firestore and local storage.
- `flutter_app/test`: Unit and widget tests.

## Building and Running

### Development
```bash
cd flutter_app
flutter pub get

# Run in Guest Mode (local only)
flutter run

# Run with Firebase enabled
flutter run --dart-define=ENABLE_FIREBASE=true
```

### Scripts (Root Directory)
- `./run_local.sh`: Runs the app locally with Firebase enabled (Chrome).
- `./deploy.sh`: Builds and deploys the web app to Firebase Hosting.

### Testing and Analysis
```bash
flutter analyze
flutter test
```

### Firebase Configuration
To update Firebase configuration:
```bash
flutterfire configure \
  --project=sundee-fundee \
  --platforms=ios,android,web \
  --ios-bundle-id=com.sundeefundee.app \
  --android-package-name=com.sundeefundee.app
```

## Development Conventions

- **State Management:** Use Riverpod providers (typically found in `lib/features/*/providers.dart` or similar).
- **Routing:** Use GoRouter with auth-state-based redirects defined in `lib/app/router.dart`. It specifically handles `loading`, `unauthenticated`, `needsOnboarding`, `authenticated`, and `guest` statuses.
- **Theming:** Adhere to the `Light Theme` defined in `lib/app/theme.dart`.
  - **Primary:** `#1C354C` (Navy)
  - **Secondary:** `#E25E29` (Orange)
  - **Surface:** `#F4ECE1` (Cream)
- **Data Serialization:** Models in `lib/domain/models` use standard JSON serialization patterns for Firestore.
- **Linting:** Follow rules in `flutter_app/analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`).
- **Commits:** Use Conventional Commits (`feat:`, `fix:`, `docs:`, etc.).
- **Testing:** Add unit tests for logic in `lib/domain/calculations` and widget tests for key UI components.

## Knowledge Base & Learning

- **Phase Detection:** `CycleCalculations` determines the current cycle phase (Menstrual, Follicular, Ovulation, Luteal) from logged period data.
- **Program Generation:** `CycleProgramGenerator` adapts training programs based on the active cycle phase.
- **Guest Mode:** The app supports a guest mode via a compile-time flag `ENABLE_FIREBASE`.
- **Google Sign-In Web:** Requires initialization before use; handled in `AuthRepository`.

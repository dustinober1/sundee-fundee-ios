# Sundee Fundee

**Strength Gained - On Your Cycle** — Cross-platform strength training powered by your hormones.

## Overview

Sundee Fundee is a hormonal-aware strength training tracker built with Flutter and Firebase. It helps users follow structured periodized programs while incorporating menstrual cycle phase data for optimized training recommendations. Available on **iOS**, **Android**, and **Web**.

## Tech Stack

| Component | Technology |
|:---|:---|
| **Language** | Dart 3.11+ |
| **UI Framework** | Flutter 3.41+ |
| **State Management** | Riverpod |
| **Database** | Cloud Firestore (with offline persistence) |
| **Authentication** | Firebase Auth (Apple, Google, Email/Password) |
| **File Storage** | Firebase Cloud Storage |
| **Analytics** | Firebase Analytics |
| **Crash Reporting** | Firebase Crashlytics |
| **Routing** | GoRouter |
| **Hosting (Web)** | Firebase Hosting |

- ⏱️ **Workout Execution:** Active workout tracking with set-by-set logging of actual weights & reps vs prescribed amounts. Includes visual completion tracking and session management, accessible via a dedicated Workout Landing Screen tab.
- 📊 **Dynamic Dashboard:** Now features a personalized "Welcome {User Name}" message for a premium, familiar feel. includes quick access to next sessions and workout history.
- 🏋️ **Program Management:** Removed the dedicated "Programs" navigation tab to allow for manual oversight of weekly training schedules.
- 🦈 Sharkweek logo displayed full-width on the Cycle page during the Menstrual phase
- 🏋️ Set-by-set workout logging with prescribed weights (based on 1RM)
- 📈 **Automated Lift Records:** Completing a workout now automatically detects new personal records (1/3/5 RM) and updates your Max Lifts tracker.
- ⚙️ **Enhanced Settings & Legal:** Completely redesigned Settings screen with dedicated sections for Account, Support, and Legal. Added placeholders for Terms of Service, Privacy Policy, and Contact Support, along with mandatory account deletion functionality.
- ⚙️ **Admin Dashboard** allowing authorized users (e.g. dustinober@me.com) to upload and push new custom workout programs via JSON to Firestore directly from the mobile app.
- 🏋️ **Streamlined Exercise Library:** Removed redundant and non-essential movements, focusing on core strength and performance lifts.
- 📈 **Optimized Progress Tracking:** Removed 10 rep maxes to focus on strength-specific metrics (1/3/5 RM).
- 🚀 **Plyometrics Tracking:** Integrated specific tracking for Box Jumps and Broad Jumps in inches (highest/farthest effort).
- 📈 **Enhanced Max Lifts UI:** Redesigned the Personal Bests screen with search functionality, category-specific icons, and a modern, premium aesthetic.
- 📊 Progress tracking and personal records
- 🔄 Menstrual cycle phase tracking with training recommendations
- 👤 Guest mode for offline-first usage
- 🔐 Sign in with Apple & Google authentication
- ☁️ Real-time cloud sync across devices via Firestore
- 📱 Responsive design for mobile & web

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── bootstrap.dart            # Firebase init & app startup
│   ├── firebase_options.dart     # Generated Firebase config
│   ├── app/                      # App shell, router, theme
│   │   ├── app.dart              # Root MaterialApp widget
│   │   ├── router.dart           # GoRouter with auth redirects
│   │   └── theme.dart            # App-wide theming
│   ├── domain/                   # Core business logic & data
│   │   ├── enums.dart            # Shared enumerations
│   │   ├── models/               # Data models with Firestore serialization
│   │   └── calculations/         # Weight & cycle calculation logic
│   ├── features/                 # Feature modules (Clean Architecture)
│   │   ├── auth/                 # Authentication (Firebase Auth, guest mode)
│   │   ├── dashboard/            # Dashboard UI
│   │   ├── repositories/         # Firestore data repositories
│   │   ├── migration/            # Legacy data migration utilities
│   │   ├── observability/        # Analytics & crashlytics
│   │   ├── settings/             # User settings
│   │   ├── shell/                # Main tab shell
│   │   ├── shared/               # Shared widgets
│   │   └── storage/              # Firebase Cloud Storage
│   └── firebase/                 # Firebase bootstrap & config
├── test/                         # Unit & widget tests
├── android/                      # Android platform project
├── ios/                          # iOS platform project
├── web/                          # Web platform project
├── pubspec.yaml                  # Dart dependencies
└── analysis_options.yaml         # Lint rules
```

## Prerequisites

- Flutter 3.41+ (`flutter --version`)
- Dart 3.11+
- Firebase CLI (`npm install -g firebase-tools` or `curl -sL https://firebase.tools | bash`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- A Firebase project with iOS, Android, and Web apps registered

## Getting Started

```bash
# 1. Navigate to the Flutter app
cd flutter_app

# 2. Install dependencies
flutter pub get

# 3. Run static analysis
flutter analyze

# 4. Run tests
flutter test

# 5. Run the app (without Firebase — guest mode)
flutter run

# 6. Run the app with Firebase enabled
flutter run --dart-define=ENABLE_FIREBASE=true
```

### Firebase Configuration

To configure or refresh Firebase bindings:

```bash
flutterfire configure \
  --project=sundee-fundee \
  --platforms=ios,android,web \
  --ios-bundle-id=com.sundeefundee.app \
  --android-package-name=com.sundeefundee.app \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --android-out=android/app/google-services.json
```

This generates/updates:
- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

## Firebase Configuration Files

Root-level Firebase config files manage the backend:

| File | Purpose |
|------|---------|
| `firebase.json` | Firestore rules, indexes, storage rules, and hosting config |
| `.firebaserc` | Firebase project alias (`sundee-fundee`) |
| `firestore.rules` | Firestore security rules (user-scoped data isolation) |
| `firestore.indexes.json` | Composite index definitions |
| `storage.rules` | Cloud Storage security rules |

### Deploy Firebase Rules

```bash
# Deploy Firestore rules & indexes
firebase deploy --only firestore

# Deploy Storage rules
firebase deploy --only storage

# Deploy web app to Firebase Hosting
cd flutter_app && flutter build web --release
cd .. && firebase deploy --only hosting
```
### One-Step Deployment (Web)

A shortcut script is provided in the root directory to build and deploy the web app in one command:

```bash
./deploy.sh
```

This script automatically handles the `ENABLE_FIREBASE=true` flag and uses the `canvaskit` renderer for performance.

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI Framework | Flutter | Single codebase for iOS, Android, and Web |
| State Management | Riverpod | Type-safe, testable, modern Flutter state management |
| Database | Cloud Firestore | Real-time sync, offline persistence, NoSQL scalability |
| Auth | Firebase Auth | Multi-provider (Apple, Google, Email), cross-platform |
| Routing | GoRouter | Declarative routing with auth-based redirects |
| Architecture | Feature-first Clean Architecture | Separation of concerns, testability |

## Auth Flow

The app uses GoRouter with auth-state redirects:

1. **Loading** → `LoadingScreen` (Firebase initializing)
2. **Unauthenticated** → `SignInScreen` (Apple / Google / Guest)
3. **Needs Onboarding** → `OnboardingScreen` (name, experience, goals)
4. **Authenticated / Guest** → `MainShellScreen` (dashboard)

## Known Issues & Fixes

- **Firestore Permission Denied**: If you see `[cloud_firestore/permission-denied] Missing or insufficient permissions` when accessing features like the cycle tracker or program enrollments, ensure that your local `firestore.rules` file has been deployed to the Firebase project (`firebase deploy --only firestore`). Added missing `enrollments`, `periodLogs`, `symptomLogs`, and `cycleSettings` rules.
- **Dart Compiler Errors**: Resolved duplicate `_` variable naming errors in GoRouter error handlers and cycle tracking error states. Fixed missing required named parameters in `ProgramWeek` and `ProgramExercise` constructors in the admin dashboard. Addressed type resolution issues with Riverpod `AutoDisposeNotifier` in the rest timer provider by switching to `Notifier` with `.autoDispose` provider factory.
- **Web Authentication Plugins**: The application uses Firebase Auth's built-in `signInWithPopup` (with `GoogleAuthProvider` and `AppleAuthProvider`) on the Web platform. This avoids manual OAuth client ID configuration and bypasses initialization issues inherent to the `google_sign_in` and `sign_in_with_apple` web plugins. On mobile devices, the native plugins are still utilized. `AuthRepository` tracks `_googleSignInInitialized` to prevent signing out uninitialized plugins.

## Cycle-Based Training Recommendations

`CycleCalculations` provides training guidance per menstrual phase:

| Phase | Recommendation |
|-------|---------------|
| **Menstrual** | Low intensity, recovery focus |
| **Follicular** | Moderate, building strength |
| **Ovulation** | Peak intensity, PR attempts |
| **Luteal** | Maintenance, technique work |

## CI/CD

GitHub Actions workflows are located in `.github/workflows/`:

- **`flutter-release.yml`**: Analyze, test, and build release artifacts for Web, Android (.aab), and iOS (.ipa) on every push to `main`.

## Contributing

1. Make focused, atomic changes with corresponding tests.
2. Run `flutter analyze` and `flutter test` before committing.
3. Use Conventional Commits: `feat:`, `fix:`, `docs:`, etc.
4. Never commit secrets, API keys, or `.env` files.

## UI & Theme
- Transitioned from a dark theme defaults to a brand-new `Light Theme` (Cream, Navy, and Orange accents) to match the latest logos and branding.

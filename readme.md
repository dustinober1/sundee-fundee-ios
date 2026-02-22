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

## Features

- 📋 Structured training programs (periodized, multi-phase)
- 🏋️ Set-by-set workout logging with prescribed weights (based on 1RM)
- 📈 Max Lifts Tracker for recording 1RM, 3RM, 5RM, and 10RM for various powerlifting and Olympic lifts
- 📊 Progress tracking and personal records
- 🔄 Full menstrual cycle tracking: period logging, symptom tracking, phase-based training recommendations, and cycle settings
- 💪 Phase-aware training recommendations with exercise emphasis/avoidance guidance
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
│   │   ├── cycle/                # Period cycle tracking & phase recommendations
│   │   ├── dashboard/            # Dashboard UI
│   │   ├── maxes/                # Max Lifts tracker
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

- **Google Sign-In web plugin**: The `google_sign_in_web` plugin requires `initialize()` before any other method call. `AuthRepository` tracks initialization state via a `_googleSignInInitialized` flag and skips `GoogleSignIn.signOut()` when the plugin was never initialized (e.g., guest mode, email, or Apple sign-in paths).

## Cycle Tracking

The Cycle tab provides comprehensive menstrual cycle tracking, fully integrated with the strength training experience:

### Phase Detection & Status
`CycleCalculations` determines the current cycle phase from logged period data and user settings:

| Phase | Emoji | Training Recommendation |
|-------|-------|------------------------|
| **Menstrual** | 🩸 | Low intensity, recovery focus |
| **Follicular** | 🌱 | Moderate, building strength |
| **Ovulation** | ☀️ | Peak intensity, PR attempts |
| **Luteal** | 🌙 | Maintenance, technique work |

### Features
- **Phase Hero Card** — Displays current phase, cycle day, days until next phase, predicted next period, and recommended intensity
- **Quick Actions** — One-tap Start/End Period, Log Symptom, and Log Period with detailed bottom sheets
- **Training Recommendations** — Phase-specific exercise emphasis and avoidance guidance
- **Phase Timeline** — Color-coded progress bar showing all four phases relative to the current day
- **Symptom Quick-Log** — Tap emoji chips (Cramps, Headache, Bloating, Fatigue, Mood Swings, Acne, Back Pain, Insomnia) for instant logging
- **Period History** — View and delete past period logs with flow level and duration
- **Cycle Settings** — Sliders to configure average cycle length, period length, and luteal phase length

### Firestore Collections
All cycle data is stored under `users/{userId}/` with the following subcollections:
- `periodLogs/` — Start/end dates, flow level, notes
- `symptomLogs/` — Symptom ID, severity (1–5), date, notes
- `cycleSettings/` — Average cycle length, period length, luteal phase length, enabled symptoms

The application also includes the **Squat 1 Cycle**. For women, this baseline program's Sunday heavy lifting day is dynamically adapted based on their active cycle phase via `CycleProgramGenerator`.

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

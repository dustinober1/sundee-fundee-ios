# Sundee Fundee — Flutter App

Cross-platform Flutter client for the Sundee Fundee strength training app with Firebase backend.

## Prerequisites

- Flutter 3.41+
- Dart 3.11+
- Firebase project with iOS, Android, and Web apps registered
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

## Local Setup

```bash
flutter pub get
flutter analyze
flutter test
```

## Firebase Configuration

### Configure or refresh Firebase bindings

```bash
flutterfire configure \
  --project=sundee-fundee \
  --platforms=ios,android,web \
  --ios-bundle-id=com.sundeefundee.app \
  --android-package-name=com.sundeefundee.app \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --android-out=android/app/google-services.json
```

This generates / updates:
- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

## Running the App

### Guest mode (no Firebase required)

```bash
flutter run
```

### With Firebase enabled

```bash
flutter run --dart-define=ENABLE_FIREBASE=true
```

## Building Release Artifacts

```bash
# Web
flutter build web --release --dart-define=ENABLE_FIREBASE=true

# Android (AAB)
flutter build appbundle --release

# iOS (unsigned IPA)
flutter build ipa --release --no-codesign
```

## UI & Design

- **Dark theme** with brand color `#8D2A5B`, gold accent `#D4A853`
- **Sign-in screen**: gradient background, app logo, glassmorphism card, social sign-in (Apple/Google), email/password, guest mode
- **Loading screen**: branded splash with logo and gold progress indicator
- **Global styling**: rounded inputs, gradient primary buttons, styled navigation bar
- Design tokens centralized in `lib/app/theme.dart` (`AppColors`)

## Architecture

- **State Management**: Riverpod — providers in `lib/features/*/providers.dart`
- **Routing**: GoRouter with auth-state-based redirects
- **Data Access**: Firestore repositories behind abstract interfaces
- **Business Logic**: Pure calculations in `lib/domain/calculations/`
- **Firebase Gate**: Compile-time flag `ENABLE_FIREBASE` — when false, app runs in guest mode

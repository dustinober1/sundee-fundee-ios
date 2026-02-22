# Sundee Fundee Flutter App

Flutter cross-platform client for the Sundee Fundee migration from SwiftUI/CloudKit to Flutter/Firebase.

## Prerequisites

- Flutter 3.41+
- Dart 3.11+
- Firebase project(s) with iOS/Android/Web apps registered

## Local setup

```bash
flutter pub get
flutter analyze
flutter test
```

## Firebase bootstrap

This app initializes Firebase only when `ENABLE_FIREBASE=true` is supplied.

### Configure or refresh Firebase bindings

Run:

```bash
~/.pub-cache/bin/flutterfire configure \
  --project=sundee-fundee \
  --platforms=ios,android,web \
  --ios-bundle-id=com.sundeefundee.app \
  --android-package-name=com.sundeefundee.app \
  --ios-out=ios/Runner/GoogleService-Info.plist \
  --android-out=android/app/google-services.json
```

This updates:

- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

### Run with Firebase enabled

Firebase initialization is gated by a flag:

```bash
flutter run --dart-define=ENABLE_FIREBASE=true
```

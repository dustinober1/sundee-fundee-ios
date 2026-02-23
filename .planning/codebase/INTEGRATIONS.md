# Integrations

The app integrates with external services and libraries:

- **Firebase**
  - Firestore for data persistence (user data, programs, cycles, etc.)
  - Firebase Auth for user authentication (email/password, anonymous)
  - Firebase Storage for file uploads if needed
  - Analytics + Crashlytics for observability
  - Configured via `firebase_options.dart` and conditional `ENABLE_FIREBASE` flags
- **Third-party packages** (see `pubspec.yaml` for complete list)
  - `flutter_riverpod`, `go_router`, `flutter_localizations` etc.
- **Platform-specific**
  - Android: Gradle build, Google Services plugin, `google-services.json`
  - iOS: CocoaPods, `GoogleService-Info.plist` (not committed)
- **Development utilities**
  - `devtools_options.yaml`, analysis options linting
  - Custom migration service for legacy data

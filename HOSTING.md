# Hosting Guide — Sundee-Fundee

## Summary

Sundee-Fundee is hosted entirely on **Firebase**. The Flutter app targets iOS, Android, and Web from a single codebase, with Firebase providing all backend services.

## Firebase Services in Use

| Service | Purpose |
|---------|---------|
| **Cloud Firestore** | Primary database — real-time sync, offline persistence, user-scoped data |
| **Firebase Authentication** | Sign in with Apple, Google Sign-In, Email/Password, Guest mode |
| **Firebase Cloud Storage** | User file uploads (profile images, etc.) |
| **Firebase Hosting** | Web app deployment (`flutter_app/build/web`) |
| **Firebase Analytics** | Usage tracking and event logging |
| **Firebase Crashlytics** | Crash reporting and diagnostics |

## Deployment

### Web (Firebase Hosting)

```bash
# Build the Flutter web release
cd flutter_app
flutter build web --release --dart-define=ENABLE_FIREBASE=true

# Deploy to Firebase Hosting
cd ..
firebase deploy --only hosting
```

The web app is served from `flutter_app/build/web/` with SPA rewrites configured in `firebase.json`.

### Android (Google Play)

```bash
cd flutter_app
flutter build appbundle --release
```

Upload the `.aab` from `flutter_app/build/app/outputs/bundle/release/app-release.aab` to the Google Play Console.

### iOS (App Store / TestFlight)

```bash
cd flutter_app
flutter build ipa --release
```

Upload the `.ipa` from `flutter_app/build/ios/ipa/` via Xcode Organizer or Transporter.

## Firebase Rules Deployment

```bash
# Deploy Firestore security rules and indexes
firebase deploy --only firestore

# Deploy Cloud Storage security rules
firebase deploy --only storage

# Deploy everything
firebase deploy
```

## Firestore Data Architecture

All user data is scoped under `users/{userId}/` for security:

```
users/{userId}                    → User profile & settings
users/{userId}/workouts/          → Workout logs
users/{userId}/completedSets/     → Completed set data
users/{userId}/maxLifts/          → 1RM data
users/{userId}/oneRepMaxes/       → ORM history
users/{userId}/records/           → Personal records
users/{userId}/cycles/            → Cycle tracking data
users/{userId}/customPrograms/    → User-created programs
programCatalog/{programId}        → Public program catalog (read-only)
```

**Security rules** (`firestore.rules`) enforce that users can only read/write their own data. The `programCatalog` collection is publicly readable but not writable.

## CI/CD

GitHub Actions (`.github/workflows/flutter-release.yml`) handles:
1. **Quality gate**: `flutter analyze` + `flutter test`
2. **Web build**: `flutter build web --release`
3. **Android build**: `flutter build appbundle --release`
4. **iOS build**: `flutter build ipa --release --no-codesign`

Artifacts are uploaded for each platform on every push to `main`.

## Environment & Secrets

- **Firebase project**: `sundee-fundee` (configured in `.firebaserc`)
- **Firebase feature flag**: `ENABLE_FIREBASE=true` passed via `--dart-define`
- **CI secrets** (GitHub Actions):
  - `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
- Never commit sensitive keys, `GoogleService-Info.plist`, or `google-services.json`.

## Custom Domain (Optional)

To serve the web app from a custom domain (e.g., `app.sundeefundee.com`):

1. Go to Firebase Console → Hosting → Add custom domain
2. Verify domain ownership via DNS TXT record
3. Add CNAME record pointing to Firebase Hosting
4. Firebase provisions SSL automatically

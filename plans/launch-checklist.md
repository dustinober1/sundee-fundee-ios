# Sundee Fundee Launch Checklist

A comprehensive checklist for launching the Sundee Fundee hormonal-aware strength training application on iOS, Android, and Web platforms.

---

## 1. Development Environment Setup

- [ ] **Install Flutter SDK 3.41+**
  - Verify: `flutter --version`
  - Ensure Dart 3.11+ is included

- [ ] **Install Firebase CLI**
  - Option A: `npm install -g firebase-tools`
  - Option B: `curl -sL https://firebase.tools | bash`
  - Verify: `firebase --version`

- [ ] **Install FlutterFire CLI**
  - Run: `dart pub global activate flutterfire_cli`
  - Verify: `flutterfire --version`

- [ ] **Install Platform-Specific Tools**
  - **Android**: Android Studio with Android SDK
  - **iOS**: Xcode 15+ (macOS only)
  - **Web**: Chrome browser for testing

---

## 2. Firebase Project Configuration

### 2.1 Firebase Console Setup

- [ ] **Create Firebase Project** (if not exists)
  - Project ID: `sundee-fundee`
  - Enable Google Analytics

- [ ] **Enable Required Firebase Services**
  - [ ] Authentication (Email/Password, Google, Apple)
  - [ ] Cloud Firestore
  - [ ] Cloud Storage
  - [ ] Firebase Analytics
  - [ ] Firebase Crashlytics

### 2.2 Authentication Providers

- [ ] **Enable Email/Password Authentication**
  - Firebase Console → Authentication → Sign-in method

- [ ] **Enable Google Sign-In**
  - Firebase Console → Authentication → Sign-in method
  - Configure OAuth consent screen in Google Cloud Console

- [ ] **Enable Sign in with Apple**
  - Firebase Console → Authentication → Sign-in method
  - Configure Apple Developer capabilities (requires Apple Developer account)

### 2.3 Platform Registration

- [ ] **Register iOS App**
  - Bundle ID: `com.sundeefundee.app`
  - Download `GoogleService-Info.plist`
  - Already exists at: [`flutter_app/ios/Runner/GoogleService-Info.plist`](flutter_app/ios/Runner/GoogleService-Info.plist)

- [ ] **Register Android App**
  - Package name: `com.sundeefundee.app`
  - Download `google-services.json`
  - Already exists at: [`flutter_app/android/app/google-services.json`](flutter_app/android/app/google-services.json)

- [ ] **Register Web App**
  - Add authorized domains for hosting
  - Configure OAuth redirect URLs

### 2.4 Firestore Configuration

- [ ] **Deploy Firestore Security Rules**
  ```bash
  firebase deploy --only firestore:rules
  ```
  - Rules file: [`firestore.rules`](firestore.rules)

- [ ] **Deploy Firestore Indexes**
  ```bash
  firebase deploy --only firestore:indexes
  ```
  - Indexes file: [`firestore.indexes.json`](firestore.indexes.json)

- [ ] **Create Required Indexes** (if any composite indexes needed)
  - Check Firebase Console for missing index errors

### 2.5 Storage Configuration

- [ ] **Deploy Storage Security Rules**
  ```bash
  firebase deploy --only storage
  ```
  - Rules file: [`storage.rules`](storage.rules)

---

## 3. iOS-Specific Requirements

### 3.1 Apple Developer Account

- [ ] **Active Apple Developer Account** ($99/year)
  - Required for App Store distribution
  - Required for Sign in with Apple

- [ ] **Create App ID**
  - Bundle ID: `com.sundeefundee.app`
  - Enable capabilities: Sign in with Apple

- [ ] **Create Provisioning Profiles**
  - Development profile for testing
  - Distribution profile for App Store

### 3.2 Xcode Configuration

- [ ] **Configure Signing & Capabilities**
  - Open `flutter_app/ios/Runner.xcworkspace` in Xcode
  - Set Team and Signing Certificate
  - Enable Sign in with Apple capability

- [ ] **Configure Info.plist**
  - Verify permissions/capabilities descriptions
  - File: [`flutter_app/ios/Runner/Info.plist`](flutter_app/ios/Runner/Info.plist)

- [ ] **Update App Display Name**
  - CFBundleDisplayName in Info.plist

- [ ] **Configure App Icons**
  - Icons already exist in `flutter_app/ios/Runner/Assets.xcassets/`

### 3.3 CocoaPods

- [ ] **Install CocoaPods Dependencies**
  ```bash
  cd flutter_app/ios && pod install
  ```

---

## 4. Android-Specific Requirements

### 4.1 Google Play Developer Account

- [ ] **Active Google Play Developer Account** ($25 one-time fee)
  - Required for Google Play distribution

### 4.2 Signing Configuration

- [ ] **Generate Release Keystore**
  ```bash
  keytool -genkey -v -keystore ~/sundee-fundee-release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias sundee-fundee
  ```

- [ ] **Configure Key Properties**
  - Create `flutter_app/android/key.properties` (not in version control)
  - Reference keystore path and credentials

- [ ] **Update Build Configuration**
  - Configure signing in [`flutter_app/android/app/build.gradle.kts`](flutter_app/android/app/build.gradle.kts)

### 4.3 App Configuration

- [ ] **Verify Application ID**
  - Check `applicationId` in build.gradle.kts

- [ ] **Configure App Icons**
  - Icons already exist in `flutter_app/android/app/src/main/res/mipmap-*/`

---

## 5. Web-Specific Requirements

### 5.1 Firebase Hosting

- [ ] **Configure Custom Domain** (optional)
  - Firebase Console → Hosting → Add custom domain
  - Configure DNS records

- [ ] **Verify Hosting Configuration**
  - File: [`firebase.json`](firebase.json)
  - Public directory: `flutter_app/build/web`

### 5.2 Web App Configuration

- [ ] **Configure OAuth Redirect URLs**
  - Add authorized JavaScript origins
  - Add authorized redirect URIs for Google/Apple sign-in

- [ ] **Update Web Manifest**
  - Configure PWA settings if needed

---

## 6. Pre-Launch Testing

### 6.1 Local Testing

- [ ] **Run Static Analysis**
  ```bash
  cd flutter_app && flutter analyze
  ```

- [ ] **Run Unit Tests**
  ```bash
  cd flutter_app && flutter test
  ```

- [ ] **Run Locally with Firebase**
  ```bash
  ./run_local.sh
  ```
  - Or: `cd flutter_app && flutter run -d chrome --dart-define=ENABLE_FIREBASE=true`

### 6.2 Platform Testing

- [ ] **Test on iOS Simulator/Device**
  ```bash
  cd flutter_app && flutter run -d ios --dart-define=ENABLE_FIREBASE=true
  ```

- [ ] **Test on Android Emulator/Device**
  ```bash
  cd flutter_app && flutter run -d android --dart-define=ENABLE_FIREBASE=true
  ```

- [ ] **Test on Web Browser**
  ```bash
  cd flutter_app && flutter run -d chrome --dart-define=ENABLE_FIREBASE=true
  ```

### 6.3 Feature Testing

- [ ] **Authentication Flow**
  - Test Sign in with Apple
  - Test Google Sign-In
  - Test Email/Password authentication
  - Test Guest mode

- [ ] **Firestore Operations**
  - Test data read/write
  - Verify security rules work correctly

- [ ] **Cycle Tracking Features**
  - Test period logging
  - Test symptom logging
  - Verify cycle calculations

- [ ] **Workout Features**
  - Test workout execution
  - Test program enrollment
  - Verify personal record tracking

---

## 7. Build Release Artifacts

### 7.1 Web Build

- [ ] **Build Web Release**
  ```bash
  ./deploy.sh
  ```
  - Or manually:
  ```bash
  cd flutter_app && flutter build web --release --dart-define=ENABLE_FIREBASE=true
  ```

### 7.2 iOS Build

- [ ] **Build iOS Release**
  ```bash
  cd flutter_app && flutter build ipa --release --dart-define=ENABLE_FIREBASE=true
  ```

- [ ] **Archive in Xcode** (for App Store)
  - Open Xcode
  - Product → Archive
  - Upload to App Store Connect

### 7.3 Android Build

- [ ] **Build Android App Bundle (AAB)**
  ```bash
  cd flutter_app && flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true
  ```

- [ ] **Build Android APK** (for testing)
  ```bash
  cd flutter_app && flutter build apk --release --dart-define=ENABLE_FIREBASE=true
  ```

---

## 8. App Store Submission

### 8.1 iOS App Store

- [ ] **Create App Record in App Store Connect**
  - App name: Sundee Fundee
  - Bundle ID: com.sundeefundee.app
  - Primary language: English

- [ ] **Prepare App Store Assets**
  - App screenshots (required sizes for all supported devices)
  - App icon (1024x1024)
  - App description
  - Keywords
  - Support URL
  - Privacy Policy URL

- [ ] **Complete App Privacy Declaration**
  - Declare health data collection (cycle tracking)
  - Declare data sharing practices

- [ ] **Submit for Review**
  - Upload build via Xcode or Transporter
  - Complete submission questionnaire
  - Submit for App Review

### 8.2 Google Play Store

- [ ] **Create App in Google Play Console**
  - App name: Sundee Fundee
  - Package name: com.sundeefundee.app

- [ ] **Prepare Store Listing**
  - App screenshots (phone, tablet)
  - Feature graphic (1024x500)
  - App icon (512x512)
  - App description
  - Privacy Policy URL

- [ ] **Complete Content Rating Questionnaire**

- [ ] **Complete Data Safety Section**
  - Declare health data collection
  - Declare data sharing practices

- [ ] **Upload AAB**
  - Upload to Production track
  - Or use Internal/Closed Testing tracks first

- [ ] **Submit for Review**

---

## 9. CI/CD Configuration

### 9.1 GitHub Actions Secrets

The CI/CD pipeline in [`.github/workflows/flutter-release.yml`](.github/workflows/flutter-release.yml) requires these secrets:

- [ ] **ANDROID_KEYSTORE_BASE64**
  - Base64-encoded keystore file

- [ ] **ANDROID_KEYSTORE_PASSWORD**
  - Keystore password

- [ ] **ANDROID_KEY_ALIAS**
  - Key alias name

- [ ] **ANDROID_KEY_PASSWORD**
  - Key password

### 9.2 Verify CI/CD Pipeline

- [ ] **Test Workflow Triggers**
  - Push to main branch
  - Pull request

- [ ] **Verify Artifact Generation**
  - Web release artifact
  - Android AAB artifact
  - iOS IPA artifact

---

## 10. Post-Launch

### 10.1 Monitoring

- [ ] **Set Up Firebase Crashlytics Alerts**
  - Configure email notifications for crashes

- [ ] **Monitor Analytics**
  - Track user engagement
  - Monitor authentication success rates

### 10.2 Legal & Compliance

- [ ] **Privacy Policy Published**
  - Must be accessible via URL
  - Must cover health data handling

- [ ] **Terms of Service Published**

- [ ] **Medical Disclaimer Displayed**
  - Already implemented in app

### 10.3 Support Infrastructure

- [ ] **Support Email/Contact Configured**

- [ ] **App Store Support URLs Configured**

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Install dependencies | `cd flutter_app && flutter pub get` |
| Run analysis | `cd flutter_app && flutter analyze` |
| Run tests | `cd flutter_app && flutter test` |
| Run locally | `./run_local.sh` |
| Deploy web | `./deploy.sh` |
| Deploy Firestore rules | `firebase deploy --only firestore` |
| Deploy Storage rules | `firebase deploy --only storage` |
| Configure Firebase | `flutterfire configure --project=sundee-fundee` |

---

## Current Status Summary

Based on the project analysis, the following items appear to be **already configured**:

| Item | Status | Location |
|------|--------|----------|
| Firebase project | ✅ Configured | `sundee-fundee` |
| iOS Firebase config | ✅ Present | `flutter_app/ios/Runner/GoogleService-Info.plist` |
| Android Firebase config | ✅ Present | `flutter_app/android/app/google-services.json` |
| Firebase options | ✅ Generated | `flutter_app/lib/firebase_options.dart` |
| Firestore rules | ✅ Present | `firestore.rules` |
| Storage rules | ✅ Present | `storage.rules` |
| CI/CD workflow | ✅ Present | `.github/workflows/flutter-release.yml` |
| Deploy script | ✅ Present | `deploy.sh` |
| Local run script | ✅ Present | `run_local.sh` |

---

*Generated: 2026-02-23*

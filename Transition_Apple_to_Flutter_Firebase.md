# Transition Plan: Native iOS to Flutter & Firebase

This document details the comprehensive strategy for migrating the Sundee-Fundee application from an Apple-exclusive architecture (SwiftUI, SwiftData, CloudKit) to a cross-platform solution supporting iOS, Android, and Web using Flutter and Firebase.

## 1. Executive Summary
The goal of this transition is to maintain the premium, native feel of the current iOS application while expanding its reach to Android and Web users. By adopting Flutter, we achieve a single codebase for UI and business logic. By adopting Firebase, we replace Apple's CloudKit and SwiftData with a robust, offline-capable NoSQL database and authentication system that works seamlessly across all platforms.

### Tech Stack Mapping
| Component | Current (Apple Native) | Target (Cross-Platform) |
| :--- | :--- | :--- |
| **Language** | Swift 5.9 | Dart |
| **UI Framework** | SwiftUI | Flutter |
| **State Management** | `@Observable` & `ModelContext` | Riverpod (or Provider) |
| **Local Database** | SwiftData | Cloud Firestore (with Offline Persistence) |
| **Cloud Database** | CloudKit | Cloud Firestore |
| **Authentication** | Sign in with Apple | Firebase Authentication |
| **File Storage** | CloudKit / Local | Firebase Cloud Storage |
| **Analytics/Crash Reporting** | - | Google Analytics / Firebase Crashlytics |

---

## 2. Phase 1: Architecture and Data Modeling

Before writing UI code, the foundational data structures and cloud services must be established.

### 2.1 Firebase Project Setup
*   Create a new Firebase project (e.g., `sundee-fundee-app`).
*   Enable **Authentication**, **Cloud Firestore**, and **Cloud Storage**.
*   Register the iOS, Android, and Web applications within the Firebase console to generate the necessary configuration files (`GoogleService-Info.plist` for iOS, `google-services.json` for Android, and Firebase Config object for Web).

### 2.2 Data Schema Migration (SwiftData to Firestore)
Firestore is a NoSQL, document-based database. We need to map the flat, relational-style SwiftData `@Model` classes to Firestore Collections and Documents.

*   **Users Collection:** `users/{userId}`
    *   Stores user profile info, settings, and current cycle data.
*   **Workouts Collection:** `users/{userId}/workouts/{workoutId}`
    *   Sub-collection for isolation and security. Stores logged workouts and history.
*   **Max Lifts Collection:** `users/{userId}/maxLifts/{liftId}`
    *   Sub-collection storing 1RM data and history for calculations.

*Action Item:* Create Dart data classes (e.g., `UserModel`, `WorkoutModel`, `LiftMaxModel`) with explicit `fromJson` and `toJson` methods to handle Firestore serialization.

### 2.3 Authentication Strategy
*   Enable **Sign in with Apple** in Firebase Auth (crucial for retaining existing iOS users).
*   Enable **Sign in with Google** (standard for Android/Web).
*   Enable **Email/Password** as a fallback.
*   Implement a Firebase Auth listener in Flutter to manage the global authentication state.

---

## 3. Phase 2: Core Logic and State Management

### 3.1 Porting Business Logic (Swift to Dart)
The pure business logic is framework-agnostic and should be ported first. This ensures the app's core value—calculating weights and syncing with cycle phases—remains intact.
*   Translate static utility namespaces like `WeightCalculations` and `CycleCalculations` from Swift to Dart.
*   Port the `ProgramRepository` logic that parses the JSON training programs.
*   *Testing constraint:* Immediately write Dart unit tests corresponding to the existing Swift unit tests (`SundeeFundeeTests`) to verify calculation accuracy.

### 3.2 State Management Architecture
Replace SwiftUI's `@Observable` with **Riverpod** (the modern standard for Flutter state management).
*   **Providers:** Create providers for user settings, loaded programs, and current cycle phase.
*   **Repository Pattern:** Abstract Firestore calls behind Repository classes (e.g., `WorkoutRepository`, `AuthRepository`). The UI will only interact with these repositories via Riverpod, decoupling the views from the database implementation.

---

## 4. Phase 3: UI and UX Rebuilding

Recreate the SwiftUI interface using Flutter Widgets. Flutter's declarative nature makes this a relatively 1:1 conceptual mapping.

### Widget Mapping Guide
| SwiftUI | Flutter Equivalent |
| :--- | :--- |
| `VStack`, `HStack`, `ZStack` | `Column`, `Row`, `Stack` |
| `Text`, `Image` | `Text`, `Image` (or `SvgPicture`) |
| `List`, `ScrollView` | `ListView`, `SingleChildScrollView` |
| `NavigationStack` / `NavigationLink` | `Navigator` / `GoRouter` or `AutoRoute` |
| `.padding()`, `.background()` | `Padding`, `Container` (or `DecoratedBox`) |
| `@State`, `@Binding` | `StatefulWidget`, or Riverpod `StateProvider` |

### Platform Adaptability
*   Use standard Material Design for Android/Web and Cupertino widgets for iOS if a 100% native feel is desired, OR build a unified, custom branded design system (recommended for modern fitness apps).
*   Implement responsive breakpoints for the Web version to ensure dashboards look good on desktop monitors vs. mobile screens.

---

## 5. Phase 4: Data Migration Strategy for Existing Users

Since the app is currently live (or has test data) using CloudKit, a strategy is needed to migrate existing users' data to Firebase without data loss.

### The "Lazy Migration" Approach (Recommended)
1.  **Upon Update:** The user downloads the new Flutter version of the app over the old native iOS version.
2.  **First Login:** The user logs in using their existing Apple ID.
3.  **Local Check:** The Flutter app checks the local device for legacy SwiftData SQLite files or utilizes a native channel (Platform Channels in Flutter) to call a Swift function that reads the existing SwiftData/CloudKit records.
4.  **Upload:** The app silently reads this legacy data and writes it to the new Firestore collections.
5.  **Completion:** Once verified, the app flags the migration as complete and relies solely on Firestore moving forward.

---

## 6. Phase 5: Testing, CI/CD, and Deployment

### 6.1 Testing
*   **Unit Tests:** Verify all Dart business logic and calculations.
*   **Widget Tests:** Verify UI components render correctly in isolation.
*   **Integration Tests:** Verify the full flow (Login -> Calculate Max -> Log Workout) on both iOS and Android simulators.

### 6.2 CI/CD Pipeline
*   Set up **GitHub Actions** or **Codemagic**.
*   Configure pipelines to automatically run tests, build iOS (.ipa), Android (.aab), and Web artifacts on every push to the `main` branch.

### 6.3 Deployment
*   **Android:** Deploy the `.aab` file to the Google Play Console.
*   **iOS:** Deploy using Fastlane heavily via TestFlight, then the App Store.
*   **Web:** Deploy the compiled web artifacts using **Firebase Hosting**, connected to a custom domain (e.g., `app.sundeefundee.com`).

---

## Next Steps to Begin
1. Define the exact Firestore data schema on paper/whiteboard based on the current Swift `Models/` directory.
2. Initialize the empty Flutter project and connect the Firebase environments.
3. Begin porting `WeightCalculations.swift` and `CycleCalculations.swift` to Dart to establish the testing baseline.

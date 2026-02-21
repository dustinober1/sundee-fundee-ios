# Sundee Fundee

**Native iOS strength training app** powered by your cycle.

## Overview

Sundee Fundee is a hormonal-aware strength training tracker built with SwiftUI and CloudKit. It helps users follow structured periodized programs while incorporating menstrual cycle phase data for optimized training recommendations.

## Tech Stack

- **UI**: SwiftUI (iOS 17+)
- **Data**: SwiftData with automatic CloudKit sync
- **Auth**: Sign in with Apple
- **Charts**: Swift Charts
- **Backend**: Apple CloudKit (private + public databases)
- **Architecture**: MVVM with `@Observable`

## Features

- 📋 Structured training programs (periodized, multi-phase)
- 🏋️ Set-by-set workout logging with prescribed weights (based on 1RM)
- 📊 Progress tracking with charts and personal records
- 🔄 Menstrual cycle phase tracking with training recommendations
- ⏱ Rest timer with haptic feedback
- ☁️ Automatic iCloud sync across devices
- 🎉 Celebration animations for PRs

## Project Structure

```
SundeeFundee/
├── App/                    # App entry point & root views
├── Models/                 # SwiftData models & Codable types
├── Views/                  # SwiftUI views organized by feature
│   ├── Auth/
│   ├── Dashboard/
│   ├── Onboarding/
│   ├── Programs/
│   ├── Progress/
│   ├── Settings/
│   ├── Workout/
│   └── Components/
├── ViewModels/             # @Observable view models
├── Services/               # Business services (ProgramRepository, etc.)
├── Utilities/              # Calculations, helpers, Keychain
├── Resources/              # Assets, program JSON files
│   ├── Programs/           # Training program definitions
│   └── Assets.xcassets
└── Extensions/             # Swift extensions
```

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Apple Developer account (for CloudKit & Sign in with Apple)

## Getting Started

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate the Xcode project: `xcodegen generate`
3. Open `SundeeFundee.xcodeproj` in Xcode
4. Set your development team in Signing & Capabilities
5. Configure CloudKit container: `iCloud.com.sundeefundee.app`
6. Build and run on simulator or device

## Running Tests

```bash
xcodegen generate
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| UI Framework | SwiftUI | Native, declarative, best iOS integration |
| Persistence | SwiftData | Modern, automatic CloudKit sync |
| Backend | CloudKit | Zero server cost, native Apple integration |
| Auth | Sign in with Apple | Required for CloudKit identity |
| Charts | Swift Charts | Native framework, no dependencies |
| State | @Observable | Modern Swift observation, no 3rd party |
| Min iOS | 17.0 | Required for SwiftData |

## Legacy Code

Previous implementations (Next.js PWA, Flutter, React Native) are archived on the `legacy/web-flutter-rn` branch for reference.
